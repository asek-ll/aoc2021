const std = @import("std");
const u = @import("utils");
const print = std.debug.print;
const Reader = u.Reader;
const Allocator = std.mem.Allocator;

const Field = struct {
    data: []u1,
    width: u64,
    height: u64,
    default: u1,

    const Self = @This();

    pub fn init(a: Allocator, w: u64, h: u64) !Self {
        var raw = try a.alloc(u1, w * h);
        for (raw) |_, i| {
            raw[i] = 0;
        }
        return Self{
            .data = raw,
            .width = w,
            .height = h,
            .default = 0,
        };
    }

    pub fn deinit(s: *Self, a: Allocator) void {
        a.free(s.data);
    }

    pub fn put(s: *Self, y: i32, x: i32) void {
        s.data[@intCast(u64, y) * s.width + @intCast(u64, x)] = 1;
    }

    pub fn get(s: Self, y: i32, x: i32) u1 {
        if (y < 0 or x < 0 or y >= s.height or x >= s.width) {
            return s.default;
        }
        return s.data[@intCast(u64, y) * s.width + @intCast(u64, x)];
    }

    pub fn debug(s: Self) void {
        var i: i32 = 0;
        var j: i32 = 0;

        print("Field ({d},{d})\n", .{ s.width, s.height });

        while (i < s.height) : (i += 1) {
            j = 0;
            while (j < s.width) : (j += 1) {
                if (s.get(i, j) == 1) {
                    print("#", .{});
                } else {
                    print(".", .{});
                }
            }
            print("\n", .{});
        }
    }

    pub fn count(s: Self) u64 {
        var c: u64 = 0;
        for (s.data) |v| {
            c += v;
        }
        return c;
    }
};

var algo = [_]u1{0} ** 512;

pub fn parse(r: *Reader, a: Allocator) !Field {
    var i: u64 = 0;
    while (r.peek() != '\n') {
        const c = r.readChar().?;
        if (c == '#') {
            algo[i] = 1;
        } else {
            algo[i] = 0;
        }
        i += 1;
    }
    try r.skipChars("\n\n");

    var f = try Field.init(a, 100, 100);

    i = 0;
    var j: i32 = 0;
    while (r.readChar()) |c| {
        if (c == '\n') {
            j += 1;
            i = 0;
        } else if (c == '#') {
            f.put(j, @intCast(i32, i));
            i += 1;
        } else {
            i += 1;
        }
    }
    return f;
}

fn getValueByPoint(f: *Field, i: i32, j: i32) u64 {
    var res: u64 = 0;
    var y: i32 = -1;
    var x: i32 = -1;
    while (y < 2) : (y += 1) {
        x = -1;
        while (x < 2) : (x += 1) {
            res *= 2;
            res += f.get(y + i, x + j);
        }
    }
    return res;
}

pub fn enhance(f: *Field, a: Allocator) !Field {
    var i: i32 = 0;
    var j: i32 = 0;

    var out = try Field.init(a, f.width + 2, f.height + 2);
    out.default = algo[getValueByPoint(f, i - 2, j - 2)];

    while (i < out.height) : (i += 1) {
        j = 0;
        while (j < out.width) : (j += 1) {
            const idx = getValueByPoint(f, i - 1, j - 1);
            if (algo[idx] == 1) {
                out.put(i, j);
            }
        }
    }

    return out;
}

pub fn solve(content: []const u8, a: *std.mem.Allocator) !u64 {
    var r = Reader.init(content);
    var mp = try parse(&r, a.*);

    var i: u64 = 0;
    while (i < 2) : (i += 1) {
        var mp2 = try enhance(&mp, a.*);
        mp.deinit(a.*);
        mp = mp2;
    }

    return mp.count();
}
