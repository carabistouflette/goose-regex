// SPDX-License-Identifier: Apache-2.0
import regex from "..";
import std;
fn main() {
    let options = regex::Options { .. };
    let pattern, compiled = regex::compile("^(.+):([0-9]+):([0-9]+): (.*)$", options);
    assert(compiled.error == regex::Error.None);
    let line = "main.goose:12:3: unknown identifier";
    var offsets: i64[10] = [-1; 10];
    let found = regex::find(pattern, line, 0, offsets);
    assert(found.error == regex::Error.None && found.matched);
    print(line[offsets[2]..offsets[3]]);
    print(line[offsets[8]..offsets[9]]);
    assert(regex::close(pattern) == regex::Error.None);
}
