const rl = @import("raylib");
const game_manager = @import("game_manager.zig");

const agent = @import("agent.zig");
const Agent = agent.Agent;

pub const Flock = struct {
    target: rl.Vector2 = rl.Vector2.zero(),

    cohesion_radius: f32 = 5,
    avoidance_radius: f32 = 1,

    cohesion_factor: f32 = 1,
    avoidance_factor: f32 = 2.5,
    alignment_factor: f32 = 2,
    target_factor: f32 = 1,
    bounds_avoidance_factor: f32 = 10,
    normal_acceleration_factor: f32 = 0.5,

    level_size: f32 = 0,

    agents: []Agent = undefined,
    debug_infos: ?agent.AgentDebugInfos = null,

    pub fn update(self: *Flock) void {
        if (self.debug_infos) |*infos| {
            infos.in_cohesion_range.clearRetainingCapacity();
            infos.in_avoidance_range.clearRetainingCapacity();
        }

        for (self.agents, 0..) |*current, current_index| {
            var attraction_count: f32 = 0;
            var separation_count: f32 = 0;

            var separation = rl.Vector2.zero();
            var cohesion = rl.Vector2.zero();
            var alignment = rl.Vector2.zero();
            var center_of_mass = rl.Vector2.zero();
            var bounds_avoidance = rl.Vector2.zero();

            for (self.agents, 0..) |*other, other_index| {
                if (current_index == other_index) {
                    continue;
                }

                const dist = current.position.distanceTo(other.position);

                // Ignore agent behind
                const dot = rl.Vector2DotProduct(
                    current.velocity.normalize(), 
                    other.position.sub(current.position).normalize()
                );

                if (dot < -0.75) {
                    continue;
                }

                // Cohesion and Alignment
                if (dist < self.cohesion_radius) {
                    if (self.debug_infos) |*infos| {
                        if (infos.index == current_index) {
                            infos.*.in_cohesion_range.append(other) catch @panic("WTF!");
                        }
                    }
                    attraction_count += 1.0;
                    center_of_mass = center_of_mass.add(other.position);
                    alignment = alignment.add(other.velocity);
                }

                // Separation
                if (dist < self.avoidance_radius) {
                    if (self.debug_infos) |*infos| {
                        if (infos.index == current_index) {
                            infos.*.in_avoidance_range.append(other) catch @panic("WTF!");
                        }
                    }
                    separation_count += 1;
                    const dir = current.position.sub(other.position).normalize();
                    separation = separation.add((dir.scale(1 / dist)));
                }
            }

            var cohesion_target = rl.Vector2.zero();
            if (attraction_count > 0) {
                cohesion_target = center_of_mass.scale(1 / attraction_count);
                cohesion = steerToward(current.velocity, cohesion_target).scale(rl.GetFrameTime());
                alignment = steerToward(current.velocity, alignment.scale(1 / attraction_count)).scale(rl.GetFrameTime());
            }

            var separation_target = rl.Vector2.zero();
            if (separation_count > 0) {
                separation_target = separation.scale(1 / separation_count);
                separation = steerToward(current.velocity, separation_target).scale(rl.GetFrameTime());
            }

            const dist_from_center = current.position.distanceTo(rl.Vector2.zero());

            if (dist_from_center > self.level_size - self.avoidance_radius) {
                bounds_avoidance = steerToward(current.velocity, current.position.scale(-1)).scale(rl.GetFrameTime());
            }

            const target_attraction = steerToward(current.velocity, self.target.sub(current.position)).scale(rl.GetFrameTime());

            if (self.debug_infos) |*infos| {
                if (infos.index == current_index) {
                    infos.*.cohesion_force = cohesion;
                    infos.*.alignment_force = alignment;
                    infos.*.separation_force = separation;
                    infos.*.bounds_avoidance_force = bounds_avoidance;
                    infos.*.cohesion_target = if (attraction_count > 0) cohesion_target else null;
                    infos.*.separation_target = if (separation_count > 0) separation_target else null;
                }
            }

            // Apply forces and move agent 
            if (game_manager.game_state == game_manager.GameState.running) {
                const forward = rl.Vector2Rotate(rl.Vector2 {.x = 0, .y = 1}, current.rotation * rl.DEG2RAD);
                current.velocity = current.velocity
                    .add(separation.scale(self.avoidance_factor))
                    .add(alignment.scale(self.alignment_factor))
                    .add(cohesion.scale(self.cohesion_factor))
                    .add(bounds_avoidance.scale(self.bounds_avoidance_factor))
                    .add(target_attraction.scale(self.target_factor))
                    .add(forward.scale(agent.base_acceleration * self.normal_acceleration_factor).scale(rl.GetFrameTime()));

                current.velocity = rl.Vector2ClampValue(current.velocity, -agent.max_speed, agent.max_speed);
                current.update();
            }
        }
    }

    pub fn draw(self: *Flock) void {
        for (self.agents) |*a| {
            a.draw();
        }
    }
};

fn steerToward(velocity: rl.Vector2, target: rl.Vector2) rl.Vector2 {
    return rl.Vector2Clamp(
        target
            .normalize()
            .scale(agent.max_speed)
            .sub(velocity), 
        agent.max_acceleration_vec.scale(-1), 
        agent.max_acceleration_vec
    );
}