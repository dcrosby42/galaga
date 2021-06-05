module Galaga
  def new_enemy_fleet
    open_struct({
      t: 0.0,
      ships: [
        ["B", 0, 0],
        ["B", 0, 1],
        ["B", 0, 2],
      ],
      spawned: false,
      enemies: [],
      debug: false,
    })
  end

  def new_enemy
    open_struct(
      id: 1,
      sprite: "enemy1",
      mode: :active,
      pos: { x: 0, y: 0 },
      hit_box: { x: 0, y: 0, w: 11, h: 10 },
      collisions: [],
      fire_timer: 1.0,
      missiles_fired: 0,
      missiles: [],
    )
  end

  def update_enemy_fleet(fleet, input)
    fleet.t += input.time.dt

    if !fleet.spawned
      grid_w = 16
      grid_h = 16
      fx = 16
      fy = HeaderHeight + 16

      fleet.ships.each.with_index do |(type, row, col), i|
        e = new_enemy
        e.id = i + 1
        e.pos.x = fx + (col * grid_w)
        e.pos.y = fy + (row * grid_h)

        fleet.enemies << e
      end
      fleet.spawned = true
    end

    fleet.enemies.each do |enemy|
      if !enemy.collisions.empty?
        enemy.mode = :explode
      end

      if enemy.mode == :active
        enemy.fire_timer -= input.time.dt
        if enemy.fire_timer <= 0
          enemy.fire_timer = 1.0
          enemy.missiles_fired += 1
          missile = open_struct(
            id: enemy.missiles_fired,
            pos: { x: enemy.pos.x, y: enemy.pos.y },
            vel: { x: 0, y: MissileSpeed },
            collisions: [],
          )
          enemy.missiles << missile
        end
        enemy.pos.y += 1
        if enemy.pos.y > Height
          enemy.pos.y = 0
        end

        # update hitbox location
        enemy.hit_box.x = enemy.pos.x - 5
        enemy.hit_box.y = enemy.pos.y - 5

        update_missiles enemy.missiles, input
      elsif enemy.mode == :explode
        if !enemy.explosion
          # start the explosion
          # enemy.explosion = open_struct(t: 0, limit: 1.0 / 24 * 5) # ~ four (+1 extra, for safety) frames @ 24 fps
          enemy.explosion = open_struct(t: 0, limit: 1) # ~ four (+1 extra, for safety) frames @ 24 fps
        else
          # update the explosion
          enemy.explosion.t += input.time.dt
          if enemy.explosion.t >= enemy.explosion.limit
            enemy.remove = true
          end
        end
      end
    end

    to_remove = nil
    fleet.enemies.each.with_index do |enemy, i|
      if enemy.remove
        to_remove ||= []
        to_remove << i
      end
    end
    if to_remove
      to_remove.each do |i|
        fleet.enemies.delete_at(i)
      end
    end
  end

  def update_missiles(missiles, input)
    removals = nil
    missiles.each.with_index do |missile, i|
      if missile.collisions.length > 0
        # missile hit something
        removals ||= []
        removals << i
      else
        missile.pos.y += missile.vel.y * input.time.dt
        missile.pos.x += missile.vel.x * input.time.dt
        if missile.pos.y < HeaderHeight || missile.pos.y > Height
          # missile out of range; mark for deletion
          removals ||= []
          removals << i
        end
      end
    end
    removals && removals.each do |i|
      missiles.delete_at i
    end
  end

  def draw_enemy_fleet(g, fleet)
    fleet.enemies.each do |enemy|
      draw_enemy g, fleet, enemy
    end
  end

  def draw_enemy(g, fleet, enemy)
    if enemy.mode == :active
      flap_rate = 1.0
      fr = 6 + ((fleet.t * flap_rate) % 2) # 6 is the first of two upright flap frames
      g << Draw::Sprite.new(name: enemy.sprite, x: enemy.pos.x, y: enemy.pos.y, z: Layer.enemy, frame: fr)

      if fleet.debug
        x = enemy.pos.x
        y = enemy.pos.y
        z = Layer.enemy_debug
        c = Gosu::Color::CYAN
        c = Gosu::Color::RED if !enemy.collisions.empty?

        g << Draw::Rect.new(x: x, y: y, z: z, color: c)
        g << Draw::RectOutline.new(x: enemy.hit_box.x, y: enemy.hit_box.y, w: enemy.hit_box.w, h: enemy.hit_box.h, z: z, color: c)
      end

      enemy.missiles.each do |missile|
        g << Draw::Sprite.new(
          name: "bad_missile",
          x: missile.pos.x, y: missile.pos.y, z: Layer.player_missiles,
        )

        #g << Sound::Effect.new(name: "pew", id: missile.id)

        if fleet.debug
          x = missile.pos.x
          y = missile.pos.y
          z = Layer.player_debug
          c = Gosu::Color::YELLOW
          g << Draw::Rect.new(x: x, y: y, z: z, w: 1, h: 1, color: c)
        end
      end
    elsif enemy.mode == :explode
      g << Draw::Animation.new(name: "enemy_splode", t: enemy.explosion.t, x: enemy.pos.x, y: enemy.pos.y)
      g << Sound::Effect.new(name: "waka", id: enemy.id)
    end
  end
end
