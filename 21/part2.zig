const std = @import("std");
const u = @import("utils");
const print = std.debug.print;
const p1 = @import("part1.zig");

const CountByScoreAtPos = struct {
    count: [10][22]u64,
    validState: [10]u1,

    pub fn init() CountByScoreAtPos {
        return .{
            .count = [_][22]u64{[_]u64{0} ** 22} ** 10,
            .validState = [_]u1{0} ** 10,
        };
    }

    pub fn addTo(s: *CountByScoreAtPos, pos: u64, score: u64, count: u64) void {
        s.validState[pos] = 1;
        if (score >= 21) {
            s.count[pos][21] += count;
        } else {
            s.count[pos][score] += count;
        }
    }

    pub fn clear(s: *CountByScoreAtPos) void {
        for (s.validState) |_, i| {
            s.validState[i] = 0;
        }
        for (s.count) |sc, i| {
            for (sc) |_, cc| {
                s.count[i][cc] = 0;
            }
        }
    }
};

const turnSplit = [7]u4{ 1, 3, 6, 7, 6, 3, 1 };

var state = [_]CountByScoreAtPos{CountByScoreAtPos.init()} ** 20;

fn symState(pos: u64) void {
    state[0].addTo(pos - 1, 0, 1);
    for (state[0..(state.len - 1)]) |s, si| {
        for (s.validState) |vs, i| {
            if (vs == 1) {
                for (turnSplit) |baseCnt, ps| {
                    var nps = (ps + 3 + i) % 10;
                    for (s.count[i]) |univerCnt, scoreCnt| {
                        if (scoreCnt < 21) {
                            var nextScore = scoreCnt + nps + 1;
                            state[si + 1].addTo(nps, nextScore, univerCnt * baseCnt);
                        }
                    }
                }
            }
        }
    }
}

fn fillWinLoseMap(wlm: *[20][2]u64) void {
    for (state) |s, si| {
        for (s.validState) |vs, i| {
            if (vs == 1) {
                var p = s.count[i];
                if (p[21] > 0) {
                    wlm[si][1] += p[21];
                }
                for (p[0..21]) |c| {
                    wlm[si][0] += c;
                }
            }
        }
    }
    for (state) |*s| {
        s.clear();
    }
}

pub fn solve(content: []const u8, _: *std.mem.Allocator) !u64 {
    var r = u.Reader.init(content);
    var pos = try p1.parse(&r);

    symState(pos[0]);
    var p1winmap = [_][2]u64{[_]u64{ 0, 0 }} ** 20;
    fillWinLoseMap(&p1winmap);
    symState(pos[1]);
    var p2winmap = [_][2]u64{[_]u64{ 0, 0 }} ** 20;
    fillWinLoseMap(&p2winmap);

    var p1Sum: u64 = 0;
    for (p1winmap) |_, i| {
        var p2LossPrev: u64 = 1;
        if (i > 0) {
            p2LossPrev = p2winmap[i - 1][0];
        }
        p1Sum += p2LossPrev * p1winmap[i][1];
    }
    var p2Sum: u64 = 0;
    for (p2winmap) |_, i| {
        p2Sum += p1winmap[i][0] * p2winmap[i][1];
    }
    if (p1Sum > p2Sum) {
        return p1Sum;
    }

    return p2Sum;
}
