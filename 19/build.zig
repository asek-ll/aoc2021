const std = @import("std");
const Builder = std.build.Builder;

pub fn build(b: *Builder) void {
    const exe = b.addExecutable("main_zig", "main.zig");
    exe.addPackagePath("utils", "../lib/utils.zig");
    b.installArtifact(exe);

    const run_cmd = exe.run();
    run_cmd.addArg("sample.txt");
    // run_cmd.addArg("input.txt");

    b.default_step.dependOn(&run_cmd.step);
}
