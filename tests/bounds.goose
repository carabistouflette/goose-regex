// SPDX-License-Identifier: Apache-2.0
import regex from "..";
import std;
fn rejected(options: regex::Options) {
    let pattern, status = regex::compile("a", options);
    assert(status.error == regex::Error.InvalidInput && pattern.token == 0 && pattern.pairs == 0);
}
fn prepare(text: const u8[:], options: regex::Options) -> regex::Pattern, regex::Status {
    return regex::compile(text, options);
}
fn main() {
    rejected(regex::Options { input_limit: -1, .. });
    rejected(regex::Options { input_limit: 1048577, .. });
    rejected(regex::Options { memory_limit: 0, .. });
    rejected(regex::Options { memory_limit: 8388609, .. });
    rejected(regex::Options { work_limit: 0, .. });
    rejected(regex::Options { work_limit: 1000001, .. });
    rejected(regex::Options { depth_limit: 0, .. });
    rejected(regex::Options { depth_limit: 1001, .. });
    let small, memory_status = prepare("a", regex::Options { memory_limit: 1, .. });
    assert(memory_status.error == regex::Error.LimitExceeded && small.token == 0);
    for text in ["(*UTF)a", "(*UCP)a"] {
        let forbidden, status = prepare(text, regex::Options { .. });
        assert(status.error == regex::Error.InvalidPattern && forbidden.token == 0);
    }
    var text = str(""); text.resize(16385, 'a');
    let long_pattern, long_status = prepare(text, regex::Options { .. });
    assert(long_status.error == regex::Error.LimitExceeded && long_pattern.token == 0);
    var captures = str("");
    for _ in 63 { captures.append("()"); }
    let maximum, maximum_status = prepare(captures, regex::Options { .. });
    assert(maximum_status.error == regex::Error.None && maximum.pairs == 64);
    var full: i64[128] = [42; 128];
    let found = regex::find(maximum, "", 0, full);
    assert(found.error == regex::Error.None && found.matched && found.pairs == 64);
    for offset in full { assert(offset == 0); }
    var short: i64[127] = [42; 127];
    assert(regex::find(maximum, "", 0, short).error == regex::Error.InvalidInput);
    for offset in short { assert(offset == -1); }
    assert(regex::close(maximum) == regex::Error.None);
    captures.append("()");
    let excess, excess_status = prepare(captures, regex::Options { .. });
    assert(excess_status.error == regex::Error.LimitExceeded && excess.token == 0);
    let limited, limited_status = prepare("a*", regex::Options { input_limit: 3, .. });
    assert(limited_status.error == regex::Error.None);
    var offsets: i64[2] = [42; 2];
    assert(regex::find(limited, "aaa", 0, offsets).matched && offsets == [0, 3]);
    let over = regex::find(limited, "aaaa", 0, offsets);
    assert(over.error == regex::Error.LimitExceeded && !over.matched && over.pairs == 0);
    assert(offsets == [-1 as! i64; 2]);
    let at_end = regex::find(limited, "aaa", 3, offsets);
    assert(at_end.error == regex::Error.None && at_end.matched && offsets == [3, 3]);
    assert(regex::find(limited, "aaa", 4, offsets).error == regex::Error.InvalidInput);
    let alias = limited;
    assert(regex::close(alias) == regex::Error.None);
    let fresh, fresh_status = prepare("b", regex::Options { .. });
    assert(fresh_status.error == regex::Error.None && fresh.token != limited.token);
    assert(regex::find(limited, "a", 0, offsets).error == regex::Error.InvalidHandle);
    assert(regex::close(limited) == regex::Error.InvalidHandle);
    assert(regex::find(fresh, "b", 0, offsets).matched);
    assert(regex::close(fresh) == regex::Error.None);
    let zero, zero_status = prepare("", regex::Options { input_limit: 0, .. });
    assert(zero_status.error == regex::Error.None);
    assert(regex::find(zero, "", 0, offsets).matched);
    assert(regex::find(zero, "a", 0, offsets).error == regex::Error.LimitExceeded);
    assert(regex::close(zero) == regex::Error.None);
}
