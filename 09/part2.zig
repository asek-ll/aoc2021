const std = @import("std");
const u = @import("utils");
const print = std.debug.print;
const p1 = @import("part1.zig");

var processed = [_][100]bool{[_]bool{false} ** 100} ** 100;

fn Stack(comptime size: u14) type {
    return struct {
        queue: [size][2]u7,
        writeIdx: u14,
        readIdx: u14,

        const Self = @This();

        pub fn push(self: *Self, i: u7, j: u7) void {
            self.queue[self.writeIdx][0] = i;
            self.queue[self.writeIdx][1] = j;
            self.writeIdx = (self.writeIdx + 1) % size;
        }

        pub fn pop(self: *Self) [2]u7 {
            var pair = self.queue[self.readIdx];
            self.readIdx = (self.readIdx + 1) % size;
            return pair;
        }

        pub fn isEmpty(self: *Self) bool {
            return self.readIdx == self.writeIdx;
        }
    };
}

const StackType = Stack(10000);

var stack: StackType = StackType{
    .queue = [_][2]u7{[_]u7{ 0, 0 }} ** 10000,
    .readIdx = 0,
    .writeIdx = 0,
};

const moves = [_][2]i2{
    [_]i2{ -1, 0 },
    [_]i2{ 1, 0 },
    [_]i2{ 0, -1 },
    [_]i2{ 0, 1 },
};

const Bh3 = u.BinaryHeap(u64, 3, std.sort.asc(u64));

var heap = Bh3{
    .data = [_]u64{0} ** 3,
    .size = 0,
};

fn expand(field: [][]u4, ri: u7, ci: u7) u64 {
    stack.push(ri, ci);

    var size: u14 = 0;
    while (!stack.isEmpty()) {
        var toCheck = stack.pop();
        var i = toCheck[0];
        var j = toCheck[1];
        if (processed[i][j]) {
            continue;
        }
        processed[i][j] = true;
        size += 1;

        for (moves) |m| {
            const ni = @intCast(i32, i) + m[0];
            const nj = @intCast(i32, j) + m[1];
            if (ni >= 0 and nj >= 0) {
                const nin = @intCast(u7, ni);
                const njn = @intCast(u7, nj);
                if (nin < field.len and njn < field[nin].len and !processed[nin][njn] and field[nin][njn] != 9) {
                    stack.push(nin, njn);
                }
            }
        }
    }
    return size;
}

pub fn solve(content: []const u8, allocator: *std.mem.Allocator) !u64 {
    var field = p1.parse(content);
    heap.size = 0;

    for (field) |row, ri| {
        for (row) |val, ci| {
            if (p1.isLowest(field, row, ri, ci, val)) {
                var res = expand(field, @intCast(u7, ri), @intCast(u7, ci));
                if (heap.size < 3) {
                    heap.push(res);
                } else if (heap.peek().? < res) {
                    _ = heap.poll();
                    heap.push(res);
                }
            }
        }
    }

    var result: u64 = 1;
    for (heap.data) |d| {
        result *= d;
    }

    return result;
}
