const std = @import("std");

//const mbedtls = @import("libs/zig-mbedtls/mbedtls.zig");
//const libssh2 = @import("libs/zig-libssh2/libssh2.zig");
//const libcurl = @import("libs/zig-libcurl/libcurl.zig");
//const libzlib = @import("libs/zig-zlib/zlib.zig");
//const libxml2 = @import("libs/zig-libxml2/libxml2.zig");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "podcast",
        .root_source_file = .{ .path = "podcast" ++ ".zig" },
        .target = target,
        .optimize = optimize,
    });

    const dvui_dep = b.dependency("dvui", .{ .target = target, .optimize = optimize });
    exe.addModule("dvui", dvui_dep.module("dvui"));
    exe.addModule("SDLBackend", dvui_dep.module("SDLBackend"));

    const freetype_dep = dvui_dep.builder.dependency("freetype", .{
        .target = target,
        .optimize = optimize,
    });
    exe.linkLibrary(freetype_dep.artifact("freetype"));

    exe.linkSystemLibrary("SDL2");
    exe.linkLibC();

    const sqlite = b.addStaticLibrary(.{ .name = "sqlite", .target = target, .optimize = optimize });
    sqlite.addCSourceFile(.{ .file = .{ .path = "libs/zig-sqlite/c/sqlite3.c" }, .flags = &[_][]const u8{"-std=c99"} });
    sqlite.linkLibC();

    exe.linkLibrary(sqlite);
    exe.addAnonymousModule("sqlite", .{ .source_file = .{ .path = "libs/zig-sqlite/sqlite.zig" } });
    exe.addIncludePath(.{ .path = "libs/zig-sqlite/c" });

    const curl_dep = b.dependency("curl", .{ .target = target, .optimize = optimize });
    exe.linkLibrary(curl_dep.artifact("curl"));

    //const tls = mbedtls.create(b, target, optimize);
    //tls.link(exe);

    //const ssh2 = libssh2.create(b, target, optimize);
    //tls.link(ssh2.step);
    //ssh2.link(exe);

    //const zlib = libzlib.create(b, target, optimize);
    //zlib.link(exe, .{});

    //const curl = try libcurl.create(b, target, optimize);
    //tls.link(curl.step);
    //ssh2.link(curl.step);
    //curl.link(exe, .{ .import_name = "curl" });

    //const libxml = try libxml2.create(b, target, optimize, .{
    //    .iconv = false,
    //    .lzma = false,
    //    .zlib = true,
    //});

    //libxml.link(exe);

    const ffmpeg_dep = b.dependency("ffmpeg", .{ .target = target, .optimize = optimize });
    exe.linkLibrary(ffmpeg_dep.artifact("ffmpeg"));

    const libxml2_dep = b.dependency("libxml2", .{ .target = target, .optimize = optimize });
    exe.linkLibrary(libxml2_dep.artifact("xml2"));
    //exe.addObjectFile("../libxml2/zig-out/lib/libxml2.a");
    //exe.addIncludePath("../libxml2/zig-out/include");

    //if (target.isDarwin()) {
    //    exe.linkSystemLibrary("z");
    //    exe.linkSystemLibrary("bz2");
    //    exe.linkSystemLibrary("iconv");
    //    exe.linkFramework("AppKit");
    //    exe.linkFramework("AudioToolbox");
    //    exe.linkFramework("Carbon");
    //    exe.linkFramework("Cocoa");
    //    exe.linkFramework("CoreAudio");
    //    exe.linkFramework("CoreFoundation");
    //    exe.linkFramework("CoreGraphics");
    //    exe.linkFramework("CoreHaptics");
    //    exe.linkFramework("CoreVideo");
    //    exe.linkFramework("ForceFeedback");
    //    exe.linkFramework("GameController");
    //    exe.linkFramework("IOKit");
    //    exe.linkFramework("Metal");
    //}

    const compile_step = b.step("compile-" ++ "podcast", "Compile " ++ "podcast");
    compile_step.dependOn(&b.addInstallArtifact(exe, .{}).step);
    b.getInstallStep().dependOn(compile_step);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(compile_step);

    const run_step = b.step("podcast", "Run " ++ "podcast");
    run_step.dependOn(&run_cmd.step);
}
