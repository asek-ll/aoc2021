const std = @import("std");
const u = @import("utils");
const p1 = @import("part1.zig");
const p2 = @import("part2.zig");

const runner = u.Runner(p1.solve, p2.solve);

pub fn main() !void {
    try runner.run();
}
