const std = @import("std");
const u = @import("utils");
const print = std.debug.print;
const p1 = @import("part1.zig");

fn scaleFive(f: [][]u4) [][]u4 {
    var i: u64 = 0;
    var j: u64 = 0;
    var mY = f.len;
    var mX = f[0].len;
    while (i < 5) : (i += 1) {
        j = 0;
        while (j < 5) : (j += 1) {
            if (j == 0 and i == 0) {
                continue;
            }
            for (f) |r, di| {
                for (r) |v, dj| {
                    p1.data[i * mY + di][j * mX + dj] = @intCast(u4, (@intCast(u64, v) + i + j - 1) % 9 + 1);
                }
            }
        }
    }
    for (p1.data[0..(mY * 5)]) |*r, idx| {
        p1.field[idx] = r[0 .. mX * 5];
    }
    return p1.field[0..(mY * 5)];
}

pub fn solve(content: []const u8, allocator: *std.mem.Allocator) !u64 {
    var f = scaleFive(p1.parse(content));
    return try p1.sym(f, allocator);
}
