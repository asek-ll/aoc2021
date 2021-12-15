const std = @import("std");
const u = @import("utils");
const print = std.debug.print;
const isDigit = std.ascii.isDigit;

pub const Board = [5][5]u32;

pub const Input = struct {
    numbers: []u32,
    numbersOrder: []u32,
    boards: []Board,
};

var numbers = [_]u32{0} ** 200;
var numbersOrder = [_]u32{0} ** 200;

var boards = [_][5][5]u32{
    [5][5]u32{
        [5]u32{ 0, 0, 0, 0, 0 },
        [5]u32{ 0, 0, 0, 0, 0 },
        [5]u32{ 0, 0, 0, 0, 0 },
        [5]u32{ 0, 0, 0, 0, 0 },
        [5]u32{ 0, 0, 0, 0, 0 },
    },
} ** 1000;

pub fn parse(content: []const u8, _: *std.mem.Allocator, input: *Input) void {
    var i: u64 = 0;
    var j: u64 = 0;
    var buf: u32 = 0;
    while (i < content.len) {
        if (content[i] == ',' or content[i] == '\n') {
            numbers[j] = buf;
            numbersOrder[buf] = @intCast(u32, j);
            j += 1;
            if (content[i] == '\n') {
                break;
            }
            buf = 0;
        } else {
            buf *= 10;
            buf += (content[i] - '0');
        }
        i += 1;
    }

    i += 1;

    input.numbers = numbers[0..j];
    input.numbersOrder = numbersOrder[0..j];

    j = 0;
    buf = 0;
    var k: u64 = 0;
    while (i < content.len) {
        if (isDigit(content[i])) {
            buf *= 10;
            buf += (content[i] - '0');
        } else {
            if (isDigit(content[i - 1])) {
                boards[k][j / 5][j % 5] = buf;
                buf = 0;
                j += 1;
                if (j >= 25) {
                    j = 0;
                    k += 1;
                }
            }
        }
        i += 1;
    }

    input.boards = boards[0..k];
}

pub fn solve(content: []const u8, allocator: *std.mem.Allocator) !i32 {
    var input = Input{
        .numbers = &[_]u32{},
        .numbersOrder = &[_]u32{},
        .boards = &[_]Board{},
    };
    parse(content, allocator, &input);

    var minBoardIndex: u64 = 0;
    var minBoardStep: u64 = 200;
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
        if (minStep < minBoardStep) {
            minBoardStep = minStep;
            minBoardIndex = k;
        }
    }

    var board = input.boards[minBoardIndex];
    var sumNonPlayed: u32 = 0;
    for (board) |r| {
        for (r) |v| {
            if (input.numbersOrder[v] > minBoardStep) {
                sumNonPlayed += v;
            }
        }
    }

    return @intCast(i32, sumNonPlayed * input.numbers[minBoardStep]);
}
