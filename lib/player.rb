module Galaga
  def new_player
    {
      num: 1,
      score: 0,
      mode: :active,
      pos: { x: 100, y: Height - 30 },
      cruising: { mode: :cruising, loc: 0, speed: 0, max_speed: 100, accel: 150 },
      hit_box: { x: 0, y: 0, w: 15, h: 15 },
      missiles_fired: 0,
      missiles: [],
      collisions: [],
      debug: false,
    }
  end

  def update_player(player, input)
    if !player.collisions.empty?
      player.mode = :explode
    end

    if player.mode == :active
      # Left/Right motion
      if input.keyboard.down?(LeftButton)
        player.pos.x -= FighterSpeed * input.time.dt
      elsif input.keyboard.down?(RightButton)
        player.pos.x += FighterSpeed * input.time.dt
      end
      # constrain motion:
      if player.pos.x > Width - 16
        player.pos.x = Width - 16
      elsif player.pos.x < 0
        player.pos.x = 0
      end

      if input.keyboard.pressed?(Fire1Button)
        if player.missiles.length < MissileFireLimit
          # Fire missile
          player.missiles_fired += 1
          missile = open_struct(
            id: player.missiles_fired,
            pos: { x: player.pos.x + 7.5, y: player.pos.y },
            vel: { x: 0, y: -MissileSpeed },
            collisions: [],
          )
          player.missiles << missile
        end
      end
    elsif player.mode == :explode
      if !player.explosion
        # start the explosion
        player.explosion = open_struct(t: 0, limit: 1)
        player.cruising.mode = :stopping
      else
        # update the explosion
        player.explosion.t += input.time.dt
        if player.explosion.t >= player.explosion.limit
          player.remove = true
        end
      end
    end

    # Update starfield cruising loc
    begin
      c = player.cruising
      if c.mode == :cruising
        c.speed += c.accel * input.time.dt
        c.speed = c.max_speed if c.speed > c.max_speed
      elsif c.mode == :stopping
        c.speed -= c.accel * input.time.dt
        c.speed = 0 if c.speed < 0
      end
      # (remember: moving "forward" against the starfield means climbing toward -y)
      c.loc -= c.speed * input.time.dt
    end

    # update hitbox location
    player.hit_box.x = player.pos.x
    player.hit_box.y = player.pos.y

    update_missiles(player.missiles, input)
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

  def draw_player(g, player)
    if player.mode == :active
      g << Draw::Image.new(path: "fighter_01.png", x: player.pos.x, y: player.pos.y, z: Layer.player)

      if player.debug
        x = player.pos.x
        y = player.pos.y
        z = Layer.player_debug
        c = Gosu::Color::YELLOW
        g << Draw::Rect.new(x: x, y: y, z: z, color: c)
        # g << Draw::RectOutline.new(x: x, y: y, w: 15, h: 15, z: z, color: c)
        g << Draw::RectOutline.new(x: player.hit_box.x, y: player.hit_box.y, w: player.hit_box.w, h: player.hit_box.h, z: z, color: c)
      end

      player.missiles.each do |missile|
        g << Draw::Image.new(
          path: "missile_01.png",
          x: missile.pos.x, y: missile.pos.y, z: Layer.player_missiles,
          center_x: 0.5, center_y: 0,
        )

        g << Sound::Effect.new(name: "pew", id: missile.id)

        if player.debug
          x = missile.pos.x
          y = missile.pos.y
          z = Layer.player_debug
          c = Gosu::Color::YELLOW
          g << Draw::Rect.new(x: x, y: y, z: z, w: 1, h: 1, color: c)
        end
      end
    elsif player.mode == :explode
      g << Draw::Animation.new(name: "player_splode",
                               t: player.explosion.t,
                               x: player.pos.x,
                               y: player.pos.y)
      g << Sound::Effect.new(name: "boom", id: player.num)
    end
  end
end
