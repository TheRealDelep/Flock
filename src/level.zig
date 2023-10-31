const std = @import("std");
const rl = @import("raylib");
const helper = @import("helper.zig");
const settings = @import("settings.zig");
const game_manager = @import("game_manager.zig");

const agent = @import("agent.zig");
const Agent = agent.Agent;
const debug = @import("debug.zig");

pub const size: f32 = 50;
pub const level_bounds = rl.Rectangle {
    .x = 0,
    .y = 0,
    .height = size,
    .width = size
};

pub const flock_size = 100;

pub const attraction_radius = 5;
pub const avoidance_radius = 2;

pub const attraction_factor = 2;
pub const avoidance_factor = 5;
pub const bounds_avoidance_factor = 10;

const attraction_color = rl.YELLOW;
const avoidance_color = rl.RED;

var flock: [flock_size]Agent = undefined;
var selected_agent: ?*Agent = null;

var camera: *rl.Camera2D = undefined;

pub fn init(cam: *rl.Camera2D) void {
    camera = cam;

    for (&flock) |*a| {
        const coef = (size - 1) * 2;
        const position = helper.random.getVec2(rl.Vector2 {.x = coef, .y = coef});
        const rotation = helper.random.getF32() * 360.0;

        a.* = Agent.new(position, rotation, null);
    }
}

pub fn update() void {
    if (rl.IsMouseButtonPressed(rl.MouseButton.MOUSE_BUTTON_LEFT)) {
        select_agent(helper.vec2.scalarMult(
            rl.GetScreenToWorld2D(rl.GetMousePosition(), camera.*), 
            1 / settings.ppu_f));
    }

    for (&flock) |*self| {
        const is_selected = selected_agent == self;

        var center_of_mass = rl.Vector2.zero();

        var attraction_count: f32 = 0;
        var separation_count: f32 = 0;

        var separation = rl.Vector2.zero();
        var cohesion = rl.Vector2.zero();
        var alignment = rl.Vector2.zero();
        var bounds_avoidance = rl.Vector2.zero();

        for (&flock) |*other| {
            if (self == other) {
                continue;
            }

            const dist = rl.Vector2.distanceTo(self.position, other.position);
            // Cohesion and Alignment
            if (dist < attraction_radius) {
                if (is_selected) {
                    debug.drawShape(debug.Shape {
                        .color = attraction_color,
                        .origin = self.position,
                        .kind = .{.line = other.position}
                    });
                }

                attraction_count += 1.0;
                center_of_mass = center_of_mass.add(other.position);
                alignment = alignment.add(other.velocity);
            }

            // Separation
            if (dist < avoidance_radius) {
                if (is_selected) {
                    debug.drawShape(debug.Shape {
                        .color = avoidance_color,
                        .origin = self.position,
                        .kind = .{.line = other.position}
                    });
                }

                separation_count += 1;
                const dir = rl.Vector2Subtract(self.position, other.position).normalize();
                separation = separation.add(dir.scale(1 / dist));
            }
        }

        if (attraction_count > 0) {
            cohesion = rl.Vector2Clamp(
                center_of_mass
                    .scale(1 / attraction_count)
                    .normalize()
                    .scale(agent.cruise_speed)
                    .sub(self.velocity)
                    .scale(rl.GetFrameTime()),
                agent.max_acceleration_vec.scale(-1),
                agent.max_acceleration_vec
            );

            alignment = rl.Vector2Clamp(
                alignment
                    .scale(1 / attraction_count)
                    .normalize()
                    .scale(agent.cruise_speed)
                    .sub(self.velocity)
                    .scale(rl.GetFrameTime()),
                agent.max_acceleration_vec.scale(-1),
                agent.max_acceleration_vec
            );
        }

        if (separation_count > 0) {
            separation = rl.Vector2Clamp(
                separation
                    .scale(1 / separation_count)
                    .normalize()
                    .scale(agent.cruise_speed)
                    .sub(self.velocity)
                    .scale(rl.GetFrameTime()),
                agent.max_acceleration_vec.scale(-1),
                agent.max_acceleration_vec
            );
        }

        const dist_from_center = self.position.distanceTo(rl.Vector2.zero());

        if (dist_from_center > size - avoidance_radius) {
            bounds_avoidance = rl.Vector2Clamp(
                self.position
                    .scale(-1)
                    .normalize()
                    .scale(agent.cruise_speed)
                    .sub(self.velocity)
                    .scale(rl.GetFrameTime()),
                agent.max_acceleration_vec.scale(-1),
                agent.max_acceleration_vec
            );
        }

        // Filnally moves the agent
        if (game_manager.game_state == game_manager.GameState.running) {
            self.velocity = self.velocity
                .add(separation.scale(avoidance_factor))
                .add(alignment)
                .add(cohesion.scale(attraction_factor))
                .add(bounds_avoidance.scale(bounds_avoidance_factor));

            self.velocity = rl.Vector2ClampValue(self.velocity, -agent.max_speed, agent.max_speed);
            self.update();
        }

        // Draw debug infos
        if (is_selected) {
            debug.drawShape(debug.Shape {
                .color = attraction_color,
                .origin = center_of_mass,
                .kind = .{ .circle = 0.25 }
            });

            debug.drawShape(debug.Shape {
                .color = avoidance_color,
                .origin = separation,
                .kind = .{ .circle = 0.25 }
            });

            debug.drawShape(debug.Shape {
                .origin = self.position,
                .color = attraction_color,
                .kind = .{ .circle = attraction_radius }
            });

            debug.drawShape(debug.Shape {
                .origin = self.position,
                .color = avoidance_color,
                .kind = .{.circle = avoidance_radius}
            });
        }
    }
}

pub fn draw() void {
    drawGrid();
    for (&flock) |*a| {
        a.draw();
    }
    debug.draw();
}

pub fn select_agent(position: rl.Vector2) void {
    for (&flock) |*a| {
        const bounds = rl.Rectangle {
            .x = a.*.position.x - 0.5,
            .y = a.*.position.y - 0.5,
            .width = 1,
            .height = 1
        };

        if (rl.CheckCollisionPointRec(position, bounds)) {
            selected_agent = a;    
            return;
        }
    }

    selected_agent = null;
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