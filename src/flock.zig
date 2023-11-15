const std = @import("std");
const rl = @import("raylib");
const game_manager = @import("game_manager.zig");

const agent = @import("./entities/agent.zig");
const bullet_pool = @import("./bullet_pool.zig");
const Agent = agent.Agent;
const player = @import("./entities/player.zig");
const debug = @import("./debug/debug_drawer.zig");

const bullet_danger_zone_radius: f32 = 2;
const lazer_danger_zone_radius: f32 = 6;
const grenade_danger_zone_radius: f32 = 10;

const bullet_danger_zone_lifespan: f32 = 0.5;
const lazer_danger_zone_lifespan: f32 = 2;
const grenade_danger_zone_lifespan: f32 = 3;

const bullet_danger_zone_shrink_speed = bullet_danger_zone_radius / bullet_danger_zone_lifespan;
const lazer_danger_zone_shrink_speed = lazer_danger_zone_radius / lazer_danger_zone_lifespan;
const grenade_danger_zone_shrink_speed = grenade_danger_zone_radius / grenade_danger_zone_lifespan;

pub const DangerZoneTag = enum {
    bullet,
    laser,
    grenade 
};

pub const DangerZone = struct {
    begin: rl.Vector2 = rl.Vector2.zero(),
    end: rl.Vector2 = rl.Vector2.zero(),
    is_active: bool = false,
    radius: f32 = 0,
    kind: DangerZoneTag = DangerZoneTag.bullet
};

pub const Flock = struct {
    target: rl.Vector2 = rl.Vector2.zero(),

    cohesion_radius: f32 = 8,
    avoidance_radius: f32 = 1,

    cohesion_factor: f32 = 1,
    avoidance_factor: f32 = 2.5,
    alignment_factor: f32 = 1.5,
    target_factor: f32 = 1.5,
    bounds_avoidance_factor: f32 = 3,
    normal_acceleration_factor: f32 = 0.5,
    danger_avoidance_factor: f32 = 0.5,
    center_attraction_factor: f32 = 0.25,

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

            var new_zone: ?DangerZone = null;

            bullets: for (self.bullet_pool.bullets) |*bullet| {
                if (bullet.*.entity.is_active) {
                    if (current.hasPoint(bullet.*.entity.position)) {
                        current.entity.is_active = false;
                        bullet.entity.is_active = false;
                        
                        new_zone = DangerZone {
                            .begin = current.entity.position,
                            .end = current.entity.position,
                            .is_active = true,
                            .radius = bullet_danger_zone_radius,
                            .kind = DangerZoneTag.bullet
                        };
                        break :bullets;
                    }
                }
            }

            if (new_zone == null and player.is_grenade_active and current.hasPoint(player.grenade_position)) {
                current.entity.is_active = false;
                for (self.agents) |*a| {
                    if (a.*.entity.position.distanceTo(player.grenade_position) <= player.grenade_radius) {
                        a.*.entity.is_active = false;
                    }
                }

                new_zone = DangerZone {
                    .is_active = true,
                    .begin = player.grenade_position,
                    .end = player.grenade_position,
                    .radius = grenade_danger_zone_radius,
                    .kind = DangerZoneTag.grenade
                };

                player.is_grenade_active = false;
            }

            if (new_zone == null and player.is_lazer_active) {
                for (self.agents) |*a| {
                    const dir = rl.Vector2Rotate(.{.x = 0, .y = 1}, player.entity.rotation);
                    const begin = player.entity.position; 
                    const end = begin.add(dir.scale(player.lazer_length));
                    const normal = rl.Vector2 { .x = dir.y, .y = -dir.x };

                    const closest_point = findClosestPointOnLine(current.entity.position, begin, end);
                    const dir_to_closest = closest_point.sub(current.entity.position).normalize();
                    const dist = current.entity.position.distanceTo(closest_point);

                    if (dist > player.lazer_radius or 
                        (rl.Vector2Equals(dir_to_closest, normal) !=  1 and rl.Vector2Equals(dir_to_closest, normal.scale(-1)) != 1)){
                    }

                    a.*.entity.is_active = false;
                    player.is_lazer_active = false;
                }
            }

            if (new_zone) |z| {
                danger: for (0..self.danger_zones_pool.len - 1) |index| {
                    const c_zone = self.danger_zones_pool[index];

                    if (index == self.danger_zones_pool.len - 1 and c_zone.is_active) {
                        @panic("No more danger zones available");
                    }

                    if (!c_zone.is_active) {
                        self.danger_zones_pool[index] = z;
                        break :danger;
                    } 
                }

            }

            // Danger avoidance
            var danger_avoidance_count: f32 = 0;
            var danger_avoidance = rl.Vector2.zero();

            for (self.danger_zones_pool) |zone| {
                if (!zone.is_active) {
                    continue;
                }

                if (zone.kind == DangerZoneTag.laser) {
                    const dir = zone.end.sub(zone.begin).normalize();
                    const normal = rl.Vector2 { .x = dir.y, .y = -dir.x };

                    const closest_point = findClosestPointOnLine(current.entity.position, zone.begin, zone.end);
                    const dir_to_closest = closest_point.sub(current.entity.position).normalize();
                    const dist = current.entity.position.distanceTo(closest_point);

                    if (dist > zone.radius) {
                        continue;
                    }

                    if (rl.Vector2Equals(normal, dir_to_closest) != 1 and rl.Vector2Equals(normal.scale(-1), dir_to_closest) != 1) {
                        continue;
                    }

                    danger_avoidance_count += 1;
                    danger_avoidance = danger_avoidance.add((dir_to_closest.scale(-1 / dist)));
                } else {
                    const dist = current.entity.position.distanceTo(zone.begin);
                    if (dist <= zone.radius) {
                        const dir = zone.begin.sub(current.entity.position);
                        danger_avoidance_count += 1;
                        danger_avoidance = danger_avoidance.add(dir.scale(-1 / dist));
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
                if (current_index == other_index or !other.entity.is_active) {
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
            const center_attraction = steerToward(current.velocity, current.entity.position.scale(-1)).scale(rl.GetFrameTime());

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
                    .add(danger_avoidance.scale(self.danger_avoidance_factor))
                    .add(center_attraction.scale(self.center_attraction_factor));

                current.velocity = rl.Vector2ClampValue(current.velocity, -agent.max_speed, agent.max_speed);
                current.update();
            }
        }

        for (0..self.danger_zones_pool.len - 1) |index| {
            var zone = self.danger_zones_pool[index];
            if (!zone.is_active) {
                continue;
            }

            const shrink_speed = switch (zone.kind) {
                DangerZoneTag.bullet => bullet_danger_zone_shrink_speed,
                DangerZoneTag.grenade => grenade_danger_zone_shrink_speed,
                DangerZoneTag.laser => lazer_danger_zone_shrink_speed
            };

            const radius = zone.radius - (shrink_speed * rl.GetFrameTime());
            self.danger_zones_pool[index] = DangerZone {
                .radius = radius,
                .is_active = radius > 0,
                .begin = zone.begin,
                .end = zone.end
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

fn findClosestPointOnLine(point: rl.Vector2, line_start: rl.Vector2, line_end: rl.Vector2) rl.Vector2 {
    const line = line_end.sub(line_start);
    const len = line.length();
    const dir = line.normalize();

    const v = point.sub(line_start);
    const dot = std.math.clamp(v.dot(dir), 0, len);
    return line_start.add(dir.scale(dot));
}