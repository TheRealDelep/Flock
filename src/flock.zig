const std = @import("std");
const rl = @import("raylib");
const game_manager = @import("game_manager.zig");

const agent = @import("./entities/agent.zig");
const bullet_pool = @import("./bullet_pool.zig");
const Agent = agent.Agent;

const danger_zone_initial_radius: f32 = 5;
const danger_zone_lifespan: f32 = 2;
const danger_zone_shrink_speed = danger_zone_initial_radius / danger_zone_lifespan;

pub const DangerZone = struct {
    position: rl.Vector2 = rl.Vector2.zero(),
    is_active: bool = false,
    radius: f32 = 0
};

pub const Flock = struct {
    target: rl.Vector2 = rl.Vector2.zero(),

    cohesion_radius: f32 = 8,
    avoidance_radius: f32 = 1.25,

    cohesion_factor: f32 = 0.75,
    avoidance_factor: f32 = 2.5,
    alignment_factor: f32 = 1.5,
    target_factor: f32 = 0,
    bounds_avoidance_factor: f32 = 3,
    normal_acceleration_factor: f32 = 0.5,
    danger_avoidance_factor: f32 = 2,

    level_bounds: rl.Rectangle,

    agents: []Agent,
    debug_infos: ?agent.AgentDebugInfos = null,

    bullet_pool: *bullet_pool.BulletPool = undefined,
    danger_zones_pool: [200]DangerZone = [_]DangerZone {DangerZone {}} ** 200,

    pub fn update(self: *Flock) void {
        if (self.debug_infos) |*infos| {
            infos.in_cohesion_range.clearRetainingCapacity();
            infos.in_avoidance_range.clearRetainingCapacity();
        }

        for (self.agents, 0..) |*current, current_index| {
            if (!current.entity.is_active) {
                continue;
            }

            bullets: for (self.bullet_pool.bullets) |*bullet| {
                if (bullet.*.entity.is_active) {
                    if (current.hasPoint(bullet.*.entity.position)) {
                        current.entity.is_active = false;
                        bullet.entity.is_active = false;

                        for (0..self.danger_zones_pool.len - 1) |index| {
                            const zone = self.danger_zones_pool[index];
                            if (!zone.is_active) {
                                self.danger_zones_pool[index] = DangerZone {
                                    .is_active = true,
                                    .position = current.entity.position,
                                    .radius = danger_zone_initial_radius
                                };

                                break :bullets;
                            } 
                        }

                        @panic("No more danger zones available");
                    }
                }
            }

            // Danger avoidance
            var danger_avoidance_count: f32 = 0;
            var danger_avoidance = rl.Vector2.zero();

            for (self.danger_zones_pool) |zone| {
                const dist = current.entity.position.distanceTo(zone.position);
                if (zone.is_active) {
                    if (dist <= zone.radius) {
                        danger_avoidance_count += 1;
                        const dir = current.entity.position.sub(zone.position).normalize();
                        danger_avoidance = danger_avoidance.add((dir.scale(1 / dist)));
                    }
                }
            }

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

                const dist = current.entity.position.distanceTo(other.entity.position);

                // Ignore agent behind
                const dot = rl.Vector2DotProduct(
                    current.velocity.normalize(), 
                    other.entity.position.sub(current.entity.position).normalize()
                );
                _ = dot;

                // if (dot < -0.5) {
                    // continue;
                // }

                // Cohesion and Alignment
                if (dist < self.cohesion_radius) {
                    if (self.debug_infos) |*infos| {
                        if (infos.index == current_index) {
                            infos.*.in_cohesion_range.append(other) catch @panic("WTF!");
                        }
                    }
                    attraction_count += 1.0;
                    center_of_mass = center_of_mass.add(other.entity.position);
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
                    const dir = current.entity.position.sub(other.entity.position).normalize();
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

            // DANGER!!!
            if (danger_avoidance_count > 0) {
                danger_avoidance = steerToward(current.velocity, danger_avoidance.scale(1 / danger_avoidance_count).scale(rl.GetFrameTime()));
            }

            // Bounds avoidance
            const nearest_bound = findNearestPointOnBounds(self.level_bounds, current.entity.position);
            const dist_from_bound = current.entity.position.distanceTo(nearest_bound);

            if (dist_from_bound < 10) {
                var normal = current.entity.position.sub(nearest_bound);
                _ = normal;
                bounds_avoidance = steerToward(current.velocity, current.entity.position.scale(-1))
                    //.scale(std.math.clamp(1 / dist_from_bound, 0.5, 20))
                    .scale(rl.GetFrameTime());
                //bounds_avoidance = steerToward(current.velocity, bounds_avoidance).scale(rl.GetFrameTime());
            }

            const target_attraction = steerToward(current.velocity, self.target.sub(current.entity.position)).scale(rl.GetFrameTime());

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
                const forward = rl.Vector2Rotate(rl.Vector2 {.x = 0, .y = 1}, current.entity.rotation * rl.DEG2RAD);
                current.velocity = current.velocity
                    .add(separation.scale(self.avoidance_factor))
                    .add(alignment.scale(self.alignment_factor))
                    .add(cohesion.scale(self.cohesion_factor))
                    .add(bounds_avoidance.scale(self.bounds_avoidance_factor))
                    .add(target_attraction.scale(self.target_factor))
                    .add(forward.scale(agent.base_acceleration * self.normal_acceleration_factor).scale(rl.GetFrameTime()))
                    .add(danger_avoidance.scale(self.danger_avoidance_factor));

                current.velocity = rl.Vector2ClampValue(current.velocity, -agent.max_speed, agent.max_speed);
                current.update();
            }
        }

        for (0..self.danger_zones_pool.len - 1) |index| {
            var zone = self.danger_zones_pool[index];
            if (!zone.is_active) {
                continue;
            }

            const radius = zone.radius - (danger_zone_shrink_speed * rl.GetFrameTime());
            self.danger_zones_pool[index] = DangerZone {
                .radius = radius,
                .is_active = radius > 0,
                .position = zone.position
            };
        }
    }

    pub fn draw(self: *Flock) void {
        for (self.agents) |*a| {
            if (a.entity.is_active) {
                a.draw();
            }
        }
    }

    pub fn drawScreen(self: *Flock) void {
        _ = self;
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

fn findNearestPointOnBounds(rect: rl.Rectangle, point: rl.Vector2) rl.Vector2 {
    const is_inside = rl.CheckCollisionPointRec(point.add(rl.Vector2 { .x =  rect.width / 2, .y = rect.height / 2}), rect);

    if (!is_inside) {
        return rl.Vector2 {
            .x = @max(rect.x - rect.width / 2, @min(point.x, rect.x + rect.width / 2)),
            .y = @max(rect.y - rect.height / 2, @min(point.y, rect.y + rect.height / 2))
        };
    }

    const left = rl.Vector2 { .x = rect.x - rect.width / 2, .y = point.y };
    const right = rl.Vector2 { .x = rect.x + rect.width / 2, .y = point.y };
    const bottom = rl.Vector2 { .x = point.x, .y = rect.y - rect.height / 2 };
    const top = rl.Vector2 { .x = point.x, .y = rect.y + rect.height / 2 };

    var dist_to_left = left.distanceTo(point);
    var dist_to_right = right.distanceTo(point);
    var dist_to_bottom = bottom.distanceTo(point);
    var dist_to_top = top.distanceTo(point);

    var closest = left;
    var dist = dist_to_left;

    if (dist_to_right < dist) {
        closest = right;
        dist = dist_to_right;
    }

    if (dist_to_bottom < dist) {
        closest = bottom;
        dist = dist_to_bottom;
    }

    if (dist_to_top < dist) {
        closest = top;
        dist = dist_to_top;
    }

    return closest;
}