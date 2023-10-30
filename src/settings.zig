const Resolution = struct {
    Width: u16,
    Height: u16,
};

pub var resolution = Resolution{ .Width = 800, .Height = 450 };

pub const ppu: u8 = 64;
pub const ppu_f: f32 = @floatFromInt(ppu);
