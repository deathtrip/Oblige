------------------------------------------------------------------------
--  RENDER : CONSTRUCT AREAS
------------------------------------------------------------------------
--
--  Oblige Level Maker
--
--  Copyright (C) 2008-2014 Andrew Apted
--
--  This program is free software; you can redistribute it and/or
--  modify it under the terms of the GNU General Public License
--  as published by the Free Software Foundation; either version 2
--  of the License, or (at your option) any later version.
--
--  This program is distributed in the hope that it will be useful,
--  but WITHOUT ANY WARRANTY; without even the implied warranty of
--  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--  GNU General Public License for more details.
--
------------------------------------------------------------------------


function edge_wall(S, dir, mat)

--[[ DEBUG CRUD
local m_idx = (S.area.id % 8) + 1
local m_tab = {"NUKAGE1", "FWATER1", "STARTAN3", "FLAT1", "FLAT10", "COMPSPAN", "MARBLE1", "ROCK1"}
mat = m_tab[m_idx]
assert(mat)
--## if S.room and (S.room.id % 3 == 1) then return end
--]]


  local TK = 16

  local x1, y1 = S.x1, S.y1
  local x2, y2 = S.x2, S.y2

  if dir == 2 then y2 = y1 + TK end
  if dir == 8 then y1 = y2 - TK end

  if dir == 4 then x2 = x1 + TK end
  if dir == 6 then x1 = x2 - TK end


  local brush

  if dir == 2 or dir == 4 or dir == 6 or dir == 8 then
    brush = brushlib.quad(x1, y1, x2, y2)

  elseif dir == 1 then
    brush =
    {
      { x=x1,      y=y2      }
      { x=x2,      y=y1      }
      { x=x2,      y=y1 + TK }
      { x=x1 + TK, y=y2      }
    }
  elseif dir == 9 then
    brush =
    {
      { x=x1,      y=y2      }
      { x=x1,      y=y2 - TK }
      { x=x2 - TK, y=y1      }
      { x=x2,      y=y1      }
    }
  elseif dir == 3 then
    brush =
    {
      { x=x1,      y=y1 }
      { x=x2,      y=y2 }
      { x=x2 - TK, y=y2 }
      { x=x1,      y=y1 + TK }
    }
  elseif dir == 7 then
    brush =
    {
      { x=x1,      y=y1 }
      { x=x1 + TK, y=y1 }
      { x=x2,      y=y2 - TK }
      { x=x2,      y=y2 }
    }
  else
    error("edge_wall : bad dir")
  end

  brushlib.set_mat(brush, mat, mat)

  Trans.brush(brush)
end



function straddle_fence_or_wall(S, dir, mat, fence_h)
  local TK = 16

  local x1, y1 = S.x1, S.y1
  local x2, y2 = S.x2, S.y2

  if dir == 2 then y2 = y1 end
  if dir == 8 then y1 = y2 end

  if dir == 4 then x2 = x1 end
  if dir == 6 then x1 = x2 end

  local brush

  if dir == 2 or dir == 4 or dir == 6 or dir == 8 then
    brush = brushlib.quad(x1 - TK, y1 - TK, x2 + TK, y2 + TK)

  elseif dir == 3 or dir == 7 then
    brush =
    {
      { x=x1 - TK, y=y1 + TK }
      { x=x1 - TK, y=y1 - TK }
      { x=x1 + TK, y=y1 - TK }

      { x=x2 + TK, y=y2 - TK }
      { x=x2 + TK, y=y2 + TK }
      { x=x2 - TK, y=y2 + TK }
    }
  else
    brush =
    {
      { x=x2 - TK, y=y1 - TK }
      { x=x2 + TK, y=y1 - TK }
      { x=x2 + TK, y=y1 + TK }

      { x=x1 + TK, y=y2 + TK }
      { x=x1 - TK, y=y2 + TK }
      { x=x1 - TK, y=y2 - TK }
    }
  end

  if fence_h then
    table.insert(brush, { t=fence_h })
  end

  brushlib.set_mat(brush, mat, mat)

  Trans.brush(brush)
end



function dummy_arch(S, dir)
  local mx, my = S:mid_point()

  if dir == 2 then my = int((my + S.y1 * 7) / 8) end
  if dir == 8 then my = int((my + S.y2 * 7) / 8) end
  if dir == 4 then mx = int((mx + S.x1 * 7) / 8) end
  if dir == 6 then mx = int((mx + S.x2 * 7) / 8) end

--[[ FIXME
  if dir == 1 then mx = mx - 40 ; my = my - 40 end
  if dir == 3 then mx = mx + 40 ; my = my - 40 end
  if dir == 7 then mx = mx - 40 ; my = my + 40 end
  if dir == 9 then mx = mx + 40 ; my = my + 40 end
--]]

  Trans.entity("candle", mx, my, assert(S.area.floor_h))
end



function Render_edge(A, S, dir)

  local bord = S.border[dir]
  local LOCK = bord.lock


  local function edge_simple_sky(floor_h)
    assert(not geom.is_corner(dir))

    local x1, y1 = S.x1, S.y1
    local x2, y2 = S.x2, S.y2

    if dir == 2 then y2 = y1 + 8 end
    if dir == 8 then y1 = y2 - 8 end

    if dir == 4 then x2 = x1 + 8 end
    if dir == 6 then x1 = x2 - 8 end

    local brush = brushlib.quad(x1, y1, x2, y2)

    each C in brush do
      C.flags = DOOM_LINE_FLAGS.draw_never
    end

    table.insert(brush, { b=floor_h + 16, delta_z = -16 })

    brushlib.set_mat(brush, "_SKY", "_SKY")

    Trans.brush(brush)
  end


  local function straddle_keyed_door()
    local z = A.floor_h

    assert(LOCK)

---!!!    local o_tex = outer_tex(S, dir, w_tex)
---!!!    local skin1 = { wall=w_tex, floor=f_tex, outer=o_tex }

    local skin1 = { }


    -- FIXME : find it properly
    local fab_name = "Locked_" .. LOCK.item

    local def


    if geom.is_corner(dir) then
      fab_name = fab_name .. "_diag"

      local def = PREFABS[fab_name]
      assert(def)

      local DIR_MAP = { [1]=2, [9]=8, [3]=4, [7]=6 }
      local dir2 = DIR_MAP[dir]

      local T = Trans.box_transform(S.x1, S.y1, S.x2, S.y2, z, dir2)

      Fabricate(R, def, T, { skin1 })

    else  -- axis-aligned edge

      local def = PREFABS[fab_name]
      assert(def)

      local S2 = S
      local seed_w = 1

      local T = Trans.edge_transform(S.x1, S.y1, S2.x2, S2.y2, z,
                                     dir, 0, seed_w * 192, def.deep, def.over)

      Fabricate(R, def, T, { skin1 })
  
---???    do_door_base(S, dir, z, w_tex, o_tex)
    end
  end


  local function straddle_locked_door()
    assert(LOCK)

    if LOCK.item then
      straddle_keyed_door()
      return
    end

    error("WTF : switched door")

--[[  TODO

    local z = assert(S.conn and S.conn.conn_h)

    -- FIXME : find it properly
    local fab_name = "Door_with_bars" --!!! Door_SW_blue

    local def = PREFABS[fab_name]
    assert(def)

    local o_tex = outer_tex(S, dir, w_tex)
    local skin1 = { wall=w_tex, floor=f_tex, outer=o_tex }

    skin1.lock_tag = LOCK.tag

    local S2 = S
    local seed_w = 1

    local T = Trans.edge_transform(S.x1, S.y1, S2.x2, S2.y2, z,
                                   dir, 0, seed_w * 192, def.deep, def.over)

    Fabricate(R, def, T, { skin1 })

    do_door_base(S, dir, z, w_tex, o_tex)
--]]
  end


  local function add_edge_line()
    local x1, y1 = S.x1, S.y1
    local x2, y2 = S.x2, S.y2

    if dir == 2 then y2 = y1 end
    if dir == 8 then y1 = y2 end

    if dir == 4 then x2 = x1 end
    if dir == 6 then x1 = x2 end

    if dir == 3 or dir == 7 then
      -- no change necessary
    end

    if dir == 1 or dir == 9 then
      y1, y2 = y2, y1
    end

    local E = { x1=x1, y1=y1, x2=x2, y2=y2 }

    table.insert(A.side_edges, E)
  end


  ---| build_edge |---

  local N = S:diag_neighbor(dir, "NODIR")

  if N == "NODIR" then return end

  -- edge of map
  if not (N and N.area) then
    if bord.kind == "sky_edge" and A.floor_h then
      edge_simple_sky(A.floor_h)
    end

    return
  end


  -- same area ?   nothing needed
  if N.area == S.area then return end

  local NA = N.area


  add_edge_line()


  local same_room = (N.room and N.room == S.room)

  if bord.kind == "arch" then
    dummy_arch(S, dir)

  elseif bord.kind == "lock_door" then
    straddle_locked_door()

  elseif bord.kind == "straddle" then
    -- nothing

--!!!!    elseif A.mode == "hallway" or
--!!!!        (rand.odds(80) and (A.kind == "building" or A.kind == "cave"))
--!!!!    then
  
  elseif A.mode == "scenic" and A.is_outdoor then
    -- nothing

  elseif A.is_outdoor and NA and NA.mode == "scenic" and NA.kind == "water" then
    -- nothing

  elseif not same_room then
    local mat = A.wall_mat

    if A.is_outdoor and not NA.is_outdoor then
      mat = NA.wall_mat
    end

    assert(mat)

    edge_wall(S, dir, mat)

  else
--!!!      straddle_fence_or_wall(S, dir, A.wall_mat, A.floor_h + 8)
  end
end



function dummy_sector(A, S)
  assert(S.area == A)

  -- get parent seed
  local PS = S
  if S.bottom then PS = S.bottom end

  local bare_brush =
  {
    { x=PS.x1, y=PS.y1 }
    { x=PS.x2, y=PS.y1 }
    { x=PS.x2, y=PS.y2 }
    { x=PS.x1, y=PS.y2 }
  }

  if S.diagonal == 3 then
    table.remove(bare_brush, 4)
  elseif S.diagonal == 7 then
    table.remove(bare_brush, 2)
  elseif S.diagonal == 1 then
    table.remove(bare_brush, 3)
  elseif S.diagonal == 9 then
    table.remove(bare_brush, 1)
  elseif S.diagonal then
    error("Invalid diagonal seed!")
  end


  if A.mode == "void" then
    local w_brush = bare_brush

    brushlib.set_mat(w_brush, "BLAKWAL1")

    Trans.brush(w_brush)
    return
  end


  local light = 160
  if A.ceil_mat == "_SKY" then light = 192 end


local tag  ---##  = sel(A.ceil_mat == "_SKY", 1, 0)
if A.room then tag = A.room.id end


  local f_brush = table.deep_copy(bare_brush)
  local c_brush = bare_brush

  table.insert(f_brush, { t=A.floor_h, tag=tag })
  table.insert(c_brush, { b=A. ceil_h, light=light })

  brushlib.set_mat(f_brush, A.floor_mat, A.floor_mat)
  brushlib.set_mat(c_brush, A. ceil_mat, A. ceil_mat)

  Trans.brush(f_brush)
  Trans.brush(c_brush)


  -- remember floor brush for the spot logic
  table.insert(A.floor_brushes, f_brush)


  -- walls

  each dir in geom.ALL_DIRS do
    Render_edge(A, S, dir)
  end
end



function Render_area(A)
  A.floor_brushes = {}
  A.side_edges = {}

  each S in A.half_seeds do
    dummy_sector(A, S)
  end

-- TEST CRUD !!! 
--[[
    if A.mode != "void" then
      local ent_name = rand.pick({"potion", "stimpack", "helmet", "shells", "rocket", "cells", "allmap"});
      each P in A.inner_points do
        Trans.entity(ent_name, P.x1, P.y1, A.floor_h)
      end
    end
--]]
end



function dummy_properties(A)
    if not A.floor_h then
      A.floor_h = -7
    end

    if not A.ceil_h then
      A.ceil_h = A.floor_h + 200
    end

--DEBUG
---##  A.kind = "building"
---##  if A.mode != "scenic" then A.mode = "normal" end

    if A.kind == "building" then
      A.wall_mat  = "STARTAN3"
      A.floor_mat = "FLOOR4_8"

    elseif A.kind == "courtyard" then
      A.floor_mat = "BROWN1"

    elseif A.kind == "landscape" then
      A.floor_mat = "RROCK19"

    elseif A.kind == "cave" then
      A.wall_mat  = "ASHWALL4"
      A.floor_mat = "RROCK04"

    else
      A.floor_mat = "CRACKLE2"
    end

    if A.mode == "scenic" and A.kind == "water" then
      assert(A.floor_h)
      A.floor_mat = "FWATER1"

    elseif A.mode == "scenic" then
      A.floor_mat = "LAVA1"
      A.floor_h   = -64

    elseif A.mode == "hallway" then
      A.floor_mat = "FLAT5_1"
      A.wall_mat  = "WOOD1"
      A.ceil_mat  = "WOOD1"

      if not A.is_outdoor then
        A.ceil_h = A.floor_h + 72
      end

    elseif A.mode == "water" then
      A.floor_h = -8
      A.floor_mat = "FWATER1"

    end

    if A.is_outdoor then
      A.ceil_mat = "_SKY"
    end

    A.wall_mat = A.wall_mat or A.floor_mat
    A.ceil_mat = A.ceil_mat or A.wall_mat

    assert(A.wall_mat)
end



function Render_all_areas()
  each A in LEVEL.areas do
    dummy_properties(A)
  end

  each A in LEVEL.areas do
    Render_area(A)
  end
end


------------------------------------------------------------------------


function Render_importants()

  local R  -- the current room


  local function player_dir(spot)
    -- FIXME : analyse all 4 directions, pick one which can see the most
    --         [ or opposite of one which can see the least ]

    local S = Seed_from_coord(spot.x, spot.y)

    if R.sh > R.sw then
      if S.sy > (R.sy1 + R.sy2) / 2 then 
        return 2
      else
        return 8
      end
    else
      if S.sx > (R.sx1 + R.sx2) / 2 then 
        return 4
      else
        return 6
      end
    end
  end


  local function content_big_item(spot, item)
    local fab_name = "Item_pedestal"

    -- FIXME: TEMP RUBBISH
    if string.sub(item, 1, 2) == "kc" or
       string.sub(item, 1, 2) == "ks" then
      fab_name = "Item_podium"
    end

    local def = PREFABS[fab_name]
    assert(def)

    local skin1 = { item=item }

    local T = Trans.spot_transform(spot.x, spot.y, spot.z, spot.dir)

    Fabricate(R, def, T, { skin1 })

    Trans.entity("light", spot.x, spot.y, spot.z+112, { cave_light=176 })
  end


  local function content_very_big_item(spot, item, is_weapon)
--[[  FIXME : LOWERING PEDESTALS

    -- sometimes make a lowering pedestal
    local prob = sel(is_weapon, 40, 20)

    if rand.odds(prob) and
       THEME.lowering_pedestal_skin and
       not S.chunk[2]
    then
      local mx, my = spot.x, spot.y
      local z1 = spot.z

      local z_top

      if R.kind == "cave" then
        z_top = z1 + rand.pick({ 64, 96 })

      else
        local z2 = S.ceil_h or S.room.ceil_h or (z1 + 256)

        if z2 < z1 + 170 then
          z_top = z1 + 64
        else
          z_top = z1 + 128
        end
      end

      Build.lowering_pedestal(S, z_top, THEME.lowering_pedestal_skin)

      Trans.entity(item, mx, my, z_top)
      Trans.entity("light", mx, my, z_top + 24, { cave_light=176 })

      return
    end
--]]

    content_big_item(spot, item)
  end


  local function content_start_pad(spot, dir)
    local def = PREFABS["Start_basic"]
    assert(def)

    local T = Trans.spot_transform(spot.x, spot.y, spot.z, 10 - dir)

    Fabricate(R, def, T, { })
  end


  local function content_coop_pair(spot, dir)
    -- no prefab for this : add player entities directly

    local mx = spot.x
    local my = spot.y
    local  z = spot.z

    local angle = geom.ANGLES[dir]

    local dx, dy = geom.delta(dir)

    dx = dx * 24 ; dy = dy * 24

    Trans.entity(R.player_set[1], mx - dy, my + dx, z, { angle=angle })
    Trans.entity(R.player_set[2], mx + dy, my - dx, z, { angle=angle })

    if GAME.ENTITIES["player8"] then
      mx = mx - dx * 2
      my = my - dy * 2

      Trans.entity(R.player_set[3], mx - dy, my + dx, z, { angle=angle })
      Trans.entity(R.player_set[4], mx + dy, my - dx, z, { angle=angle })
    end
  end


  local function content_start(spot)
    local dir = player_dir(spot)

    if R.player_set then
      content_coop_pair(spot, dir)

--[[
    elseif false and PARAM.raising_start and R.svolume >= 20 and
       R.kind != "cave" and
       THEME.raising_start_switch and rand.odds(25)
    then
      -- TODO: fix this
      gui.debugf("Raising Start made\n")

      local skin =
      {
        f_tex = S.f_tex or R.main_tex,
        switch_w = THEME.raising_start_switch,
      }

      Build.raising_start(S, 6, z1, skin)
      angle = 0

      S.no_floor = true
      S.raising_start = true
      R.has_raising_start = true
--]]
    else

      content_start_pad(spot, dir)
    end
  end


  local function content_exit(spot)
    local def = PREFABS["Exit_switch"]
    assert(def)

    local skin1 = { }

    if R.purpose == "SECRET_EXIT" then skin1.special = 51 end

    local dir = spot.dir or 2

    local T = Trans.spot_transform(spot.x, spot.y, spot.z, 10 - dir)

    Fabricate(R, def, T, { skin1 })
  end


  local function content_purpose(spot)
    if R.purpose == "START" then
      content_start(spot)

---???    elseif R.purpose == "EXIT" and OB_CONFIG.game == "quake" then
---???      local skin = { floor="SLIP2", wall="SLIPSIDE" }
---???
---???      Build.quake_exit_pad(S, z1 + 16, skin, LEVEL.next_map)

    elseif R.purpose == "EXIT" or R.purpose == "SECRET_EXIT" then
      content_exit(spot)

    elseif R.purpose == "KEY" then
      local LOCK = assert(R.purpose_lock)
      content_very_big_item(spot, LOCK.item)

    elseif R.purpose == "SWITCH" then
--[[ FIXME: BUILD SWITCHES
      local LOCK = assert(R.purpose_lock)
      local INFO = assert(GAME.SWITCHES[LOCK.switch])
      Build.small_switch(S, dir_for_wotsit(S), z1, INFO.skin, LOCK.tag)
      Trans.entity("light", mx, my, z1+112, { cave_light=176 })
--]]

    else
      error("unknown purpose: " .. tostring(R.purpose))
    end
  end


  local function content_weapon(spot)
    local weapon = assert(spot.content_item)

    if R.purpose == "START" or R.is_hallway then
      -- bare item
      Trans.entity(weapon, spot.x, spot.y, spot.z)
    else
      content_very_big_item(spot, weapon, "is_weapon")
    end

    gui.debugf("Placed weapon '%s' @ (%d,%d,%d)\n", weapon, spot.x, spot.y, spot.z)
  end


  local function content_item(spot)
    local item = assert(spot.content_item)

    if R.purpose == "START" or R.is_hallway then
      -- bare item
      Trans.entity(item, spot.x, spot.y, spot.z)
    else
      content_big_item(spot, item)
    end
  end


  local function content_teleporter(spot)
    -- FIXME !!!!  content_teleporter

    local C = R.teleport_conn
    assert(C)

    local def = PREFABS["Teleporter1"]
    assert(def)

    local skin1 = {}

    if C.R1 == R then
      skin1. in_tag = C.tele_tag2
      skin1.out_tag = C.tele_tag1
    else
      skin1. in_tag = C.tele_tag1
      skin1.out_tag = C.tele_tag2
    end

    skin1. in_target = string.format("tele%d", skin1. in_tag)
    skin1.out_target = string.format("tele%d", skin1.out_tag)

    local mx, my = S:mid_point()
    local spot_dir = 10 - dir_for_wotsit(S)
    local z = assert(S.floor_h)

    local T = Trans.spot_transform(mx, my, z, spot_dir)

    Fabricate(R, def, T, { skin1 })
  end


  local function build_goal(G)
    if G.content_kind == "WEAPON" then
      content_weapon(G)
    elseif G.content_kind == "ITEM" then
      content_item(G)
    elseif G.content_kind == "TELEPORTER" then
      content_teleporter(G)
    else
      content_purpose(G)
    end
  end


  ---| Layout_build_importants |---

  each room in LEVEL.rooms do
    R = room

    each goal in R.goals do
      build_goal(goal)
    end
  end
end


