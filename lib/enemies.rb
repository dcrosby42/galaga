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
        enemy.pos.y += 1
        if enemy.pos.y > Height
          enemy.pos.y = 0
        end

        # update hitbox location
        enemy.hit_box.x = enemy.pos.x - 5
        enemy.hit_box.y = enemy.pos.y - 5
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
    elsif enemy.mode == :explode
      g << Draw::Animation.new(name: "enemy_splode", t: enemy.explosion.t, x: enemy.pos.x, y: enemy.pos.y)
      g << Sound::Effect.new(name: "waka", id: enemy.id)
    end
  end
end
