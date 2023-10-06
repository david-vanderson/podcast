const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "podcast",
        .root_source_file = .{ .path = "podcast" ++ ".zig" },
        .target = target,
        .optimize = optimize,
    });

    const local_dev = true;
    if (local_dev) {
        const dvui_mod = b.createModule(.{ .source_file = .{ .path = "../dvui/src/dvui.zig" } });
        exe.addModule("dvui", dvui_mod);
        const sdlbackend_mod = b.createModule(.{ .source_file = .{ .path = "../dvui/src/backends/SDLBackend.zig" }, .dependencies = &.{.{ .name = "dvui", .module = dvui_mod }} });
        exe.addModule("SDLBackend", sdlbackend_mod);

        const freetype_dep = b.dependency("freetype", .{
            .target = exe.target,
            .optimize = exe.optimize,
        });
        exe.linkLibrary(freetype_dep.artifact("freetype"));

        exe.addIncludePath(.{ .path = "/home/purism/SDL2-2.28.1/include" });
        exe.addObjectFile(.{ .path = "/home/purism/SDL2-2.28.1/build/.libs/libSDL2.a" });
    } else {
        const dvui_dep = b.dependency("dvui", .{ .target = target, .optimize = optimize });
        exe.addModule("dvui", dvui_dep.module("dvui"));
        exe.addModule("SDLBackend", dvui_dep.module("SDLBackend"));

        const freetype_dep = dvui_dep.builder.dependency("freetype", .{
            .target = target,
            .optimize = .ReleaseFast,
        });
        exe.linkLibrary(freetype_dep.artifact("freetype"));

        exe.linkSystemLibrary("SDL2");
    }

    exe.linkLibC();

    const sqlite = b.addStaticLibrary(.{ .name = "sqlite", .target = target, .optimize = .ReleaseFast });
    sqlite.addCSourceFile(.{ .file = .{ .path = "libs/zig-sqlite/c/sqlite3.c" }, .flags = &[_][]const u8{"-std=c99"} });
    sqlite.linkLibC();

    exe.linkLibrary(sqlite);
    exe.addAnonymousModule("sqlite", .{ .source_file = .{ .path = "libs/zig-sqlite/sqlite.zig" } });
    exe.addIncludePath(.{ .path = "libs/zig-sqlite/c" });

    const curl_dep = b.dependency("curl", .{ .target = target, .optimize = .ReleaseFast });
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
