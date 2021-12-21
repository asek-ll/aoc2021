const std = @import("std");
const u = @import("utils");
const print = std.debug.print;
const p1 = @import("part1.zig");

pub fn solve(content: []const u8, a: *std.mem.Allocator) !u64 {
    var r = u.Reader.init(content);
    var mp = try p1.parse(&r, a.*);

    var i: u64 = 0;
    while (i < 50) : (i += 1) {
        var mp2 = try p1.enhance(&mp, a.*);
        mp.deinit(a.*);
        mp = mp2;
    }

    return mp.count();
}
