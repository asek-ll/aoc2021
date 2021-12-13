const std = @import("std");
const u = @import("utils");
const print = std.debug.print;
const p1 = @import("part1.zig");
const Id = p1.Id;

const isUpper = std.ascii.isUpper;

const Visited = struct {
    mask: u64,
    twice: bool,
};

fn canVisit(id: Id, visited: Visited) ?Visited {
    const label = p1.labels[id];
    if (isUpper(label[0])) {
        return visited;
    }
    if (visited.mask & (@intCast(u64, 1) << id) == 0) {
        return Visited{
            .mask = visited.mask | (@intCast(u64, 1) << id),
            .twice = visited.twice,
        };
    }

    if (label.len > 2) {
        return null;
    }

    if (visited.twice) {
        return null;
    }

    return Visited{
        .mask = visited.mask,
        .twice = true,
    };
}

fn traverse(visited: Visited, currentIdx: Id, endIdx: Id, rels: [][]Id) u64 {
    if (currentIdx == endIdx) {
        return 1;
    }
    var result: u64 = 0;
    for (rels[currentIdx]) |toId| {
        if (canVisit(toId, visited)) |nextVisited| {
            result += traverse(nextVisited, toId, endIdx, rels);
        }
    }
    return result;
}

pub fn solve(content: []const u8, allocator: *std.mem.Allocator) !u64 {
    var rels = p1.parse(content);
    var sidx = p1.findLabel("start");
    var eidx = p1.findLabel("end");
    return traverse(.{
        .mask = @intCast(u64, 1) << sidx.?,
        .twice = false,
    }, sidx.?, eidx.?, rels);
}
