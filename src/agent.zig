const std = @import("std");
const rl = @import("raylib");
const settings = @import("./settings.zig");
const level = @import("level.zig");
const helper = @import("helper.zig");

const agent_speed: f32 = 1 * @as(f32, @floatFromInt(settings.ppu));

const vertices = blk: {
    const ppu: f32 = @floatFromInt(settings.ppu);

    break :blk [_]rl.Vector2 {
        rl.Vector2 {.x = -1.0 * ppu, .y = -1.0 * ppu} ,
        rl.Vector2 {.x = 0.0, .y = -0.5 * ppu},
        rl.Vector2 {.x = 1.0 * ppu, .y = -1.0 * ppu},
        rl.Vector2 {.x = 0, .y = 2.0 * ppu}
    };
};

pub const Agent = struct { 
    position: rl.Vector2 = rl.Vector2.zero(), 
    rotation: f32 = 0,
    size: rl.Vector2 = rl.Vector2.zero(),
    target: rl.Vector2 = rl.Vector2.one(),

    pub fn new(position: ?rl.Vector2, rotation: ?f32, size: ?rl.Vector2, target: ?rl.Vector2) Agent {
        return Agent {
            .position = position orelse rl.Vector2.zero(),
            .rotation = rotation orelse 0,
            .size = size orelse rl.Vector2.one(),
            .target = target orelse rl.Vector2.one()
        };
    }

    pub fn update(self: *Agent) void {
        const forward = rl.Vector2Rotate(rl.Vector2 {.x = 0, .y = 1}, self.rotation * rl.DEG2RAD);
        const direction = rl.Vector2 {
            .x = self.target.x - self.position.x,
            .y = self.target.y - self.position.y
        };

        self.position = rl.Vector2Add(self.position, rl.Vector2 {
            .x = forward.x * agent_speed * rl.GetFrameTime() / @as(f32, @floatFromInt(settings.ppu)),
            .y = forward.y * agent_speed * rl.GetFrameTime() / @as(f32, @floatFromInt(settings.ppu))
        });

        if (rl.Vector2DotProduct(forward, direction) < 0.001) {
            self.lookAt(rl.Vector2 {
                .x = helper.Random.get_f32() * 18.0, 
                .y = helper.Random.get_f32() * 18.0
            });
        }
    }

    pub fn lookAt(self: *Agent, target: rl.Vector2) void {
        self.target = target;
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