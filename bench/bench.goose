// SPDX-License-Identifier: Apache-2.0
import regex from "..";
import std;
import os;
fn main() {
    let argv = args();
    let cold = argv.len > 1 && argv[1] == "compile";
    let options = regex::Options { .. };
    let text = "source/main.goose:123:45: unknown identifier";
    let source = "^(.+):([0-9]+):([0-9]+): (.*)$";
    var offsets: i64[10] = [-1; 10];
    var total:   i64     = 0;
    let pattern, status = regex::compile(source, options);
    assert(status.error == regex::Error.None);
    for i in 10000 {
        if cold {
            let temporary, compiled = regex::compile(source, options);
            assert(compiled.error == regex::Error.None);
            let result = regex::find(temporary, text, 0, offsets);
            assert(result.error == regex::Error.None && result.matched);
            total += offsets[9];
            assert(regex::close(temporary) == regex::Error.None);
        } else {
            let result = regex::find(pattern, text, 0, offsets);
            assert(result.error == regex::Error.None && result.matched);
            total += offsets[9];
        }
    }
    assert(regex::close(pattern) == regex::Error.None);
    print(total);
}
