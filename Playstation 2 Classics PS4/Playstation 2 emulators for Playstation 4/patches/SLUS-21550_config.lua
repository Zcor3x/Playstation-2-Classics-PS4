
-- Metal Slug Anthology PS2 - SLUS-21550 (USA)

apiRequest(1.2)	-- request version 0.1 API. Calling apiRequest() is mandatory.

local eeObj		= getEEObject()
local emuObj	= getEmuObject()

-- Fix for black screen booting an elf. This is a game bug.
-- The v1.0 of the game suffered from an intermittent bug on the real PS2
-- where sometimes it would hang on a black screen trying to launch a new elf.
-- This is apparently due to a bad IOP state, which caused sceCdInit to hang.
-- Later versions of the game (1.1, 1.2) attempted to fix this in different ways.
-- On Olympus, v1.0 (USA) hangs always, while v1.2 (EUR/JPN) works always.
-- The fix implemented here replaces a call to FlushCache() to loadImageAndReboot(),
-- which is a function that reboots the IOP and resolves the hang.

eeInsnReplace(0x189c24, 0x0c08f7f8, 0x0c061dd2) -- FlushCache() -> loadImageAndReboot()
eeInsnReplace(0x117804, 0x0c0c1e08, 0x0c045e20) -- FlushCache() -> loadImageAndReboot()
