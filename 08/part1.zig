const std = @import("std");
const u = @import("utils");
const print = std.debug.print;

pub fn solve(content: []const u8, _: *std.mem.Allocator) !u64 {
    var i: u64 = 0;
    var j: u64 = 0;
    var result: u64 = 0;

    while (i < content.len) {
        while (i < content.len and content[i] != '|') {
            i += 1;
        }
        i += 1;
        j = i;
        while (i < content.len) {
            if (content[i] == ' ' or content[i] == '\n') {
                var len = i - j;

                if (len == 2 or len == 3 or len == 4 or len == 7) {
                    result += 1;
                }

                j = i + 1;
            }

            if (content[i] == '\n') {
                break;
            }
            i += 1;
        }
    }

    return result;
}
