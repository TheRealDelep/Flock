const rl = @import("raylib");

pub const Entity =  struct {
    position: rl.Vector2 = rl.Vector2.zero(),
    rotation: f32 = 0,
    is_active: bool = true
};