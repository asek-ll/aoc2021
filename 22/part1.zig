const std = @import("std");
const u = @import("utils");
const print = std.debug.print;
const Reader = u.Reader;
const Allocator = std.mem.Allocator;

const Range = [2]i32;
const Cube = [3]Range;
const Cubes = std.ArrayList(Cube);

const CubesUnion = struct {
    a: Allocator,
    cs: Cubes,

    const Self = @This();

    pub fn init(a: Allocator) Self {
        return .{
            .a = a,
            .cs = Cubes.init(a),
        };
    }

    pub fn addOn(self: *Self, c: Cube) !void {
        var curr = Cubes.init(self.a);
        try curr.append(c);

        var temp = Cubes.init(self.a);
        for (self.cs.items) |i| {
            for (curr.items) |sc| {
                try split(i, sc, &temp);
            }
            var buf = curr;
            curr = temp;
            temp = buf;
            temp.clearRetainingCapacity();
        }

        for (curr.items) |sc| {
            try self.cs.append(sc);
        }
        curr.deinit();
        temp.deinit();
    }

    pub fn addOff(self: *Self, c: Cube) !void {
        var curr = Cubes.init(self.a);
        for (self.cs.items) |sc| {
            try split(c, sc, &curr);
        }
        var temp = self.cs;
        self.cs = curr;
        temp.deinit();
    }

    pub fn volume(self: Self) u64 {
        var res: u64 = 0;
        for (self.cs.items) |c| {
            res += cubeVolume(c);
        }
        return res;
    }
};

fn cubeVolume(c: Cube) u64 {
    var res: u64 = 1;
    for (c) |dim| {
        res *= @intCast(u64, dim[1] - dim[0] + 1);
    }
    return res;
}

fn intersectRange(r1: Range, r2: Range) ?Range {
    var m1 = if (r1[0] > r2[0]) r1[0] else r2[0];
    var m2 = if (r1[1] < r2[1]) r1[1] else r2[1];
    if (m2 >= m1) {
        return Range{ m1, m2 };
    }
    return null;
}

fn intersectCube(c1: Cube, c2: Cube) ?Cube {
    if (intersectRange(c1[0], c2[0])) |r1| {
        if (intersectRange(c1[1], c2[1])) |r2| {
            if (intersectRange(c1[2], c2[2])) |r3| {
                return Cube{ r1, r2, r3 };
            }
        }
    }

    return null;
}

fn debugCube(c: Cube) void {
    print("x={d}..{d},y={d}..{d},z={d}..{d}\n", .{
        c[0][0],
        c[0][1],
        c[1][0],
        c[1][1],
        c[2][0],
        c[2][1],
    });
}

fn split(base: Cube, other: Cube, resultCubes: *Cubes) !void {
    if (intersectCube(base, other)) |ins| {
        var result = other;
        for (result) |_, dim| {
            if (result[dim][0] < ins[dim][0]) {
                var part = result;
                part[dim] = Range{ result[dim][0], ins[dim][0] - 1 };
                try resultCubes.append(part);
                result[dim][0] = ins[dim][0];
            }
            if (result[dim][1] > ins[dim][1]) {
                var part = result;
                part[dim] = Range{ ins[dim][1] + 1, result[dim][1] };
                try resultCubes.append(part);
                result[dim][1] = ins[dim][1];
            }
        }
    } else {
        try resultCubes.append(other);
    }
}

pub fn parse(r: *Reader, a: Allocator, p1: bool) !CubesUnion {
    var cu = CubesUnion.init(a);
    while (!r.isEmpty()) {
        var x = Range{ 0, 0 };
        var y = Range{ 0, 0 };
        var z = Range{ 0, 0 };
        var isOn: bool = true;

        if (r.trySkip("off")) {
            isOn = false;
        } else {
            try r.skipChars("on");
        }

        try r.skipChars(" x=");
        x[0] = r.readInt(i32);
        try r.skipChars("..");
        x[1] = r.readInt(i32);

        try r.skipChars(",y=");
        y[0] = r.readInt(i32);
        try r.skipChars("..");
        y[1] = r.readInt(i32);

        try r.skipChars(",z=");
        z[0] = r.readInt(i32);
        try r.skipChars("..");
        z[1] = r.readInt(i32);
        try r.skipChars("\n");

        var c = Cube{ x, y, z };

        var isValid: bool = true;

        if (p1) {
            for (c) |d| {
                for (d) |v| {
                    if (v > 50 or v < -50) {
                        isValid = false;
                        break;
                    }
                }
            }
        }

        if (isValid) {
            if (isOn) {
                try cu.addOn(c);
            } else {
                try cu.addOff(c);
            }
        }
    }
    return cu;
}

pub fn solve(content: []const u8, a: *std.mem.Allocator) !u64 {
    var r = Reader.init(content);
    var cs = try parse(&r, a.*, true);
    return cs.volume();
}
