const std = @import("std");
const rl = @import("raylib");

const settings = @import("../settings.zig");
const Entity = @import("./entity.zig").Entity;
const Bullet = @import("../bullet_pool.zig").Bullet;
const BulletPool = @import("../bullet_pool.zig").BulletPool;

const max_speed: f32 = 20;
const fire_rate: f32 = 10;
const fire_rate_dt: f32 = 1 / fire_rate;

const vertices = [_]rl.Vector2 {
    rl.Vector2 { .x = -0.4, .y = -0.4 },
    rl.Vector2 { .x = 0.0, .y = -0.2 },
    rl.Vector2 { .x = 0.4, .y = -0.4 },
    rl.Vector2 { .x = 0, .y = 0.6 }
};

pub var entity: Entity = Entity {};
var size: rl.Vector2 = rl.Vector2 {.x = 2, .y = 2};

var camera: *rl.Camera2D = undefined;

var time_since_last_bullet: f32 = 0;
var bullet_pool: BulletPool = undefined;

pub fn init(allocator: std.mem.Allocator, cam: *rl.Camera2D) void {
    camera = cam;
    bullet_pool = BulletPool.init(allocator, 200);
}

pub fn update() void {
    time_since_last_bullet += rl.GetFrameTime();

    const direction = rl.Vector2Normalize(rl.Vector2 {
        .x = rl.GetGamepadAxisMovement(0, rl.GamepadAxis.GAMEPAD_AXIS_LEFT_X),
        .y = rl.GetGamepadAxisMovement(0, rl.GamepadAxis.GAMEPAD_AXIS_LEFT_Y)
    });

    entity.position = entity.position.add(direction.scale(max_speed * rl.GetFrameTime()));
    camera.*.target = entity.position.scale(settings.ppu_f);

    var forward = rl.Vector2Normalize(rl.Vector2 {
        .x = rl.GetGamepadAxisMovement(0, rl.GamepadAxis.GAMEPAD_AXIS_RIGHT_X),
        .y = rl.GetGamepadAxisMovement(0, rl.GamepadAxis.GAMEPAD_AXIS_RIGHT_Y)
    });

    if (rl.Vector2Equals(forward, rl.Vector2.zero()) != 1) {
        entity.rotation = (forward.angle() * rl.RAD2DEG) - 90;
    } else {
        forward = rl.Vector2Rotate(.{.x = 0, .y = 1}, entity.rotation * rl.DEG2RAD);
    }

    if (rl.GetGamepadAxisMovement(0, rl.GamepadAxis.GAMEPAD_AXIS_RIGHT_TRIGGER) > 0.5) {
        if (time_since_last_bullet > fire_rate_dt) {
            const pos = entity.position.add(forward.scale(2));
            _= bullet_pool.getOne(pos, forward);

            time_since_last_bullet = 0;
        }
    }

    bullet_pool.update();
}

pub fn draw() void {
    const first = get_vertex_position(vertices[0]);
    var current = first;
    
    for (vertices[1..]) |vertex| {
        const next = get_vertex_position(vertex);
        rl.DrawLineV(current, next, rl.RED);
        current = next;
    }
    
    rl.DrawLineV(current, first, rl.RED);

    bullet_pool.draw();
}

fn get_vertex_position(vertex: rl.Vector2) rl.Vector2 {
    return rl
        .Vector2Multiply(vertex, size)
        .scale(settings.ppu_f)
        .rotate(entity.rotation * rl.DEG2RAD)
        .add(entity.position.scale(settings.ppu_f));
}