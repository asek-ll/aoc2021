const std = @import("std");
const u = @import("utils");
const print = std.debug.print;
const p1 = @import("part1.zig");

pub fn solve(content: []const u8, a: *std.mem.Allocator) !u64 {
    var r = u.Reader.init(content);
    var cs = try p1.parse(&r, a.*, false);
    return cs.volume();
}
