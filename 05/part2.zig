const std = @import("std");
const u = @import("utils");
const print = std.debug.print;
const p1 = @import("part1.zig");

pub fn solve(content: []const u8, _: *std.mem.Allocator) !i32 {
    var data = p1.parse(content);
    var field: [1000][1000]u9 = undefined;
    for (field) |r, i| {
        for (r) |_, j| {
            field[i][j] = 0;
        }
    }
    for (data) |d| {
        var x = d[0];
        var y = d[1];

        while (true) {
            field[@intCast(u64, x)][@intCast(u64, y)] += 1;
            if (x == d[2] and y == d[3]) {
                break;
            }
            if (x > d[2]) {
                x -= 1;
            } else if (x < d[2]) {
                x += 1;
            }
            if (y > d[3]) {
                y -= 1;
            } else if (y < d[3]) {
                y += 1;
            }
        }
    }
    var overlaps: i32 = 0;
    for (field) |r| {
        for (r) |v| {
            if (v > 1) {
                overlaps += 1;
            }
        }
    }
    return overlaps;
}
