const Resolution = struct {
    Width: u16,
    Height: u16,
};

pub var resolution = Resolution {
    .Width = 1280,
    .Height = 720
};

pub const ppu: u8 = 64;