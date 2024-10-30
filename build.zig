const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const reco = b.addModule("reco", .{
        .root_source_file = b.path("src/reco.zig"),
        .target = target,
        .optimize = optimize,
    });

    // ------------------------------------------------------------
    const EXAMPLES = [_][]const u8{
        "simple",
    };
    inline for (EXAMPLES) |example| {
        const exe = b.addExecutable(.{
            .name = example,
            .root_source_file = b.path("src/bin/" ++ example ++ ".zig"),
            .target = target,
            .optimize = optimize,
        });
        exe.root_module.addImport("reco", reco);

        const run_cmd = b.addRunArtifact(exe);
        run_cmd.step.dependOn(b.getInstallStep());
        if (b.args) |args| run_cmd.addArgs(args);
        const run_step = b.step("example-" ++ example, "Run the " ++ example ++ " example");
        run_step.dependOn(&run_cmd.step);
    }
}
