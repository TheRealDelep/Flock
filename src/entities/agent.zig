const std = @import("std");
const rl = @import("raylib");

const Entity = @import("./entity.zig").Entity;
const settings = @import("../settings.zig");
const helper = @import("../helper.zig");

const debug = @import("../debug/debug_drawer.zig");

pub const max_speed: f32 = 15;
pub const cruise_speed: f32 = 10;

pub const max_acceleration: f32 = 10;
pub const base_acceleration: f32 = 5;

pub const max_acceleration_vec = rl.Vector2 {
    .x = max_acceleration,
    .y = max_acceleration
};

const vertices = [_]rl.Vector2 {
    rl.Vector2 {.x = -0.4 * settings.ppu_f, .y = -0.4 * settings.ppu_f},
    rl.Vector2 {.x = 0.0, .y = -0.2 * settings.ppu_f},
    rl.Vector2 {.x = 0.4 * settings.ppu_f, .y = -0.4 * settings.ppu_f},
    rl.Vector2 {.x = 0, .y = 0.6 * settings.ppu_f}
};

const collider_radius = 0.5;

pub const Agent = struct { 
    entity: Entity = Entity {},
    size: rl.Vector2 = rl.Vector2.one(),
    velocity: rl.Vector2 = rl.Vector2.zero(),

    pub fn new(position: ?rl.Vector2, rotation: ?f32, size: ?rl.Vector2) Agent {
        return Agent {
                .entity = .{
                .position = position orelse rl.Vector2.zero(),
                .rotation = rotation orelse 0,
            },
            .size = size orelse rl.Vector2.one(),
            .velocity = rl.Vector2.zero()
        };
    }

    pub fn update(self: *Agent) void {
        const new_pos = self.entity.position.add(self.velocity.scale(rl.GetFrameTime()));
        self.lookAt(new_pos);
        self.entity.position = new_pos;
    }

    pub fn lookAt(self: *Agent, target: rl.Vector2) void {
        const direction = rl.Vector2Normalize(rl.Vector2 {
            .x = target.x - self.entity.position.x,
            .y = target.y - self.entity.position.y
        });

        self.entity.rotation = (rl.Vector2LineAngle(rl.Vector2.zero(), direction) * rl.RAD2DEG) - 90;
    }

    pub fn draw(self: *Agent) void {
        const first = self.get_vertex_position(vertices[0]);
        var current = first;
    
        for (vertices[1..]) |vertex| {
            const next = self.get_vertex_position(vertex);
            rl.DrawLineV(current, next, rl.GREEN);
            current = next;
        }
    
        rl.DrawLineV(current, first, rl.GREEN);
    }

    pub fn hasPoint(self: *Agent, point: rl.Vector2) bool {
        return rl.CheckCollisionCircles(
            self.entity.position, 
            collider_radius, 
            point,
            0.5
        );
    }

    fn get_vertex_position(self: *Agent, vertex: rl.Vector2) rl.Vector2 {
        return rl
            .Vector2Multiply(vertex, self.size)
            .rotate(self.entity.rotation * rl.DEG2RAD)
            .add(rl.Vector2 {
                .x = self.entity.position.x * settings.ppu_f,
                .y = self.entity.position.y * settings.ppu_f
            });
    }
};

pub const AgentDebugInfos = struct {
    index: usize,
    self: *Agent,

    in_cohesion_range: std.ArrayList(*Agent),
    in_avoidance_range: std.ArrayList(*Agent),

    cohesion_force: rl.Vector2 = rl.Vector2.zero(),
    alignment_force: rl.Vector2 = rl.Vector2.zero(),
    separation_force: rl.Vector2 = rl.Vector2.zero(),
    bounds_avoidance_force: rl.Vector2 = rl.Vector2.zero(),

    cohesion_target: ?rl.Vector2 = null,
    separation_target: ?rl.Vector2 = null,
};