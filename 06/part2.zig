const std = @import("std");
const u = @import("utils");
const print = std.debug.print;
const p1 = @import("part1.zig");

pub fn solve(content: []const u8, _: *std.mem.Allocator) !u64 {
    var data = [_]u64{0} ** 9;
    p1.parse(content, &data);
    var i: u64 = 256;
    while (i > 0) {
        p1.simulate(&data);
        i -= 1;
    }
    var result: u64 = 0;
    for (data) |d| {
        result += d;
    }
    return result;
}
