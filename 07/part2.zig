const std = @import("std");
const u = @import("utils");
const print = std.debug.print;
const p1 = @import("part1.zig");

fn getFuel(data: []u64, level: u64) u64 {
    var fuel: u64 = 0;
    for (data) |d| {
        if (d > level) {
            fuel += (d - level) * (d - level + 1) / 2;
        } else {
            fuel += (level - d) * (level + 1 - d) / 2;
        }
    }
    return fuel;
}

pub fn solve(content: []const u8, _: *std.mem.Allocator) !u64 {
    var data = p1.parse(content);

    var min: u64 = 1000;
    var max: u64 = 0;
    for (data) |d| {
        if (d < min) {
            min = d;
        }
        if (d > max) {
            max = d;
        }
    }

    var i = min;
    var minFuel: u64 = 1000 * 1000 * 1000;
    var minFuelLevel: u64 = 0;
    while (i <= max) {
        var fuel = getFuel(data, i);
        if (minFuel > fuel) {
            minFuel = fuel;
            minFuelLevel = i;
        }
        i += 1;
    }

    return minFuel;
}
