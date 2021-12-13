const std = @import("std");
const u = @import("utils");
const part1 = @import("part1.zig");
const part2 = @import("part2.zig");
const print = std.debug.print;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = &arena.allocator;

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    for (args[1..args.len]) |c| {
        print("Input file: {s}\n", .{c});
        const content = try u.readFile(allocator, c);

        const p1 = try part1.solve(content, allocator);
        print("Part 1: {d}\n", .{p1});

        const p2 = try part2.solve(content, allocator);
        print("Part 2: {d}\n", .{p2});
    }
}
