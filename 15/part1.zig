const std = @import("std");
const u = @import("utils");
const print = std.debug.print;
const Order = std.math.Order;

pub var data = [_][500]u4{[_]u4{0} ** 500} ** 500;
pub var field = [_][]u4{&[_]u4{}} ** 500;
var temp = [_][500]u64{[_]u64{0} ** 500} ** 500;

pub fn parse(content: []const u8) [][]u4 {
    var i: u64 = 0;
    var x: u64 = 0;
    var y: u64 = 0;
    var maxX: u64 = 0;
    var maxY: u64 = 0;
    while (i < content.len) {
        if (content[i] == '\n') {
            y += 1;
            x = 0;
            if (maxY < y) {
                maxY = y;
            }
        } else {
            data[y][x] = @intCast(u4, (content[i] - '0'));
            x += 1;
            if (maxX < x) {
                maxX = x;
            }
        }
        i += 1;
    }

    for (data[0..maxY]) |*r, j| {
        field[j] = r[0..maxX];
    }

    return field[0..maxY];
}

const Step = struct {
    x: u64,
    y: u64,
    cost: u64,
};

fn compareStep(a: Step, b: Step) bool {
    return a.cost < b.cost;
}

const PQ = std.PriorityQueue(Step);

pub fn sym(f: [][]u4, allocator: *std.mem.Allocator) !u64 {
    var q = PQ.init(allocator, compareStep);
    const pathes = [_][2]i2{
        [_]i2{ -1, 0 },
        [_]i2{ 1, 0 },
        [_]i2{ 0, -1 },
        [_]i2{ 0, 1 },
    };
    for (f) |r, j| {
        for (r) |_, i| {
            temp[j][i] = 0;
        }
    }
    try q.add(.{ .x = 0, .y = 0, .cost = f[0][0] });
    while (q.len > 0) {
        var step = q.remove();
        if (temp[step.y][step.x] != 0) {
            continue;
        }
        // print("process {d},{d} and cost {d}\n", .{ step.x, step.y, step.cost });
        temp[step.y][step.x] = step.cost;
        for (pathes) |d| {
            var nextX = @intCast(i64, step.x) + d[0];
            var nextY = @intCast(i64, step.y) + d[1];
            if (nextX < 0 or nextY < 0 or nextY >= f.len) {
                continue;
            }
            var nX = @intCast(u64, nextX);
            var nY = @intCast(u64, nextY);
            if (nX >= f[nY].len or temp[nY][nX] != 0) {
                continue;
            }
            try q.add(.{ .x = nX, .y = nY, .cost = step.cost + f[nY][nX] });
        }
    }
    const lr = f.len - 1;
    return temp[lr][f[lr].len - 1] - temp[0][0];
}

pub fn solve(content: []const u8, allocator: *std.mem.Allocator) !u64 {
    var f = parse(content);
    return try sym(f, allocator);
}
