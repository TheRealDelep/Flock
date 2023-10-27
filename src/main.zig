const std = @import("std");
const rl = @import("raylib");

const helper = @import("helper.zig");
const settings = @import("settings.zig");
const level = @import("level.zig");
const debug = @import("debug_scene.zig");

const Agent = @import("./agent.zig").Agent;

const CamSpeed = 10.0;
const ScrollSpeed = 1.0;

pub fn main() void {
    rl.SetConfigFlags(rl.ConfigFlags{ .FLAG_WINDOW_RESIZABLE = true });

    rl.InitWindow(
        @as(i32, @intCast(settings.resolution.Width)),
        @as(i32, @intCast(settings.resolution.Height)),
        "HUGEEEEE FLOCK!!!"
    );
    defer rl.CloseWindow();

    rl.SetTargetFPS(60);

    var cam = rl.Camera2D {
        .target = rl.Vector2.zero(),
        .offset =  rl.Vector2 {
            .x = @floatFromInt(@divExact(@as(i32, @intCast(settings.resolution.Width)), 2)),
            .y = @floatFromInt(@divExact(@as(i32, @intCast(settings.resolution.Height)), 2)),
        },
        .rotation = 0,
        .zoom = 0.5
    };

    level.init();

    while (!rl.WindowShouldClose()) {
        // --- UPDATE ---
        updateCamera(&cam);
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

fn updateCamera(cam: *rl.Camera2D) void {
    const x = 
        @as(i32, @intFromBool(rl.IsKeyDown(rl.KeyboardKey.KEY_RIGHT))) - 
        @as(i32, @intFromBool(rl.IsKeyDown(rl.KeyboardKey.KEY_LEFT)));

    const y = 
        @as(i32, @intFromBool(rl.IsKeyDown(rl.KeyboardKey.KEY_DOWN))) - 
        @as(i32, @intFromBool(rl.IsKeyDown(rl.KeyboardKey.KEY_UP)));

    var movement = rl.Vector2Normalize(rl.Vector2 { .x = @floatFromInt(x), .y = @floatFromInt(y)});
    movement = rl.Vector2 { 
        .x = movement.x * CamSpeed * rl.GetFrameTime() * @as(f32, @floatFromInt(settings.ppu)), 
        .y = movement.y * CamSpeed * rl.GetFrameTime() * @as(f32, @floatFromInt(settings.ppu))
    };

    cam.target = rl.Vector2Add(cam.target, movement);

    const scroll = rl.GetMouseWheelMove();
    if ((scroll) != 0.0) {
        cam.zoom += scroll * ScrollSpeed * rl.GetFrameTime();
    }
}