const std = @import("std");
const rl = @import("raylib");

var rnd = std.rand.DefaultPrng.init(0);

var is_rnd_initialized = false;

pub const random = struct {
    pub fn getF32() f32 {
        if (!is_rnd_initialized) {
            const seed : u64 = @truncate(@as(u128, @bitCast(std.time.nanoTimestamp())));
            rnd = std.rand.DefaultPrng.init(seed);
            is_rnd_initialized = true;
        }

        return rnd.random().float(f32);
    }

    pub fn getVec2(coef: ?rl.Vector2) rl.Vector2 {
        const x = getF32();
        const y = getF32();

        if (coef) |c| {
            return rl.Vector2 {
               .x = (x - 0.5) * c.x,
               .y = (y - 0.5) * c.y
            }; 
        }

        return rl.Vector2 {.x = x, .y = y};
    }
};

pub const vec2 = struct {
    pub fn scalarMult(vec: rl.Vector2, scalar: f32) rl.Vector2 {
        return rl.Vector2 {.x = vec.x * scalar, .y = vec.y * scalar};
    }
};