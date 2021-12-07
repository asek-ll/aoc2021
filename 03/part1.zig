const std = @import("std");
const u = @import("utils");
const print = std.debug.print;

pub fn solve(content: []const u8, allocator: *std.mem.Allocator) !i32 {
    var i: u64 = 0;
    var j: u64 = 0;
    var buf = [_]i16{0} ** 16;
    var len: u64 = 0;

    while (i < content.len) {
        while (i < content.len and (content[i] == '0' or content[i] == '1')) {
            if (content[i] == '0') {
                buf[j] -= 1;
            } else {
                buf[j] += 1;
            }
            i += 1;
            j += 1;
            if (len < j) {
                len = j;
            }
        }
        i += 1;
        j = 0;
    }

    i = 0;
    var gr: i32 = 0;
    var er: i32 = 0;

    while (i < len) {
        gr *= 2;
        er *= 2;
        if (buf[i] > 0) {
            gr += 1;
        } else if (buf[i] < 0) {
            er += 1;
        }

        i += 1;
    }

    return gr * er;
}
