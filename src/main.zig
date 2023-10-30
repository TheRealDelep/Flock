const std = @import("std");
const rl = @import("raylib");

const helper = @import("helper.zig");
const settings = @import("settings.zig");
const level = @import("level.zig");
const debug = @import("debug.zig");

const Agent = @import("./agent.zig").Agent;
const Controller = @import("./controller.zig");


pub fn main() void {
    rl.SetConfigFlags(rl.ConfigFlags{ .FLAG_WINDOW_RESIZABLE = true });

    rl.InitWindow(@as(i32, @intCast(settings.resolution.Width)), @as(i32, @intCast(settings.resolution.Height)), "HUGEEEEE FLOCK!!!");
    defer rl.CloseWindow();

    rl.SetTargetFPS(60);

    var cam = rl.Camera2D{ .target = rl.Vector2.zero(), .offset = rl.Vector2{
        .x = @floatFromInt(@divExact(@as(i32, @intCast(settings.resolution.Width)), 2)),
        .y = @floatFromInt(@divExact(@as(i32, @intCast(settings.resolution.Height)), 2)),
    }, .rotation = 0, .zoom = 0.5 };

    level.init(&cam);
    debug.init(std.heap.page_allocator);

    while (!rl.WindowShouldClose()) {
        // --- UPDATE ---
        Controller.update(&cam);
        level.update();

        // --- Draw ---
        rl.BeginDrawing();
        defer rl.EndDrawing();

        rl.ClearBackground(rl.BLACK);

        rl.BeginMode2D(cam);
        level.draw();

        rl.EndMode2D();
    }
}