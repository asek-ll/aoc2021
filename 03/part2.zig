const std = @import("std");
const u = @import("utils");
const print = std.debug.print;

pub fn parse(content: []const u8, allocator: *std.mem.Allocator) ![][]u1 {
    var i: u64 = 0;
    var prev: u64 = 0;
    var count: u64 = 0;
    var len: u64 = 0;

    while (i < content.len) {
        if (content[i] == '\n') {
            if (i > prev + 1) {
                if (i - prev > len) {
                    len = i - prev - 1;
                }
                prev = i;
                count += 1;
            }
        }
        i += 1;
    }
    if (content.len > prev + 1) {
        count += 1;
    }

    var data = try allocator.alloc(u1, count * len);
    var parsed = try allocator.alloc([]u1, count);

    i = 0;
    var j: u64 = 0;
    while (i < content.len) {
        while (i < content.len and (content[i] == '0' or content[i] == '1')) {
            if (content[i] == '0') {
                data[j] = 0;
            } else {
                data[j] = 1;
            }
            i += 1;
            j += 1;
        }
        i += 1;
    }

    for (parsed) |_, idx| {
        parsed[idx] = data[(idx * len)..((idx + 1) * len)];
    }

    return parsed;
}

pub fn initState(data: [][]u1, state: []i32) void {
    for (state) |_, i| {
        state[i] = 0;
    }
    for (data) |d| {
        for (d) |v, i| {
            state[i] += (@intCast(i32, v) * 2 - 1);
        }
    }
}

pub fn bin2Dec(data: []u1) i32 {
    var result: i32 = 0;
    for (data) |v| {
        result *= 2;
        result += v;
    }
    return result;
}

pub fn filter(data: [][]u1, current: []u16, state: []i32, pos: u64, val: u1) []u1 {
    if (pos >= state.len) {
        return data[current[0]];
    }

    var common: u1 = 0;
    if (state[pos] == 0) {
        common = val;
    } else if (val == 1) {
        if (state[pos] > 0) {
            common = 1;
        } else if (state[pos] < 0) {
            common = 0;
        }
    } else {
        if (state[pos] == @intCast(i32, current.len)) {
            common = 1;
        } else if (state[pos] == -@intCast(i32, current.len)) {
            common = 0;
        } else if (state[pos] > 0) {
            common = 0;
        } else if (state[pos] < 0) {
            common = 1;
        }
    }

    var i: u64 = 0;
    var j: u64 = 0;

    while (i < current.len) {
        if (data[current[i]][pos] == common) {
            if (j < i) {
                current[j] = current[i];
            }
            j += 1;
        } else {
            for (data[current[i]]) |v, idx| {
                state[idx] -= (@intCast(i32, v) * 2 - 1);
            }
        }
        i += 1;
    }

    return filter(data, current[0..j], state, pos + 1, val);
}

pub fn solve(content: []const u8, allocator: *std.mem.Allocator) !i32 {
    var data = try parse(content, allocator);
    var state = try allocator.alloc(i32, data[0].len);
    var current = try allocator.alloc(u16, data.len);

    for (current) |_, i| {
        current[i] = @intCast(u16, i);
    }

    initState(data, state);
    var o2 = bin2Dec(filter(data, current, state, 0, 1));

    for (current) |_, i| {
        current[i] = @intCast(u16, i);
    }
    initState(data, state);
    var co2 = bin2Dec(filter(data, current, state, 0, 0));

    return o2 * co2;
}
