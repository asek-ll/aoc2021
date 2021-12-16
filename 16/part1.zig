const std = @import("std");
const u = @import("utils");
const print = std.debug.print;
const ArrayList = std.ArrayList;

const Packets = ArrayList(Packet);

pub const Packet = struct {
    ver: u3,
    typeId: u3,
    val: ?u64,
    subPackets: Packets,
};

const BitReader = struct {
    const Self = @This();
    bits: []u1,
    pos: u64,

    pub fn init(bitData: []u1) Self {
        return .{
            .bits = bitData,
            .pos = 0,
        };
    }

    pub fn read(self: *Self, comptime T: type) T {
        const typeInfo = @typeInfo(T);

        return switch (typeInfo) {
            .Int => {
                if (typeInfo.Int.signedness == .signed) {
                    @compileError("Unable read non unsigned type: '" ++ @typeName(T) ++ "'");
                }
                var val: T = 0;
                if (typeInfo.Int.bits == 1) {
                    val = self.bits[self.pos];
                    self.pos += 1;
                    return val;
                }
                for (self.bits[(self.pos)..(self.pos + typeInfo.Int.bits)]) |b| {
                    if (val != 0) {
                        val <<= 1;
                    }
                    val += b;
                    self.pos += 1;
                }
                return val;
            },
            else => {
                @compileError("Unable read non int type: '" ++ @typeName(T) ++ "'");
            },
        };
    }
    pub fn readLiteral(self: *Self) u64 {
        var result: u64 = 0;
        var buf: u5 = 0;
        while (true) {
            buf = self.read(u5);
            result *= 16;
            result += (buf % 16);

            if (buf < 16) {
                break;
            }
        }
        return result;
    }
};

var data = [_]u1{0} ** 6000;

pub fn readBits(content: []const u8) []u1 {
    var i: u64 = 0;
    var j: u64 = 0;
    var char: u8 = 0;
    while (i < content.len) : (i += 1) {
        if (content[i] == '\n') {
            break;
        }
        char = content[i];
        if (char >= '0' and char <= '9') {
            char -= '0';
        } else {
            char = char - 'A' + 10;
        }
        j = 4;
        while (j > 0) : (j -= 1) {
            data[i * 4 + j - 1] = @intCast(u1, char % 2);
            char = char / 2;
        }
    }
    return data[0..(i * 4)];
}

fn readPacket(br: *BitReader, allocator: std.mem.Allocator) Packet {
    const ver = br.read(u3);
    const typeId = br.read(u3);

    switch (typeId) {
        4 => {
            const litVal = br.readLiteral();
            return .{
                .ver = ver,
                .typeId = typeId,
                .val = litVal,
                .subPackets = Packets.init(allocator),
            };
        },
        else => {
            const lengthType = br.read(u1);
            if (lengthType == 0) {
                const totalSubPacketsLen = br.read(u15);

                var packet = Packet{
                    .ver = ver,
                    .typeId = typeId,
                    .val = null,
                    .subPackets = Packets.init(allocator),
                };

                const end = br.pos + totalSubPacketsLen;
                while (br.pos < end) {
                    packet.subPackets.append(readPacket(br, allocator)) catch unreachable;
                }

                return packet;
            }
            const subPackedCount = br.read(u11);
            var i: u11 = 0;
            var packet = Packet{
                .ver = ver,
                .typeId = typeId,
                .val = null,
                .subPackets = Packets.init(allocator),
            };
            while (i < subPackedCount) : (i += 1) {
                packet.subPackets.append(readPacket(br, allocator)) catch unreachable;
            }
            return packet;
        },
    }
}

fn sumVersion(packet: Packet) u64 {
    var result: u64 = 0;
    result += packet.ver;
    for (packet.subPackets.items) |p| {
        result += sumVersion(p);
    }
    return result;
}

pub fn readData(content: []const u8, allocator: *std.mem.Allocator) Packet {
    var bits = readBits(content);
    var bitReader = BitReader.init(bits);
    return readPacket(&bitReader, allocator.*);
}

pub fn solve(content: []const u8, allocator: *std.mem.Allocator) !u64 {
    var rootPacket = readData(content, allocator);
    return sumVersion(rootPacket);
}
