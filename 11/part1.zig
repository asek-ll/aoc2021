const std = @import("std");
const u = @import("utils");
const print = std.debug.print;

var data = [_][10]u4{[_]u4{0} ** 10} ** 10;
const StackU4 = u.RingStack([2]u4, 100 * 100);
var stack = StackU4{
    .queue = [_][2]u4{[2]u4{ 0, 0 }} ** 10000,
    .writeIdx = 0,
    .readIdx = 0,
};

pub fn parse(content: []const u8) [10][10]u4 {
    var i: u64 = 0;
    var r: u64 = 0;
    var c: u64 = 0;
    while (i < content.len) {
        if (content[i] == '\n') {
            r += 1;
            c = 0;
        } else {
            data[r][c] = @intCast(u4, (content[i] - '0'));
            c += 1;
        }
        i += 1;
    }
    return data;
}

pub fn sym() u64 {
    stack.reset();
    for (data) |r, i| {
        for (r) |v, j| {
            data[i][j] = v + 1;
            if (v == 9) {
                stack.push([2]u4{ @intCast(u4, i), @intCast(u4, j) });
            }
        }
    }

    while (!stack.isEmpty()) {
        var point = stack.pop();
        var i = point[0];
        var j = point[1];
        if (data[i][j] != 10) {
            continue;
        }
        data[i][j] = 11;
        var y: u4 = 0;
        var x: u4 = 0;
        if (i > 0) {
            y = i - 1;
        }
        while (y <= i + 1 and y < data.len) {
            if (j > 0) {
                x = j - 1;
            } else {
                x = 0;
            }
            while (x <= j + 1 and x < data[y].len) {
                if (y != i or x != j) {
                    var val = data[y][x];
                    if (val != 11) {
                        if (val >= 9) {
                            data[y][x] = 10;
                            stack.push([2]u4{ y, x });
                        } else {
                            data[y][x] = val + 1;
                        }
                    }
                }
                x += 1;
            }
            y += 1;
        }
    }

    var result: u64 = 0;
    for (data) |r, i| {
        for (r) |v, j| {
            if (v == 11) {
                data[i][j] = 0;
                result += 1;
            }
        }
    }
    return result;
}

fn debug() void {
    for (data) |r, i| {
        for (r) |v, j| {
            print("{d}", .{v});
        }
        print("\n", .{});
    }
    print("\n", .{});
}

pub fn solve(content: []const u8, allocator: *std.mem.Allocator) !u64 {
    var parsed = parse(content);
    var i: u64 = 100;
    var result: u64 = 0;
    while (i > 0) {
        result += sym();
        i -= 1;
    }

    return result;
}
