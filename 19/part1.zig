const std = @import("std");
const u = @import("utils");
const print = std.debug.print;
const Reader = u.Reader;
const Allocator = std.mem.Allocator;

const Beacon = [3]i32;
const Beacons = std.ArrayList(Beacon);
const Scanners = std.ArrayList(Beacons);

const EmptyVec = [3]i32{ 0, 0, 0 };

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

    pub fn vec(self: Self, v: *[3]i32) void {
        const x = self.data[0][0] * v[0] + self.data[0][1] * v[1] + self.data[0][2] * v[2];
        const y = self.data[1][0] * v[0] + self.data[1][1] * v[1] + self.data[1][2] * v[2];
        const z = self.data[2][0] * v[0] + self.data[2][1] * v[1] + self.data[2][2] * v[2];
        v[0] = x;
        v[1] = y;
        v[2] = z;
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

    pub fn debug(self: Self) void {
        for (self.data) |r| {
            for (r) |v| {
                print("{d} ", .{v});
            }
            print("\n", .{});
        }
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
        return self.apply(v);
    }

    pub fn apply(self: Self, v: [3]i32) [3]i32 {
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
    pub fn debug(self: Self) void {
        print("Shift: {d},{d},{d}, Rotation: \n", .{
            self.shift[0],
            self.shift[1],
            self.shift[2],
        });
        self.rot.debug();
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

fn abs(x: i32) u32 {
    if (x < 0) {
        return @intCast(u32, -x);
    }
    return @intCast(u32, x);
}

fn dist(a: [3]i32, b: [3]i32) u64 {
    return abs(a[0] - b[0]) + abs(a[1] - b[1]) + abs(a[2] - b[2]);
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
    // print("rot:\n", .{});
    // other.rot.debug();
    // for (other.items.items) |o, i| {
    // const b = other.get(i);
    // print("bv: {d},{d},{d} => {d},{d},{d}\n", .{ o[0], o[1], o[2], b[0], b[1], b[2] });
    // }
    // print("compare map and view !!\n", .{});

    var max: u64 = 0;
    var tempMax: u64 = 0;
    var maxShift: ?[3]i32 = null;

    var mit = base.keyIterator();
    while (mit.next()) |b1| {
        var j: u64 = 0;
        while (j < other.items.items.len) : (j += 1) {
            other.shift = EmptyVec;
            const b2 = other.get(j);
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

fn findBestRotation(base: BeaconMap, other: Beacons) ?BeaconsView {
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
    if (max == 1) {
        return null;
    }

    view.rot = rot.?;
    view.shift = shift.?;
    return view;
}

fn mergeBeacons(map: *BeaconMap, other: Beacons) !?BeaconsView {
    if (findBestRotation(map.*, other)) |view| {
        // view.debug();
        for (view.items.items) |_, i| {
            try map.put(view.get(i), 0);
        }
        return view;
    }
    return null;
}

pub fn solve(content: []const u8, a: *std.mem.Allocator) !u64 {
    var reader = Reader.init(content);
    var scanners = try parse(&reader, a.*);

    var map = BeaconMap.init(a.*);
    for (scanners.items[0].items) |b| {
        try map.put(b, 0);
    }

    var done = [_]bool{false} ** 100;
    var pos = [_]Beacon{Beacon{ 0, 0, 0 }} ** 100;

    var suc: bool = true;
    while (true) {
        suc = true;
        for (scanners.items[1..]) |s, si| {
            if (!done[si]) {
                if (try mergeBeacons(&map, s)) |v| {
                    done[si] = true;
                    pos[si + 1] = v.apply(EmptyVec);
                } else {
                    suc = false;
                }
            }
        }
        if (suc) {
            break;
        }
    }

    var maxDist: u64 = 0;

    for (scanners.items) |_, si1| {
        for (scanners.items) |_, si2| {
            var m = dist(pos[si1], pos[si2]);
            if (m > maxDist) {
                maxDist = m;
            }
        }
    }
    print("MAX dist: {d}\n", .{maxDist});

    // var bs = Beacons.init(a.*);
    // try bs.append(Beacon{ 686, 422, 578 });
    // try bs.append(Beacon{ 605, 423, 415 });
    // var bv = BeaconsView.init(bs);

    // bv.rot = RZ.mulMat(RZ).mulMat(RZ);
    // debug(bv.get(0));
    // debug(bv.get(1));

    // var mx = getShiftWithMaxClash(map, &bv);
    // print("MAX: {d}\n", .{mx});

    // try mergeBeacons(&map, scanners.items[1]);
    return map.count();
}
