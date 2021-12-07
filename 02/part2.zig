const std = @import("std");
const u = @import("utils");
const print = std.debug.print;

pub fn parseAndNextState(c: []const u8, s: u64, delta: *[3]i32) u64 {
    var i = s;
    var dh = switch (c[i]) {
        'f' => blk: {
            i += 7;
            break :blk [3]i32{ 1, delta[2], 0 };
        },
        'u' => blk: {
            i += 2;
            break :blk [3]i32{ 0, 0, -1 };
        },
        'd' => blk: {
            i += 4;
            break :blk [3]i32{ 0, 0, 1 };
        },
        else => unreachable,
    };

    var x: i32 = 0;
    i = u.parseNum(c, i + 1, &x);

    delta[0] += dh[0] * x;
    delta[1] += dh[1] * x;
    delta[2] += dh[2] * x;

    return i;
}

pub fn solve(content: []const u8, allocator: *std.mem.Allocator) !i32 {
    var i: u64 = 0;
    var m = [3]i32{ 0, 0, 0 };
    var aim: i32 = 0;
    while (i < content.len) {
        i = parseAndNextState(content, i, &m) + 1;
    }

    return m[0] * m[1];
}
