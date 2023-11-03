const rl = @import("raylib");
const std = @import("std");

const Player = @import("player.zig").Player;
const Bullet = @import("player.zig").Bullet;

const player_speed: f32 = 15;
const bullet_speed: f32 = 40;

const bullet_lifespan: f32 = 1;
const fire_rate: f32 = 10;
const fire_rate_dt: f32 = 1 / fire_rate;

var time_since_last_bullet: f32 = 0;

var bullet_pool = [_]Bullet {Bullet{.entity = .{.is_active = false}}} ** 200;

var player = Player {
    .size = .{.x = 2, .y = 2}
};

pub fn update() void {
    time_since_last_bullet += rl.GetFrameTime();

    for (bullet_pool, 0..) |bullet, index| {
        if (!bullet.entity.is_active) {
            continue;            
        }

        if (bullet.lifespan >= bullet_lifespan) {
            bullet_pool[index].entity.is_active = false;
            continue;
        }

        bullet_pool[index].entity.position = bullet.entity.position.add(
            bullet_pool[index].direction.scale(bullet_speed * rl.GetFrameTime())
        );

        bullet_pool[index].lifespan += rl.GetFrameTime();
    }

    const direction = rl.Vector2Normalize(rl.Vector2 {
        .x = rl.GetGamepadAxisMovement(0, rl.GamepadAxis.GAMEPAD_AXIS_LEFT_X),
        .y = rl.GetGamepadAxisMovement(0, rl.GamepadAxis.GAMEPAD_AXIS_LEFT_Y)
    });

    player.entity.position = player.entity.position.add(direction.scale(player_speed * rl.GetFrameTime()));

    var forward = rl.Vector2Normalize(rl.Vector2 {
        .x = rl.GetGamepadAxisMovement(0, rl.GamepadAxis.GAMEPAD_AXIS_RIGHT_X),
        .y = rl.GetGamepadAxisMovement(0, rl.GamepadAxis.GAMEPAD_AXIS_RIGHT_Y)
    });

    if (rl.Vector2Equals(forward, rl.Vector2.zero()) != 1) {
        player.entity.rotation = (forward.angle() * rl.RAD2DEG) - 90;
    } else {
        forward = rl.Vector2Rotate(.{.x = 0, .y = 1}, player.entity.rotation * rl.DEG2RAD);
    }

    if (rl.GetGamepadAxisMovement(0, rl.GamepadAxis.GAMEPAD_AXIS_RIGHT_TRIGGER) > 0.5) {
        if (time_since_last_bullet > fire_rate_dt) {
            var bullet = getBullet();
            bullet.*.entity.is_active = true;
            bullet.*.entity.position = player.entity.position.add(forward.scale(2));

            bullet.*.direction = forward;
            bullet.*.lifespan = 0;

            time_since_last_bullet = 0;
        }
    }
}

pub fn draw() void {
    player.draw();

    for(0..199) |i| {
        var bullet = bullet_pool[i];
        if (bullet.entity.is_active) {
            bullet.draw();
        }
    }  
}

fn getBullet() *Bullet {
    for (bullet_pool, 0..) |bullet, index| {
        if (!bullet.entity.is_active) {
            return &bullet_pool[index];
        }
    }

    @panic("No more bullets");
}