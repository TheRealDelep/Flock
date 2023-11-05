const rl = @import("raylib");

pub const Scene = struct {
    initFn: ?*const fn (camera: *rl.Camera2D) void = null,
    updateFn: ?*const fn () void = null,
    camDrawFn: ?*const fn () void = null,
    screenDrawFn: ?*const fn () void = null,
    deinitFn: ?*const fn () void = null
};