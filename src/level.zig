const std = @import("std");
const rl = @import("raylib");
const helper = @import("helper.zig");
const settings = @import("settings.zig");

const Agent = @import("agent.zig").Agent;

pub const size: f32 = 50;
pub const flock_size = 2;

var flock: [flock_size]Agent = undefined;

pub fn init() void {
    // for (&flock) |*agent| {
    //     const coef = (size - 1) * 2;
    //     const position = helper.Random.get_vec2(rl.Vector2 {.x = coef, .y = coef});
    //     const rotation = helper.Random.get_f32() * 360.0;

    //     agent.* = Agent.new(position, rotation, null);
    // }

    flock[0] = Agent.new(rl.Vector2{ .x = 0, .y = -2}, 45, null);
    flock[1] = Agent.new(rl.Vector2{ .x = 0, .y = -5}, -45, null);
}

pub fn update() void {
    for (&flock) |*self| {
        defer self.update();

        var bird_count: f32 = 0;
        var center_of_mass = rl.Vector2.zero();

        for (&flock) |*other| {
            if (self == other) {
                continue;
            }

            if (rl.Vector2.distanceTo(self.position, other.position) < 5) {
                center_of_mass = center_of_mass.add(other.position);
                bird_count += 1.0;
            }
        }  

        if (bird_count > 0 ) {
            self.lookAt(center_of_mass);
        }
    }
}

pub fn draw() void {
    drawGrid();
    for (&flock) |*agent|{
        agent.draw();
    }
}

fn drawGrid() void {
    const ppu: i32 = @intCast(settings.ppu); 
    const sizeInt: i32 = @intFromFloat(size);

    for (0..size + 1) |i| {
        const index: i32 = @intCast(i);

        var color = rl.DARKGRAY;
        if (i % 10 == 0) {
            color = rl.LIGHTGRAY;
        } else if (i % 5 == 0){
            color = rl.GRAY; 
        }

        rl.DrawLine(ppu * index, ppu * -sizeInt, ppu * index, ppu * sizeInt, color);
        rl.DrawLine(ppu * -index, ppu * -sizeInt, ppu * -index, ppu * sizeInt, color);
        rl.DrawLine(ppu * sizeInt, ppu * -index, ppu * -sizeInt, ppu * -index, color);
        rl.DrawLine(ppu * sizeInt, ppu * index, ppu * -sizeInt, ppu * index, color);
    }
}