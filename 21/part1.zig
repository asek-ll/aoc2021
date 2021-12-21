const std = @import("std");
const u = @import("utils");
const print = std.debug.print;
const Reader = u.Reader;

pub fn parse(r: *Reader) ![2]u64 {
    try r.skipChars("Player 1 starting position: ");
    var p1 = r.readUnsignedInt(u64);
    try r.skipChars("\nPlayer 2 starting position: ");
    var p2 = r.readUnsignedInt(u64);
    return [_]u64{ p1, p2 };
}

fn sym(pos: [2]u64, limit: u64) u64 {
    var s1: u64 = 0;
    var s2: u64 = 0;
    var p1: u64 = pos[0];
    var p2: u64 = pos[1];
    var diceSum: u64 = 6;
    var cycles: u64 = 0;
    while (true) : (cycles += 1) {
        p1 = (p1 + diceSum - 1) % 10 + 1;
        if (diceSum == 0) {
            diceSum = 9;
        } else {
            diceSum -= 1;
        }
        s1 += p1;
        if (s1 >= limit) {
            return s2 * (cycles * 6 + 3);
        }
        p2 = (p2 + diceSum - 1) % 10 + 1;
        if (diceSum == 0) {
            diceSum = 9;
        } else {
            diceSum -= 1;
        }
        s2 += p2;
        if (s2 >= limit) {
            return s1 * (cycles * 6 + 6);
        }
    }
}

pub fn solve(content: []const u8, _: *std.mem.Allocator) !u64 {
    var r = Reader.init(content);
    var pos = try parse(&r);
    return sym(pos, 1000);
}
