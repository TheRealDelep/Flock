const rl = @import("raylib");

const settings = @import("settings.zig");
const Entity = @import("entity.zig").Entity;

const vertices = [_]rl.Vector2 {
    rl.Vector2 { .x = -0.4, .y = -0.4 },
    rl.Vector2 { .x = 0.0, .y = -0.2 },
    rl.Vector2 { .x = 0.4, .y = -0.4 },
    rl.Vector2 { .x = 0, .y = 0.6 }
};

pub const Player = struct {
    entity: Entity = Entity {},
    velocity: rl.Vector2 = rl.Vector2.zero(),
    size: rl.Vector2 = rl.Vector2.one(),

    pub fn draw(self: *Player) void {
        const first = self.get_vertex_position(vertices[0]);
        var current = first;
    
        for (vertices[1..]) |vertex| {
            const next = self.get_vertex_position(vertex);
            rl.DrawLineV(current, next, rl.RED);
            current = next;
        }
    
        rl.DrawLineV(current, first, rl.RED);
    }

    fn get_vertex_position(self: *Player, vertex: rl.Vector2) rl.Vector2 {
        return rl
            .Vector2Multiply(vertex, self.size)
            .scale(settings.ppu_f)
            .rotate(self.entity.rotation * rl.DEG2RAD)
            .add(self.entity.position.scale(settings.ppu_f));
    }
};

pub const Bullet = struct {
    entity: Entity,
    direction: rl.Vector2 = rl.Vector2.zero(),
    lifespan: f32 = 0,

    pub fn draw(self: *Bullet) void {
        const pos = self.entity.position.scale(settings.ppu_f);
        rl.DrawCircle(
            @as(i32, @intFromFloat(pos.x)), 
            @as(i32, @intFromFloat(pos.y)), 
            0.25 * settings.ppu_f, 
            rl.RED);
    }
};