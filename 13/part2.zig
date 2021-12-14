const std = @import("std");
const u = @import("utils");
const print = std.debug.print;
const p1 = @import("part1.zig");

pub fn solve(content: []const u8, allocator: *std.mem.Allocator) !i32 {
    p1.parse(content, false);
    p1.debug();
    return -1;
}
