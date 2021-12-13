const std = @import("std");
const u = @import("utils");
const print = std.debug.print;
const p1 = @import("part1.zig");
const sort = std.sort;

fn getPoint(char: u8) u64 {
    if (char == '(') {
        return 1;
    }
    if (char == '[') {
        return 2;
    }
    if (char == '{') {
        return 3;
    }
    if (char == '<') {
        return 4;
    }
    return 0;
}

fn getScore(str: []const u8) u64 {
    p1.stack.reset();
    for (str) |char| {
        if (p1.isOpen(char)) {
            p1.stack.push(char);
        } else {
            if (p1.stack.len > 0 and char == p1.getClosedPair(p1.stack.peek().?)) {
                p1.stack.pop();
            } else {
                return 0;
            }
        }
    }

    var result: u64 = 0;
    while (p1.stack.len > 0) {
        result *= 5;
        result += getPoint(p1.stack.peek().?);
        p1.stack.pop();
    }
    return result;
}

pub fn solve(content: []const u8, allocator: *std.mem.Allocator) !u64 {
    var i: u64 = 0;
    var len: u64 = 0;
    var scores = [_]u64{0} ** 100;
    var scoreLen: u64 = 0;
    while (i < content.len) {
        if (content[i] == '\n') {
            var score = getScore(p1.buf[0..len]);
            if (score != 0) {
                scores[scoreLen] = score;
                scoreLen += 1;
            }
            len = 0;
        } else {
            p1.buf[len] = content[i];
            len += 1;
        }
        i += 1;
    }

    var sc = scores[0..scoreLen];

    sort.sort(u64, sc, {}, comptime sort.asc(u64));

    return sc[scoreLen / 2];
}
