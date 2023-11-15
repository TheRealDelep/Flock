const std = @import("std");
const rl = @import("raylib");

const settings = @import("settings.zig");
const Entity = @import("./entities/entity.zig").Entity;

const bullet_speed: f32 = 100;
const max_lifespan: f32 = 2;

pub const BulletPool = struct {
    bullets: []Bullet,

    pub fn init(allocator: std.mem.Allocator, size: u32) BulletPool {
        const bullets = allocator.alloc(Bullet, size) catch unreachable;
        for (bullets) |*bullet| {
            bullet.* = .{
                .entity = .{
                    .is_active = false
                }
            };
        }

        return BulletPool {
            .bullets = bullets
        };
    }

    pub fn update(self: *BulletPool) void {
        for (self.bullets) |*bullet| {
            bullet.update();
        }
    }

    pub fn draw(self: *BulletPool) void {
        for (self.bullets) |*bullet| {
            bullet.draw();
        }
    }

    pub fn getOne(self: *BulletPool, position: rl.Vector2, direction: rl.Vector2) *Bullet {
        for (self.bullets) |*bullet| {
            if (bullet.entity.is_active) {
                continue;
            }

            bullet.entity.is_active = true;
            bullet.entity.position = position;

            bullet.direction = direction;
            bullet.lifespan = 0;

            return bullet;
        }

        @panic("No more bullets");
    }
};

pub const BulletTag = enum {
    bullet,
    grenade,
    lazer
};

pub const Bullet = struct {
    entity: Entity,
    direction: rl.Vector2 = rl.Vector2.zero(),
    lifespan: f32 = 0,

    pub fn update(self: *Bullet) void {
        if (!self.entity.is_active) {
            return;
        }

        self.*.lifespan += rl.GetFrameTime();

        if (self.lifespan >= max_lifespan) {
            self.entity.is_active = false; 
        }

        self.entity.position = self.entity.position.add(
            self.direction.scale(bullet_speed * rl.GetFrameTime())
        );
    }

    pub fn draw(self: *Bullet) void {
        if (!self.entity.is_active) {
            return;
        }

        const pos = self.entity.position.scale(settings.ppu_f);
        rl.DrawCircle(
            @as(i32, @intFromFloat(pos.x)), 
            @as(i32, @intFromFloat(pos.y)), 
            0.25 * settings.ppu_f, 
            rl.RED
        );
    }
};