const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "podcast",
        .root_module = b.createModule(.{
            .root_source_file = b.path("podcast" ++ ".zig"),
            .target = target,
            .optimize = optimize,
        }),
        .use_llvm = true,
    });

    const dvui_dep = b.dependency("dvui", .{ .target = target, .optimize = optimize, .backend = .sdl3 });
    exe.root_module.addImport("dvui", dvui_dep.module("dvui_sdl3"));

    const sqlite = b.dependency("sqlite", .{
        .target = target,
        .optimize = .ReleaseFast,
    });

    exe.root_module.addImport("sqlite", sqlite.module("sqlite"));

    // links the bundled sqlite3, so leave this out if you link the system one
    exe.linkLibrary(sqlite.artifact("sqlite"));

    const curl_dep = b.dependency("libcurl", .{ .target = target, .optimize = .ReleaseFast });
    exe.linkLibrary(curl_dep.artifact("curl"));

    const ffmpeg_dep = b.dependency("ffmpeg", .{ .target = target, .optimize = .ReleaseFast });
    exe.linkLibrary(ffmpeg_dep.artifact("ffmpeg"));

    const libxml2_dep = b.dependency("libxml2", .{ .target = target, .optimize = .ReleaseFast });
    exe.linkLibrary(libxml2_dep.artifact("xml2"));

    const compile_step = b.step("compile-" ++ "podcast", "Compile " ++ "podcast");
    compile_step.dependOn(&b.addInstallArtifact(exe, .{}).step);
    b.getInstallStep().dependOn(compile_step);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(compile_step);

    const run_step = b.step("podcast", "Run " ++ "podcast");
    run_step.dependOn(&run_cmd.step);
}
