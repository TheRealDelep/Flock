pub const GameState = enum {
    running,
    paused,
    gameover
};

pub var game_state = GameState.paused;