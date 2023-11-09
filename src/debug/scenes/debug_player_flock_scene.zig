const std = @import("std");
const rl = @import("raylib");

const helper = @import("../../helper.zig");
const entities = @import("../../entities/entities.zig");
const player = @import("../../entities/player.zig");
const Flock = @import("../../flock.zig").Flock;
const DebugInfos = @import("../../entities/agent.zig").AgentDebugInfos;

const level_size = 100;
const flock_size = 1000;

pub const scene = @import("../../scene.zig").Scene {
    .initFn = init,
    .updateFn = update,
    .camDrawFn = draw,
    .screenDrawFn = drawScreen,
};

var arena: std.heap.ArenaAllocator = undefined;
var flock: Flock = undefined;

const exit_rect = rl.Rectangle {
    .x = 95,
    .y = 0,
    .height = 20,
    .width = 10
};

var score: u32 = 0;

pub fn init(camera: *rl.Camera2D) void {
    arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    var agents = arena.allocator().alloc(entities.Agent, flock_size) catch unreachable;

    for (agents, 0..) |*a, i| {
        var position = rl.Vector2.zero();
        if (i % 4 == 0) {
            position = rl.Vector2.one().scale(-(level_size - 10));
        } else if (i % 3 == 0) {
            position = rl.Vector2.one().scale(level_size - 10);
        } else if (i % 2 == 0) {
            position = rl.Vector2Scale(.{.x = 1, .y = -1}, level_size - 10);
        } else {
            position = rl.Vector2Scale(.{.x = -1, .y = 1}, level_size - 10);
        }

        a.* = entities.Agent.new(position, 0, null);
    }

    player.init(arena.allocator(), camera);
    player.entity.position = rl.Vector2.zero();

    flock = Flock {
        .level_bounds = rl.Rectangle {
            .height = level_size * 2,
            .width = level_size * 2,
            .x = 0,
            .y = 0
        },
        .agents = agents,
        .bullet_pool = &player.bullet_pool,
    };
}

pub fn update() void {
    player.update();
    flock.target = player.entity.position; 
    flock.update();

    for (flock.agents) |*a| {
        if (a.entity.is_active and rl.CheckCollisionPointRec(a.entity.position, exit_rect)) {
            a.entity.is_active = false;
            score += 1;
        }
    }
}

pub fn draw() void {
    flock.draw();
    player.draw();

    const ppu = @import("../../settings.zig").ppu;
    
    const level_bounds = rl.Rectangle {
        .height = level_size * @as(i32, 2) * ppu,
        .width = level_size * @as(i32, 2) * ppu,
        .x = -level_size * @as(i32, ppu),
        .y = -level_size * @as(i32, ppu)
    };
    
    rl.DrawRectangleLinesEx(level_bounds, 5, rl.WHITE);
    rl.DrawRectangleLinesEx(rl.Rectangle {
        .height = exit_rect.height * ppu,
        .width = exit_rect.width * ppu,
        .x = exit_rect.x * ppu,
        .y = exit_rect.y * ppu
    }, 5, rl.GREEN);
}

pub fn drawScreen() void {
    flock.drawScreen();
    const score_txt = std.fmt.allocPrintZ(std.heap.page_allocator, "Score: {d}", .{score}) catch unreachable;

    rl.DrawText(score_txt, 20, 20, 18, rl.RED);
}