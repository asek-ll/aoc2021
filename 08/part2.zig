const std = @import("std");
const u = @import("utils");
const print = std.debug.print;

fn detect(data: [14][]const u8) u64 {
    var map = [_]u8{0} ** 10;
    var bitmap = [_]u8{0} ** 14;
    var in5 = [3]u4{ 0, 0, 0 };
    var in6 = [3]u4{ 0, 0, 0 };
    var in5idx: u4 = 0;
    var in6idx: u4 = 0;

    for (data) |d, i| {
        var bitmask: u8 = 0;
        const one: u8 = 1;
        for (d) |c| {
            var power = @intCast(u3, (c - 'a'));
            bitmask |= one << power;
        }
        bitmap[i] = bitmask;
    }

    for (data) |d, i| {
        if (i > 9) {
            break;
        }
        if (d.len == 2) {
            map[1] = @intCast(u8, i);
        } else if (d.len == 3) {
            map[7] = @intCast(u8, i);
        } else if (d.len == 4) {
            map[4] = @intCast(u8, i);
        } else if (d.len == 7) {
            map[8] = @intCast(u8, i);
        } else if (d.len == 5) {
            in5[in5idx] = @intCast(u4, i);
            in5idx += 1;
        } else if (d.len == 6) {
            in6[in6idx] = @intCast(u4, i);
            in6idx += 1;
        }
    }

    for (in6) |i| {
        const b7 = bitmap[map[7]];
        const b4 = bitmap[map[4]];
        if (b7 & bitmap[i] != b7) {
            map[6] = i;
        } else if (b4 & bitmap[i] != b4) {
            map[0] = i;
        } else {
            map[9] = i;
        }
    }

    for (in5) |i| {
        const b1 = bitmap[map[1]];
        const b1and6 = b1 & bitmap[map[6]];
        if (b1 & bitmap[i] == b1) {
            map[3] = i;
        } else if (b1and6 & bitmap[i] == b1and6) {
            map[5] = i;
        } else {
            map[2] = i;
        }
    }

    var i: u4 = 10;
    var result: u64 = 0;
    while (i < bitmap.len) {
        for (map) |bidx, j| {
            if (bitmap[bidx] == bitmap[i]) {
                result *= 10;
                result += j;
                break;
            }
        }
        i += 1;
    }
    return result;
}

pub fn solve(content: []const u8, _: *std.mem.Allocator) !u64 {
    var buf = [_][]const u8{&[_]u8{}} ** 14;

    var i: u64 = 0;
    var j: u64 = 0;
    var idx: u64 = 0;
    var result: u64 = 0;

    while (i < content.len) {
        if (content[i] == ' ' or content[i] == '\n') {
            buf[idx] = content[j..i];
            idx += 1;
            j = i + 1;
        } else if (content[i] == '|') {
            i += 2;
            j = i;
        }

        if (content[i] == '\n') {
            idx = 0;
            result += detect(buf);
        }

        i += 1;
    }

    return result;
}
