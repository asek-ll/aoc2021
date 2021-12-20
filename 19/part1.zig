const std = @import("std");
const u = @import("utils");
const print = std.debug.print;
const Reader = u.Reader;
const Allocator = std.mem.Allocator;

const Beacon = [3]i32;
const Beacons = std.ArrayList(Beacon);
const Scanners = std.ArrayList(Beacons);

pub fn parse(reader: *Reader, a: Allocator) !Scanners {
    var result = Scanners.init(a);
    while (!reader.isEmpty()) {
        try reader.skipChars("--- scanner ");
        _ = reader.readUnsignedInt(u32);
        try reader.skipChars(" ---\n");
        var beacons = Beacons.init(a);
        while (!reader.isEmpty() and reader.peek() != '\n') {
            const x = reader.readInt(i32);
            try reader.skipChars(",");
            const y = reader.readInt(i32);
            try reader.skipChars(",");
            const z = reader.readInt(i32);
            try reader.skipChars("\n");
            try beacons.append([_]i32{ x, y, z });
        }
        if (!reader.isEmpty()) {
            try reader.skipChars("\n");
        }
        try result.append(beacons);
    }

    return result;
}

pub fn solve(content: []const u8, a: *std.mem.Allocator) !i32 {
    var reader = Reader.init(content);
    var scanners = parse(&reader, a.*);
    _ = try scanners;
    return -1;
}
