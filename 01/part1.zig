const std = @import("std");
const u = @import("utils");
const print = std.debug.print;

pub fn solve(content: []const u8, _: *std.mem.Allocator) !i32 {
    var i: u64 = 0;
    var prev: i32 = 0;
    var result: i32 = 0;
    while (i < content.len) {
        var x: i32 = 0;
        var next = u.parseNum(content, i, &x) + 1;
        if (i > 0 and x > prev) {
            result += 1;
        }
        prev = x;
        i = next;
    }
    return result;
}
