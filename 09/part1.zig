const std = @import("std");
const u = @import("utils");
const print = std.debug.print;
const isDigit = std.ascii.isDigit;

var data = [_][100]u4{[_]u4{0} ** 100} ** 100;
var rows = [_][]u4{&[_]u4{}} ** 100;

pub fn parse(content: []const u8) [][]u4 {
    var i: u64 = 0;
    var colIdx: u64 = 0;
    var rowIdx: u64 = 0;
    while (i < content.len) {
        if (isDigit(content[i])) {
            data[rowIdx][colIdx] = @intCast(u4, content[i] - '0');
            colIdx += 1;
        } else {
            rows[rowIdx] = data[rowIdx][0..colIdx];
            rowIdx += 1;
            colIdx = 0;
        }

        i += 1;
    }
    return rows[0..rowIdx];
}

pub fn isLowest(field: [][]u4, row: []u4, ri: u64, ci: u64, val: u4) bool {
    if (ri > 0 and field[ri - 1][ci] <= val) {
        return false;
    }
    if (ci > 0 and field[ri][ci - 1] <= val) {
        return false;
    }
    if (ri < field.len - 1 and field[ri + 1][ci] <= val) {
        return false;
    }
    if (ci < row.len - 1 and field[ri][ci + 1] <= val) {
        return false;
    }
    return true;
}

pub fn solve(content: []const u8, allocator: *std.mem.Allocator) !u64 {
    var field = parse(content);
    var result: u64 = 0;
    for (field) |row, ri| {
        for (row) |val, ci| {
            if (isLowest(field, row, ri, ci, val)) {
                result += val + 1;
            }
        }
    }
    return result;
}
