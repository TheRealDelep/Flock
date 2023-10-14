const std = @import("std");

pub const Random = struct {
    pub fn get_f32() f32 {
        const seed : u64 = @truncate(@as(u128, @bitCast(std.time.nanoTimestamp())));
        var prng = std.rand.DefaultPrng.init(seed);
        return prng.random().float(f32);
    }
};