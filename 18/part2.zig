const std = @import("std");
const u = @import("utils");
const print = std.debug.print;
const p1 = @import("part1.zig");
const Pair = p1.Pair;
const Reader = u.Reader;
const Allocator = std.mem.Allocator;

fn cpy(p: *Pair, a: Allocator) anyerror!*Pair {
    return switch (p.*) {
        Pair.pair => |cp| {
            return p1.own(Pair{
                .pair = .{
                    .p1 = try cpy(cp.p1, a),
                    .p2 = try cpy(cp.p2, a),
                },
            }, a);
        },
        Pair.value => |val| {
            return p1.own(Pair{
                .value = val,
            }, a);
        },
    };
}

fn destroy(p: *Pair, a: Allocator) anyerror!void {
    switch (p.*) {
        Pair.pair => |cp| {
            try destroy(cp.p1, a);
            try destroy(cp.p2, a);
        },
        else => {},
    }
    a.destroy(p);
}

var pairs = [_]*Pair{undefined} ** 100;

fn readPairs(content: []const u8, a: Allocator) ![]*Pair {
    var i: u64 = 0;
    var reader = Reader.init(content);
    while (reader.pos < reader.data.len) {
        pairs[i] = try p1.parsePair(&reader, a);
        i += 1;
        try reader.skipChars("\n");
    }
    return pairs[0..i];
}

fn calculate(pl: *Pair, pr: *Pair, a: Allocator) !u64 {
    var plc = try cpy(pl, a);
    var prc = try cpy(pr, a);

    var p = try p1.plus(plc, prc, a);
    try p1.simplify(p, a);
    var result = p1.magnitude(p);

    try destroy(plc, a);
    try destroy(prc, a);

    return result;
}

pub fn solve(content: []const u8, a: *std.mem.Allocator) !u64 {
    var ps = try readPairs(content, a.*);
    var max: u64 = 0;
    for (ps) |pl, i| {
        for (ps) |pr, j| {
            if (i != j) {
                var tempMax = try calculate(pl, pr, a.*);
                if (tempMax > max) {
                    max = tempMax;
                }
            }
        }
    }

    return max;
}
