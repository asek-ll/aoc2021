const std = @import("std");
const u = @import("utils");
const print = std.debug.print;

var fieldData = [_][140]u2{[_]u2{0} ** 140} ** 140;
var field = [_][]u2{&[_]u2{}} ** 140;

pub fn loadField(content: []const u8) [][]u2 {
    var i: u64 = 0;
    var y: u64 = 0;
    var x: u64 = 0;
    var maxWidth: u64 = 0;
    while (i < content.len) : (i += 1) {
        switch (content[i]) {
            '\n' => {
                y += 1;
                if (x > maxWidth) {
                    maxWidth = x;
                }
                x = 0;
            },
            '>' => {
                fieldData[y][x] = 1;
                x += 1;
            },
            'v' => {
                fieldData[y][x] = 2;
                x += 1;
            },
            '.' => {
                fieldData[y][x] = 0;
                x += 1;
            },
            else => unreachable,
        }
    }
    for (fieldData[0..y]) |*d, idx| {
        field[idx] = d[0..maxWidth];
    }
    return field[0..y];
}

pub fn symEast(f: [][]u2) bool {
    for (f) |r, i| {
        for (r) |v, j| {
            if (v == 1) {
                const nj = (j + 1) % r.len;
                if (f[i][nj] == 0) {
                    f[i][nj] = 3;
                }
            }
        }
    }

    var changed: bool = false;
    for (f) |r, i| {
        for (r) |v, j| {
            if (v == 3) {
                const nj = (j + r.len - 1) % r.len;
                f[i][j] = 1;
                f[i][nj] = 0;
                changed = true;
            }
        }
    }
    return changed;
}

pub fn symSouth(f: [][]u2) bool {
    for (f) |r, i| {
        for (r) |v, j| {
            if (v == 2) {
                const ni = (i + 1) % f.len;
                if (f[ni][j] == 0) {
                    f[ni][j] = 3;
                }
            }
        }
    }

    var changed: bool = false;

    for (f) |r, i| {
        for (r) |v, j| {
            if (v == 3) {
                f[i][j] = 2;
                const ni = (i + f.len - 1) % f.len;
                f[ni][j] = 0;
                changed = true;
            }
        }
    }
    return changed;
}

fn sym(f: [][]u2) bool {
    var res1 = symEast(f);
    var res2 = symSouth(f);
    return res1 or res2;
}

fn debug(f: [][]u2) void {
    for (f) |r| {
        for (r) |v| {
            var char: u8 = switch (v) {
                0 => '.',
                1 => '>',
                2 => 'v',
                else => unreachable,
            };
            print("{c}", .{char});
        }
        print("\n", .{});
    }
}

pub fn solve(content: []const u8, _: *std.mem.Allocator) !u64 {
    var f = loadField(content);
    var i: u64 = 1;
    while (sym(f)) : (i += 1) {}
    return i;
}
