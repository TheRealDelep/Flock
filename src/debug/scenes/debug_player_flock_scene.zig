const std = @import("std");
const rl = @import("raylib");

const helper = @import("../../helper.zig");
const entities = @import("../../entities/entities.zig");
const player = @import("../../entities/player.zig");
const Flock = @import("../../flock.zig").Flock;

const level_size = 200;
const flock_size = 1000;

pub const scene = @import("../../scene.zig").Scene {
    .initFn = init,
    .updateFn = update,
    .camDrawFn = draw,
    .screenDrawFn = drawScreen,
};

var arena: std.heap.ArenaAllocator = undefined;
var flock: Flock = undefined;

pub fn init(camera: *rl.Camera2D) void {
    arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    var agents = arena.allocator().alloc(entities.Agent, flock_size) catch unreachable;

    for (agents) |*a| {
        const coef = (level_size - 1) * 2;
        const position = helper.random.getVec2(rl.Vector2 {.x = coef, .y = coef});
        const rotation = helper.random.getF32() * 360.0;

        a.* = entities.Agent.new(position, rotation, null);
    }

    player.init(arena.allocator(), camera);
    player.entity.position = rl.Vector2.zero();

    flock = Flock {
        .level_size = level_size,
        .agents = agents,
        .bullet_pool = &player.bullet_pool
    };
}

pub fn update() void {
    player.update();
    flock.target = player.entity.position; 
    flock.update();
}

pub fn draw() void {
    flock.draw();
    player.draw();
}

pub fn drawScreen() void {
    flock.drawScreen();
}