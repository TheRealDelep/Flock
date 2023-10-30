const std = @import("std");
const rl = @import("raylib");
const settings = @import("./settings.zig");
const level = @import("level.zig");
const helper = @import("helper.zig");

const average_agent_speed: f32 = 0 * @as(f32, @floatFromInt(settings.ppu));

const vertices = blk: {
    const ppu: f32 = @floatFromInt(settings.ppu);

    break :blk [_]rl.Vector2 {
        rl.Vector2 {.x = -0.4 * ppu, .y = -0.4 * ppu},
        rl.Vector2 {.x = 0.0, .y = -0.2 * ppu},
        rl.Vector2 {.x = 0.4 * ppu, .y = -0.4 * ppu},
        rl.Vector2 {.x = 0, .y = 0.6 * ppu}
    };
};

pub const Agent = struct { 
    position: rl.Vector2 = rl.Vector2.zero(), 
    rotation: f32 = 0,
    size: rl.Vector2 = rl.Vector2.zero(),
    velocity: rl.Vector2 = rl.Vector2.zero(),

    pub fn new(position: ?rl.Vector2, rotation: ?f32, size: ?rl.Vector2) Agent {
        return Agent {
            .position = position orelse rl.Vector2.zero(),
            .rotation = rotation orelse 0,
            .size = size orelse rl.Vector2.one(),
            .velocity = rl.Vector2.zero()
        };
    }

    pub fn update(self: *Agent) void {
        const forward = rl.Vector2Rotate(rl.Vector2 {.x = 0, .y = 1}, self.rotation * rl.DEG2RAD);
        const ppu = @as(f32, @floatFromInt(settings.ppu));
        self.position = self.position.add(rl.Vector2 {
            .x = forward.x * average_agent_speed * rl.GetFrameTime() / ppu, 
            .y = forward.y * average_agent_speed * rl.GetFrameTime() / ppu
        });
    }

    pub fn lookAt(self: *Agent, target: rl.Vector2) void {
        const direction = rl.Vector2Normalize(rl.Vector2 {
            .x = target.x - self.position.x,
            .y = target.y - self.position.y
        });

        self.rotation = (rl.Vector2LineAngle(rl.Vector2.zero(), direction) * rl.RAD2DEG) - 90;
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

    fn get_vertex_position(self: *Agent, vertex: rl.Vector2) rl.Vector2 {
        return rl
            .Vector2Multiply(vertex, self.size)
            .rotate(self.rotation * rl.DEG2RAD)
            .add(rl.Vector2 {
                .x = self.position.x * @as(f32, @floatFromInt(settings.ppu)),
                .y = self.position.y * @as(f32, @floatFromInt(settings.ppu))
            });
    }
};