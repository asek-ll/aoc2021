const std = @import("std");
const u = @import("utils");
const print = std.debug.print;
const Reader = u.Reader;
const Allocator = std.mem.Allocator;

const Beacon = [3]i32;
const Beacons = std.ArrayList(Beacon);
const Scanners = std.ArrayList(Beacons);

const BeaconCtx = struct {
    pub fn hash(_: BeaconCtx, b: Beacon) u64 {
        var code: u64 = @intCast(u64, @bitCast(u32, b[0]));
        _ = @mulWithOverflow(u64, code, 31, &code);
        _ = @addWithOverflow(u64, code, @bitCast(u32, b[1]), &code);
        _ = @mulWithOverflow(u64, code, 31, &code);
        _ = @addWithOverflow(u64, code, @bitCast(u32, b[2]), &code);

        return code;
    }
    pub fn eql(_: BeaconCtx, b1: Beacon, b2: Beacon) bool {
        return b1[0] == b2[0] and b1[1] == b2[1] and b1[2] == b2[2];
    }
};

const BeaconMap = std.HashMap(Beacon, u0, BeaconCtx, 80);

const RotationMatrix = struct {
    data: [3][3]i32,

    const Self = @This();

    pub fn init(m: [3][3]i32) Self {
        return .{ .data = m };
    }

    pub fn mulVec(self: Self, v: [3]i32) [3]i32 {
        return [3]i32{
            self.data[0][0] * v[0] + self.data[0][1] * v[1] + self.data[0][2] * v[2],
            self.data[1][0] * v[0] + self.data[1][1] * v[1] + self.data[1][2] * v[2],
            self.data[2][0] * v[0] + self.data[2][1] * v[1] + self.data[2][2] * v[2],
        };
    }

    pub fn mulMat(self: Self, o: Self) Self {
        return Self.init([3][3]i32{
            [3]i32{
                self.data[0][0] * o.data[0][0] + self.data[0][1] * o.data[1][0] + self.data[0][2] * o.data[2][0],
                self.data[0][0] * o.data[0][1] + self.data[0][1] * o.data[1][1] + self.data[0][2] * o.data[2][1],
                self.data[0][0] * o.data[0][2] + self.data[0][1] * o.data[1][2] + self.data[0][2] * o.data[2][2],
            },
            [3]i32{
                self.data[1][0] * o.data[0][0] + self.data[1][1] * o.data[1][0] + self.data[1][2] * o.data[2][0],
                self.data[1][0] * o.data[0][1] + self.data[1][1] * o.data[1][1] + self.data[1][2] * o.data[2][1],
                self.data[1][0] * o.data[0][2] + self.data[1][1] * o.data[1][2] + self.data[1][2] * o.data[2][2],
            },
            [3]i32{
                self.data[2][0] * o.data[0][0] + self.data[2][1] * o.data[1][0] + self.data[2][2] * o.data[2][0],
                self.data[2][0] * o.data[0][1] + self.data[2][1] * o.data[1][1] + self.data[2][2] * o.data[2][1],
                self.data[2][0] * o.data[0][2] + self.data[2][1] * o.data[1][2] + self.data[2][2] * o.data[2][2],
            },
        });
    }
};

const BeaconsView = struct {
    items: Beacons,
    rot: RotationMatrix,
    shift: [3]i32,

    const Self = @This();

    pub fn init(is: Beacons) Self {
        return .{ .items = is, .rot = R0, .shift = [3]i32{ 0, 0, 0 } };
    }

    pub fn get(self: Self, i: u64) [3]i32 {
        const v = self.items.items[i];
        return [3]i32{
            self.rot.data[0][0] * v[0] + self.rot.data[0][1] * v[1] + self.rot.data[0][2] * v[2] + self.shift[0],
            self.rot.data[1][0] * v[0] + self.rot.data[1][1] * v[1] + self.rot.data[1][2] * v[2] + self.shift[1],
            self.rot.data[2][0] * v[0] + self.rot.data[2][1] * v[1] + self.rot.data[2][2] * v[2] + self.shift[2],
        };
    }

    pub fn rotate(self: *Self, r: RotationMatrix) void {
        self.rot = self.rot.mulMat(r);
    }

    pub fn move(self: *Self, dv: [3]i32) void {
        self.shift[0] += dv[0];
        self.shift[1] += dv[1];
        self.shift[2] += dv[2];
    }
};

const R0 = RotationMatrix.init([3][3]i32{
    [3]i32{ 1, 0, 0 },
    [3]i32{ 0, 1, 0 },
    [3]i32{ 0, 0, 1 },
});

const RX = RotationMatrix.init([3][3]i32{
    [3]i32{ 1, 0, 0 },
    [3]i32{ 0, 0, -1 },
    [3]i32{ 0, 1, 0 },
});

const RY = RotationMatrix.init([3][3]i32{
    [3]i32{ 0, 0, 1 },
    [3]i32{ 0, 1, 0 },
    [3]i32{ -1, 0, 0 },
});

const RZ = RotationMatrix.init([3][3]i32{
    [3]i32{ 0, -1, 0 },
    [3]i32{ 1, 0, 0 },
    [3]i32{ 0, 0, 1 },
});

const RZR = RotationMatrix.init([3][3]i32{
    [3]i32{ 0, 1, 0 },
    [3]i32{ -1, 0, 0 },
    [3]i32{ 0, 0, 1 },
});

fn debug(b: [3]i32) void {
    print("{d},{d},{d}\n", .{ b[0], b[1], b[2] });
}

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

fn getShiftWithMaxClash(base: BeaconMap, other: *BeaconsView) u64 {
    // print("compare map and view !!\n", .{});

    var max: u64 = 0;
    var tempMax: u64 = 0;
    var maxShift: ?[3]i32 = null;

    var mit = base.keyIterator();
    while (mit.next()) |b1| {
        var j: u64 = 0;
        while (j < other.items.items.len) : (j += 1) {
            const b2 = other.get(j);
            // print("check\n", .{});
            const shift = [3]i32{
                b1[0] - b2[0],
                b1[1] - b2[1],
                b1[2] - b2[2],
            };

            other.shift = shift;
            var i: u64 = 0;
            tempMax = 0;
            while (i < other.items.items.len) : (i += 1) {
                const res = other.get(i);
                // debug(res);
                if (base.contains(res)) {
                    tempMax += 1;
                }
            }
            if (tempMax > max) {
                max = tempMax;
                maxShift = shift;
            }
        }
    }
    if (maxShift) |s| {
        other.shift = s;
    }
    return max;
}

fn findBestRotation(base: BeaconMap, other: Beacons) BeaconsView {
    var view = BeaconsView.init(other);

    var i: u64 = 0;
    var j: u64 = 0;

    var max: u64 = 0;
    var tempMax: u64 = 0;

    var rot: ?RotationMatrix = null;
    var shift: ?[3]i32 = null;

    while (i < 4) : (i += 1) {
        j = 0;
        while (j < 4) : (j += 1) {
            tempMax = getShiftWithMaxClash(base, &view);
            if (tempMax > max) {
                max = tempMax;
                rot = view.rot;
                shift = view.shift;
            }
            view.rotate(RX);
        }
        view.rotate(RZ);
        tempMax = getShiftWithMaxClash(base, &view);
        if (tempMax > max) {
            max = tempMax;
            rot = view.rot;
            shift = view.shift;
        }
        view.rotate(RZR);
        view.rotate(RZR);
        tempMax = getShiftWithMaxClash(base, &view);
        if (tempMax > max) {
            max = tempMax;
            rot = view.rot;
            shift = view.shift;
        }
        view.rotate(RZ);

        view.rotate(RY);
    }

    print("tm: {d}\n", .{max});

    view.rot = rot.?;
    view.shift = shift.?;
    return view;
}

fn mergeBeacons(map: *BeaconMap, other: Beacons) !void {
    const view = findBestRotation(map.*, other);
    for (view.items.items) |b| {
        try map.put(b, 0);
    }
}

pub fn solve(content: []const u8, a: *std.mem.Allocator) !u64 {
    var reader = Reader.init(content);
    var scanners = try parse(&reader, a.*);

    var map = BeaconMap.init(a.*);
    for (scanners.items[0].items) |b| {
        try map.put(b, 0);
    }

    for (scanners.items[1..]) |s| {
        try mergeBeacons(&map, s);
    }

    // try mergeBeacons(&map, scanners.items[1]);
    return map.count();
}
