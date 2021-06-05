module Galaga
  def update_collisions(state)
    state.enemy_fleet.enemies.each do |enemy|
      enemy.collisions.clear
    end
    state.player.collisions.clear

    # Player missiles v enemies
    state.player.missiles.each do |missile|
      state.enemy_fleet.enemies.each do |enemy|
        if enemy.mode == :active and point_in_rect(missile.pos, enemy.hit_box)
          # HIT!
          enemy.collisions << missile
          missile.collisions << enemy
          state.player.score += 80
        end
      end
    end

    # Enemies v player
    state.enemy_fleet.enemies.each do |enemy|
      if enemy.mode == :active
        if rect_overlap(enemy.hit_box, state.player.hit_box)
          if enemy.collisions.length == 0 && state.player.mode == :active && state.player.collisions.length == 0
            enemy.collisions << state.player
            state.player.collisions << enemy
          end
        end
      end
    end
    # Enemy missiles v player
    player = state.player
    state.enemy_fleet.enemies.each do |enemy|
      enemy.missiles.each do |missile|
        if player.mode == :active and point_in_rect(missile.pos, player.hit_box)
          # HIT!
          player.collisions << missile
          missile.collisions << player
        end
      end
    end
  end

  def point_in_rect(pt, rect)
    pt.x >= rect.x &&
      pt.x <= rect.x + rect.w &&
      pt.y >= rect.y &&
      pt.y <= rect.y + rect.h
  end

  def rect_overlap(r1, r2)
    return r1.x + r1.w >= r2.x && # r1 right edge past r2 left
             r1.x <= r2.x + r2.w && # r1 left edge past r2 right
             r1.y + r1.h >= r2.y && # r1 top edge past r2 bottom
             r1.y <= r2.y + r2.h    # r1 bottom edge past r2 top
  end
end
