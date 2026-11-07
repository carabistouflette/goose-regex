/* SPDX-License-Identifier: Apache-2.0 */
#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>
#include "../native/regex.h"
int LLVMFuzzerTestOneInput(const uint8_t *data, size_t size) {
    if (!size || size>32768) return 0;
    size_t split=data[0] % size;
    int64_t config[4]={32768,1048576,1000,100}, m[4], f[3], out[128];
    int rc=(int)gr_compile((gr_bytes){data,(int64_t)split},(gr_ints){config,4},(gr_ints){m,4});
    if (!rc) {
        rc=(int)gr_find(m[0],(gr_bytes){data+split,(int64_t)(size-split)},0,(gr_ints){out,128},(gr_ints){f,3});
        if (rc || !f[0]) { for(int i=0;i<128;++i) if(out[i]!=-1) abort(); }
        else for(int i=0;i<f[1];++i) {
            if(out[2*i]==-1 && out[2*i+1]==-1) continue;
            if(out[2*i]<0 || out[2*i]>out[2*i+1] || (uint64_t)out[2*i+1]>size-split) abort();
        }
        if(gr_close(m[0])) abort();
    }
    return 0;
}
