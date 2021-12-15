const std = @import("std");
const u = @import("utils");
const print = std.debug.print;

const Stack = struct {
    data: [128]u8,
    len: u8,

    const Self = @This();

    pub fn reset(self: *Self) void {
        self.len = 0;
    }

    pub fn push(self: *Self, val: u8) void {
        self.data[self.len] = val;
        self.len += 1;
    }
    pub fn peek(self: Self) ?u8 {
        if (self.len == 0) {
            return null;
        }
        return self.data[self.len - 1];
    }
    pub fn pop(self: *Self) void {
        if (self.len == 0) {
            return;
        }
        self.len -= 1;
    }
};

pub var stack = Stack{
    .data = [_]u8{0} ** 128,
    .len = 0,
};
pub var buf = [_]u8{0} ** 128;

pub fn isOpen(char: u8) bool {
    return char == '[' or char == '{' or char == '<' or char == '(';
}
pub fn getClosedPair(char: u8) u8 {
    if (char == '[') {
        return ']';
    }
    if (char == '{') {
        return '}';
    }
    if (char == '<') {
        return '>';
    }
    return ')';
}

fn getPoint(char: u8) u64 {
    if (char == ')') {
        return 3;
    }
    if (char == ']') {
        return 57;
    }
    if (char == '}') {
        return 1197;
    }
    if (char == '>') {
        return 25137;
    }
    return 0;
}

fn getScore(str: []const u8) u64 {
    stack.reset();
    for (str) |char| {
        if (isOpen(char)) {
            stack.push(char);
        } else {
            if (stack.len > 0 and char == getClosedPair(stack.peek().?)) {
                stack.pop();
            } else {
                return getPoint(char);
            }
        }
    }
    return 0;
}

pub fn solve(content: []const u8, _: *std.mem.Allocator) !u64 {
    var i: u64 = 0;
    var len: u64 = 0;
    var score: u64 = 0;
    while (i < content.len) {
        if (content[i] == '\n') {
            score += getScore(buf[0..len]);
            len = 0;
        } else {
            buf[len] = content[i];
            len += 1;
        }
        i += 1;
    }

    return score;
}
