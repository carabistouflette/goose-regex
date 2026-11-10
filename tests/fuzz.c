/* SPDX-License-Identifier: Apache-2.0 */
#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>
#include "../native/regex.h"
int LLVMFuzzerTestOneInput(const uint8_t *data, size_t size) {
    if (size<2 || size>32768) return 0;
    size_t payload=size-2;
    size_t split=((size_t)data[0]*256+data[1]) % (payload+1);
    data+=2;
    size=payload;
    int64_t config[4]={32768,1048576,1000,100}, m[4], f[3], out[128];
    int rc=(int)gr_compile((gr_bytes){data,(int64_t)split},(gr_ints){config,4},(gr_ints){m,4});
    if (!rc) {
        if (m[0]<=0 || m[1]<1 || m[1]>64) abort();
        rc=(int)gr_find(m[0],(gr_bytes){data+split,(int64_t)(size-split)},0,(gr_ints){out,128},(gr_ints){f,3});
        if (rc || !f[0]) {
            if (f[0]!=0 || f[1]!=0) abort();
            for(size_t i=0;i<128;++i) if(out[i]!=-1) abort();
        } else {
            if (f[0]!=1 || f[1]!=m[1] || f[1]<1 || f[1]>64) abort();
            if(out[0]<0 || out[1]<0) abort();
            for(size_t i=(size_t)f[1]*2;i<128;++i) if(out[i]!=-1) abort();
            for(int i=0;i<f[1];++i) {
                if(out[2*i]==-1 && out[2*i+1]==-1) continue;
                if(out[2*i]<0 || out[2*i]>out[2*i+1] || (uint64_t)out[2*i+1]>size-split) abort();
            }
        }
        if(gr_close(m[0])) abort();
    }
    return 0;
}
