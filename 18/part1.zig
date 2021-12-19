const std = @import("std");
const u = @import("utils");
const print = std.debug.print;
const Allocator = std.mem.Allocator;
const Reader = u.Reader;

pub const Pair = union(enum) {
    value: u64,
    pair: struct { p1: *Pair, p2: *Pair },
};

pub fn own(p: Pair, a: Allocator) !*Pair {
    const res = try a.dupe(Pair, &[_]Pair{p});
    return &res[0];
}

pub fn parsePair(r: *Reader, a: Allocator) anyerror!*Pair {
    if (r.peek() == '[') {
        try r.skipChars("[");
        const p1 = try parsePair(r, a);
        try r.skipChars(",");
        const p2 = try parsePair(r, a);
        try r.skipChars("]");
        const p = Pair{ .pair = .{ .p1 = p1, .p2 = p2 } };
        const res = try a.dupe(Pair, &[_]Pair{p});
        return &res[0];
    }
    const p = Pair{ .value = r.readUnsignedInt(u64) };
    const res = try a.dupe(Pair, &[_]Pair{p});
    return &res[0];
}

pub fn printPair(p: *Pair) void {
    switch (p.*) {
        Pair.value => |x| {
            print("{d}", .{x});
        },
        Pair.pair => |x| {
            print("[", .{});
            printPair(x.p1);
            print(",", .{});
            printPair(x.p2);
            print("]", .{});
        },
    }
}

pub fn plus(p1: *Pair, p2: *Pair, a: Allocator) !*Pair {
    const p = Pair{ .pair = .{ .p1 = p1, .p2 = p2 } };
    return try own(p, a);
}

const Context = struct {
    level: u4,
    exploded: bool,
    toLeft: ?u64,
    toRight: ?u64,
    prev: ?*Pair,

    pub fn init() Context {
        return .{
            .level = 0,
            .exploded = false,
            .toLeft = null,
            .toRight = null,
            .prev = null,
        };
    }
};

fn explode(p: *Pair, ctx: *Context, a: Allocator) anyerror!bool {
    if (ctx.exploded and ctx.toRight == null) {
        return false;
    }
    switch (p.*) {
        Pair.pair => |*np| {
            if (ctx.level == 4) {
                if (!ctx.exploded) {
                    if (ctx.prev) |prev| {
                        prev.value += np.p1.value;
                    }
                    ctx.toRight = np.p2.value;
                    ctx.exploded = true;
                    return true;
                }
            }
            ctx.level += 1;
            if (try explode(np.p1, ctx, a)) {
                np.p1 = try own(Pair{ .value = 0 }, a);
            }
            if (try explode(np.p2, ctx, a)) {
                np.p2 = try own(Pair{ .value = 0 }, a);
            }
            ctx.level -= 1;
        },
        Pair.value => {
            if (ctx.toRight) |add| {
                p.value += add;
                ctx.toRight = null;
            }
            ctx.prev = p;
        },
    }
    return false;
}

fn split(p: *Pair, a: Allocator) anyerror!bool {
    switch (p.*) {
        Pair.pair => |*np| {
            switch (np.p1.*) {
                Pair.value => |v1| {
                    if (v1 >= 10) {
                        np.p1 = try own(Pair{ .pair = .{
                            .p1 = try own(Pair{ .value = v1 / 2 }, a),
                            .p2 = try own(Pair{ .value = v1 - (v1 / 2) }, a),
                        } }, a);
                        return true;
                    }
                },
                else => {
                    if (try split(np.p1, a)) {
                        return true;
                    }
                },
            }
            switch (np.p2.*) {
                Pair.value => |v2| {
                    if (v2 >= 10) {
                        np.p2 = try own(Pair{ .pair = .{
                            .p1 = try own(Pair{ .value = v2 / 2 }, a),
                            .p2 = try own(Pair{ .value = v2 - (v2 / 2) }, a),
                        } }, a);
                        return true;
                    }
                },
                else => {
                    if (try split(np.p2, a)) {
                        return true;
                    }
                },
            }
            return false;
        },
        else => {
            return false;
        },
    }
}

pub fn simplify(p: *Pair, a: Allocator) anyerror!void {
    while (true) {
        var ctx = Context.init();
        _ = try explode(p, &ctx, a);
        if (ctx.exploded) {
            continue;
        }

        if (try split(p, a)) {
            continue;
        }
        break;
    }
}

pub fn magnitude(p: *Pair) u64 {
    return switch (p.*) {
        Pair.pair => |np| {
            return magnitude(np.p1) * 3 + magnitude(np.p2) * 2;
        },
        Pair.value => |v| {
            return v;
        },
    };
}

pub fn solve(content: []const u8, a: *Allocator) !u64 {
    var reader = Reader.init(content);
    var p1 = try parsePair(&reader, a.*);
    try reader.skipChars("\n");

    while (reader.pos < reader.data.len) {
        var p2 = try parsePair(&reader, a.*);
        try reader.skipChars("\n");
        var p3 = try plus(p1, p2, a.*);
        try simplify(p3, a.*);
        p1 = p3;
    }
    return magnitude(p1);
}
