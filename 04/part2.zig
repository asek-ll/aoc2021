const std = @import("std");
const u = @import("utils");
const print = std.debug.print;
const p1 = @import("part1.zig");

pub fn solve(content: []const u8, allocator: *std.mem.Allocator) !i32 {
    var input = p1.Input{
        .numbers = &[_]u32{},
        .numbersOrder = &[_]u32{},
        .boards = &[_]p1.Board{},
    };
    p1.parse(content, allocator, &input);

    var minBoardIndex: u64 = 0;
    var boardStep: u64 = 0;
    for (input.boards) |b, k| {
        var minStep: u32 = 200;
        for (b) |r, i| {
            var rowMax: u32 = 0;
            var columnMax: u32 = 0;
            for (r) |v, j| {
                var n = input.numbersOrder[v];
                if (n > rowMax) {
                    rowMax = n;
                }
                var n2 = input.numbersOrder[b[j][i]];
                if (n2 > columnMax) {
                    columnMax = n2;
                }
            }
            if (rowMax < minStep) {
                minStep = rowMax;
            }
            if (columnMax < minStep) {
                minStep = columnMax;
            }
        }
        if (minStep > boardStep) {
            boardStep = minStep;
            minBoardIndex = k;
        }
    }

    var board = input.boards[minBoardIndex];
    var sumNonPlayed: u32 = 0;
    for (board) |r| {
        for (r) |v| {
            if (input.numbersOrder[v] > boardStep) {
                sumNonPlayed += v;
            }
        }
    }

    return @intCast(i32, sumNonPlayed * input.numbers[boardStep]);
}
