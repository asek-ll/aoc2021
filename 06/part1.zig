const std = @import("std");
const u = @import("utils");
const print = std.debug.print;

pub fn parse(content: []const u8, data: *[9]u64) void {
    var i: u64 = 0;
    var x: i32 = 0;
    while (i < content.len) {
        i = u.parseNum(content, i, &x);
        data[@intCast(u64, x)] += 1;
        i += 1;
    }
}

pub fn simulate(data: *[9]u64) void {
    var nextData = [_]u64{0} ** 9;

    for (data) |d, i| {
        if (i == 0) {
            nextData[6] += d;
            nextData[8] += d;
        } else {
            nextData[i - 1] += d;
        }
    }
    for (data) |_, i| {
        data[i] = nextData[i];
    }
}

pub fn solve(content: []const u8, allocator: *std.mem.Allocator) !i32 {
    var data = [_]u64{0} ** 9;
    parse(content, &data);
    var i: u64 = 80;
    while (i > 0) {
        simulate(&data);
        i -= 1;
    }
    var result: i32 = 0;
    for (data) |d| {
        result += @intCast(i32, d);
    }
    return result;
}
