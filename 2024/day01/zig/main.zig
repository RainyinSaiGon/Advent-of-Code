const std = @import("std");

fn parse(data: []const u8, allocator: std.mem.Allocator) !struct {
    left: []i64,
    right: []i64,
} {
    // No .init(allocator) — initialize with empty literal
    var left: std.ArrayList(i64) = .{ .items = &.{}, .capacity = 0 };
    var right: std.ArrayList(i64) = .{ .items = &.{}, .capacity = 0 };

    var lines = std.mem.splitScalar(u8, data, '\n');
    while (lines.next()) |line| {
        if (line.len == 0) continue;
        var parts = std.mem.tokenizeAny(u8, line, " \t");
        const a = try std.fmt.parseInt(i64, parts.next().?, 10);
        const b = try std.fmt.parseInt(i64, parts.next().?, 10);
        // Pass allocator to every mutating method
        try left.append(allocator, a);
        try right.append(allocator, b);
    }

    return .{
        .left = try left.toOwnedSlice(allocator),
        .right = try right.toOwnedSlice(allocator),
    };
}

fn part1(data: []const u8, allocator: std.mem.Allocator) !i64 {
    const parsed = try parse(data, allocator);
    defer allocator.free(parsed.left);
    defer allocator.free(parsed.right);

    std.mem.sort(i64, parsed.left, {}, std.sort.asc(i64));
    std.mem.sort(i64, parsed.right, {}, std.sort.asc(i64));

    var total: i64 = 0;
    for (parsed.left, parsed.right) |l, r| {
        total += @as(i64, @intCast(@abs(l - r)));
    }
    return total;
}

fn part2(data: []const u8, allocator: std.mem.Allocator) !i64 {
    const parsed = try parse(data, allocator);
    defer allocator.free(parsed.left);
    defer allocator.free(parsed.right);

    var counts: std.AutoHashMap(i64, i64) = .init(allocator);
    defer counts.deinit();

    for (parsed.right) |num| {
        const entry = try counts.getOrPutValue(num, 0);
        entry.value_ptr.* += 1;
    }

    var total: i64 = 0;
    for (parsed.left) |num| {
        const count = counts.get(num) orelse 0;
        total += num * count;
    }
    return total;
}

pub fn main(init: std.process.Init) !void {
    var da = std.heap.DebugAllocator(.{}).init;
    defer _ = da.deinit();
    const allocator = da.allocator();

    const cwd = std.Io.Dir.cwd();
    const file = try cwd.openFile(init.io, "../input.txt", .{ .mode = .read_only });
    var read_buf: [4096]u8 = undefined;
    var f_reader = file.reader(init.io, &read_buf);
    var content = std.Io.Writer.Allocating.init(allocator);
    defer content.deinit();
    _ = try f_reader.interface.streamRemaining(&content.writer);

    const trimmed = std.mem.trim(u8, content.written(), "\n\r ");
    const p1 = try part1(trimmed, allocator);
    const p2 = try part2(trimmed, allocator);
    // std.debug.print("Test: {d}\n", .{p1});
    std.debug.print("Part 1: {d}\n", .{p1});
    std.debug.print("Part 2: {d}\n", .{p2});
}
