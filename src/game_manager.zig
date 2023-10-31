pub const GameState = enum {
    running,
    paused
};

pub var game_state = GameState.paused;