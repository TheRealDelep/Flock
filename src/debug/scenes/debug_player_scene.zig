const rl = @import("raylib");
const std = @import("std");
const bullet = @import("../../bullet_pool.zig");

const Bullet = @import("../../entities/player.zig").Bullet;
const Scene = @import("../../scene.zig").Scene;

const player = @import("../../entities/player.zig");

var arena: std.heap.ArenaAllocator = undefined;

pub var scene = Scene {
    .initFn = init,
    .updateFn = update,
    .camDrawFn = draw,
    .screenDrawFn = null,
    .deinitFn = null
};

pub fn init(camera: *rl.Camera2D) void {
    arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    player.init(arena.allocator(), camera);
}

pub fn update() void {
    player.update();
}

pub fn draw() void {
    player.draw();
}