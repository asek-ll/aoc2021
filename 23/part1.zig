const std = @import("std");
const Allocator = std.mem.Allocator;
const u = @import("utils");
const print = std.debug.print;

const StateMapCtx = struct {
    pub fn hash(_: StateMapCtx, a: u64) u64 {
        return a;
    }
    pub fn eql(_: StateMapCtx, a: u64, b: u64) bool {
        return a == b;
    }
};

const StateMap = std.HashMap(u64, u64, StateMapCtx, 80);

const RoomTarget = [_]u8{ 'A', 'B', 'C', 'D' };
const UnitScore = [_]u64{ 1, 10, 100, 1000 };

const U8List = std.ArrayList(u8);
const LimitedStack = struct {
    ls: U8List,
    limit: usize,

    const Self = @This();

    pub fn init(a: Allocator, limit: usize) !Self {
        return LimitedStack{
            .ls = try U8List.initCapacity(a, limit),
            .limit = limit,
        };
    }

    pub fn canAccept(self: Self) bool {
        return self.ls.items.len < self.limit;
    }

    pub fn push(self: *Self, e: u8) !void {
        try self.ls.append(e);
    }

    pub fn pop(self: *Self) u8 {
        return self.ls.pop();
    }

    pub fn top(self: *Self) ?u8 {
        if (self.ls.items.len > 0) {
            return self.ls.items[self.ls.items.len - 1];
        }
        return null;
    }

    pub fn getOrEmpty(self: Self, idx: usize) u8 {
        if (idx < self.ls.items.len) {
            return self.ls.items[idx];
        }
        return '.';
    }

    pub fn code(self: Self) u11 {
        var base: u10 = 0;
        for (self.ls.items) |i| {
            base *= 5;
            base += (i - 'A' + 1);
        }
        return base;
    }
};

const State = struct {
    left: LimitedStack,
    right: LimitedStack,
    rooms: [4]LimitedStack,
    walls: [3]LimitedStack,

    const Self = @This();
    pub fn debug(self: Self) void {
        print("#############\n", .{});
        print("#{c}{c}.{c}.{c}.{c}.{c}{c}#\n", .{
            self.left.getOrEmpty(0),
            self.left.getOrEmpty(1),
            self.walls[0].getOrEmpty(0),
            self.walls[1].getOrEmpty(0),
            self.walls[2].getOrEmpty(0),
            self.right.getOrEmpty(1),
            self.right.getOrEmpty(0),
        });
        print("###{c}#{c}#{c}#{c}###\n", .{
            self.rooms[0].getOrEmpty(3),
            self.rooms[1].getOrEmpty(3),
            self.rooms[2].getOrEmpty(3),
            self.rooms[3].getOrEmpty(3),
        });
        print("  #{c}#{c}#{c}#{c}#\n", .{
            self.rooms[0].getOrEmpty(2),
            self.rooms[1].getOrEmpty(2),
            self.rooms[2].getOrEmpty(2),
            self.rooms[3].getOrEmpty(2),
        });
        print("  #{c}#{c}#{c}#{c}#\n", .{
            self.rooms[0].getOrEmpty(1),
            self.rooms[1].getOrEmpty(1),
            self.rooms[2].getOrEmpty(1),
            self.rooms[3].getOrEmpty(1),
        });
        print("  #{c}#{c}#{c}#{c}#\n", .{
            self.rooms[0].getOrEmpty(0),
            self.rooms[1].getOrEmpty(0),
            self.rooms[2].getOrEmpty(0),
            self.rooms[3].getOrEmpty(0),
        });
        print("  #########\n", .{});
    }

    pub fn isWallClear(self: Self, from: usize, to: usize) bool {
        var min = if (from < to) from else to;
        var max = if (from > to) from else to;
        while (min < max) : (min += 1) {
            if (self.walls[min].ls.items.len > 0) {
                return false;
            }
        }
        return true;
    }

    pub fn isRoomOk(self: Self, ri: usize) bool {
        var t = RoomTarget[ri];
        for (self.rooms[ri].ls.items) |i| {
            if (i != t) {
                return false;
            }
        }

        return true;
    }

    pub fn canMoveFromRoomToRoom(self: Self, a: u8, from: usize, to: usize) bool {
        if (!self.rooms[to].canAccept()) {
            return false;
        }

        if (!self.isWallClear(from, to)) {
            return false;
        }

        var t = RoomTarget[to];
        if (t != a) {
            return false;
        }
        for (self.rooms[to].ls.items) |i| {
            if (i != t) {
                return false;
            }
        }

        return true;
    }

    pub fn code(self: Self) u64 {
        var base: u64 = 0;
        for (self.rooms) |r| {
            base = base << 10;
            base = base | r.code();
        }

        base <<= 5;
        base |= @intCast(u6, self.left.code());
        base <<= 5;
        base |= @intCast(u6, self.right.code());

        base <<= 3;
        base |= @intCast(u3, self.walls[0].code());
        base <<= 3;
        base |= @intCast(u3, self.walls[1].code());
        base <<= 3;
        base |= @intCast(u3, self.walls[2].code());

        return base;
    }
};

fn parse(content: []const u8, a: Allocator) !State {
    var i: u64 = 28;
    var roomA = try LimitedStack.init(a, 4);
    var roomB = try LimitedStack.init(a, 4);
    var roomC = try LimitedStack.init(a, 4);
    var roomD = try LimitedStack.init(a, 4);
    var rooms = [_]LimitedStack{ roomA, roomB, roomC, roomD };

    var cnt: u64 = 0;
    while (i < content.len) : (i += 1) {
        const c = content[i];
        if (c == 'A' or c == 'B' or c == 'C' or c == 'D') {
            try rooms[cnt].ls.insert(0, c);
            cnt += 1;
            cnt = cnt % 4;
        }
    }

    return State{
        .left = try LimitedStack.init(a, 2),
        .right = try LimitedStack.init(a, 2),
        .rooms = rooms,
        .walls = [_]LimitedStack{
            try LimitedStack.init(a, 1),
            try LimitedStack.init(a, 1),
            try LimitedStack.init(a, 1),
        },
    };
}

pub fn find(s: *State, sm: *StateMap, score: u64) anyerror!void {
    const cd = s.code();
    if (sm.get(cd)) |bestScore| {
        if (score >= bestScore) {
            return;
        }
    }
    try sm.put(cd, score);
    if (s.left.top()) |a| {
        for (s.rooms) |*r, i| {
            if (s.canMoveFromRoomToRoom(a, 0, i)) {
                var currentScore = (2 - s.left.ls.items.len) + 1 + (2 * i) + (4 - r.ls.items.len);
                currentScore *= UnitScore[a - 'A'];
                try r.push(s.left.pop());
                try find(s, sm, currentScore + score);
                try s.left.push(r.pop());
            }
        }
    }

    if (s.right.top()) |a| {
        for (s.rooms) |*r, i| {
            if (s.canMoveFromRoomToRoom(a, 3, i)) {
                var currentScore = (2 - s.right.ls.items.len) + 1 + (2 * (3 - i)) + (4 - r.ls.items.len);
                currentScore *= UnitScore[a - 'A'];
                try r.push(s.right.pop());
                try find(s, sm, currentScore + score);
                try s.right.push(r.pop());
            }
        }
    }

    for (s.walls) |*w, wi| {
        if (w.top()) |a| {
            for (s.rooms) |*r, i| {
                const ti = if (wi < i) wi + 1 else wi;
                var currentScore = (if (wi < i) i - wi - 1 else wi - i) * 2 + 1 + (4 - r.ls.items.len);
                currentScore *= UnitScore[a - 'A'];
                if (s.canMoveFromRoomToRoom(a, ti, i)) {
                    try r.push(w.pop());
                    try find(s, sm, currentScore + score);
                    try w.push(r.pop());
                }
            }
        }
    }

    for (s.rooms) |*r, ri| {
        if (!s.isRoomOk(ri)) {
            const a = r.top().?;
            for (s.rooms) |*r2, ri2| {
                if (ri != ri2 and s.canMoveFromRoomToRoom(a, ri, ri2)) {
                    var currentScore = (if (ri < ri2) ri2 - ri else ri - ri2) * 2 + (5 - r.ls.items.len) + (4 - r2.ls.items.len);
                    currentScore *= UnitScore[a - 'A'];
                    try r2.push(r.pop());
                    try find(s, sm, currentScore + score);
                    try r.push(r2.pop());
                }
            }

            if (s.left.canAccept() and s.isWallClear(0, ri)) {
                var currentScore = ri * 2 + (2 - s.left.ls.items.len) + (5 - r.ls.items.len);
                currentScore *= UnitScore[a - 'A'];
                try s.left.push(r.pop());
                try find(s, sm, currentScore + score);
                try r.push(s.left.pop());
            }
            if (s.right.canAccept() and s.isWallClear(ri, 3)) {
                var currentScore = (3 - ri) * 2 + (2 - s.right.ls.items.len) + (5 - r.ls.items.len);
                currentScore *= UnitScore[a - 'A'];
                try s.right.push(r.pop());
                try find(s, sm, currentScore + score);
                try r.push(s.right.pop());
            }
            for (s.walls) |*w, wi| {
                if (w.canAccept() and s.isWallClear(wi, ri)) {
                    var currentScore = (if (wi < ri) ri - wi - 1 else wi - ri) * 2 + 1 + (5 - r.ls.items.len);
                    currentScore *= UnitScore[a - 'A'];
                    try w.push(r.pop());
                    try find(s, sm, currentScore + score);
                    try r.push(w.pop());
                }
            }
        }
    }
}

pub fn solve(content: []const u8, a: *Allocator) !u64 {
    var s = try parse(content, a.*);
    var sm = StateMap.init(a.*);
    try find(&s, &sm, 0);
    return sm.get(87991968130400256).?;
}
