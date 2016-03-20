------------------------------------------------------------------------
--  BASIC DEFINITIONS
------------------------------------------------------------------------
--
--  Oblige Level Maker
--
--  Copyright (C) 2006-2014 Andrew Apted
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

-- important global tables
GAME   = {}
PARAM  = {}
STYLE  = {}
LEVEL  = {}
THEME  = {}
SEEDS  = {}

EPISODE = {}
PREFABS = {}


-- a place for unfinished stuff
UNFINISHED = {}


-- tables which interface with GUI code
OB_CONFIG = {}

OB_GAMES   = {}
OB_THEMES  = {}
OB_ENGINES = {}
OB_MODULES = {}


-- the default engine (basically Vanilla + limit removing)
OB_ENGINES["nolimit"] =
{
  label = "Limit Removing"
  priority = 95  -- top most
}


-- special theme types, usable by all games
OB_THEMES["original"] =
{
  label = "As Original"
  priority = -80
}

OB_THEMES["mixed"] =
{
  label = "A Bit Mixed"
  priority = -85,
}

OB_THEMES["jumble"] =
{
  label = "Jumbled Up"
  priority = -90
}


-- important constants

SEED_SIZE = 128

EDGE_SIZE  = 3  -- # of seeds
BOUNDARY_SIZE = 4

EXTREME_H = 32000


-- special value for merging tables
REMOVE_ME = "__REMOVE__"


-- constants for gui.spots_xxx API functions
SPOT_CLEAR    = 0
SPOT_LOW_CEIL = 1
SPOT_WALL     = 2
SPOT_LEDGE    = 3


GLOBAL_STYLE_LIST =
{
  -- these two correspond to buttons in the GUI

  outdoors   = { few=20, some=60, heaps=30 }
  caves      = { none=30 }  --!!!!!!  , few=30, some=30, heaps=7 }

  -- things that affect the whole level

  traps      = { few=20, some=80, heaps=20 }
  secrets    = { few=20, some=50, heaps=10 }
  hallways   = { few=60, some=30, heaps=10 }
  liquids    = { few=30, some=50, heaps=10 }
  scenics    = { few=30, some=50, heaps=10 }
  lakes      = { few=60, heaps=10 }
  islands    = { few=60, heaps=40 }
  organics   = { none=5, few=20, some=60, heaps=20 }

  ambushes    = { none=10, some=50, heaps=10 }
  big_rooms   = { none=20, few=50, some=30, heaps=10 }
  cycles      = { none=50, some=50, heaps=50 }
  crossovers  = { none=40 } --!!!! , some=40, heaps=40 }

  mon_variety = { some=50 }
  teleporters = { none=50 } --!!!!  few=30, some=30, heaps=10 }
  switches    = { none=5, few=50, some=50, heaps=10 }
  doors       = { none=5, few=30, some=60, heaps=5 }
  porches     = { few=10, some=60, heaps=10 }

  -- things that affect stuff in rooms

  junk       = { few=10, some=60, heaps=30 }
  pillars    = { few=60, some=30, heaps=10 }
  beams      = { few=25, some=50, heaps=5  }
  barrels    = { few=50, some=50, heaps=10 }
  closets    = { few=10, some=30, heaps=30 }

  ex_floors  = { few=40, some=60, heaps=20 }
  windows    = { few=20, some=50, heaps=20 }
  pictures   = { few=10, some=50, heaps=10 }
  steepness  = { few=20, some=60, heaps=10 }

  symmetry   = { none=10, few=40, some=60, heaps=10 }
  cages      = { none=20 }  --!!!! , few=20, some=20, heaps=10 }
  fences     = { none=30, few=30, some=10 }
  crates     = { none=20, some=40, heaps=10 }
}


GLOBAL_PARAMETERS =
{
  map_limit = 10000

  step_height = 16
  jump_height = 24

  spot_low_h  = 72
  spot_high_h = 128
}


-- this function is now deprecated
require = function() error("require() is deprecated") end

