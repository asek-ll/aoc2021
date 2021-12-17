const std = @import("std");
const u = @import("utils");
const print = std.debug.print;
const p1 = @import("part1.zig");

pub fn solve(content: []const u8, _: *std.mem.Allocator) !u64 {
    const area = try p1.parse(content);
    var dyByStepCount = [_][50]i32{[_]i32{0} ** 50} ** 300;
    var dyByStepCounter = [_]u64{0} ** 300;
    var v = [_][300]bool{[_]bool{false} ** 300} ** 300;
    var i: i32 = 1;
    i = area.y[0];
    while (i < -area.y[0]) : (i += 1) {
        var speed = i;
        var yPos: i32 = 0;
        var stepCount: u64 = 0;
        while (yPos >= area.y[0]) {
            if (yPos <= area.y[1]) {
                dyByStepCount[stepCount][dyByStepCounter[stepCount]] = i;
                dyByStepCounter[stepCount] += 1;
            }

            yPos += speed;
            speed -= 1;
            stepCount += 1;
        }
    }

    i = 0;
    var result: u64 = 0;
    while (i <= area.x[1]) : (i += 1) {
        const initSpeed = i;
        const maxRange = @divExact((initSpeed * (initSpeed + 1)), 2);
        if (maxRange >= area.x[0]) {
            var range: i32 = 0;
            var step: i32 = initSpeed;
            var stepCount: u32 = 0;

            while (range <= area.x[1] and step > 0) {
                if (range >= area.x[0]) {
                    for (dyByStepCount[stepCount][0..(dyByStepCounter[stepCount])]) |dy| {
                        v[@intCast(u64, i)][@intCast(u64, dy + 150)] = true;
                    }
                }
                range += step;
                step -= 1;
                stepCount += 1;
            }
            if (step == 0 and range <= area.x[1]) {
                while (stepCount < 300) : (stepCount += 1) {
                    for (dyByStepCount[stepCount][0..(dyByStepCounter[stepCount])]) |dy| {
                        v[@intCast(u64, i)][@intCast(u64, dy + 150)] = true;
                    }
                }
            }
        }
    }

    for (v) |r| {
        for (r) |b| {
            if (b) {
                result += 1;
            }
        }
    }
    return result;
}
