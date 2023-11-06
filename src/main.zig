const std = @import("std");
const rl = @import("raylib");

const settings = @import("settings.zig");
const debug = @import("debug/debug_drawer.zig");

const controller = @import("./debug/debug_controller.zig");

pub fn main() void {
    rl.SetConfigFlags(rl.ConfigFlags{ .FLAG_WINDOW_RESIZABLE = true });

    rl.InitWindow(@as(i32, @intCast(settings.resolution.Width)), @as(i32, @intCast(settings.resolution.Height)), "HUGEEEEE FLOCK!!!");
    defer rl.CloseWindow();

    rl.SetTargetFPS(60);

    var cam = rl.Camera2D{ .target = rl.Vector2.zero(), .offset = rl.Vector2{
        .x = @floatFromInt(@divExact(@as(i32, @intCast(settings.resolution.Width)), 2)),
        .y = @floatFromInt(@divExact(@as(i32, @intCast(settings.resolution.Height)), 2)),
    }, .rotation = 0, .zoom = 0.5 };

    debug.init(std.heap.page_allocator);

    var current_scene = @import("./debug//scenes/debug_player_flock_scene.zig").scene;
    if (current_scene.initFn) |init| { init(&cam); }

    while (!rl.WindowShouldClose()) {
        // --- UPDATE ---
        controller.update(&cam);
        if (current_scene.updateFn) |update| { update(); }

        // --- Draw ---
        rl.BeginDrawing();
        defer rl.EndDrawing();

        debug.draw();

        rl.ClearBackground(rl.BLACK);

        rl.BeginMode2D(cam);
        if (current_scene.camDrawFn) |draw| { draw(); }

        rl.EndMode2D();
        if (current_scene.screenDrawFn) |draw| { draw(); }
    }
}