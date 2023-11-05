const std = @import("std");
const rl = @import("raylib");

const entities = @import("../../entities/entities.zig");
const Flock = @import("../../flock.zig").Flock;

const level_size = 50;
const flock_size = 100;

pub const scene = @import("../../scene.zig").Scene {
    .initFn = init,
    .updateFn = update,
    .camDrawFn = draw
};

var arena: std.heap.ArenaAllocator = undefined;

var cam: *rl.Camera2D = undefined;
var player = entities.Player {};
var flock: Flock = undefined;


pub fn init(camera: *rl.Camera2D) void {
    cam = camera; 
    arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);

    var agents = arena.allocator().alloc(entities.Agent, flock_size) catch unreachable;

    flock = Flock {
        .level_size = level_size,
        .agents = agents
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