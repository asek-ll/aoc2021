const std = @import("std");
const u = @import("utils");
const print = std.debug.print;

var template: []const u8 = undefined;
var rules = [_]u8{' '} ** 1000;
var state = [_]u64{0} ** 1000;
var tempState = [_]u64{0} ** 1000;

fn code(str: [2]u8) u10 {
    return @intCast(u10, str[0] - 'A') * 27 + (str[1] - 'A');
}

fn fromCode(c: u10) [2]u8 {
    return [_]u8{ @intCast(u8, (c / 27) + 'A'), @intCast(u8, (c % 27) + 'A') };
}

pub fn parse(content: []const u8) void {
    for (rules) |_, i| {
        rules[i] = ' ';
    }
    for (state) |_, i| {
        state[i] = 0;
    }

    var i: u64 = 0;
    while (content[i] != '\n') {
        i += 1;
    }
    template = content[0..i];
    i += 2;
    var source = [_]u8{0} ** 2;
    var target: u8 = undefined;
    while (i < content.len) {
        source[0] = content[i];
        source[1] = content[i + 1];
        i += 6;
        target = content[i];
        i += 2;

        rules[code(source)] = target;
    }

    i = 1;
    while (i < template.len) {
        source[0] = template[i - 1];
        source[1] = template[i];
        state[code(source)] += 1;
        i += 1;
        // print("{s}\n", .{source});
    }
}

pub fn sym() void {
    for (tempState) |_, i| {
        tempState[i] = 0;
    }

    for (rules) |t, c| {
        var cnt = state[c];
        if (t != ' ' and cnt > 0) {
            var chars = fromCode(@intCast(u10, c));
            // print("proces '{s}' to {c} x {d}\n", .{ chars, t, cnt });
            tempState[code([_]u8{ chars[0], t })] += cnt;
            tempState[code([_]u8{ t, chars[1] })] += cnt;
            // print("add '{c}{c}' x {d}, code {d}\n", .{ chars[0], t, cnt, code([_]u8{ chars[0], t }) });
            // print("add '{c}{c}' x {d}, code {d}\n", .{ t, chars[1], cnt, code([_]u8{ t, chars[1] }) });

            state[c] = 0;
        }
    }
    for (tempState) |inc, i| {
        state[i] += inc;
    }
}

pub fn getCharCnt(char: u8) u64 {
    var result: u64 = 0;

    var i: u8 = 0;
    while (i < 27) {
        result += state[code([_]u8{ 'A' + i, char })];
        i += 1;
    }
    if (template[0] == char) {
        result += 1;
    }

    return result;
}

fn debug() void {
    for (state) |c, i| {
        if (c > 0) {
            var str = fromCode(@intCast(u10, i));
            print("{s}: {d} \n", .{ str, c });
        }
    }
    print("\n", .{});
}

pub fn solve(content: []const u8, allocator: *std.mem.Allocator) !u64 {
    parse(content);
    var i: u8 = 10;
    while (i > 0) {
        sym();
        i -= 1;
    }

    i = 0;
    var min: ?u64 = null;
    var max: ?u64 = null;
    while (i < 27) {
        var cnt = getCharCnt('A' + i);
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
