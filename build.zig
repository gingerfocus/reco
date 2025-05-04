const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const reco = b.addModule("reco", .{
        .root_source_file = b.path("src/reco.zig"),
        .target = target,
        .optimize = optimize,
    });
    //     const fixed = b.addStaticLibrary(.{
    //         .name = "fixedme",
    //         .root_source_file = b.path("src/fixed.zig"),
    //         .target = target,
    //         .optimize = optimize,
    //     });

    // ------------------------------------------------------------
    const EXAMPLES = [_][]const u8{
        "simple",
        // "fixed",
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

//     const lib_unit_tests = b.addTest(.{
//         .root_source_file = b.path("src/test.zig"),
//         .target = target,
//         .optimize = optimize,
//     });
//     const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);
//     const test_step = b.step("test", "Run unit tests");
