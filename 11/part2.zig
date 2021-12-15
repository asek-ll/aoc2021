const std = @import("std");
const u = @import("utils");
const print = std.debug.print;
const p1 = @import("part1.zig");

pub fn solve(content: []const u8, _: *std.mem.Allocator) ?u64 {
    _ = p1.parse(content);
    var i: u64 = 1;
    while (true) {
        if (p1.sym() == 100) {
            return i;
        }
        i += 1;
    }

    return null;
}
