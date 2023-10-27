const std = @import("std");
const rl = @import("raylib");

var rnd = std.rand.DefaultPrng.init(0);

var is_rnd_initialized = false;

pub const Random = struct {
    pub fn get_f32() f32 {
        if (!is_rnd_initialized) {
            const seed : u64 = @truncate(@as(u128, @bitCast(std.time.nanoTimestamp())));
            rnd = std.rand.DefaultPrng.init(seed);
            is_rnd_initialized = true;
        }

        return rnd.random().float(f32);
    }

    pub fn get_vec2(coef: ?rl.Vector2) rl.Vector2 {
        const x = get_f32();
        const y = get_f32();

        if (coef) |c| {
            return rl.Vector2 {
               .x = (x - 0.5) * c.x,
               .y = (y - 0.5) * c.y
            }; 
        }

        return rl.Vector2 {.x = x, .y = y};
    }
};