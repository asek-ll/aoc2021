const std = @import("std");
const u = @import("utils");
const print = std.debug.print;
const isUpper = std.ascii.isUpper;

pub const Id = u6;

pub var labels = [_][]const u8{&[_]u8{}} ** 50;
var labelsLen: Id = 0;
var relationsData = [_][25]Id{[_]Id{0} ** 25} ** 25;
var relationsLens = [_]u64{0} ** 25;
pub var relations = [_][]Id{&[_]Id{}} ** 25;

pub fn findLabel(label: []const u8) ?Id {
    var i: Id = 0;
    var isEqv: bool = false;
    while (i < labelsLen) {
        var l2 = labels[i];
        if (l2.len == label.len) {
            isEqv = true;
            for (l2) |c2, idx| {
                if (label[idx] != c2) {
                    isEqv = false;
                    break;
                }
            }
            if (isEqv) {
                return i;
            }
        }

        i += 1;
    }
    return null;
}

pub fn getLabelIndex(label: []const u8) Id {
    if (findLabel(label)) |idx| {
        return idx;
    }
    labels[labelsLen] = label;
    labelsLen += 1;
    return labelsLen - 1;
}

pub fn parse(content: []const u8) [][]Id {
    var i: u64 = 0;
    var j: u64 = 0;

    labelsLen = 0;
    for (relationsLens) |_, idx| {
        relationsLens[idx] = 0;
    }

    while (i < content.len) {
        j = i;
        while (j < content.len and content[j] != '-') {
            j += 1;
        }
        var l1Idx = getLabelIndex(content[i..j]);

        i = j + 1;
        j = i;
        while (j < content.len and content[j] != '\n') {
            j += 1;
        }

        var l2Idx = getLabelIndex(content[i..j]);
        relationsData[l1Idx][relationsLens[l1Idx]] = l2Idx;
        relationsData[l2Idx][relationsLens[l2Idx]] = l1Idx;

        relationsLens[l1Idx] += 1;
        relationsLens[l2Idx] += 1;

        i = j + 1;
    }

    for (relationsData[0..labelsLen]) |_, k| {
        relations[k] = relationsData[k][0..relationsLens[k]];
    }

    return relations[0..labelsLen];
}

fn canVisit(id: Id, visited: u64) bool {
    if (isUpper(labels[id][0])) {
        return true;
    }
    return (visited & (@intCast(u64, 1) << id)) == 0;
}

fn traverse(visited: u64, currentIdx: Id, endIdx: Id, rels: [][]Id) u64 {
    if (currentIdx == endIdx) {
        return 1;
    }
    var result: u64 = 0;
    for (rels[currentIdx]) |toId| {
        if (canVisit(toId, visited)) {
            var nextVisited = visited | (@intCast(u64, 1) << toId);
            result += traverse(nextVisited, toId, endIdx, rels);
        }
    }
    return result;
}

pub fn solve(content: []const u8, allocator: *std.mem.Allocator) !u64 {
    var rels = parse(content);
    var sidx = findLabel("start");
    var eidx = findLabel("end");
    return traverse(@intCast(u64, 1) << sidx.?, sidx.?, eidx.?, rels);
}
