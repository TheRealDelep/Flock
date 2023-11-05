const std = @import("std");
const rl = @import("raylib");

const settings = @import("../settings.zig");
const helper = @import("../helper.zig");

pub const ShapeTag = enum {
    line,
    rectangle,
    circle
};

pub const Shape = struct {
    origin: rl.Vector2,
    color: rl.Color,

    kind: union (ShapeTag) {
        line: rl.Vector2,
        rectangle: struct { width: f32, height: f32 },
        circle: f32
    }
};

var debug_shapes : std.ArrayList(Shape) = undefined;

pub fn init(allocator: std.mem.Allocator) void {
    debug_shapes = std.ArrayList(Shape).init(allocator);
}

pub fn drawShape(shape: Shape) void {
    debug_shapes.append(shape) catch {
        std.debug.print("Error while allocating memory", .{});
    };
}

pub fn draw() void {
    for (debug_shapes.items) |shape| {
        switch (shape.kind) {
            ShapeTag.line => |dest| rl.DrawLineEx(
                helper.vec2.scalarMult(shape.origin, settings.ppu_f),
                helper.vec2.scalarMult(dest, settings.ppu_f),
                2, shape.color
            ),
            ShapeTag.rectangle => |size| rl.DrawRectangleLines(
                @as(i32, @intFromFloat(shape.origin.x * settings.ppu_f)), 
                @as(i32, @intFromFloat(shape.origin.y * settings.ppu_f)), 
                @as(i32, @intFromFloat(size.width * settings.ppu_f)), 
                @as(i32, @intFromFloat(size.height * settings.ppu_f)), 
                shape.color
            ),
            ShapeTag.circle => |radius| rl.DrawCircleLines(
                @as(i32, @intFromFloat(shape.origin.x * settings.ppu_f)), 
                @as(i32, @intFromFloat(shape.origin.y * settings.ppu_f)), 
                radius * settings.ppu_f,
                shape.color
            )
        }    
    }

    debug_shapes.clearRetainingCapacity();
}