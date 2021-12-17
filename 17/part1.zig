const std = @import("std");
const u = @import("utils");
const print = std.debug.print;
const Reader = u.Reader;

pub const Point2D = [2]i32;

pub const Area = struct {
    x: Point2D,
    y: Point2D,
};

pub fn parse(content: []const u8) !Area {
    var reader = Reader.init(content);

    try reader.skipChars("target area: x=");
    var x = Point2D{ 0, 0 };
    var y = Point2D{ 0, 0 };

    x[0] = reader.readInt(i32);
    try reader.skipChars("..");
    x[1] = reader.readInt(i32);

    try reader.skipChars(", y=");

    y[0] = reader.readInt(i32);
    try reader.skipChars("..");
    y[1] = reader.readInt(i32);

    return Area{
        .x = x,
        .y = y,
    };
}

pub fn solve(content: []const u8, _: *std.mem.Allocator) !i32 {
    const area = try parse(content);
    const maxDy = -area.y[0];
    return @divExact((maxDy * (maxDy - 1)), 2);
}
