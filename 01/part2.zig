const std = @import("std");
const u = @import("utils");
const print = std.debug.print;

pub fn solve(content: []const u8, allocator: *std.mem.Allocator) !i32 {
    var buf = [3]i32{ 0, 0, 0 };

    var result: i32 = 0;
    var prev: i32 = 0;

    var i: u64 = 0;
    var counter: u64 = 0;
    while (i < content.len) {
        var x: i32 = 0;
        i = u.parseNum(content, i, &x) + 1;
        var current = prev - buf[counter % 3] + x;
        buf[counter % 3] = x;
        if (counter > 2 and current > prev) {
            result += 1;
        }
        prev = current;
        counter += 1;
    }
    return result;
}
