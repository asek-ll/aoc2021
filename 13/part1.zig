const std = @import("std");
const u = @import("utils");
const print = std.debug.print;

const Point = struct {
    x: u64,
    y: u64,
};

var field = [_][900]bool{[_]bool{false} ** 900} ** 1400;
var points = [_]Point{Point{ .x = 0, .y = 0 }} ** 1000;
var plen: u64 = 0;
var maxX: u64 = 0;
var maxY: u64 = 0;

fn removePoint(idx: u64) void {
    var p = points[idx];
    field[p.x][p.y] = false;
    points[idx] = points[plen - 1];
    plen -= 1;
}

fn foldX(l: u64) void {
    // print("fold x {d}, before folde is {d} points \n", .{ l, plen });
    maxX = l;
    var i: u64 = 0;
    while (i < plen) {
        var p = points[i];
        if (p.x == l) {
            removePoint(i);
        } else if (p.x > l) {
            var newX = 2 * l - p.x;
            if (field[newX][p.y]) {
                // print("clash {d},{d} to {d},{d}\n", .{ p.x, p.y, newX, p.y });
                removePoint(i);
            } else {
                field[newX][p.y] = true;
                field[p.x][p.y] = false;
                points[i].x = newX;
                i += 1;
            }
        } else {
            i += 1;
        }
    }
}
fn foldY(l: u64) void {
    // print("fold y {d}, before folde is {d} points \n", .{ l, plen });
    maxY = l;
    var i: u64 = 0;
    while (i < plen) {
        var p = points[i];
        if (p.y == l) {
            removePoint(i);
        } else if (p.y > l) {
            var newY = 2 * l - p.y;
            if (field[p.x][newY]) {
                removePoint(i);
            } else {
                field[p.x][newY] = true;
                field[p.x][p.y] = false;
                points[i].y = newY;
                i += 1;
            }
        } else {
            i += 1;
        }
    }
}

pub fn parse(content: []const u8, onlyFirst: bool) void {
    for (field) |r, i| {
        for (r) |v, j| {
            if (v) {
                field[i][j] = false;
            }
        }
    }
    plen = 0;

    var i: u64 = 0;
    var x: i32 = 0;
    var y: i32 = 0;
    while (i < content.len) {
        if (content[i] == '\n') {
            break;
        }
        i = u.parseNum(content, i, &x);
        i = u.parseNum(content, i + 1, &y);
        field[@intCast(u64, x)][@intCast(u64, y)] = true;
        points[plen] = Point{ .x = @intCast(u64, x), .y = @intCast(u64, y) };
        plen += 1;
        i += 1;

        if (x + 1 > maxX) {
            maxX = @intCast(u64, x) + 1;
        }
        if (y + 1 > maxY) {
            maxY = @intCast(u64, y) + 1;
        }
    }
    // debug();
    i += 1;
    var isX: bool = true;
    while (i < content.len) {
        i += 11;
        isX = content[i] == 'x';
        i += 2;
        i = u.parseNum(content, i, &x);
        i += 1;
        if (isX) {
            foldX(@intCast(u64, x));
        } else {
            foldY(@intCast(u64, x));
        }
        // debug();
        if (onlyFirst) {
            break;
        }
    }
}

pub fn debug() void {
    var x: u64 = 0;
    var y: u64 = 0;
    var c: u8 = '.';

    while (y < maxY) {
        x = 0;
        while (x < maxX) {
            if (field[x][y]) {
                c = '#';
            } else {
                c = '.';
            }
            print("{c} ", .{c});
            x += 1;
        }
        print("\n", .{});

        y += 1;
    }
    print("\n", .{});
}

pub fn solve(content: []const u8, allocator: *std.mem.Allocator) !u64 {
    parse(content, true);
    return plen;
}
