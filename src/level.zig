const std = @import("std");
const rl = @import("raylib");
const helper = @import("helper.zig");
const settings = @import("settings.zig");

const Agent = @import("agent.zig").Agent;
const debug = @import("debug.zig");

pub const size: f32 = 50;
pub const flock_size = 2;

pub const attraction_radius = 2.5;

var flock: [flock_size]Agent = undefined;
var selected_agent: ?*Agent = null;

var camera: *rl.Camera2D = undefined;

pub fn init(cam: *rl.Camera2D) void {
    camera = cam;
    // for (&flock) |*agent| {
    //     const coef = (size - 1) * 2;
    //     const position = helper.Random.get_vec2(rl.Vector2 {.x = coef, .y = coef});
    //     const rotation = helper.Random.get_f32() * 360.0;

    //     agent.* = Agent.new(position, rotation, null);
    // }

    flock[0] = Agent.new(rl.Vector2{ .x = 0, .y = -2 }, 45, null);
    flock[1] = Agent.new(rl.Vector2{ .x = 0, .y = -4 }, -45, null);
}

pub fn update() void {
    if (rl.IsMouseButtonPressed(rl.MouseButton.MOUSE_BUTTON_LEFT)) {
        select_agent(helper.vec2.scalarMult(
            rl.GetScreenToWorld2D(rl.GetMousePosition(), camera.*), 
            1 / settings.ppu_f));
    }

    for (&flock) |*self| {
        defer self.update();

        var bird_count: f32 = 0;
        var center_of_mass = rl.Vector2.zero();

        for (&flock) |*other| {
            if (self == other) {
                continue;
            }

            if (rl.Vector2.distanceTo(self.position, other.position) < attraction_radius) {
                if (selected_agent == self) {
                    debug.drawShape(debug.Shape {
                        .color = rl.YELLOW,
                        .origin = self.position,
                        .kind = .{.line = other.position}
                    });
                }

                center_of_mass = center_of_mass.add(other.position);
                bird_count += 1.0;
            }
        }

        if (bird_count > 0) {
            self.lookAt(center_of_mass);
        }
    }

    debugSelectedAgent();
}

pub fn draw() void {
    drawGrid();
    for (&flock) |*agent| {
        agent.draw();
    }
    debug.draw();
}

pub fn select_agent(position: rl.Vector2) void {
    for (&flock) |*agent| {
        const bounds = rl.Rectangle {
            .x = agent.*.position.x - 0.5,
            .y = agent.*.position.y - 0.5,
            .width = 1,
            .height = 1
        };

        if (rl.CheckCollisionPointRec(position, bounds)) {
            selected_agent = agent;    
            return;
        }
    }

    selected_agent = null;
}

fn debugSelectedAgent() void {
    if (selected_agent) |*agent| {
        debug.drawShape(debug.Shape {
            .origin = agent.*.position,
            .color = rl.YELLOW,
            .kind = .{ .circle = attraction_radius }
        });
    }
}

fn drawGrid() void {
    const ppu: i32 = @intCast(settings.ppu);
    const sizeInt: i32 = @intFromFloat(size);

    for (0..size + 1) |i| {
        const index: i32 = @intCast(i);

        var color = rl.DARKGRAY;
        if (i % 10 == 0) {
            color = rl.LIGHTGRAY;
        } else if (i % 5 == 0) {
            color = rl.GRAY;
        }

        rl.DrawLine(ppu * index, ppu * -sizeInt, ppu * index, ppu * sizeInt, color);
        rl.DrawLine(ppu * -index, ppu * -sizeInt, ppu * -index, ppu * sizeInt, color);
        rl.DrawLine(ppu * sizeInt, ppu * -index, ppu * -sizeInt, ppu * -index, color);
        rl.DrawLine(ppu * sizeInt, ppu * index, ppu * -sizeInt, ppu * index, color);
    }
}