const std = @import("std");
const u = @import("utils");
const print = std.debug.print;
const Allocator = std.mem.Allocator;

const Instruction = enum {
    inp,
    mul,
    add,
    div,
    mod,
    eql,
};

fn applyInstruction(ins: Instruction, a: i64, b: i64) i64 {
    return switch (ins) {
        .mul => a * b,
        .add => a + b,
        .div => @divFloor(a, b),
        .mod => a % b,
        .eql => if (a == b) 1 else 0,
        else => unreachable,
    };
}

const Variable = enum {
    x,
    y,
    z,
    w,
};

const Param = union(enum) {
    label: Variable,
    value: i64,
};

const Cmd = struct {
    ins: Instruction,
    label: Variable,
    param: ?Param,
};

const CmdList = std.ArrayList(Cmd);

const Formula = struct {
    op: Instruction,
    a1: *const Argument,
    a2: *const Argument,
};

const ArgData = union(enum) {
    value: i64,
    formula: Formula,
    input: usize,
};
const SetCtx = struct {
    pub fn hash(_: SetCtx, v: i64) u64 {
        return @bitCast(u64, v);
    }
    pub fn eql(_: SetCtx, a: i64, b: i64) bool {
        return a == b;
    }
};
const Set = std.HashMap(i64, bool, SetCtx, 80);

const Range = struct {
    vals: Set,

    pub fn init(a: Allocator) !Range {
        return Range{ .vals = Set.init(a) };
    }

    pub fn initInput(a: Allocator) !Range {
        var r = Range.init(a);

        var i: i64 = 1;
        while (i <= 9) : (i += 1) {
            r.vals.put(i, true);
        }
        return r;
    }

    pub fn apply(self: Range, ins: Instruction, other: Range, a: Allocator) Range {
        var r = Range.init(a);

        for (self.vals.keys) |v1| {
            for (other.vals.keys) |v2| {
                r.vals.put(applyInstruction(ins, v1, v2), true);
            }
        }
        return r;
    }
};

const Argument = struct {
    data: ArgData,
    nums: []const i64,

    pub fn value(val: i64) Argument {
        return .{
            .data = ArgData{ .value = val },
            .nums = &[_]i64{val},
        };
    }

    pub fn input(i: usize) Argument {
        return .{
            .data = ArgData{ .input = i },
            .nums = &[_]i64{ 1, 2, 3, 4, 5, 6, 7, 8, 9 },
        };
    }

    pub fn formula(f: Formula) Argument {
        return .{
            .data = ArgData{ .formula = f },
            .nums = &[_]i64{},
        };
    }

    pub fn debug(self: Argument) void {
        switch (self.data) {
            .value => |v| print("{d}", .{v}),
            .input => |i| print("I{d}", .{i}),
            .formula => |f| {
                print("(", .{});
                f.a1.debug();
                var sym: u8 = switch (f.op) {
                    .add => '+',
                    .mul => '*',
                    .div => '/',
                    .mod => '%',
                    .eql => '=',
                    else => unreachable,
                };
                print(" {c} ", .{sym});
                f.a2.debug();
                print("),r = ", .{});
                for (self.nums) |n| {
                    print("{d} ", .{n});
                }
            },
        }
    }

    pub fn apply(self: *const Argument, ins: Instruction, param: *const Argument, a: Allocator) !*const Argument {

        // switch(ins) {
        //     .mul =>

        // }

        switch (self.data) {
            .value => |v| {
                switch (param.data) {
                    .value => |v2| {
                        return try own(a, switch (ins) {
                            Instruction.add => Argument.value(v + v2),
                            Instruction.mul => Argument.value(v * v2),
                            Instruction.div => Argument.value(@divFloor(v, v2)),
                            Instruction.mod => Argument.value(@mod(v, v2)),
                            Instruction.eql => Argument.value(if (v == v2) 1 else 0),
                            else => unreachable,
                        });
                    },
                    else => {
                        if (v == 0 and ins == .add) {
                            return param;
                        }
                        if (v == 0 and (ins == .mul or ins == .div or ins == .mod)) {
                            return &ZERO;
                        }
                        if (v == 1 and ins == .mul) {
                            return param;
                        }
                    },
                }
            },
            else => {
                switch (param.data) {
                    .value => |v2| {
                        if (v2 == 0 and ins == .add) {
                            return self;
                        }
                        if (v2 == 0 and ins == .mul) {
                            return &ZERO;
                        }
                        if (v2 == 1 and (ins == .mul or ins == .div)) {
                            return self;
                        }
                        if (v2 == 1 and ins == .mod) {
                            return &ZERO;
                        }
                    },
                    else => {},
                }
            },
        }

        return try own(a, Argument.formula(Formula{
            .op = ins,
            .a1 = self,
            .a2 = param,
        }));
    }
};

const ZERO = Argument.value(0);

const State = struct {
    vars: [4]*const Argument,
    inputCounter: u64,

    pub fn init() State {
        return .{
            .vars = [_]*const Argument{&ZERO} ** 4,
            .inputCounter = 0,
        };
    }

    pub fn get(self: State, v: Variable) *const Argument {
        return self.vars[@enumToInt(v)];
    }

    pub fn set(self: *State, v: Variable, val: *const Argument) void {
        self.vars[@enumToInt(v)] = val;
    }

    pub fn apply(self: *State, cmd: Cmd, a: Allocator) !void {
        switch (cmd.ins) {
            .inp => {
                self.set(cmd.label, try own(a, Argument.input(self.inputCounter)));
                self.inputCounter += 1;
            },
            else => {
                var p = switch (cmd.param.?) {
                    .label => |l| self.get(l),
                    .value => |v| try own(a, Argument.value(v)),
                };
                self.set(cmd.label, try self.get(cmd.label).apply(cmd.ins, p, a));
            },
        }
    }

    pub fn debug(self: State) void {
        for (self.vars) |v, i| {
            var label = @intToEnum(Variable, i);
            print("{d}=", .{label});
            v.debug();
            print("\n", .{});
        }
    }
};

fn own(a: Allocator, arg: Argument) !*Argument {
    return &(try a.dupe(Argument, &[_]Argument{arg}))[0];
}

fn min(a: i64, b: i64) i64 {
    return if (a < b) a else b;
}

fn divCeil(a: i64, b: i64) i64 {
    if (b == 0) {
        return 0;
    }
    return @floatToInt(i64, @ceil(@intToFloat(f64, a) / @intToFloat(f64, b)));
}

fn parseInstruction(str: []const u8) Instruction {
    return switch (str[0]) {
        'a' => .add,
        'i' => .inp,
        'e' => .eql,
        'd' => .div,
        else => switch (str[1]) {
            'u' => Instruction.mul,
            else => Instruction.mod,
        },
    };
}

fn parseLabel(label: u8) Variable {
    return switch (label) {
        'x' => .x,
        'y' => .y,
        'z' => .z,
        'w' => .w,
        else => unreachable,
    };
}

pub fn parse(content: []const u8, a: Allocator) !CmdList {
    var res = CmdList.init(a);
    var i: u64 = 0;
    var x: i32 = 0;
    var state = State.init();
    while (i < content.len) : (i += 1) {
        const ins = parseInstruction(content[i..(i + 3)]);
        i += 4;
        var v = parseLabel(content[i]);
        i += 1;
        var p: ?Param = null;
        if (ins != .inp) {
            i += 1;
            var ni = u.parseNum(content, i, &x);
            if (i == ni) {
                p = Param{ .label = parseLabel(content[i]) };
                i += 1;
            } else {
                p = Param{ .value = x };
                i = ni;
            }
        }

        var cmd = Cmd{
            .ins = ins,
            .label = v,
            .param = p,
        };

        try state.apply(cmd, a);
        print("{d} {d}", .{ ins, v });
        if (p) |pv| {
            switch (pv) {
                .label => |l| print(" {d}", .{l}),
                .value => |val| print(" {d}", .{val}),
            }
        }
        print("\n", .{});
        state.debug();

        try res.append(cmd);
    }
    return res;
}

pub fn solve(content: []const u8, a: *std.mem.Allocator) !i32 {
    var cmds = (try parse(content, a.*)).items;
    var i: u64 = cmds.len;
    while (i > 0) : (i -= 1) {
        var cmd = cmds[i - 1];
        print("{d}\n", .{cmd.ins});
    }
    return -1;
}
