const std = @import("std");
const rl = @import("raylib");

const settings = @import("./settings.zig");
const helper = @import("./helper.zig");

const move_speed_kb = 10.0;
const move_speed_mouse = 1.0;
const scroll_speed = 1.0;

pub fn update(cam: *rl.Camera2D) void {
    var movement = getCamMove();

    if ((rl.Vector2Equals(movement, rl.Vector2.zero())) != 1) {
        cam.target = rl.Vector2Add(cam.target, rl.Vector2 {
            .x = movement.x * rl.GetFrameTime() * settings.ppu_f,
            .y = movement.y * rl.GetFrameTime() * settings.ppu_f
        });
    }

    const scroll = rl.GetMouseWheelMove();
    if ((scroll) != 0.0) {
        cam.zoom += scroll * scroll_speed * rl.GetFrameTime();
    }
}

fn getCamMove() rl.Vector2 {
    if (rl.IsMouseButtonDown(rl.MouseButton.MOUSE_BUTTON_MIDDLE)) {
        return helper.vec2.scalarMult(rl.GetMouseDelta(), -1 * move_speed_mouse);
    }

    const x =
        @as(i32, @intFromBool(rl.IsKeyDown(rl.KeyboardKey.KEY_RIGHT))) -
        @as(i32, @intFromBool(rl.IsKeyDown(rl.KeyboardKey.KEY_LEFT)));

    const y =
        @as(i32, @intFromBool(rl.IsKeyDown(rl.KeyboardKey.KEY_DOWN))) -
        @as(i32, @intFromBool(rl.IsKeyDown(rl.KeyboardKey.KEY_UP)));

    return helper.vec2.scalarMult(rl.Vector2Normalize(rl.Vector2 { 
        .x = @floatFromInt(x), 
        .y = @floatFromInt(y) 
    }), move_speed_kb);
}