const rl = @import("raylib");
const settings = @import("settings.zig");

const Agent = @import("agent.zig").Agent;

var agent: Agent = Agent.new(null, null, null);
var camera: *rl.Camera2D = undefined;

var is_pause = true;

pub fn init(cam: *rl.Camera2D) void {
    camera = cam;
}

pub fn update() void {
    if (rl.IsMouseButtonDown(rl.MouseButton.MOUSE_BUTTON_LEFT)) {
        agent.lookAt(rl.Vector2Multiply(
            rl.GetScreenToWorld2D(rl.GetMousePosition(), camera.*),
            rl.Vector2 {
                .x = @as(f32, @floatFromInt(settings.ppu)),
                .y = @as(f32, @floatFromInt(settings.ppu)),
            }));
    }
    
    if (rl.IsKeyPressed(rl.KeyboardKey.KEY_SPACE)) {
        is_pause = !is_pause;
    }

    if (!is_pause) {
        agent.update();
    }
}

pub fn draw() void {
    agent.draw();
}