              --
-- bookz
-- License:GPLv3
--

bookz = {}

local modname = minetest.get_current_modname()
local modpath = minetest.get_modpath(modname)
local S = minetest.get_translator(modname)

--
-- Bookz Mod
--

-- Load the files
assert(loadfile(modpath .. "/api.lua"))(S, modname)
