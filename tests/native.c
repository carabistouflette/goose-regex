/* SPDX-License-Identifier: Apache-2.0 */
#define PCRE2_CODE_UNIT_WIDTH 8
#include <pcre2.h>
#include <assert.h>
#include <pthread.h>
#include <stdio.h>
#include <string.h>
#include "../native/regex.h"
extern void gr_test_fail_after(int64_t);
extern void gr_test_find_hook(void (*)(void));
static gr_bytes bytes(const char *p) { return (gr_bytes){(const uint8_t *)p, (int64_t)strlen(p)}; }
static int64_t config[4] = {1048576,8388608,1000000,1000};
static int compile(const char *p, int64_t *meta) {
    return (int)gr_compile(bytes(p), (gr_ints){config,4}, (gr_ints){meta,4});
}
static void basic(void) {
    int64_t m[4], f[3], out[128];
    assert(compile("(a+)(b)?",m)==GR_OK && m[1]==3);
    int64_t id=m[0];
    assert(gr_find(id,bytes("xxaaa"),0,(gr_ints){out,128},(gr_ints){f,3})==GR_OK);
    assert(f[0]==1 && f[1]==3 && out[0]==2 && out[1]==5 && out[4]==-1 && out[127]==-1);
    assert(gr_find(id,bytes("zzz"),0,(gr_ints){out,128},(gr_ints){f,3})==GR_OK && !f[0]);
    for(int i=0;i<128;++i) assert(out[i]==-1);
    assert(gr_close(id)==GR_OK && gr_close(id)==GR_HANDLE);
    assert(compile("x",m)==GR_OK && m[0]!=id);
    assert(gr_find(id,bytes("x"),0,(gr_ints){out,128},(gr_ints){f,3})==GR_HANDLE);
    assert(gr_close(m[0])==GR_OK);
    assert(compile("(",m)==GR_PATTERN && m[0]==0 && m[3]>=0);
    assert(compile("(*UTF)x",m)==GR_PATTERN);
    assert(compile("(*UCP)x",m)==GR_PATTERN);
    assert(compile("(?=(ab))a",m)==GR_OK);
    assert(gr_find(m[0],bytes("ab"),0,(gr_ints){out,128},(gr_ints){f,3})==GR_OK);
    assert(out[1]==1 && out[3]==2);
    assert(gr_close(m[0])==GR_OK);
    uint8_t pattern[]={0,255}, subject[]={1,0,255,2};
    assert(gr_compile((gr_bytes){pattern,2},(gr_ints){config,4},(gr_ints){m,4})==GR_OK);
    assert(gr_find(m[0],(gr_bytes){subject,4},0,(gr_ints){out,128},(gr_ints){f,3})==GR_OK);
    assert(out[0]==1 && out[1]==3 && gr_close(m[0])==GR_OK);
}
static void failures(void) {
    int64_t m[4], f[3], out[128];
    int success=0;
    for(int site=0;site<100;++site) {
        gr_test_fail_after(site);
        int rc=compile("(a+)(b)?",m);
        gr_test_fail_after(-1);
        if(rc==GR_OK) { assert(gr_close(m[0])==GR_OK); success=1; break; }
        assert(rc==GR_MEMORY && m[0]==0);
        assert(compile("x",m)==GR_OK && gr_close(m[0])==GR_OK);
    }
    assert(success);
    /* First search can allocate retained backtracking frames. Failure must
     * leave empty output and permit retry on the same live handle. */
    success=0;
    for(int site=0;site<100;++site) {
        assert(compile("(a+)(b)?",m)==GR_OK);
        gr_test_fail_after(site);
        int rc=(int)gr_find(m[0],bytes("aaa"),0,(gr_ints){out,128},(gr_ints){f,3});
        gr_test_fail_after(-1);
        if(rc==GR_OK) success=1;
        else {
            assert(rc==GR_MEMORY && !f[0]);
            for(int i=0;i<128;++i) assert(out[i]==-1);
            assert(gr_find(m[0],bytes("aaa"),0,(gr_ints){out,128},(gr_ints){f,3})==GR_OK && f[0]);
        }
        assert(gr_close(m[0])==GR_OK);
        if(success) break;
    }
    assert(success);
    config[1]=1;
    assert(compile("x",m)==GR_LIMIT && m[0]==0);
    config[1]=8388608;
    config[2]=10;
    assert(compile("(*NO_START_OPT)(a+)+$",m)==GR_OK);
    assert(gr_find(m[0],bytes("aaaaaaaaaaaaaaaaaaaaaaaaaaaa!"),0,(gr_ints){out,128},(gr_ints){f,3})==GR_LIMIT);
    assert(f[0]==0 && out[0]==-1);
    assert(gr_close(m[0])==GR_OK);
    config[2]=1000000;
    int64_t ids[32];
    for(int i=0;i<32;++i) { assert(compile("",m)==GR_OK); ids[i]=m[0]; }
    assert(compile("",m)==GR_LIMIT && m[0]==0);
    for(int i=0;i<32;++i) assert(gr_close(ids[i])==GR_OK);
    /* Unaligned ABI output. */
    unsigned char storage[33];
    assert(gr_compile(bytes("a"),(gr_ints){config,4},(gr_ints){(int64_t *)(void *)(storage+1),4})==GR_OK);
    int64_t token; memcpy(&token,storage+1,8); assert(gr_close(token)==GR_OK);
}
static void *worker(void *unused) {
    (void)unused;
    for(int i=0;i<100;++i) {
        int64_t m[4], f[3], out[4];
        assert(compile("(a+)",m)==GR_OK);
        assert(gr_find(m[0],bytes("aaa"),0,(gr_ints){out,4},(gr_ints){f,3})==GR_OK && f[0]);
        assert(gr_close(m[0])==GR_OK);
    }
    return NULL;
}
static pthread_mutex_t gate_mutex = PTHREAD_MUTEX_INITIALIZER;
static pthread_cond_t gate_cond = PTHREAD_COND_INITIALIZER;
static int entered, resume_search;
static void hold_search(void) {
    pthread_mutex_lock(&gate_mutex);
    entered=1; pthread_cond_broadcast(&gate_cond);
    while(!resume_search) pthread_cond_wait(&gate_cond,&gate_mutex);
    pthread_mutex_unlock(&gate_mutex);
}
static void *held_worker(void *opaque) {
    int64_t token=*(int64_t *)opaque, out[2], meta[3];
    assert(gr_find(token,bytes("a"),0,(gr_ints){out,2},(gr_ints){meta,3})==GR_OK && meta[0]);
    return NULL;
}
static void contention(void) {
    int64_t m[4], f[3], out[2];
    assert(compile("a",m)==GR_OK);
    gr_test_find_hook(hold_search);
    pthread_t thread; assert(!pthread_create(&thread,NULL,held_worker,&m[0]));
    pthread_mutex_lock(&gate_mutex);
    while(!entered) pthread_cond_wait(&gate_cond,&gate_mutex);
    pthread_mutex_unlock(&gate_mutex);
    assert(gr_close(m[0])==GR_BUSY);
    assert(gr_find(m[0],bytes("a"),0,(gr_ints){out,2},(gr_ints){f,3})==GR_BUSY);
    assert(!f[0] && out[0]==-1 && out[1]==-1);
    pthread_mutex_lock(&gate_mutex);
    resume_search=1; pthread_cond_broadcast(&gate_cond);
    pthread_mutex_unlock(&gate_mutex);
    assert(!pthread_join(thread,NULL)); gr_test_find_hook(NULL);
    assert(gr_find(m[0],bytes("a"),0,(gr_ints){out,2},(gr_ints){f,3})==GR_OK && f[0]);
    assert(gr_close(m[0])==GR_OK);
}
static void search_quota(void) {
    int64_t m[4], f[3], out[2];
    config[1]=4096;
    assert(compile("a",m)==GR_OK);
    assert(gr_find(m[0],bytes("a"),0,(gr_ints){out,2},(gr_ints){f,3})==GR_LIMIT);
    assert(!f[0] && out[0]==-1 && out[1]==-1);
    assert(gr_close(m[0])==GR_OK);
    config[1]=8388608;
    assert(compile("a",m)==GR_OK && gr_close(m[0])==GR_OK);
}
int main(void) {
    char version[64]; assert(pcre2_config(PCRE2_CONFIG_VERSION, version)>0);
    printf("linked PCRE2: %s\n",version);
    basic(); failures(); contention(); search_quota();
    pthread_t threads[8];
    for(int i=0;i<8;++i) assert(!pthread_create(&threads[i],NULL,worker,NULL));
    for(int i=0;i<8;++i) assert(!pthread_join(threads[i],NULL));
    puts("native tests passed");
}
