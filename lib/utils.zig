const std = @import("std");
const os = std.os;
const isDigit = std.ascii.isDigit;

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
    while (i < content.len and isDigit(content[i])) {
        x.* = x.* * 10 + (content[i] - '0');
        i += 1;
    }
    return i;
}
