// SPDX-License-Identifier: Apache-2.0
import regex from "..";
import std;
fn main() {
    let options = regex::Options { .. };
    let pattern, compiled = regex::compile("(a+)(b)?", options);
    assert(compiled.error == regex::Error.None && pattern.pairs == 3);
    var offsets: i64[6] = [42; 6];
    let found = regex::find(pattern, "xxaaa", 0, offsets);
    assert(found.error == regex::Error.None && found.matched && found.pairs == 3);
    assert(offsets == [2, 5, 2, 5, -1, -1]);
    let absent = regex::find(pattern, "zzz", 0, offsets);
    assert(absent.error == regex::Error.None && !absent.matched);
    assert(offsets == [-1 as! i64; 6]);
    assert(regex::find(pattern, "aaa", -1, offsets).error == regex::Error.InvalidInput);
    assert(regex::close(pattern) == regex::Error.None);
    assert(regex::close(pattern) == regex::Error.InvalidHandle);
    assert(regex::find(pattern, "aaa", 0, offsets).error == regex::Error.InvalidHandle);
    let bad, status = regex::compile("(", options);
    assert(status.error == regex::Error.InvalidPattern && status.error_offset >= 0 && bad.token == 0);
    let empty, ok = regex::compile("", options);
    assert(ok.error == regex::Error.None);
    assert(regex::find(empty, "", 0, offsets).matched);
    assert(offsets[0] == 0 && offsets[1] == 0);
    assert(regex::close(empty) == regex::Error.None);
}
