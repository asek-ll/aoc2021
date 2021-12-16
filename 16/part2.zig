const std = @import("std");
const u = @import("utils");
const print = std.debug.print;
const p1 = @import("part1.zig");
const Packet = p1.Packet;

fn calc(packet: Packet) u64 {
    var res: u64 = 0;
    switch (packet.typeId) {
        0 => {
            for (packet.subPackets.items) |p| {
                res += calc(p);
            }
        },
        1 => {
            res = 1;
            for (packet.subPackets.items) |p| {
                res *= calc(p);
            }
        },
        2 => {
            res = calc(packet.subPackets.items[0]);
            for (packet.subPackets.items) |p| {
                var v = calc(p);
                if (res > v) {
                    res = v;
                }
            }
        },
        3 => {
            res = calc(packet.subPackets.items[0]);
            for (packet.subPackets.items) |p| {
                var v = calc(p);
                if (res < v) {
                    res = v;
                }
            }
        },
        4 => {
            res = packet.val.?;
        },
        5 => {
            const v1 = calc(packet.subPackets.items[0]);
            const v2 = calc(packet.subPackets.items[1]);
            if (v1 > v2) {
                res = 1;
            } else {
                res = 0;
            }
        },
        6 => {
            const v1 = calc(packet.subPackets.items[0]);
            const v2 = calc(packet.subPackets.items[1]);
            if (v1 < v2) {
                res = 1;
            } else {
                res = 0;
            }
        },
        7 => {
            const v1 = calc(packet.subPackets.items[0]);
            const v2 = calc(packet.subPackets.items[1]);
            if (v1 == v2) {
                res = 1;
            } else {
                res = 0;
            }
        },
    }
    return res;
}

pub fn solve(content: []const u8, allocator: *std.mem.Allocator) !u64 {
    var rootPacket = p1.readData(content, allocator);
    return calc(rootPacket);
}
