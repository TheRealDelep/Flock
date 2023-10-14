const std = @import("std");
const rl = @import("raylib");

const settings = @import("settings.zig");
const level = @import("level.zig");

const Agent = @import("./agent.zig").Agent;

const CamSpeed = 250.0;

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
        .zoom = 1
    };

    var agent = Agent.new(null, null, rl.Vector2 { .x = 1, .y = 1}, rl.Vector2 {.x = 0, .y = -1});
    var should_updtate = false;

    while (!rl.WindowShouldClose()) {
        // --- UPDATE ---
        updateCamera(&cam);
        if (rl.IsMouseButtonDown(rl.MouseButton.MOUSE_BUTTON_LEFT)) {
            const pos = rl.GetScreenToWorld2D(rl.GetMousePosition(), cam);
            agent.lookAt(rl.Vector2 {
                .x = pos.x / @as(f32, @floatFromInt(settings.ppu)),
                .y = pos.y / @as(f32, @floatFromInt(settings.ppu)) 
            });
        }

        if (rl.IsKeyDown(rl.KeyboardKey.KEY_SPACE)) {
            should_updtate = !should_updtate;
        }

        if (should_updtate) {
            agent.update();
        }
        
        // --- Draw ---
        rl.BeginDrawing();
        defer rl.EndDrawing();

        rl.ClearBackground(rl.BLACK);

        rl.BeginMode2D(cam);

        drawGrid(level.size);
        agent.draw();

        rl.EndMode2D();

        // --- Debug stuffs ---

        const pos_txt = std.fmt.allocPrintZ(std.heap.page_allocator, "position: ({d}, {d})", .{agent.position.x, agent.position.y}) 
            catch "This Language is bullshit";

        const rot_txt = std.fmt.allocPrintZ(std.heap.page_allocator, "rotation: {d}", .{agent.rotation}) 
            catch "This Language is bullshit";

        const target_txt = std.fmt.allocPrintZ(std.heap.page_allocator, "target: ({d}, {d})", .{agent.target.x, agent.target.y}) 
            catch "This Language is bullshit";

        const forward = rl.Vector2Rotate(rl.Vector2 {.x = 0, .y = 1}, agent.rotation * rl.DEG2RAD);
        const forward_txt = std.fmt.allocPrintZ(std.heap.page_allocator, "forward: ({d}, {d})", .{forward.x, forward.y})
            catch "This Language is bullshit";

        rl.DrawText(pos_txt, 20, 20, 14, rl.GREEN);
        rl.DrawText(rot_txt, 20, 40, 14, rl.GREEN);
        rl.DrawText(target_txt, 20, 60, 14, rl.GREEN);
        rl.DrawText(forward_txt, 20, 80, 14, rl.GREEN);
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
        .x = movement.x * CamSpeed * rl.GetFrameTime(), 
        .y = movement.y * CamSpeed * rl.GetFrameTime()
    };

    cam.target = rl.Vector2Add(cam.target, movement);
}

fn drawGrid(size: usize) void {
    const ppu: i32 = @intCast(settings.ppu); 
    for (0..size + 1) |i| {
        const index: i32 = @intCast(i);
        const sizeInt : i32 = @intCast(size);

        var color = rl.DARKGRAY;
        if (i % 10 == 0) {
            color = rl.LIGHTGRAY;
        } else if (i % 5 == 0){
            color = rl.GRAY; 
        }

        rl.DrawLine(ppu * index, ppu * -sizeInt, ppu * index, ppu * sizeInt, color);
        rl.DrawLine(ppu * -index, ppu * -sizeInt, ppu * -index, ppu * sizeInt, color);
        rl.DrawLine(ppu * sizeInt, ppu * -index, ppu * -sizeInt, ppu * -index, color);
        rl.DrawLine(ppu * sizeInt, ppu * index, ppu * -sizeInt, ppu * index, color);
    }
}