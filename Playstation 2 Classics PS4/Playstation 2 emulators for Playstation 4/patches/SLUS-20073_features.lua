-- Lua 5.3
-- Title:   Red Faction PS2 - SLUS-20073 (USA)
-- Author:  Ernesto Corvi, Adam McInnis

-- Changelog:

apiRequest(1.1)	-- request version 1.1 API. Calling apiRequest() is mandatory.

local eeObj		= getEEObject()
local emuObj	= getEmuObject()

local L1 =  -- main
	function()
		emuObj.ThrottleMax()
	end
	
local L2 =  -- main
	function()
		emuObj.ThrottleNorm()
	end
	
local load1 = eeObj.AddHook(0x165590, 0x27bdffb0, L1) -- game_load_level
local load2 = eeObj.AddHook(0x16578C, 0x7bb10010, L2) -- game_load_level

-- Widescreen support --
eeInsnReplace(0x2071c4, 0x00000000, 0x3c013f40) -- gr_setup_3d
eeInsnReplace(0x2071d0, 0x00000000, 0x4481f000) -- gr_setup_3d
eeInsnReplace(0x2072e0, 0x00000000, 0x461ea502) -- gr_setup_3d
eeInsnReplace(0x2072e8, 0x00000000, 0x461ead43) -- gr_setup_3d
eeInsnReplace(0x23a34c, 0x44826000, 0x461e0303) -- shadow_ngps_render_and_copy
eeInsnReplace(0x23a444, 0x3c024334, 0x3c024309) -- shadow_ngps_render_and_copy
emuObj.SetDisplayAspectWide()
