module Galaga
  PlayerStartX = 100
  PlayerGodMode = false

  def new_player
    open_struct({
      num: 1,
      score: 0,
      total_ships: 3,
      active_ships: 1,
      mode: :active,
      weapons_hot: false,
      pos: { x: PlayerStartX, y: Height - FooterHeight - FighterHeight },
      cruising: {
        mode: :cruising,
        speed: 0,
      },
      hit_box: { x: 0, y: 0, w: 16, h: 16 },
      missiles_fired: 0,
      missiles: [],
      collisions: [],
      invincible: PlayerGodMode,
      debug: false,
    })
  end

  def kill_player(player)
    player.mode = :explode
    player.cruising.mode = :stopping
    player.active_ships = 0
    player.total_ships -= 1
  end

  def revive_player(player)
    player.explosion = nil
    player.mode = :active
    player.cruising.mode = :cruising
    player.active_ships = 1
    player.pos.x = PlayerStartX
  end

  def update_player(player, input)
    if player.mode == :active && !player.collisions.empty?
      kill_player player unless player.invincible
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
        if player.weapons_hot and player.missiles.length < MissileFireLimit
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
      else
        # update the explosion
        player.explosion.t += input.time.dt
        if player.explosion.t >= player.explosion.limit
          # ?
        end
      end
    end

    # Update cruising speed
    begin
      c = player.cruising
      if c.mode == :cruising
        c.speed += FighterCruiseAccel * input.time.dt
        c.speed = StarSpeed if c.speed > StarSpeed
      elsif c.mode == :stopping
        c.speed -= FighterCruiseAccel * input.time.dt
        c.speed = 0 if c.speed < 0
      end
      # (remember: moving "forward" against the starfield means climbing toward -y)
      #c.loc -= c.speed * input.time.dt
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
      g << Draw::Sprite.new(name: "fighter", x: player.pos.x, y: player.pos.y, z: Layer.player)

      if player.debug
        x = player.pos.x
        y = player.pos.y
        z = Layer.player_debug
        c = Gosu::Color::YELLOW
        g << Draw::Rect.new(x: x, y: y, z: z, color: c)
        g << Draw::RectOutline.new(x: player.hit_box.x, y: player.hit_box.y, w: player.hit_box.w, h: player.hit_box.h, z: z, color: c)
      end

      player.missiles.each do |missile|
        g << Draw::Sprite.new(
          name: "missile",
          x: missile.pos.x, y: missile.pos.y, z: Layer.player_missiles,
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
