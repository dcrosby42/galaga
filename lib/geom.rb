module Geom
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
