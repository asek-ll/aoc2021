const std = @import("std");
const u = @import("utils");
const print = std.debug.print;
const p1 = @import("part1.zig");

pub fn solve(content: []const u8, allocator: *std.mem.Allocator) !u64 {
    p1.parse(content);
    var i: u8 = 40;
    while (i > 0) {
        p1.sym();
        i -= 1;
    }

    i = 0;
    var min: ?u64 = null;
    var max: ?u64 = null;
    while (i < 27) {
        var cnt = p1.getCharCnt('A' + i);
        if (cnt > 0) {
            if (min) |m| {
                if (m > cnt) {
                    min = cnt;
                }
            } else {
                min = cnt;
            }

            if (max) |m| {
                if (m < cnt) {
                    max = cnt;
                }
            } else {
                max = cnt;
            }
        }
        i += 1;
    }

    return max.? - min.?;
}
