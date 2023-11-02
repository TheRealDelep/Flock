const std = @import("std");
const rl = @import("raylib");
const helper = @import("helper.zig");
const settings = @import("settings.zig");
const game_manager = @import("game_manager.zig");

const agent = @import("agent.zig");
const debug = @import("debug.zig");

const Agent = agent.Agent;
const Flock = @import("flock.zig").Flock;

pub const size: f32 = 50;
pub const flock_size = 250;

const cohesion_color = rl.YELLOW;
const avoidance_color = rl.RED;

var camera: *rl.Camera2D = undefined;
var flock: Flock = undefined;

pub fn init(cam: *rl.Camera2D) void {
    camera = cam;
    var agents = std.heap.page_allocator.create([flock_size]Agent) catch unreachable;

    for (agents) |*a| {
        const coef = (size - 1) * 2;
        const position = helper.random.getVec2(rl.Vector2 {.x = coef, .y = coef});
        const rotation = helper.random.getF32() * 360.0;

        a.* = Agent.new(position, rotation, null);
    }

    flock = Flock {
        .agents = agents,
        .level_size = size
    };
}

pub fn update() void {
    if (rl.IsMouseButtonPressed(rl.MouseButton.MOUSE_BUTTON_LEFT)) {
        select_agent(rl.GetScreenToWorld2D(rl.GetMousePosition(), camera.*).scale(1 / settings.ppu_f));
    }

    if (rl.IsMouseButtonPressed(rl.MouseButton.MOUSE_BUTTON_RIGHT)) {
        flock.target = rl.GetScreenToWorld2D(rl.GetMousePosition(), camera.*).scale(1 / settings.ppu_f);
    }

    flock.update();
    drawDebugInfos();
}

pub fn draw() void {
    drawGrid();

    debug.drawShape(debug.Shape {
       .origin = flock.target,
       .color =  .{ .r = 0, .g = 255, .b = 255, .a = 255 },
       .kind = .{.circle = 0.25}
    });

    flock.draw();
    debug.draw();
}

pub fn draw_screen() void {
    if (flock.debug_infos) |infos| {
        const allocator = std.heap.page_allocator;
        
        const position_txt = std.fmt.allocPrintZ(allocator, "position: ({d}, {d})", infos.self.position) catch unreachable;
        const velocity_txt = std.fmt.allocPrintZ(allocator, "velocity: ({d}, {d})", infos.self.velocity) catch unreachable;
        const cohesion_txt = std.fmt.allocPrintZ(allocator, "cohesion: ({d}, {d})", infos.cohesion_force) catch unreachable;
        const alignment_txt = std.fmt.allocPrintZ(allocator, "alignment: ({d}, {d})", infos.alignment_force) catch unreachable;
        const separation_txt = std.fmt.allocPrintZ(allocator, "separation: ({d}, {d})", infos.separation_force) catch unreachable;
        const bounds_avoidance_txt = std.fmt.allocPrintZ(allocator, "bounds avoidance: ({d}, {d})", infos.bounds_avoidance_force) catch unreachable;

        defer allocator.free(position_txt);
        defer allocator.free(velocity_txt);
        defer allocator.free(cohesion_txt);
        defer allocator.free(alignment_txt);
        defer allocator.free(separation_txt);
        defer allocator.free(bounds_avoidance_txt);

        rl.DrawText(position_txt, 20, 20, 14, rl.GREEN);
        rl.DrawText(velocity_txt, 20, 40, 14, rl.GREEN);
        rl.DrawText(cohesion_txt, 20, 60, 14, rl.GREEN);
        rl.DrawText(alignment_txt, 20, 80, 14, rl.GREEN);
        rl.DrawText(separation_txt, 20, 100, 14, rl.GREEN);
        rl.DrawText(bounds_avoidance_txt, 20, 120, 14, rl.GREEN);
    }
}

pub fn select_agent(position: rl.Vector2) void {
    for (flock.agents, 0..) |*a, index| {
        const bounds = rl.Rectangle {
            .x = a.*.position.x - 0.5,
            .y = a.*.position.y - 0.5,
            .width = 1,
            .height = 1
        };

        if (rl.CheckCollisionPointRec(position, bounds)) {
            flock.debug_infos = agent.AgentDebugInfos {
                .self = a,
                .index = index,

                .in_cohesion_range = std.ArrayList(*Agent).init(std.heap.page_allocator),
                .in_avoidance_range = std.ArrayList(*Agent).init(std.heap.page_allocator),
            };
            return;
        }
    }

    if (flock.debug_infos) |*infos| {
        infos.in_cohesion_range.deinit();
        infos.in_avoidance_range.deinit();
    }

    flock.debug_infos = null;
}

fn drawDebugInfos() void {
    var infos: agent.AgentDebugInfos = undefined;
    if (flock.debug_infos) |*i| {
        infos = i.*;
    } else {
        return;
    }

    // Draw a line toward agents in cohesion range
    for (infos.in_cohesion_range.items) |a| {
        debug.drawShape(debug.Shape { 
            .color = cohesion_color, 
            .origin = infos.self.position, 
            .kind = .{ .line = a.position }
        });
    }

    // Draw a line towards agents in avoidance range
    for (infos.in_avoidance_range.items) |a| {
        debug.drawShape(debug.Shape { 
            .color = avoidance_color, 
            .origin = infos.self.position, 
            .kind = .{ .line = a.position }
        });
    }

    debug.drawShape(debug.Shape {
        .origin = infos.self.position,
        .color = cohesion_color,
        .kind = .{ .circle = flock.cohesion_radius }
    });

    debug.drawShape(debug.Shape {
        .origin = infos.self.position,
        .color = avoidance_color,
        .kind = .{.circle = flock.avoidance_radius}
    });
}

fn drawGrid() void {
    const ppu: i32 = @intCast(settings.ppu);
    const sizeInt: i32 = @intFromFloat(size);

    for (0..size + 1) |i| {
        const index: i32 = @intCast(i);

        var color = rl.DARKGRAY;
        if (i % 10 == 0) {
            color = rl.LIGHTGRAY;
        } else if (i % 5 == 0) {
            color = rl.GRAY;
        }

        rl.DrawLine(ppu * index, ppu * -sizeInt, ppu * index, ppu * sizeInt, color);
        rl.DrawLine(ppu * -index, ppu * -sizeInt, ppu * -index, ppu * sizeInt, color);
        rl.DrawLine(ppu * sizeInt, ppu * -index, ppu * -sizeInt, ppu * -index, color);
        rl.DrawLine(ppu * sizeInt, ppu * index, ppu * -sizeInt, ppu * index, color);
    }
}