const std = @import("std");

fn part1(data: []const u8, allocator: std.mem.Allocator) !i64 {
    _ = data;
    _ = allocator;
    return 0;
}

fn part2(data: []const u8, allocator: std.mem.Allocator) !i64 {
    _ = data;
    _ = allocator;
    return 0;
}

pub fn main(init: std.process.Init) !void {
    var da = std.heap.DebugAllocator(.{}).init;
    defer _ = da.deinit();
    const allocator = da.allocator();

    // Read input file
    const cwd = std.Io.Dir.cwd();
    const file = try cwd.openFile(init.io, "../input.txt", .{ .mode = .read_only });
    var read_buf: [4096]u8 = undefined;
    var f_reader = file.reader(init.io, &read_buf);
    var content = std.Io.Writer.Allocating.init(allocator);
    defer content.deinit();
    _ = try f_reader.interface.streamRemaining(&content.writer);

    const trimmed = std.mem.trim(u8, content.written(), "\n\r ");

    // Write output — std.debug.print writes to stderr and always flushes
    const p1 = try part1(trimmed, allocator);
    const p2 = try part2(trimmed, allocator);
    std.debug.print("Part 1: {d}\n", .{p1});
    std.debug.print("Part 2: {d}\n", .{p2});
}
