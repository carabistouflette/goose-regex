// SPDX-License-Identifier: Apache-2.0
import regex from "..";
import std;
import os;
fn main() {
    let argv = args();
    let cold = argv.len > 1 && argv[1] == "compile";
    let workload = if argv.len > 2 { argv[2] } else { "diagnostic" };
    var options = regex::Options { .. };
    var text:       u8[>..] = str("source/main.goose:123:45: unknown identifier");
    var source:     u8[>..] = str("^(.+):([0-9]+):([0-9]+): (.*)$");
    var iterations: i64     = 10000;
    if workload == "large" || workload == "no-match" {
        text.clear(); text.resize(262144, 'a');
        source = str(if workload == "large" { "^a+$" } else { "^a+b$" });
        iterations = 128;
    } else if workload == "captures" {
        source.clear(); text.clear();
        for i in 32 { source.push('('); source.push('a'); source.push(')'); text.push('a'); }
    } else if workload == "hostile" {
        text.clear(); text.resize(64, 'a'); text.push('!');
        source = str("(*NO_START_OPT)(a+)+$");
        options.work_limit = 1000;
        iterations = 1000;
    } else { assert(workload == "diagnostic"); }
    var offsets: i64[128] = [-1; 128];
    var total:   i64      = 0;
    let pattern, status = regex::compile(source, options);
    assert(status.error == regex::Error.None);
    for i in iterations {
        var active = pattern;
        if cold {
            let temporary, compiled = regex::compile(source, options);
            assert(compiled.error == regex::Error.None);
            active = temporary;
        }
        let result = regex::find(active, text, 0, offsets);
        if workload == "hostile" {
            assert(result.error == regex::Error.LimitExceeded && !result.matched);
            total += 1;
        } else if workload == "no-match" {
            assert(result.error == regex::Error.None && !result.matched);
            assert(offsets[0] == -1);
        } else {
            assert(result.error == regex::Error.None && result.matched);
            total += offsets[1];
        }
        if cold { assert(regex::close(active) == regex::Error.None); }
    }
    assert(regex::close(pattern) == regex::Error.None);
    print(total);
}
