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
    a1: *Argument,
    a2: *Argument,
};
const Argument = union(enum) {
    value: i64,
    formula: Formula,
    input: usize,

    pub fn debug(self: Argument) void {
        switch (self) {
            .value => |v| print("{d}", .{v}),
            .input => |i| print("I{d}", .{i}),
            .formula => |f| {
                print("={d}(", .{f.op});
                f.a1.debug();
                print(",", .{});
                f.a2.debug();
                print(")", .{});
            },
        }
    }

    pub fn apply(self: *Argument, ins: Instruction, param: *Argument) Argument {
        switch (self.*) {
            .value => |v| {
                switch (param.*) {
                    .value => |v2| {
                        return switch (ins) {
                            Instruction.add => Argument{ .value = v + v2 },
                            Instruction.mul => Argument{ .value = v * v2 },
                            Instruction.div => Argument{ .value = @divFloor(v, v2) },
                            Instruction.mod => Argument{ .value = @mod(v, v2) },
                            Instruction.eql => Argument{ .value = if (v == v2) 1 else 0 },
                            else => unreachable,
                        };
                    },
                    else => {},
                }
            },
            else => {},
        }

        return Argument{
            .formula = Formula{
                .op = ins,
                .a1 = self,
                .a2 = param,
            },
        };
    }
};

const State = struct {
    vars: [4]Argument,
    inputCounter: u64,

    pub fn init() State {
        return .{
            .vars = [_]Argument{Argument{ .value = 0 }} ** 4,
            .inputCounter = 0,
        };
    }

    pub fn get(self: State, v: Variable) Argument {
        return self.vars[@enumToInt(v)];
    }

    pub fn set(self: *State, v: Variable, val: Argument) void {
        self.vars[@enumToInt(v)] = val;
    }

    pub fn apply(self: *State, cmd: Cmd) void {
        switch (cmd.ins) {
            .inp => {
                self.set(cmd.label, Argument{ .input = self.inputCounter });
                self.inputCounter += 1;
            },
            else => {
                var p = switch (cmd.param.?) {
                    .label => |l| self.get(l),
                    .value => |v| Argument{ .value = v },
                };
                self.set(cmd.label, self.get(cmd.label).apply(cmd.ins, &p));
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
    state.debug();
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

        state.apply(cmd);
        state.debug();

        try res.append(cmd);
    }
    return res;
}

pub fn solve(content: []const u8, a: *std.mem.Allocator) !i32 {
    var cmds = try parse(content, a.*);
    _ = cmds;
    return -1;
}
