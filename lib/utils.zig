const std = @import("std");
const os = std.os;
const isDigit = std.ascii.isDigit;
const print = std.debug.print;

fn solutionType(comptime T: type) type {
    return fn (c: []const u8, a: *std.mem.Allocator) ?T;
}

fn OptionPrinter(comptime T: type) type {
    return struct {
        pub fn print(comptime format: []const u8, val: T) void {
            if (val) |p| {
                std.debug.print(format, .{p});
            }
        }
    };
}

fn ErrorUnionPrinter(comptime T: type) type {
    return struct {
        pub fn print(comptime format: []const u8, val: T) void {
            if (val) |p| {
                std.debug.print(format, .{p});
            } else |err| {
                std.debug.print("Error: {e}\n", .{err});
            }
        }
    };
}

fn ResultProcessor(comptime resultType: type) type {
    return switch (@typeInfo(resultType)) {
        .Optional => {
            return OptionPrinter(resultType);
        },
        .ErrorUnion => {
            return ErrorUnionPrinter(resultType);
        },
        else => {
            @compileError("Unable to print type '" ++ @typeName(resultType) ++ "'");
        },
    };
}

pub fn Runner(comptime part1: anytype, comptime part2: anytype) type {
    const resultType1 = @typeInfo(@TypeOf(part1)).Fn.return_type.?;
    const ResultProcessorType1 = ResultProcessor(resultType1);

    const resultType2 = @typeInfo(@TypeOf(part2)).Fn.return_type.?;
    const ResultProcessorType2 = ResultProcessor(resultType2);

    return struct {
        pub fn run() !void {
            var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
            defer arena.deinit();

            var allocator = arena.allocator();

            const args = try std.process.argsAlloc(allocator);
            defer std.process.argsFree(allocator, args);

            for (args[1..args.len]) |c| {
                print("Input file: {s}\n", .{c});
                const content = try readFile(&allocator, c);

                ResultProcessorType1.print("Part 1: {d}\n", part1(content, &allocator));

                ResultProcessorType2.print("Part 2: {d}\n", part2(content, &allocator));
            }
        }
    };
}

pub fn readFile(allocator: *std.mem.Allocator, path: []const u8) ![]u8 {
    var file = try os.open(path, 0, 0);
    defer os.close(file);

    var stat = try os.fstat(file);

    var total_read: u64 = 0;
    var result = try allocator.alloc(u8, @intCast(u64, stat.size));
    var buffer: [1024 * 4]u8 = undefined;

    var bytes_read = try os.read(file, buffer[0..buffer.len]);
    while (bytes_read > 0) {
        std.mem.copy(u8, result[total_read..], buffer[0..bytes_read]);
        total_read += bytes_read;

        bytes_read = try os.read(file, buffer[0..buffer.len]);
    }

    return result;
}

pub fn parseNum(content: []const u8, s: u64, x: *i32) u64 {
    var i = s;
    x.* = 0;
    while (i < content.len and isDigit(content[i])) {
        x.* = x.* * 10 + (content[i] - '0');
        i += 1;
    }
    return i;
}

pub fn BinaryHeap(comptime T: type, comptime maxSize: usize, comptime cmp: fn (void, T, T) bool) type {
    return struct {
        const Self = @This();

        data: [maxSize]T,
        size: usize = 0,

        pub fn push(self: *Self, val: T) void {
            if (self.size == self.data.len) {
                return;
            }
            self.siftUp(self.size, val);
            self.size += 1;
        }

        fn siftUp(self: *Self, i: u64, x: T) void {
            var k = i;
            while (true) {
                if (k > 0) {
                    var parent = (k - 1) >> 1;
                    var e: T = self.data[parent];
                    if (cmp({}, x, e)) {
                        self.data[k] = e;
                        k = parent;
                        continue;
                    }
                }

                self.data[k] = x;
                return;
            }
        }

        pub fn poll(self: *Self) ?T {
            if (self.size == 0) {
                return null;
            }

            var result = self.data[0];
            self.size -= 1;

            var el = self.data[self.size];
            self.siftDown(0, el);

            return result;
        }

        fn siftDown(self: *Self, i: u64, x: T) void {
            var half = self.size >> 1;
            var k = i;

            while (k < half) {
                var child = (k << 1) + 1;
                var c = self.data[child];
                var right = child + 1;

                if (right < self.size and cmp({}, c, self.data[right])) {
                    child = right;
                    c = self.data[right];
                }

                if (cmp({}, x, c)) {
                    break;
                }

                self.data[k] = c;
                k = child;
            }

            self.data[k] = x;
        }

        pub fn peek(self: *Self) ?T {
            if (self.size == 0) {
                return null;
            }

            return self.data[0];
        }
    };
}

pub fn RingStack(comptime T: type, comptime size: u64) type {
    return struct {
        queue: [size]T,
        writeIdx: u64,
        readIdx: u64,

        const Self = @This();

        pub fn push(self: *Self, i: T) void {
            self.queue[self.writeIdx] = i;
            self.writeIdx = (self.writeIdx + 1) % size;
        }

        pub fn pop(self: *Self) T {
            var pair = self.queue[self.readIdx];
            self.readIdx = (self.readIdx + 1) % size;
            return pair;
        }

        pub fn isEmpty(self: *Self) bool {
            return self.readIdx == self.writeIdx;
        }

        pub fn reset(self: *Self) void {
            self.readIdx = self.writeIdx;
        }
    };
}

pub fn List(comptime T: type, comptime maxSize: usize) type {
    return struct {
        data: [maxSize]T,
        size: usize,

        const Self = @This();

        pub fn create(data: [maxSize]T) Self {
            return Self{
                .data = data,
                .size = 0,
            };
        }

        pub fn add(self: *Self, item: T) void {
            if (self.size < maxSize) {
                self.data[self.size] = item;
                self.size += 1;
            }
        }

        pub fn reset(self: *Self) void {
            self.size = 0;
        }

        pub fn forEach(self: Self, comptime action: fn (T) void) void {
            for (self.data[0..self.size]) |item| {
                action(item);
            }
        }
    };
}
