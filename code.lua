-- celeste2
-- exok games

level_index = 0
level_intro = 0
level_offset = 0

standalone = false
code = {}
hearts = {false, false, false}
fresh_save = true

-- sprite flags
-- 0: if sprite should be drawn
-- 1: if sprite is solid
-- 7: if level color palette should be used

function offset(i) 
  if i == 2 then
    return {8*16, -8*16}
  elseif i == 3 then
    return {-8*2*16, 8*16}
  elseif i == 4 then
    return {-8*3*16, -8*(2*16+13)}
  elseif i == 5 then
    return {0, -8*3*16}
  else
      return {0,0}
  end
end

function tablelength(T)
  local count = 0
  for _ in pairs(T) do count += 1 end
  return count
end

star_effects = {}
foreach({72,252,1222,1285,1286,1287,1348,1349,1351,1352,1413,1414,1415,1478,1437,2645,2155,2218,2219,2220,2283,3143,3878},function (x) star_effects[x] = 1 end)
--[[star_effects[8+64] = 1
star_effects[60+3*64] = 1
star_effects[6+19*64] = 1
star_effects[5+20*64] = 1
star_effects[6+20*64] = 1
star_effects[7+20*64] = 1
star_effects[4+21*64] = 1
star_effects[5+21*64] = 1
star_effects[7+21*64] = 1
star_effects[8+21*64] = 1
star_effects[5+22*64] = 1
star_effects[6+22*64] = 1
star_effects[7+22*64] = 1
star_effects[6+23*64] = 1
star_effects[29+22*64] = 1
star_effects[21+41*64] = 1
star_effects[43+33*64] = 1
star_effects[42+34*64] = 1
star_effects[43+34*64] = 1
star_effects[44+34*64] = 1
star_effects[43+35*64] = 1
star_effects[7+49*64] = 1
star_effects[38+60*64] = 1
--]]

function game_start()

  -- reset state
  snow = {}
  comet = nil
--  clouds = {}
  as = {}
  bs = {}
  freeze_time = 0
  frames = 0
  seconds = 0
  minutes = 0
  shake = 0
  sfx_timer = 0
  berry_count = 0
  death_count = 0
  collected = {}
  camera_x = 0
  camera_y = 0
  show_score = 0
  titlescreen_flash = nil
  won_dir = 0
  slowdown_amount = 0
  slowdown_timer = 0
  -- Manually update if things are repositioned.
  local s = {
    {28,29,2},
    {6,47,4},
    {33,28,5},
    {39,48,4},
    {24,13,2},
    {28,35,5},
    {35,31,4},
    {77,23,5},
    {20,19,3},
    {44,2,2},
    {55,26,5},
    {52,5,2},
    {14,2,3},
  }
  local l = {
    {5,1},
    {5,10},
    {12,10},
    {12,8},
    {11,10},
    {11,8},
    {3,11},
    {6,3},
    {6,5},
    {6,7},
    {5,4},
    {2,7},
    {2,4},
    {13,4},
    {13,9},
    {4,7},
  }

  stars = {}
  lines = {}

  for k, v in ipairs(s) do
    stars[id(v[1],v[2],v[3])] = k
  end

  for _, v in ipairs(l) do
    local i1 = id(s[v[1]][1], s[v[1]][2], s[v[1]][3])
    local i2 = id(s[v[2]][1], s[v[2]][2], s[v[2]][3])
    local x1 = s[v[1]][1]*8
    local y1 = s[v[1]][2]*8
    local x2 = s[v[2]][1]*8
    local y2 = s[v[2]][2]*8
    local offset1 = offset(s[v[1]][3])
    local offset2 = offset(s[v[2]][3])
    lines[#lines+1] = {{x1,y1,offset1[1],offset1[2]}, {x2,y2,offset2[1],offset2[2]}}
  end

  TIME = 0.0
  LAST_TIME = 0.0

  -- uncomment to clear save data
--  for i = 0, 15, 1 do
--    dset(i, 0)
--  end

  -- loading save data
  for i = 0, 12 do
    if dget(i) != 0 then
      collected[dget(i)] = true
      fresh_save = false
    end
  end
  for i = 0, 2 do
    if dget(i+13) != 0 then
      hearts[i+1] = true
      fresh_save = false
    end
  end

  for i=0,25 do
    snow[i] = { x = rnd(132), y = rnd(132) }
--    clouds[i] = { x = rnd(132), y = rnd(132), s = 16 + rnd(32) }
  end

  -- goto titlescreen or level
  if level_index == 0 then
    --current_music = 38
    --music(current_music)
  else
    goto_level(0, level_index)
  end
end

function _init()
  cartdata("beep_arcade")
  srand(1) -- for predictable noise
  game_start()
end

function _update()

  poke(0x5f30, 1)

  -- Sync data with server
  for i = 0, 12 do
    address = 0x5f80+2*i
    if dget(i) != 0 then
      poke2(address, dget(i))
    else
      dset(i, peek2(address))
      if dget(i) != 0 then
        collected[dget(i)] = true
      end
    end
  end

  -- titlescreen
  if level_index == 0 then
    if titlescreen_flash then
      titlescreen_flash-= 1
      if titlescreen_flash < -30 then goto_level(0, 1) end
    elseif btn(4) or btn(5) then
      titlescreen_flash = 50
      sfx(22, 3)
    end

  -- level intro card
  elseif level_intro > 0 then
    level_intro -= 1
    if level_intro == 0 then psfx(17, 24, 9) end

  -- normal level
  else
    -- input toggle slowdown
    local slowdown = btnp(6)
    if slowdown then
      if slowdown_amount == 0 then
        slowdown_amount = 1
      elseif slowdown_amount == 1 then
        slowdown_amount = 3
      elseif slowdown_amount == 3 then
        slowdown_amount = 0
      end
      slowdown_timer = 0
      fresh_save = false
    end

    local p
    for o in all(objects) do
      if o.base == player then p = o else o:draw() end
    end

    if slowdown_timer == 0 or p.state == 99 or infade < 6 then
      -- timers
      sfx_timer = max(sfx_timer - 1)
      shake = max(shake - 1)
      infade = min(infade + 1, 60)
      if level_index != 8 then frames += 1 end
      if frames == 30 then seconds += 1 frames = 0 end
      if seconds == 60 then minutes += 1 seconds = 0 end

      update_input()

      -- particles
      foreach(as, function(x) x.timer -= 1 end) 
      foreach(bs, function(x) x.timer -= 1 end) 
      while #as > 0 and as[1].timer == 0 do
        del(as, as[1])
      end
      while #bs > 0 and bs[1].timer == 0 do
        del(bs, bs[1])
      end

      --freeze
      if freeze_time > 0 then
        freeze_time -= 1
      else
          --objects
          for o in all(objects) do
            o:update()
            if o.destroyed then
              del(objects, o)
            end
          end
      end
      slowdown_timer = slowdown_amount
      TIME += time() - LAST_TIME
    else
      slowdown_timer -= 1
    end

    LAST_TIME = time()
  end
end

function _draw()

  pal()

  if level_index == 0 then

    cls(0)

    if titlescreen_flash then
      local c=10
      if titlescreen_flash>10 then
        if titlescreen_flash%10<5 then c=7 end
      elseif titlescreen_flash>5 then c=2
      elseif titlescreen_flash>0 then c=1
      else c=0 end
      if c<10 then for i=1,16 do pal(i,c) end end
    end

    draw_snow()
    draw_comet()
    sspr(64, 32, 64, 32, 36, 32)
    rect(0,0,127,127,7)
    print_center("bEEP aRCADE", 64, 68, 14)
    print_center("adapted from", 64, 80, 1)
    print_center("celeste classic 2", 64, 87, 5)
    print_center("press x or c", 64, 101, 5)
    return
  end
  

  --[[
  if level_intro > 0 then
    cls(0)
    camera(0, 0)
    draw_time(4, 4)
    if level_index != 8 then
      print_center("level " .. (level_index - 2), 64, 64 - 8, 7)
    end
    print_center(level.title, 64, 64, 7)
    return
  end
  --]]

  local camera_x = peek2(0x5f28)
  local camera_y = peek2(0x5f2a)

  if shake > 0 then
    camera(camera_x - 2 + rnd(5), camera_y - 2 + rnd(5))
  end

  -- clear screen
  cls(level and level.bg or 0)

  -- draw clouds
--  draw_clouds(1, 0, 0, 1, 1, level.clouds or 13, #clouds)

  -- columns
--[[  if level.columns then
    fillp(0b0000100000000010.1)
    local x = 0
    while x < level.width do
      local tx = x * 8 + camera_x * 0.1
      rectfill(tx, 0, tx + (x % 2) * 8 + 8, level.height * 8, level.columns)
      x += 1 + x % 7
    end
    fillp()
  end
--]]

  -- draw snow
  draw_snow()

  -- draw comet
  camera(0, 0)
  draw_comet()
  camera(camera_x, camera_y)

  -- draw tileset
  local sc = {8,9,10,11,12}
  local sc2 = {1,2,3,4,5}
  for x = mid(0, flr(camera_x / 8), level.width),mid(0, flr((camera_x + 128) / 8), level.width) do
    for y = mid(0, flr(camera_y / 8), level.height),mid(0, flr((camera_y + 128) / 8), level.height) do
      local tile = tile_at(x, y)
      if level.pal and fget(tile, 7) then level.pal() end
      if tile != 0 and fget(tile, 0) then spr(tile, x * 8, y * 8) end
      -- fancy effect
      if tile == 47 then
        local x_ = x<<3
        local y_ = y<<3
        local of = flr(TIME*16)
        for i=x_+1,x_+6 do
          for j = y_+1,y_+6 do
            local i1 = ((i + of)&63) + ((j&63) << 6)
            local i2 = (i1+2064) & 4095
            local i3 = (i1+685) & 4095
            local i4 = (i1+3360) & 4095
            if star_effects[i1] then
              pset(i,j,8)
            elseif star_effects[i2] then
              pset(i,j,11)
            elseif star_effects[i3] then
              pset(i,j,10)
            elseif star_effects[i4] then
              pset(i,j,12)
            end--]]
            --local c1 = flr(abs(sin((i+flr(TIME*16))*12.9898 + j*78.233))*43758.5453123)%250+1
            --local c2 = flr(abs(sin((i+flr(TIME*8))*35.9898 + j*78.233))*93758.5453123)%200+1
            --if c1 <= 5 then
            --  pset(i, j, sc[c1])
            --end
            --if c2 <= 5 then
            --  pset(i, j, sc2[c2])
            --end
          end
        end
        --
      end
      pal() palt()
    end
  end

  -- score
  --[[
  if show_score > 105 then
    rectfill(34,392,98, 434, 1)
    rectfill(32,390,96, 432, 0)
    rect(32,390,96, 432, 7)
    spr(21, 44, 396)
    print("X "..berry_count, 56, 398, 7)
    spr(87, 44, 408)
    draw_time(56, 408)
    spr(71, 44, 420)
    print("X "..death_count, 56, 421, 7)
  end
  --]]

  -- particles
  local C = {6,7,7,7,7,6,5}
  local D = {5,6,6,6,6,5,1}
  foreach(as, function(o)
    local c1 = C[o.timer]
    local c2 = D[o.timer]
    pset(o.x+1,o.y,c2)
    pset(o.x-1,o.y,c2)
    pset(o.x,o.y+1,c2)
    pset(o.x,o.y-1,c2)
    pset(o.x,o.y,c1)
  end)
  foreach(bs, function(o)
    local c1 = C[o.timer]
    local c2 = D[o.timer]
    for i=-2,2 do
      pset(o.x+i,o.y+1,c2)
      pset(o.x+i,o.y-1,c2)
      pset(o.x+i,o.y,c1)
    end
    pset(o.x+3,o.y,c2)
    pset(o.x-3,o.y,c2)
  end)

  -- draw objects
  local p = nil
  for o in all(objects) do
    if o.base == player then p = o else o:draw() end
  end
  if p then p:draw() end

  -- not very efficient
  if tablelength(collected) >= 13 then
    local o = offset(level_index)
    for _,v in ipairs(lines) do
      local x1 = v[1][1]+v[1][3]-o[1] + 4
      local y1 = v[1][2]+v[1][4]-o[2] + 4
      local x2 = v[2][1]+v[2][3]-o[1] + 4
      local y2 = v[2][2]+v[2][4]-o[2] + 4
      line(x1,y1,x2,y2,7)
      line(x1,y1+1,x2,y2+1,6)
    end
  end

  -- draw FG clouds
  --[[if level.fogmode then
    if level.fogmode == 1 then fillp(0b0101101001011010.1) end
    draw_clouds(1.25, 0, level.height * 8 + 1, 1, 0, 7, #clouds - 10)
    fillp()
  end
--]]


  -- screen wipes
  -- very similar functions ... can they be compressed into one?
  if p ~= nil and p.wipe_timer > 5 then
    local e = (p.wipe_timer - 5) / 12
    for i=0,127 do
      s = (127 + 64) * e - 32 + sin(i * 0.2) * 16 + (127 - i) * 0.25
      rectfill(camera_x,camera_y+i,camera_x+s,camera_y+i,0)
    end
  end

  if infade < 15 then
    local e = infade / 12
    for i=0,127 do
      s = (127 + 64) * e - 32 + sin(i * 0.2) * 16 + (127 - i) * 0.25
      rectfill(camera_x+s,camera_y+i,camera_x+128,camera_y+i,0)
    end
  end

  -- game timer
  --if infade < 45 then
    --draw_time(camera_x + 4, camera_y + 4)
  --end
  --draw_time(camera_x + 4, camera_y + 120)

  -- draw slowdown timer
  if slowdown_amount > 0 then
    palt(0, false)
    palt(1, true)
    if slowdown_amount == 1 then
      print("1/2",camera_x+11,camera_y+4,3)
      print("1/2",camera_x+11,camera_y+3,11)
    elseif slowdown_amount == 3 then
      print("1/4",camera_x+11,camera_y+4,2)
      print("1/4",camera_x+11,camera_y+3,8)
      pal(3,2)
      pal(11,8)
    end
    spr(28, camera_x+2, camera_y+2)
    pal()
    palt()
  end

  for i=1,3 do
    if hearts[i] then
      pal(8,({8,12,9})[i])
      pal(14,({14,6,10})[i])
      spr(64, camera_x+16*8-i*9, camera_y)
      pal()
    end
  end

  -- debug
--  for o in all(objects) do
--    rect(o.x + o.hit_x, o.y + o .hit_y, o.x + o.hit_x + o.hit_w - 1, o.y + o.hit_y + o.hit_h - 1, 8)
--  end

  --camera(0, 0)
  --print("state: " .. p.state, 9, 9, 8)
  --print("cpu: " .. flr(stat(1) * 100) .. "/100", 9, 9, 8)
  --print("mem: " .. flr(stat(0)) .. "/2048", 9, 15, 8)
  --print("idx: " .. level_offset, 9, 21, 8)

  camera(camera_x, camera_y)
end

--[[function draw_time(x,y)
  local m = minutes % 60
  local h = flr(minutes / 60)

  rectfill(x,y,x+32,y+6,0)
  if fresh_save then
    print((h<10 and "0"..h or h)..":"..(m<10 and "0"..m or m)..":"..(seconds<10 and "0"..seconds or seconds),x+1,y+1,7)
  else
    print("XX:XX:XX",x+1,y+1,7)
  end
end--]]

--[[
function draw_clouds(scale, ox, oy, sx, sy, color, count)
  for i=0,count do
    local c = clouds[i]
    local s = c.s * scale
    local x = ox + (camera_x + (c.x - camera_x * 0.9) % (128 + s) - s / 2) * sx
    local y = oy + (camera_y + (c.y - camera_y * 0.9) % (128 + s / 2)) * sy
    clip(x - s / 2 - camera_x, y - s / 2 - camera_y, s, s / 2)
    circfill(x, y, s / 3, color)
    if i % 2 == 0 then
      circfill(x - s / 3, y, s / 5, color)
    end
    if i % 2 == 0 then
      circfill(x + s / 3, y, s / 6, color)
    end
    c.x += (4 - i % 4) * 0.25
  end
  clip(0,0,128,128)
end
--]]

function draw_snow()
  for i=1,#snow do
    local s = snow[i]
    circfill(camera_x + (s.x - camera_x * 0.5) % 132 - 2, camera_y + (s.y - camera_y * 0.5) % 132, i % 2, 6)
    -- s.x += (4 - i % 4)
    -- s.y += sin(TIME * 0.25 + i * 0.1)
  end
end

function draw_comet()
  if not comet and flr(rnd(100 * (1+slowdown_amount))) != 0 then
    return -- no comet today :(
  end

  if not comet then
    pos = rnd(256)
    if pos < 128 then
      comet = { x = pos, y = 0 }
    else
      comet = { x = 0, y = pos - 128 }
    end
  end

  line(comet.x, comet.y, comet.x - 8, comet.y - 8, 10)

  if slowdown_timer == 0 then
    comet.x += 1
    comet.y += 1
  end

  if max(comet.x, comet.y) > 136 then
    comet = nil
  end
end

function print_center(text, x, y, c)
  x -= (#text * 4 - 1) / 2
  print(text, x, y, c)
end

function approach(x, target, max_delta)
  return x < target and min(x + max_delta, target) or max(x - max_delta, target)
end

function psfx(id, off, len, lock)
  sfx(id, -1, off, len)
  --[[if sfx_timer <= 0 or lock then
    sfx(id, -1, off, len)
    if lock then sfx_timer = lock end
  end--]]
end

--[[function draw_sine_h(x0, x1, y, col, amplitude, time_freq, x_freq, fade_x_dist)
  pset(x0, y, col)
  pset(x1, y, col)

  local x_sign = sgn(x1 - x0)
  local x_max = abs(x1 - x0) - 1
  local last_y = y
  local this_y = 0
  local ax = 0
  local ay = 0
  local fade = 1

  for i = 1, x_max do

    if i <= fade_x_dist then
      fade = i / (fade_x_dist + 1)
    elseif i > x_max - fade_x_dist + 1 then
      fade = (x_max + 1 - i) / (fade_x_dist + 1)
    else
      fade = 1
    end

    ax = x0 + i * x_sign
    ay = y + sin(TIME * time_freq + i * x_freq) * amplitude * fade
    pset(ax, ay + 1, 1)
    pset(ax, ay, col)

    this_y = ay
    while abs(ay - last_y) > 1 do
      ay -= sgn(this_y - last_y)
      pset(ax - x_sign, ay + 1, 1)
      pset(ax - x_sign, ay, col)
    end
    last_y = this_y
  end
end
--]]



levels = {
    {
        offset = 0,
        width = 16,
        height = 16,
        camera_mode = 1,
        win_right = 2,
        win_bot = 3,
        win_left = 4,
        win_top = 5,
        --music = 38, -- TODO(dhashe)
    },
    {
        offset = 343,
        width = 64,
        height = 48,
        camera_mode = 2,
        win_left = 1,
        --music = 36, -- TODO(dhashe)
    },
    {
        offset = 679,
        width = 48,
        height = 55,
        camera_mode = 3,
        win_top = 1,
        --music = 36, -- TODO(dhashe)
    },
    {
        offset = 1313,
        width = 48,
        height = 64,
        camera_mode = 4,
        win_right = 1,
        --music = 36, -- TODO(dhashe)
    },
    {
        offset = 2411,
        width = 80,
        height = 48,
        camera_mode = 5,
        win_bot = 1,
        --music = 36, -- TODO(dhashe)
    },
}

function make_xbound_camera(x1, y1, x2, y2)
  return function(px, py)
    if px >= x1*8 and px < x2*8 and py >= y1*8 and py < y2*8 then
      camera_target_x = max(x1*8, min(px-64, x2*8-128))
    end
  end
end

function make_ybound_camera(x1, y1, x2, y2)
  return function(px, py)
    if px >= x1*8 and px < x2*8 and py >= y1*8 and py < y2*8 then
      camera_target_y = max(y1*8, min(py-64, y2*8-128))
    end
  end
end

function make_room_camera(x1, y1, x2, y2)
  xbound = make_xbound_camera(x1, y1, x2, y2)
  ybound = make_ybound_camera(x1, y1, x2, y2)
  return function(px, py)
    xbound(px, py)
    ybound(px, py)
  end
end

c_offset = 0
c_flag = false
camera_modes = {

    -- Level 1
    function(px, py)
    end,

    -- Level 2
    function(px, py)
      make_room_camera(0, 16, 16, 32)(px, py)
      make_xbound_camera(0, 32, 32, 48)(px, py)
      make_xbound_camera(16, 16, 32, 32)(px, py)
      make_ybound_camera(0, 32, 16, 48)(px, py)
      make_ybound_camera(16, 16, 32, 48)(px, py)
      make_room_camera(32, 16, 48, 48)(px, py)
      make_room_camera(48, 16, 64, 48)(px, py)
      make_room_camera(16, 0, 64, 16)(px, py)
    end,

    -- Level 3
    function(px, py)
      make_room_camera(32, 0, 48, 16)(px, py)
      make_room_camera(16, 16, 39, 32)(px, py)
      make_room_camera(0, 32, 39, 55)(px, py)
      make_xbound_camera(0, 32, 39, 55)(px, py)
      make_xbound_camera(0, 16, 16, 32)(px, py)
      make_ybound_camera(16, 32, 39, 55)(px, py)
      make_ybound_camera(0, 16, 16, 55)(px, py)
      make_room_camera(0, 0, 32, 16)(px, py)
    end,

    -- Level 4
    function(px, py)
      make_room_camera(16, 45, 48, 61)(px, py)
      make_room_camera(16, 29, 32, 45)(px, py)
      make_room_camera(16, 6, 32, 29)(px, py)
      make_room_camera(0, 6, 16, 64)(px, py)
      make_room_camera(32, 6, 48, 45)(px, py)
    end,

    -- Level 5
    function(px, py)
      make_room_camera(0, 30, 32, 48)(px, py)
      make_room_camera(18, 16, 64, 32)(px, py)
      make_room_camera(48, 0, 64, 16)(px, py)
      make_room_camera(64, 0, 80, 32)(px, py)
      make_room_camera(0, 24, 7, 31)(px, py)
    end
}

tile_y = function(py)
    return max(0, min(flr(py / 8), level.height - 1))
end

function goto_level(prev_index, index)

  code = {}

  -- set level
  level = levels[index]
  level_index = index
  level_checkpoint = nil

  if level.title and not standalone then
    level_intro = 60
  end

  if index == 1 then
    level_offset = 0
  else
    level_offset = peek2(0x0ffc + 2*index)
    --print("offset: " .. level_offset, 9, 30, 8)
    --  stop()
  end

  -- load into ram
  local function vget(x, y) return peek(0x4300 + x + y * level.width) end
  local function vset(x, y, v) return poke(0x4300 + x + y * level.width, v) end
  px9_decomp(0, 0, 0x1008 + level_offset, vget, vset)

  -- start music
  --if current_music != level.music and level.music then
    --current_music = level.music
    --music(level.music)
  --end

  -- start player near the edge in level 1 if returning
  if index == 1 and prev_index >= 2 then
    if prev_index == 2 then
      level_checkpoint = id(14, 5, 1)
    elseif prev_index == 3 then
      level_checkpoint = id(10, 14, 1)
    elseif prev_index == 4 then
      level_checkpoint = id(1, 14, 1)
    elseif prev_index == 5 then
      level_checkpoint = id(9, 1, 1)
    end
  end

  -- load level contents
  restart_level()
end

function next_level()
  prev_index = level_index
  if won_dir == 1 then
      level_index = level.win_right
  elseif won_dir == 2 then
      level_index = level.win_bot
  elseif won_dir == 3 then
      level_index = level.win_left
  elseif won_dir == 4 then
      level_index = level.win_top
  end
  won_dir = 0
  if standalone then
    load(level_index .. ".p8")
  else
    goto_level(prev_index, level_index)
  end
end

function restart_level()
  camera_x = 0
  camera_y = 0
  camera_target_x = 0
  camera_target_y = 0
  objects = {}
  one_ways = {}
  crumbles = {}
  spikes = {}
  infade = 0
  sfx_timer = 0

  for i = 0,level.width-1 do
    for j = 0,level.height-1 do
      local t = types[tile_at(i, j)]
      if t --[[and not collected[id(i, j)] --]] and (not level_checkpoint or t != player) then
        create(t, i * 8, j * 8)
      end
    end
  end
end

-- gets the tile at the given location from the loaded level
function tile_at(x, y)
  if x < 0 or y < 0 or x >= level.width or y >= level.height then return 0 end

  if standalone then
    return mget(x, y)
  else
    return peek(0x4300 + x + y * level.width)
  end
end


input_jump = false
input_jump_pressed = 0
input_dash = false
input_dash_pressed = 0
input_x = 0
axis_x_value = 0
axis_x_turned = false
input_y = 0
axis_y_value = 0
axis_y_turned = false

function update_input()
    -- axes
  local prev_x = axis_x_value
  if btn(0) then
    if btn(1) then
            if axis_x_turned then
                axis_x_value = prev_x
        input_x = prev_x
      else
                axis_x_turned = true
                axis_x_value = -prev_x
                input_x = -prev_x
      end
    else
            axis_x_turned = false
            axis_x_value = -1
            input_x = -1
    end
  elseif btn(1) then
        axis_x_turned = false
        axis_x_value = 1
        input_x = 1
  else
        axis_x_turned = false
        axis_x_value = 0
        input_x = 0
    end

  -- same thing for y
  local prev_y = axis_y_value
  if btn(2) then
    if btn(3) then
      if axis_y_turned then
        axis_y_value = prev_y
        input_y = prev_y
      else
        axis_y_turned = true
        axis_y_value = -prev_y
        input_y = -prev_y
      end
    else
      axis_y_turned = false
      axis_y_value = -1
      input_y = -1
    end
  elseif btn(3) then
    axis_y_turned = false
    axis_y_value = 1
    input_y = 1
  else
    axis_y_turned = false
    axis_y_value = 0
    input_y = 0
  end

  -- input_jump
  local jump = btn(4)
  if jump and not input_jump then
    input_jump_pressed = 4
  else
    input_jump_pressed = jump and max(0, input_jump_pressed - 1) or 0
  end
  input_jump = jump

  -- input_dash
  local dash = btn(5)
  if dash and not input_dash then
    input_dash_pressed = 4
  else
    input_dash_pressed = dash and max(0, input_dash_pressed - 1) or 0
  end
  input_dash = dash

end

function consume_jump_press()
  local val = input_jump_pressed > 0
  input_jump_pressed = 0
  return val
end

function consume_dash_press()
  local val = input_dash_pressed > 0
  input_dash_pressed = 0
  return val
end


objects = {}
types = {}
lookup = {}
function lookup.__index(self, i) return self.base[i] end

object = {
speed_x = 0,
speed_y = 0,
remainder_x = 0,
remainder_y = 0,
hit_x = 0,
hit_y = 0,
hit_w = 8,
hit_h = 8,
dash_mode = 0,
hazard = 0,
facing = 1
}

function object.move_x(self, x, on_collide)
  self.remainder_x += x
  local mx = flr(self.remainder_x + 0.5)
  self.remainder_x -= mx

  local total = mx
  local mxs = sgn(mx)
  while mx != 0
  do
    if self:check_solid(mxs, 0) then
      if on_collide then
        return on_collide(self, total - mx, total)
      end
      return true
    else
      self.x += mxs
      mx -= mxs
    end
  end

  return false
end

function object.move_y(self, y, on_collide)
  self.remainder_y += y
  local my = flr(self.remainder_y + 0.5)
  self.remainder_y -= my

  local total = my
  local mys = sgn(my)
  while my != 0
  do
    if self:check_solid(0, mys) then
      if on_collide then
        return on_collide(self, total - my, total)
      end
      return true
    else
      self.y += mys
      my -= mys
    end
  end

  return false
end

function object.on_collide_x(self, moved, target)
  self.remainder_x = 0
  self.speed_x = 0
  return true
end

function object.on_collide_y(self, moved, target)
  self.remainder_y = 0
  self.speed_y = 0
  return true
end

function object.update() end
function object.draw(self)
  spr(self.spr, self.x, self.y, 1, 1, self.flip_x, self.flip_y)
end

function object.overlaps(self, b, ox, oy)
  if self == b then return false end
  ox = ox or 0
  oy = oy or 0
  return
    ox + self.x + self.hit_x + self.hit_w > b.x + b.hit_x and
    oy + self.y + self.hit_y + self.hit_h > b.y + b.hit_y and
    ox + self.x + self.hit_x < b.x + b.hit_x + b.hit_w and
    oy + self.y + self.hit_y < b.y + b.hit_y + b.hit_h
end

function object.contains(self, px, py)
  return
    px >= self.x + self.hit_x and
    px < self.x + self.hit_x + self.hit_w and
    py >= self.y + self.hit_y and
    py < self.y + self.hit_y + self.hit_h
end

function object.check_solid(self, ox, oy)
  ox = ox or 0
  oy = oy or 0

  for i = flr((ox + self.x + self.hit_x) / 8),flr((ox + self.x + self.hit_x + self.hit_w - 1) / 8) do
    for j = tile_y(oy + self.y + self.hit_y),tile_y(oy + self.y + self.hit_y + self.hit_h - 1) do
      if fget(tile_at(i, j), 1) then
        return true
      end
    end
  end

  -- add other types here as needed. doing this for all(objects) was too slow
  for o in all(crumbles) do
    if o.solid and o != self and not o.destroyed and self:overlaps(o, ox, oy) then
      return true
    end
  end

  return false
end

function object.corner_correct(self, dir_x, dir_y, side_dist, look_ahead, only_sign, func)
  look_ahead = look_ahead or 1
  only_sign = only_sign or 1

  if dir_x ~= 0 then
    for i = 1, side_dist do
      for s = 1, -2, -2 do
        if s == -only_sign then
          goto continue_x
        end

        if not self:check_solid(dir_x, i * s) and (not func or func(self, dir_x, i * s)) then
          self.x += dir_x
          self.y += i * s
          return true
        end

        ::continue_x::
      end
    end
  elseif dir_y ~= 0 then
    for i = 1, side_dist do
      for s = 1, -1, -2 do
        if s == -only_sign then
          goto continue_y
        end

        if not self:check_solid(i * s, dir_y) and (not func or func(self, i * s, dir_y)) then
          self.x += i * s
          self.y += dir_y
          return true
        end

        ::continue_y::
      end
    end
  end

  return false
end

function id(tx, ty, idx) return (idx or level_index) * 8192 + flr(tx) + flr(ty) * 128 end

function create(type, x, y)
  local obj = {}
  obj.base = type
  obj.x = x
  obj.y = y
  obj.id = id(flr(x/8), flr(y/8))
  setmetatable(obj, lookup)
  add(objects, obj)
  if obj.init then obj.init(obj) end
  return obj
end

function new_type(spr)
  local obj = {}
  obj.spr = spr
  obj.base = object
  setmetatable(obj, lookup)
  types[spr] = obj
  return obj
end

spikes = {}
spike_v = new_type(36)
function spike_v.init(self)
  add(spikes, self)
  if not self:check_solid(0, 1) then
    self.flip_y = true
    self.hazard = 3
  else
    self.hit_y = 5
    self.hazard = 2
  end
  self.hit_h = 3
end

spike_h = new_type(37)
function spike_h.init(self)
  add(spikes, self)
  if self:check_solid(-1, 0) then
    self.flip_x = true
    self.hazard = 4
  else
    self.hit_x = 5
    self.hazard = 5
  end
  self.hit_w = 3
end

--[[
snowball = new_type(62)
snowball.thrown_timer = 0
snowball.stop = false
snowball.hp = 6
function snowball.update(self)
  if not self.held then
    self.thrown_timer -= 1

    --speed
    if self.stop then
      self.speed_x = approach(self.speed_x, 0, 0.25)
      if self.speed_x == 0 then
        self.stop = false
      end
    else
      if self.speed_x != 0 then
        self.speed_x = approach(self.speed_x, sgn(self.speed_x) * 2, 0.1)
      end
    end

    --gravity
    if not self:check_solid(0, 1) then
      self.speed_y = approach(self.speed_y, 4, 0.4)
    end

    --apply
    self:move_x(self.speed_x, self.on_collide_x)
    self:move_y(self.speed_y, self.on_collide_y)

    --bounds
    if self.y > level.height * 8 + 24 then
      self.destroyed = true
    end
  end
end
function snowball.on_collide_x(self, moved, total)
  if self:corner_correct(sgn(self.speed_x), 0, 2, 2, 1) then
    return false
  end

  if self:hurt() then
    return true
  end

  self.speed_x *= -1
  self.remainder_x = 0
  psfx(17, 0, 2)
  return true
end
function snowball.on_collide_y(self, moved, total)
  if self.speed_y < 0 then
    self.speed_y = 0
    self.remainder_y = 0
    return true
  end

  if self.speed_y >= 4 then
    self.speed_y = -2
    psfx(17, 0, 2)
  elseif self.speed_y >= 1 then
    self.speed_y = -1
    psfx(17, 0, 2)
  else
    self.speed_y = 0
  end
  self.remainder_y = 0
  return true
end
function snowball.on_release(self, thrown)
  if not thrown then
    self.stop = true
  end
  self.thrown_timer = 8
end
function snowball.hurt(self)
  self.hp -= 1
  if self.hp <= 0 then
    psfx(8, 16, 4)
    self.destroyed = true
    return true
  end
  return false
end
function snowball.bounce_overlaps(self, o)
  if self.speed_x != 0 then
    self.hit_w = 12
    self.hit_x = -2
    local ret = self:overlaps(o)
    self.hit_w = 8
    self.hit_x = 0
    return ret
  else
    return self:overlaps(o)
  end
end
function snowball.contains(self, px, py)
  return
    px >= self.x and
    px < self.x + 8 and
    py >= self.y - 1 and
    py < self.y + 10
end
function snowball.draw(self)
  pal(7, 1)
  spr(self.spr, self.x, self.y + 1)
  pal()
  spr(self.spr, self.x, self.y)
end
--]]

springboard = new_type(11)
--springboard.thrown_timer = 0
function springboard.update(self)
  if not self.held then
    --self.thrown_timer -= 1

    --friction and gravity
    if self:check_solid(0, 1) then
      self.speed_x = approach(self.speed_x, 0, 1)
    else
      self.speed_x = approach(self.speed_x, 0, 0.2)
      self.speed_y = approach(self.speed_y, 4, 0.4)
    end

    --apply
    self:move_x(self.speed_x, self.on_collide_x)
    self:move_y(self.speed_y, self.on_collide_y)

    if self.player then
      self.player:move_y(self.speed_y)
    end

    self.destroyed = self.y > level.height * 8 + 24
  end
end
function springboard.on_collide_x(self, moved, total)
  self.speed_x *= -0.2
  self.remainder_x = 0
  return true
end
function springboard.on_collide_y(self, moved, total)
  if self.speed_y < 0 then
    self.speed_y = 0
    self.remainder_y = 0
    return true
  end

  if self.speed_y >= 2 then
    self.speed_y *= -0.4
  else
    self.speed_y = 0
  end
  self.remainder_y = 0
  self.speed_x *= 0.5
  return true
end
--[[function springboard.on_release(self, thrown)
  if thrown then
    self.thrown_timer = 5
  end
end
--]]

--[[
bridge = new_type(63)
function bridge.update(self)
  self.y += self.falling and 3 or 0
end
--]]

function berry_init(self)
  self.ground = 0
  self.scary_timer = 1
  self.initial_x = self.x
  self.initial_y = self.y
end
function berry_update(self)
  if not self.scary_player and self.scary_timer > 1 then
    self.scary_timer -= 1
  end
  if self.collected then
    self.timer += 1
    self.y -= 0.2 * (self.timer > 5 and 1 or 0)
    if self.timer > 30 then
      self.collected = false
      self.x = self.initial_x
      self.y = self.initial_y
      self.player = nil
      self.timer = 0
      self.flash = 0
    end
  elseif self.player then
    self.x += (self.player.x - self.x) / 8
    self.y += (self.player.y - 4 - self.y) / 8
    self.flash -= 1

    if self.player:check_solid(0, 1) and self.player.state != 99 then self.ground += 1 else self.ground = 0 end

    if self.ground > 3 or self.player.x > level.width * 8 - 7 or self.player.last_berry != self then
      psfx(8, 8, 8, 20)
      if not collected[self.id] then
        dset(stars[self.id]-1, self.id)
        collected[self.id] = true
      end
      berry_count += 1
      self.collected = true
      self.timer = 0
      self.draw = score
    end
  elseif self.scary_player then
    if self.scary_player:check_solid(0, 1) and self.scary_player.state != 3 then self.ground += 1 else self.ground = 0 end

    if self.ground > 3 then
      --psfx(8, 8, 8, 20) -- TODO(dhashe) different sfx
      self.scary_player = nil
    end
    if self.scary_timer <= 4 then
      self.scary_timer += 1
    end
  end
end
function berry_collect(self, player)
  if not self.player and not self.scary_player then
    self.player = player
    player.last_berry = self
    self.flash = 5
    self.ground = 0
    psfx(7, 12, 4)
  end
end
function berry_draw(self)
  if not self.scary_player then
    if (self.timer or 0) < 5 then
      if self.spr == 27 then
        spr(({27, 41, 42, 57, 58})[self.scary_timer], self.x, self.y+sin(TIME)*2, 1, 1, not self.right)
      else
        spr(self.spr, self.x, self.y + sin(TIME) * 2, 1, 1, not self.right)
      end
      if (self.flash or 0) > 0 then
        circ(self.x + 4, self.y + 4, self.flash * 3, 7)
        circfill(self.x + 4, self.y + 4, 5, 7)
      end
    else
      local s = tostring(1000 * stars[self.id])
      print(s, self.x - 4, self.y + 1, 8)
      print(s, self.x - 4, self.y, self.timer % 4 < 2 and 7 or 14)
    end
    if collected[self.id] and not self.collected then
      spr(29, self.x+7, self.y-7 + sin(TIME)*2)
    end
  else
    spr(({27, 41, 42, 57, 58})[self.scary_timer], self.x, self.y+sin(TIME)*2)
  end
  if collected[self.id] and not self.player then
    local s = tostring(1000 * stars[self.id])
    print(s, self.x - #s, self.y + 9 + sin(TIME)*2, 8)
    print(s, self.x - #s, self.y + 8 + sin(TIME)*2, 14)
  end
end

berry = new_type(21)
function berry.init(self) berry_init(self) end
function berry.update(self) berry_update(self) end
function berry.collect(self, player) berry_collect(self, player) end
function berry.draw(self) berry_draw(self) end

scared_berry = new_type(27)
function scared_berry.init(self) berry_init(self) end
function scared_berry.update(self) berry_update(self) end
function scared_berry.collect(self, player) berry_collect(self, player) end
function scared_berry.draw(self) berry_draw(self) end
function scared_berry.scare(self, player)
  self.scary_player = player
  self.scary_timer = 1
end

balloon = new_type(46)
function balloon.update(self)
  if self.collected then
    self.timer += 1
    self.collected = self.timer < 30
  else
    self.timer = 0
  end
end
function balloon.collect(self, player)
  if not self.collected and player.has_dashed then
    player.has_dashed = false
    self.collected = true
    psfx(7, 12, 4) -- TODO(dhashe) different sound effect
  end
end
function balloon.draw(self)
  if not self.collected then
    spr(self.spr, self.x, self.y + sin(TIME) * 2, 1, 1)
  end
end

one_ways = {}
one_way_red = new_type(25)
one_way_v = new_type(9)
function one_way_v.init(self)
  add(one_ways, self)
  if tile_at(self.x/8, self.y/8+1) == one_way_red.spr then
    self.flip_y = true
    self.hit_y = 7
  else
    self.flip_y = false
  end
  self.hit_h = 1
end
one_way_h = new_type(24)
function one_way_h.init(self)
  add(one_ways, self)
  if tile_at(self.x/8+1, self.y/8) == one_way_red.spr then
    self.flip_x = true
    self.hit_x = 7
  else
    self.flip_x = false
  end
  self.hit_w = 1
end

crumbles = {}
crumble = new_type(19)
crumble.solid = true
crumble.dash_mode = 1
function crumble.init(self)
  add(crumbles, self)
  self.time = 0
  self.breaking = false
  self.ox = self.x
  self.oy = self.y
end
function crumble.update(self)
  if self.breaking then
    self.time += 1
    if self.time > 10 then
      self.x = -32
      self.y = -32
    end
    if self.time > 90 then
      self.x = self.ox
      self.y = self.oy

      local can_respawn = true
      for o in all(objects) do
        if self:overlaps(o) then can_respawn = false break end
      end

      if can_respawn then
        self.breaking = false
        self.time = 0
        psfx(17, 5, 3)
      else
        self.x = -32
        self.y = -32
      end
    end
  end
end
function crumble.draw(self)
  object.draw(self)
  if self.time > 2 then
    fillp(0b1010010110100101.1)
    rectfill(self.x, self.y, self.x + 7, self.y + 7, 1)
    fillp()
  end
end

checkpoint = new_type(13)
function checkpoint.init(self)
  if level_checkpoint == self.id then
    create(player, self.x, self.y)
  end
end
function checkpoint.draw(self)
  if level_checkpoint == self.id then
    pal(6, 13)
    spr(self.spr, self.x, self.y + sin(TIME) * 2)
    pal()
  else
    object.draw(self)
  end
end

--[[
function make_spawner(tile, dir)
  local spawner = new_type(tile)
  function spawner.init(self)
    self.timer = (self.x / 8) % 32
    self.spr = -1
  end
  function spawner.update(self)
    self.timer += 1
    if self.timer >= 32 and abs(self.x - 64 - camera_x) < 128 then
      self.timer = 0
      local snowball = create(snowball, self.x, self.y - 8)
      snowball.speed_x = dir * 2
      snowball.speed_y = 4
      psfx(17, 5, 3)
    end
  end
  return spawner
end
snowball_spawner_r = make_spawner(14, 1)
snowball_spawner_l = make_spawner(15, -1)
--]]

for i = 69,71 do
  local heartgate = new_type(i)
  heartgate.init = function(self)
    add(crumbles,self)
    self.solid = true
  end
  heartgate.update= function (self)
    if hearts[i-68] then
      self.solid = false
    end
  end
  heartgate.draw = function(self)
    spr(i + (self.solid and 0 or 45), self.x, self.y)
  end
end

heart = new_type(64)
heart.collected = false
heart.collect_timer = 0
codes = {
  {true,true,true,true,true,false,true,false,false,false,false,false},
  {true,false,true,false,false,true,false,false,true,true,true,false,false,true,true,false,false,false,false,false},
  {true,true,true,true,false,false,false,true,false,true,false,true,false,false,false,false},
}
function heart.init(self)
  self.collect_timer = 0
end
function heart.update(self)
  if hearts[level_index-1] then
    self.destroyed = true
  end
  if level_index == 1 or level_index == 5 or self.destroyed then
    return
  end
  if self.collect_timer > 0 then
    self.collect_timer -= 1
  end
  local c = codes[level_index-1]
  local match = false
  while not match do
    match = true
    for i=1,#c do
      if i > #code then
        break
      end
      if code[i] != c[i] then
        match = false
        del(code, code[1])
        break
      end
    end
  end
  if #code == #c and not self.collected then
    self.collected = true
    self.collect_timer = 9
  end
end
function heart.draw(self)
  if self.collect_timer % 2 == 1 then
    pal(8, 7)
    pal(14, 7)
  else
    if level_index == 3 then
      pal(8,12)
      pal(14,6)
    elseif level_index == 4 then
      pal(8,9)
      pal(14,10)
    end
  end
  if self.collect_timer == 1 then
    hearts[level_index-1] = true
    dset(level_index-2+13, 1)
    psfx(8, 8, 8, 20)
  end
  spr(64, self.x, self.y + sin(TIME)*2)
  pal()
end


player = new_type(2)
player.t_jump_grace = 0
player.t_var_jump = 0
player.var_jump_speed = 0
player.auto_var_jump = true
player.has_dashed = false
player.t_dash  = 0
player.wipe_timer = 0
player.finished = false
player.t_buffer = 0
player.buffered_x = 0
player.buffered_y = 0

player.state = 0

-- Helpers

function player.set_pos_buffer(self)
  self.t_buffer = 10
  self.buffered_x = self.x
  self.buffered_y = self.y
end

function player.jump(self)
  consume_jump_press()
  self.state = 0
  self.speed_y = -4
  self.var_jump_speed = -4
  self.speed_x += input_x * 0.2
  self.t_var_jump = 4
  self.t_jump_grace = 0
  self.auto_var_jump = true
  self:move_y(self.jump_grace_y - self.y)
  as[#as+1] = {x=self.x, y=self.y-4, timer=7} 
  psfx(7, 0, 2)
  code[#code+1] = false
end

function player.dash(self, x, y)
  consume_dash_press()
  self.t_var_jump = 0
  self.has_dashed = true
  self.state = 3
  self.t_dash = 6
  shake = 2
  --if self.t_buffer > 0 then
  --  self.x = self.buffered_x
  --  self.y = self.buffered_y
  --end
  if x == 0 and y == 0 then
    x = self.facing
  end
  local dash_speed = 5
  if x ~= 0 and y ~= 0 then
    dash_speed = 4
  end
  self.speed_x = x * dash_speed
  self.speed_y = y * dash_speed
  for o in all(objects) do
    if o.base == scared_berry then o:scare(self) end
  end
  bs[#bs+1] = {x=self.x, y=self.y-4, timer=7} 
  psfx(8, 0, 4)
  code[#code+1] = true
end

--[[function player.bounce(self, x, y)
  self.state = 0
  self.speed_y = -4
  self.var_jump_speed = -4
  self.t_var_jump = 4
  self.t_jump_grace = 0
  self.auto_var_jump = true
  self.speed_x += sgn(self.x - x) * 0.5
  self:move_y(y - self.y)
  self.has_dashed = false
end--]]

function player.spring(self, y)
  consume_jump_press()
  if input_jump then
    psfx(17, 2, 3)
  else
    psfx(17, 0, 2)
  end
  self.state = 0
  self.speed_y = -5
  self.var_jump_speed = -5
  self.t_var_jump = 6
  self.t_jump_grace = 0
  self.remainder_y = 0
  self.auto_var_jump = true
  self.springboard.player = nil
  self.has_dashed = false

  for o in all(objects) do
    if o.base == crumble and not o.destroyed and self.springboard:overlaps(o, 0, 4) then
      o.breaking = true
      psfx(8, 20, 4)
    end
  end
end

function player.wall_jump(self, dir)
  consume_jump_press()
  self.state = 0
  self.speed_y = -3
  self.var_jump_speed = -3
  self.speed_x = 3 * dir
  self.t_var_jump = 4
  self.auto_var_jump = true
  self.facing = dir
  self:move_x(-dir * 3)
  psfx(7, 0, 2)
  as[#as+1] = {x=self.x, y=self.y-4, timer=5} 
  code[#code+1] = false
end

function player.bounce_check(self, obj)
  return self.speed_y >= 0 and self.y - self.speed_y < obj.y + obj.speed_y + 4
end

function player.die(self)
  self.state = 99
  freeze_time = 2
  shake = 5
  death_count += 1
  psfx(14, 16, 16, 120)
end

--[[
  hazard types:
    0 - not a hazard
    1 - general hazard
    2 - up-spike
    3 - down-spike
    4 - right-spike
    5 - left-spike
]]

player.hazard_table = {
  [1] = function(self) return true end,
  [2] = function(self) return self.speed_y >= 0 end,
  [3] = function(self) return self.speed_y <= 0 end,
  [4] = function(self) return self.speed_x <= 0 end,
  [5] = function(self) return self.speed_x >= 0 end
}

function player.hazard_check(self, ox, oy)
  ox = ox or 0
  oy = oy or 0

  for o in all(spikes) do
    if o.hazard != 0 and self:overlaps(o, ox, oy) and self.hazard_table[o.hazard](self) then
      return true
    end
  end

  return false
end

function player.correction_func(self, ox, oy)
  return not self:hazard_check(ox, oy)
end

-- Events

function player.init(self)
  self.x += 4
  self.y += 8
  self.hit_x = -3
  self.hit_y = -6
  self.hit_w = 6
  self.hit_h = 6

  self.scarf = {}
  for i = 0,4 do
    add(self.scarf, { x = self.x, y = self.y })
  end

  --camera
  camera_modes[level.camera_mode](self.x, self.y)
  camera_x = camera_target_x
  camera_y = camera_target_y
  camera(camera_x, camera_y)
end

function sign(n)
  if n > 0 then
    return 1
  elseif n < 0 then
    return -1
  else
    return 0
  end
end

function player.bounded(self, x1, x2, y1, y2)
  return self.x <= 8*x2 and 8*x1 <= self.x and self.y <= 8*y2 and 8*y1 <= self.y
end

function player.update(self)
  local on_ground = self:check_solid(0, 1)
  local on_left_wall = self:check_solid(-2)
  local on_right_wall = self:check_solid(2)
  local against_wall = (on_left_wall and input_x == -1) or (on_right_wall and input_x == 1)
  if on_ground then
    self.t_jump_grace = 4
    self.jump_grace_y = self.y
    if self.state != 3 then -- if not dashing
      self.has_dashed = false
    end
    self.t_buffer = 0
  else
    self.t_jump_grace = max(0, self.t_jump_grace - 1)
    self.t_buffer -= 1
  end

  if level_index == 2 and self:bounded(44, 47, 22, 25) then
    if stat(24) == -1 then
      music(0)
    end
  elseif level_index == 3 and self:bounded(9, 16, 32, 37) then
    if stat(24) == -1 then
      music(3)
    end
  elseif level_index == 4 and self:bounded(11, 17, 14, 18) then
    if stat(24) == -1 then
      music(6)
    end
  elseif stat(24) >= 0 then
    music(-1)
  end

  --[[
    player states:
      0   - normal
      2   - springboard bounce
      99   - dead
      100 - finished level
  ]]

  if self.state == 0 then
    -- normal state

    -- facing
    if input_x ~= 0 then
      self.facing = input_x
    end

    -- running
    local target, accel = 0, 0.2
    if abs(self.speed_x) > 2 and input_x == sgn(self.speed_x) then
      target,accel = 2, 0.1
    elseif on_ground then
      target, accel = 2, 0.8
    elseif input_x != 0 then
      target, accel = 2, 0.4
    end
    self.speed_x = approach(self.speed_x, input_x * target, accel)

    -- gravity
    local initial_speed_y = self.speed_y
    if not on_ground and not (against_wall and initial_speed_y >= 0) then
      local max = input_y == 1 and 5.2 or 4.4
      if abs(self.speed_y) < 0.2 and input_jump then
        self.speed_y = min(self.speed_y + 0.4, max)
      else
        self.speed_y = min(self.speed_y + 0.8, max)
      end
    end

    -- wall slide
    if against_wall and initial_speed_y >= 0 then
      if not self.wall_slide_timer then
        self.wall_slide_timer = 0
      end
      self.wall_slide_timer += 1
      if self.wall_slide_timer > 10 then
        self.speed_y = 0.4
      else
        self.speed_y = 0
      end
    else
      self.wall_slide_timer = 0
    end

    -- variable jumping
    if self.t_var_jump > 0 then
      if input_jump or self.auto_var_jump then
        self.speed_y = self.var_jump_speed
        self.t_var_jump -= 1
      else
        self.t_var_jump = 0
      end

      if self.t_var_jump == 0 then
        self.t_var_jump = -1
      end
    end

    -- buffer position at apex of jump
    if self.t_var_jump < 0 then
      if self.speed_y >= 0 then
        self:set_pos_buffer()
        self.t_var_jump = 0
      end
    end

    -- jumping
    if input_jump_pressed > 0 then
      if self.t_jump_grace > 0 then
        self:jump()
      elseif on_right_wall then
        self:wall_jump(-1)
      elseif on_left_wall then
        self:wall_jump(1)
      end
    end

    -- dashing
    self.t_dash = 0
    if input_dash_pressed > 0 then
      if not self.has_dashed then
        self:dash(input_x, input_y)
      end
    end

  elseif self.state == 2 then
    -- springboard bounce state

    local at_x = approach(self.x, self.springboard.x + 4, 0.5)
    self:move_x(at_x - self.x)

    local at_y = approach(self.y, self.springboard.y + 4, 0.2)
    self:move_y(at_y - self.y)

    if self.springboard.spr == 11 and self.y >= self.springboard.y + 2 then
      self.springboard.spr = 12
    elseif self.y == self.springboard.y + 4 then
      self:spring(self.springboard.y + 4)
      self.springboard.spr = 11
    end

  elseif self.state == 3 then
    -- dashing

    -- give the players a couple frames to  input direction
    if self.t_dash > 4 and (input_x ~= 0 or input_y ~= 0) then
      local dash_speed = 5
      if input_x ~= 0 and input_y ~= 0 then
        dash_speed = 4
      end
      self.speed_x = input_x * dash_speed
      self.speed_y = input_y * dash_speed
    end

    self.t_dash -= 1
    if self.t_dash == 0 then
      self.state = 0
      self.speed_x = sign(self.speed_x)
      self.speed_y = sign(self.speed_y)
      self:set_pos_buffer()
    end

  elseif self.state == 99 or self.state == 100 then
    -- dead / finished state

    if self.state == 100 then
      if won_dir == 1 then
        self.x += 1
      elseif won_dir == 2 then
        self.y += 1
      elseif won_dir == 3 then
        self.x -= 1
      elseif won_dir == 4 then
        self.y -= 1
      end
      if self.wipe_timer == 5 and level_index > 1 then psfx(17, 24, 9) end
    end

    self.wipe_timer += 1
    if self.wipe_timer > 20 then
      if self.state == 99 then restart_level() else next_level() end
    end
    return
  end

  -- apply
  local sx = self.speed_x
  local sy = self.speed_y
  self:move_x(self.speed_x, self.on_collide_x)
  self:move_y(self.speed_y, self.on_collide_y)

  -- sprite
  if not on_ground then
    self.spr = 3
  elseif input_x != 0 then
    self.spr += 0.25
    self.spr = 2 + self.spr % 2
  else
    self.spr = 2
  end

  -- object interactions
  for o in all(objects) do
--[[    if o.base == bridge and not o.falling and self:overlaps(o) then
      --falling bridge tile
      o.falling = true
      shake = 2
      psfx(8, 16, 4)
--]]
    --[[if o.base == snowball and not o.held then
      --snowball
      if self:bounce_check(o) and o:bounce_overlaps(self) then
        self:bounce(o.x + 4, o.y)
        psfx(17, 0, 2)
        o.speed_y = -1
        o:hurt()
      elseif o.speed_x != 0 and o.thrown_timer <= 0 and self:overlaps(o) then
        self:die()
        return
      end
    --]]
    if o.base == springboard and self.state != 2 and not o.held and self:overlaps(o) and self:bounce_check(o) then
      --springboard
      self.state = 2
      self.speed_x = 0
      self.speed_y = 0
      self.t_jump_grace = 0
      self.springboard = o
      self.remainder_y = 0
      o.player = self
      self:move_y(o.y + 4 - self.y)
    elseif (o.base == berry or o.base == scared_berry or o.base == balloon) and self:overlaps(o) then
      --collectibles
      o:collect(self)
    elseif o.base == crumble and not o.breaking then
      --crumble
      if self.state == 0 and self:overlaps(o, 0, 1) then
        o.breaking = true
        psfx(8, 20, 4)
      elseif self.state == 3 and self:overlaps(o, sx, sy) then
        o.breaking = true
        psfx(8, 20, 4)
      end
    elseif o.base == checkpoint and level_checkpoint != o.id and self:overlaps(o) then
      level_checkpoint = o.id
      psfx(8, 24, 6, 20)
    end
  end


  -- death
  if self.state < 99 and self:hazard_check() then
    self:die()
    return
  end


  -- bounds
  if self.x > level.width * 8 - 3 and level.win_right then
    self.state = 100
    won_dir = 1
  elseif self.y > level.height * 8 - 3 and level.win_bot then
    self.state = 100
    won_dir = 2
  elseif self.x < 3 and level.win_left then
    self.state = 100
    won_dir = 3
  elseif self.y < 3 and level.win_top then
    self.state = 100
    won_dir = 4
  end

  -- intro bridge music
  --[[if current_music == levels[1].music and self.x > 61 * 8 then
    current_music = 37
    --music(37)
    psfx(17, 24, 9)
  end

  -- ending music
  if level_index == 8 then
    if current_music != 40 and self.y > 40 then
      current_music = 40
      --music(40)
    end
    if self.y > 376 then show_score += 1 end
    if show_score == 120 then music(38) end
  end
--]]

  -- camera
  camera_modes[level.camera_mode](self.x, self.y, on_ground)
  camera_x = approach(camera_x, camera_target_x, 5)
  camera_y = approach(camera_y, camera_target_y, 5)
  camera(camera_x, camera_y)
end

function player.on_collide_x(self, moved, target)

  if self.state == 0 then
    if sgn(target) == input_x and self:corner_correct(input_x, 0, 2, 2, -1, self.correction_func) then
      return false
    end
  end

  return object.on_collide_x(self, moved, target)
end

function player.on_collide_y(self, moved, target)
  if target < 0 and self:corner_correct(0, -1, 2, 1, input_x, self.correction_func) then
    return false
  end

  self.t_var_jump = 0
  return object.on_collide_y(self, moved, target)
end

function player.check_solid(self, ox, oy)
  ox = ox or 0
  oy = oy or 0

  -- one way barriers
  for o in all(one_ways) do
    if self:overlaps(o, ox, oy) then
      if ((o.base == one_way_h and o.flip_x == (self.speed_x < 0)) or
          (o.base == one_way_v and o.flip_y == (self.speed_y < 0))) and not self:overlaps(o, 0, 0) then
        return true
      end
    end
  end

  return object.check_solid(self, ox, oy)
end

function player.draw(self)

  -- death fx
  if self.state == 99 then
    local e = self.wipe_timer / 10
    local dx = mid(camera_x, self.x, camera_x + 128)
    local dy = mid(camera_y, self.y - 4, camera_y + 128)
    if e <= 1 then
      for i=0,7 do
        circfill(dx + cos(i / 8) * 32 * e, dy + sin(i / 8) * 32 * e, (1 - e) * 8, 10)
      end
    end
    return
  end

  -- scarf
  local last = { x = self.x - self.facing,y = self.y - 3 }
  if self.has_dashed then
    pal(10, 12)
  end
  for i=1,#self.scarf do
    local s = self.scarf[i]

    -- approach last pos with an offset
    s.x += (last.x - s.x - self.facing) / 1.5
    s.y += ((last.y - s.y) + sin(i * 0.25 + TIME) * i * 0.25) / 2

    -- don't let it get too far
    local dx = s.x - last.x
    local dy = s.y - last.y
    local dist = sqrt(dx * dx + dy * dy)
    if dist > 1.5 then
      local nx = (s.x - last.x) / dist
      local ny = (s.y - last.y) / dist
      s.x = last.x + nx * 1.5
      s.y = last.y + ny * 1.5
    end

    -- fill
    rectfill(s.x, s.y, s.x, s.y, 10)
    rectfill((s.x + last.x) / 2, (s.y + last.y) / 2, (s.x + last.x) / 2, (s.y + last.y) / 2, 10)
    last = s
  end

  -- sprite
  spr(self.spr, self.x - 4, self.y - 8, 1, 1, self.facing ~= 1)
  pal()
end


-- px9 decompress
-- by zep

-- x0,y0 where to draw to
-- src   compressed data address
-- vget  read function (x,y)
-- vset  write function (x,y,v)

function
    px9_decomp(x0,y0,src,vget,vset)

    local function vlist_val(l, val)
        -- find position
        for i=1,#l do
            if l[i]==val then
                for j=i,2,-1 do
                    l[j]=l[j-1]
                end
                l[1] = val
                return i
            end
        end
    end

    -- bit cache is between 16 and
    -- 31 bits long with the next
    -- bit always aligned to the
    -- lsb of the fractional part
    local cache,cache_bits=0,0
    function getval(bits)
        if cache_bits<16 then
            -- cache next 16 bits
            cache+=%src>>>16-cache_bits
            cache_bits+=16
            src+=2
        end
        -- clip out the bits we want
        -- and shift to integer bits
        local val=cache<<32-bits>>>16-bits
        -- now shift those bits out
        -- of the cache
        cache=cache>>>bits
        cache_bits-=bits
        return val
    end

    -- get number plus n
    function gnp(n)
        local bits=0
        repeat
            bits+=1
            local vv=getval(bits)
            n+=vv
        until vv<(1<<bits)-1
        return n
    end

    -- header

    local
        w,h_1,      -- w,h-1
        eb,el,pr,
        x,y,
        splen,
        predict
        =
        gnp"1",gnp"0",
        gnp"1",{},{},
        0,0,
        0
        --,nil

    for i=1,gnp"1" do
        add(el,getval(eb))
    end
    for y=y0,y0+h_1 do
        for x=x0,x0+w-1 do
            splen-=1

            if(splen<1) then
                splen,predict=gnp"1",not predict
            end

            local a=y>y0 and vget(x,y-1) or 0

            -- create vlist if needed
            local l=pr[a]
            if not l then
                l={}
                for e in all(el) do
                    add(l,e)
                end
                pr[a]=l
            end

            -- grab index from stream
            -- iff predicted, always 1

            local v=l[predict and 1 or gnp"2"]

            -- update predictions
            vlist_val(l, v)
            vlist_val(el, v)

            -- set
            vset(x,y,v)

            -- advance
            x+=1
            y+=x\w
            x%=w
        end
    end
end
