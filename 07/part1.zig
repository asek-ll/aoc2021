const std = @import("std");
const u = @import("utils");
const print = std.debug.print;
const sort = std.sort;

var buf = [_]u64{0} ** 1000;

pub fn parse(content: []const u8) []u64 {
    var i: u64 = 0;
    var x: i32 = 0;
    var len: u64 = 0;
    while (i < content.len) {
        i = u.parseNum(content, i, &x);
        buf[len] = @intCast(u64, x);
        i += 1;
        len += 1;
    }
    return buf[0..len];
}

fn getMedian(data: []u64) u64 {
    if (data.len % 2 == 1) {
        return data[data.len / 2];
    }

    return (data[data.len / 2 - 1] + data[data.len / 2]) / 2;
}

fn getFueld(data: []u64, level: u64) u64 {
    var fuel: u64 = 0;
    for (data) |d| {
        if (d > level) {
            fuel += d - level;
        } else {
            fuel += level - d;
        }
    }
    return fuel;
}

pub fn solve(content: []const u8, allocator: *std.mem.Allocator) !u64 {
    var data = parse(content);
    sort.sort(u64, data, {}, comptime sort.asc(u64));
    var median = getMedian(data);

    return getFueld(data, median);
}
