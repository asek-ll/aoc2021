const std = @import("std");
const u = @import("utils");
const print = std.debug.print;

var buf = [_][4]i32{[4]i32{ 0, 0, 0, 0 }} ** 500;

pub fn debug(field: [1000][1000]u9) void {
    for (field) |r, i| {
        for (r) |v, j| {
            if (j < 10 and i < 10) {
                print("{d} ", .{v});
            }
        }
        if (i < 10) {
            print("\n", .{});
        }
    }
}

pub fn parse(content: []const u8) [][4]i32 {
    var i: u64 = 0;
    var len: u64 = 0;
    while (i < content.len) {
        i = u.parseNum(content, i, &buf[len][0]);
        i += 1;
        i = u.parseNum(content, i, &buf[len][1]);
        i += 4;
        i = u.parseNum(content, i, &buf[len][2]);
        i += 1;
        i = u.parseNum(content, i, &buf[len][3]);
        i += 1;
        len += 1;
    }
    return buf[0..len];
}

pub fn solve(content: []const u8, allocator: *std.mem.Allocator) !i32 {
    var data = parse(content);
    var field: [1000][1000]u9 = undefined;
    for (field) |r, i| {
        for (r) |_, j| {
            field[i][j] = 0;
        }
    }
    for (data) |d, n| {
        if (d[0] == d[2]) {
            var from = d[1];
            var to = d[3];
            if (to < from) {
                to = d[1];
                from = d[3];
            }
            var i: u64 = @intCast(u64, d[0]);
            var j: u64 = @intCast(u64, from);
            while (j <= to) {
                field[i][j] += 1;
                j += 1;
            }
        } else if (d[1] == d[3]) {
            var from = d[0];
            var to = d[2];
            if (to < from) {
                to = d[0];
                from = d[2];
            }
            var i: u64 = @intCast(u64, from);
            var j: u64 = @intCast(u64, d[1]);
            while (i <= to) {
                field[i][j] += 1;
                i += 1;
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
