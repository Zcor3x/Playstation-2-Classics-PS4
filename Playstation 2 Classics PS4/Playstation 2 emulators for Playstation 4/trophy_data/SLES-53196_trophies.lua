-- Lua 5.3
-- Title:   Destroy All Humans! PS2 - SLES-53196 (EUR)
-- Author:  Ernesto Corvi, Adam McInnis

-- Changelog:
-- v1.1: Disabled progressive support
-- v1.2: Tweaked IDENTITY_THIEF trophy

apiRequest(1.1)	-- request version 1.1 API. Calling apiRequest() is mandatory.

local eeObj		= getEEObject()
local emuObj	= getEmuObject()
local trophyObj	= getTrophyObject()
local gpr = require( "ee-gpr-alias" ) -- you can access EE GPR by alias (gpr.a0 / gpr["a0"])

local RULER_OF_EARTH                        =  0 -- Unlock all other trophies. (automatic)
local PROBE_ATION_OFFICER                   =  1 -- Collect all Probes. (done)
local SUN_SURF_AND_PROBES                   =  2 -- Collect all Probes in Santa Modesta. (This also unlocks the Art of the Furon Furongami.) (done)
local SATURDAY_EVENING_PROBE                =  3 -- Collect all Probes in Rockwell. (This also unlocks the Blue Book: Saucer Blueprints Furongami.) (done)
local DOWN_HOME_COUNTRY_PROBING             =  4 -- Collect all Probes in Turnipseed Farm. (This also unlocks the Evolution of an Alien Furongami.) (done)
local A_CONSPIRACY_OF_PROBES                =  5 -- Collect all Probes in Area-42. (This also unlocks the Face of the Enemy Furongami.) (done)
local PROBE_TOWN_USA                        =  6 -- Collect all Probes in Union Town. (This also unlocks the Pathetic Humans! Furongami.) (done)
local PROBES_WITH_A_CAPITOL_P               =  7 -- Collect all Probes in Capitol City. (This also unlocks the Concept Barnyard Furongami.) (done)
local THE_TYRANT_OF_TURNIPSEED              =  8 -- Complete all side missions in Turnipseed Farm. (done)
local ROCKED_WELL                           =  9 -- Complete all side missions in Rockwell. (done)
local MODESTLY_SUCCESSFUL                   = 10 -- Complete all side missions in Santa Modesta. (done)
local AREA_86ED                             = 11 -- Complete all side missions in Area 42. (done)
local A_MUCH_LESS_PERFECT_UNION             = 12 -- Complete all side missions in Union Town. (done)
local KICKING_GOVERNMENT_IN_THE_SEAT        = 13 -- Complete all side missions in Capitol City. (done)
local FIRST_CONTACT                         = 14 -- Complete "Destination Earth!" (done)
local EMINENCE_GRISE                        = 15 -- Complete "Citizen Crypto." ("Gray Eminence," an old French phrase for being the power behind the throne. Since Crypto's a "grey," it's a play on words.) (done)
local MARS_NEEDS_INFORMATION                = 16 -- Complete "The Island Suburbia." (done)
local WE_ARE_DOING_IT_LIVE                  = 17 -- Complete "Suburb of the Damned." (done)
local BOMBING_RUN                           = 18 -- Complete "Duck and Cover!" (done)
local THIS_RIDICULOUS_WAR                   = 19 -- Complete "Armiquist vs. the Furons!" (done)
local IMPEACHED                             = 20 -- Complete "Attack of the 50 Ft. President!" (done)
local POWER_TRIP                            = 21 -- Complete a side mission with the Bulletproof Crypto code enabled. (Square, Circle, Left D-Pad, Left D-Pad, Circle, Square) (done)
local GRAY_MATTERS                          = 22 -- Collect a total of 50,000 DNA without using the Mmm… Brains! Cheat. (You'd get quite a bit of this by collecting all the Probes, and completing the main missions gives you 15 DNA per  human instead of 10, so this shouldn't be as grueling as it looks. Also, this should be total lifetime collected, rather than requiring the player to have 50,000 DNA at once.) (done)
local RIDE_THE_LIGHTNING                    = 23 -- Fully upgrade the Zap-O-Matic. (done)
local DUST_IN_THE_WIND                      = 24 -- Fully upgrade the Disintegrator Ray. (done)
local EARTH_SHATTERING_KABOOM               = 25 -- Fully upgrade the Ion Detonator. (done)
local MIND_OVER_MATTER                      = 26 -- Fully upgrade Psychokinesis. (done)
local DANGER_DEATH_RAY                      = 27 -- Fully upgrade the saucer's Death Ray. (done)
local MIND_OVER_ANTIMATTER                  = 28 -- Fully upgrade the saucer's Sonic Boom. (done)
local NOW_YOU_LEARN_TO_LOVE_THE_BOMB        = 29 -- Fully upgrade the saucer's Quantum Deconstructor. (done)
local ALIEN_OVERLORD                        = 30 -- Achieve 100% completion. (done)
local THERES_THE_BEEF                       = 31 -- Tip 100 cows. (Cows Tipped is one of the stats tracked in the Invasion Report.)
local TERROR_FROM_BEYOND_THE_STARS          = 32 -- Kill a total of 1,000 humans. (done)
local TRAIL_OF_WRECKAGE                     = 33 -- Destroy 500 vehicles. (done)
local IDENTITY_THIEF                        = 34 -- Assume 40 identities. (done)
local FOOD_FOR_THOUGHT                      = 35 -- Extract 250 brains. (done)
local TERM_LIMITED                          = 36 -- Assassinate 50 politicians. (done)
local ALIEN_CONQUEROR_VS_ROBOT_SOLDIER      = 37 -- Destroy 50 robots. (done)

local bulletproofEnabled = false

local SaveData = emuObj.LoadConfig(0)
local SaveDataDirty = false
local SaveDataCounter = 240

function initsaves()
	local needsSave = false
	
	if SaveData.t == nil then
		SaveData.t = {}
		needsSave = true
	end
	
	for x = 0, 37 do
		if SaveData.t[x] == nil then
			SaveData.t[x] = 0
			needsSave = true
		end
	end
	
	if SaveData.dnaCount == nil then
		SaveData.dnaCount = 0
		needsSave = true
	end
	
	if (needsSave == true) then
		emuObj.SaveConfig(0, SaveData)
	end
end

function updatesaves()
	SaveDataCounter = SaveDataCounter - 1
	
	if SaveDataCounter <= 0 then
		SaveDataCounter = 240
		if SaveDataDirty ~= false then
			emuObj.SaveConfig(0, SaveData)
			SaveDataDirty = false
		end
	end
end

initsaves()
emuObj.AddVsyncHook(updatesaves)

function unlockTrophy(trophy_id)
	if SaveData.t[trophy_id] ~= 1 then
		SaveData.t[trophy_id] = 1
		trophyObj.Unlock(trophy_id)
		emuObj.SaveConfig(0, SaveData)
	end
end

local luaOverlay = InsnOverlay({
	0x27bdfff0, -- addiu $sp, -0x10
	0xffbf0000, -- sd $ra, 0(sp)
	0xffb00008, -- sd $s0, 8(sp)
	0x3c05000f, -- lui $a1, 0x000f
	0x34a57000, -- ori $a1, 0x7000
	0x0c0cceb2, -- jal Script::State::DoString
	0x0080802d, -- move $s0, $a0
	0x24050001, -- li $a1, 1
	0x0c0cd01e, -- jal Script::State::GetS32(int)
	0x0200202d, -- move $a0, $s0
	0xdfb00008, -- ld $s0, 8(sp)
	0xdfbf0000, -- ld $ra, 0(sp)
	0x03e00008, -- jr ra
	0x27bd0010  -- addiu $sp, 0x10
})
local callLuaOverlay = 0x0c000000 | (luaOverlay >> 2)
eeInsnReplace(0x308B20, 0x0c0cd01e, callLuaOverlay)

local getKeyProgress = function()
	local progress = eeObj.ReadMem32(0x4318B4) -- from UFO::Progress::Get
	local keyTable = progress+0x3a4c -- from UFO::Progress::Record::FindKey
	local storage = eeObj.ReadMem32(keyTable+12)
	local count = eeObj.ReadMem32(keyTable+4)
	local keys = {}

	for x = 0, count - 1 do
		local key = eeObj.ReadMem32(storage+(x*8))
		keys[key] = x
	end
	
	return keys
end

local getIntProgress = function()
	local progress = eeObj.ReadMem32(0x4318B4) -- from UFO::Progress::Get
	local keyTable = progress+0x3a6c -- from UFO::Progress::Record::FindS32
	local storage = eeObj.ReadMem32(keyTable+12)
	local count = eeObj.ReadMem32(keyTable+4)
	local keys = {}

	for x = 0, count - 1 do
		local key = eeObj.ReadMem32(storage+(x*12))
		local value = eeObj.ReadMem32(storage+(x*12)+8)
		keys[key] = value
	end
	
	return keys
end

local countBits = function(value)
	local count = 0
	for x = 0, 31 do
		if ((value >> x) & 1) ~= 0 then
			count = count + 1
		end
	end
	
	return count
end

local checkAllProbes = function()
	-- farm.probes.count = 0x54abd989		farm.probes.1 = 0x7be8d5b3		farm.probes.2 = 0x76abf36a
	-- rockwell.probes.count = 0x9296ed86	rockwell.probes.1 = 0x42b51bbe	rockwell.probes.2 = 0x4ff63d67
	-- santa.probes.count = 0x77357d89		santa.probes.1 = 0xaa066013		santa.probes.2 = 0xa74546ca
	-- area42.probes.count = 0x00011209		area42.probes.1 = 0x69ca4687	area42.probes.2 = 0x6489605e
	-- union.probes.count = 0xffa15ed5		union.probes.1 = 0x060c00cd		union.probes.2 = 0x0b4f2614
	-- capitol.probes.count = 0xb6be1add	capitol.probes.1 = 0x19289df3	capitol.probes.2 = 0x146bbb2a
	local progress = getIntProgress()
	local allFound = true
	
	local countKeys = {0x54abd989, 0x9296ed86, 0x77357d89, 0x00011209, 0xffa15ed5, 0xb6be1add}
	local completed1Keys = {0x7be8d5b3, 0x42b51bbe, 0xaa066013, 0x69ca4687, 0x060c00cd, 0x19289df3}
	local completed2Keys = {0x76abf36a, 0x4ff63d67, 0xa74546ca, 0x6489605e, 0x0b4f2614, 0x146bbb2a}
	
	for x = 1, #countKeys do
		local countKey = countKeys[x]
		local completed1Key = completed1Keys[x]
		local completed2Key = completed2Keys[x]
		local count = progress[countKey]
		local completed1 = progress[completed1Key]
		local completed2 = progress[completed2Key]
		
		if count ~= nil and completed1 ~= nil and completed2 ~= nil then
			local completed = countBits(completed1) + countBits(completed2)
			
			if completed ~= count then
				allFound = false
				break
			end
		else
			allFound = false
			break
		end
	end
	
	if allFound == true then
		unlockTrophy(PROBE_ATION_OFFICER)
	end
end

local H1 = function() -- Graphics::Script::SetFrame
	local luaString = [[
ps4_GiveDNA = progress.GiveDNA
progress.GiveDNA = function(dna)
	print("PS4_GIVEDNA " .. dna)
	ps4_GiveDNA(dna)
end

ps4_bulletproof = cheats.stllts.call
cheats.stllts.call = function()
	local onsite = progress.FindKey("site.active")
	if onsite ~= nil then
		print("PS4_CHEAT_BULLETPROOF")
	end
	ps4_bulletproof()
end

if cheats.stllts.active ~= nil then
	cheats.stllts.active = nil
end

print("PS4_GAME_LUA_PATCHED")

-- disable progressive scan and adjust screen
gui.i.optionsDisplay.table.slots[3] = nil
gui.i.optionsDisplay.table.slots[4] = nil
]]
	eeObj.WriteMemStrZ(0xf7000, luaString)
end

local H2 = function() -- UFO::Progress::AddKey
	local keycrc = eeObj.GetGpr(gpr.s1)
	
	-- *** Main Missions
	-- farm.mission.t1.completed = 0x84dcf6ba (Destination Earth!)
	-- rockwell.mission.m3.completed = 0x0d83f806 (Citizen Crypto)
	-- santa.mission.m2.completed = 0xc0d51662 (The Island Suburbia)
	-- santa.mission.b7.completed  = 0xfaff19cf (Suburb Of The Damned)
	-- area42.mission.m2.completed  = 0x30382164 (Duck And Cover!)
	-- union.mission.m2.completed = 0x3e582db3 (Armiquist vs The Furons!)
	-- capitol.mission.m3.completed = 0x76dba755 (Attack Of The 50ft President!)
	
	if keycrc == 0x84dcf6ba then
		unlockTrophy(FIRST_CONTACT)
	elseif keycrc == 0x0d83f806 then
		unlockTrophy(EMINENCE_GRISE)
	elseif keycrc == 0xc0d51662 then
		unlockTrophy(MARS_NEEDS_INFORMATION)
	elseif keycrc == 0xfaff19cf then
		unlockTrophy(WE_ARE_DOING_IT_LIVE)
	elseif keycrc == 0x30382164 then
		unlockTrophy(BOMBING_RUN)
	elseif keycrc == 0x3e582db3 then
		unlockTrophy(THIS_RIDICULOUS_WAR)
	elseif keycrc == 0x76dba755 then
		unlockTrophy(IMPEACHED)
	end
	
	-- *** Side Missions (farm)
	-- farm.mission.armageddon1.finished (0x24a67bf6) (AddKey)
	-- farm.mission.brainstem1.finished (0xc631ec5f) (AddKey)
	-- farm.mission.race1.finished (0x0f6588cf) (AddKey)
	-- farm.mission.rampage1.finished (0xfd816583) (AddKey)
		
	if keycrc == 0x24a67bf6 or keycrc == 0xc631ec5f or keycrc == 0x0f6588cf or keycrc == 0xfd816583 then
		if bulletproofEnabled == true then
			unlockTrophy(POWER_TRIP)
		end

		local progress = getKeyProgress()
		if progress[0x24a67bf6] ~= nil and progress[0xc631ec5f] ~= nil and progress[0x0f6588cf] ~= nil and progress[0xfd816583] ~= nil then
			unlockTrophy(THE_TYRANT_OF_TURNIPSEED)
		end
	end
	
	-- *** Side Missions (rockwell)
	-- rockwell.mission.armageddon1.finished (0x9d28b1a2) (AddKey)
	-- rockwell.mission.race1.finished (0x53e66cb5) (AddKey)
	-- rockwell.mission.rampage1.finished (0xc34d8df9) (AddKey)
	-- rockwell.mission.rampage3.finished (0xc6add080) (AddKey)
	
	if keycrc == 0x9d28b1a2 or keycrc == 0x53e66cb5 or keycrc == 0xc34d8df9 or keycrc == 0xc6add080 then
		if bulletproofEnabled == true then
			unlockTrophy(POWER_TRIP)
		end

		local progress = getKeyProgress()
		if progress[0x9d28b1a2] ~= nil and progress[0x53e66cb5] ~= nil and progress[0xc34d8df9] ~= nil and progress[0xc6add080] ~= nil then
			unlockTrophy(ROCKED_WELL)
		end
	end
	
	-- *** Side Missions (santa)
	-- santa.mission.race1.finished (0xe988cbf6) (AddKey)
	-- santa.mission.rampage2.finished (0x2393f654) (AddKey)
	
	if keycrc == 0xe988cbf6 or keycrc == 0x2393f654 then
		if bulletproofEnabled == true then
			unlockTrophy(POWER_TRIP)
		end

		local progress = getKeyProgress()
		if progress[0xe988cbf6] ~= nil and progress[0x2393f654] ~= nil then
			unlockTrophy(MODESTLY_SUCCESSFUL)
		end
	end
	
	-- *** Side Missions (area42)
	-- area42.mission.rampage2.finished (0xaa56f9b7) (AddKey)
	-- area42.mission.race1.finished (0xd9d272bd) (AddKey)
	-- area42.mission.armageddon1.finished (0xb764c32c) (AddKey)
	-- area42.mission.cr.finished (0x935b5987) (AddKey)
	
	if keycrc == 0xaa56f9b7 or keycrc == 0xd9d272bd or keycrc == 0xb764c32c or keycrc == 0x935b5987 then
		if bulletproofEnabled == true then
			unlockTrophy(POWER_TRIP)
		end

		local progress = getKeyProgress()
		if progress[0xaa56f9b7] ~= nil and progress[0xd9d272bd] ~= nil and progress[0xb764c32c] ~= nil and progress[0x935b5987] ~= nil then
			unlockTrophy(AREA_86ED)
		end
	end
	
	-- *** Side Missions (union)
	-- union.mission.race2.finished (0x934eb5c0) (AddKey)
	-- union.mission.brainstem1.finished (0xaaa82dc5) (AddKey)
	
	if keycrc == 0x934eb5c0 or keycrc == 0xaaa82dc5 then
		if bulletproofEnabled == true then
			unlockTrophy(POWER_TRIP)
		end

		local progress = getKeyProgress()
		if progress[0x934eb5c0] ~= nil and progress[0xaaa82dc5] ~= nil then
			unlockTrophy(A_MUCH_LESS_PERFECT_UNION)
		end
	end
	
	-- *** Side Missions (capitol)
	-- capitol.mission.rampage1.finished (0x43b069f8) (AddKey)
	-- capitol.mission.rampage2.finished (0xc6c094e6) (AddKey)
	-- capitol.mission.race1.finished (0xdb3df7f2) (AddKey)
	-- capitol.mission.rampage3.finished (0x46503481) (AddKey)
	
	if keycrc == 0x43b069f8 or keycrc == 0xc6c094e6 or keycrc == 0xdb3df7f2 or keycrc == 0x46503481 then
		if bulletproofEnabled == true then
			unlockTrophy(POWER_TRIP)
		end

		local progress = getKeyProgress()
		if progress[0x43b069f8] ~= nil and progress[0xc6c094e6] ~= nil and progress[0xdb3df7f2] ~= nil and progress[0x46503481] ~= nil then
			unlockTrophy(KICKING_GOVERNMENT_IN_THE_SEAT)
		end
	end
	
	-- *** Upgrades
	-- weapon.zapomatic.upgrade3.purchased (0xdff82a6a) (AddKey)
	-- weapon.destructoray.upgrade3.purchased (0x28213a04) (AddKey)
	-- weapon.iondetonator.upgrade3.purchased (0xe7f83d00) (AddKey)
	-- weapon.mattermove.upgrade3.purchased (0xc0ff5ec2) (AddKey)
	
	-- weapon.deathray.upgrade2.purchased (0x085e9038) (AddKey)
	-- weapon.sonicboom.upgrade2.purchased (0xea5c79f1) (AddKey)
	-- weapon.quantum.upgrade2.purchased (0xab5ce87b) (AddKey)
	
	
	if keycrc == 0xdff82a6a then
		unlockTrophy(RIDE_THE_LIGHTNING) -- Zap-O-Matic fully upgraded (3)
	elseif keycrc == 0x28213a04 then
		unlockTrophy(DUST_IN_THE_WIND) -- Disintegrator Ray fully upgraded (3)
	elseif keycrc == 0xe7f83d00 then
		unlockTrophy(EARTH_SHATTERING_KABOOM) -- Ion Detonator fully upgraded (3)
	elseif keycrc == 0xc0ff5ec2 then
		unlockTrophy(MIND_OVER_MATTER) -- Psychokinesis fully upgraded (3)
	elseif keycrc == 0x085e9038 then
		unlockTrophy(DANGER_DEATH_RAY) -- Death Ray fully upgraded (2)
	elseif keycrc == 0xea5c79f1 then
		unlockTrophy(MIND_OVER_ANTIMATTER) -- Sonic Boom fully upgraded (2)
	elseif keycrc == 0xab5ce87b then
		unlockTrophy(NOW_YOU_LEARN_TO_LOVE_THE_BOMB) -- Quantum Deconstructor fully upgraded (2)
	end
	
end

local H3 = function() -- UFO::PickupManager::SetPickedUp

	-- farm.probes.count = 0x54abd989		farm.probes.1 = 0x7be8d5b3		farm.probes.2 = 0x76abf36a
	-- rockwell.probes.count = 0x9296ed86	rockwell.probes.1 = 0x42b51bbe	rockwell.probes.2 = 0x4ff63d67
	-- santa.probes.count = 0x77357d89		santa.probes.1 = 0xaa066013		santa.probes.2 = 0xa74546ca
	-- area42.probes.count = 0x00011209		area42.probes.1 = 0x69ca4687	area42.probes.2 = 0x6489605e
	-- union.probes.count = 0xffa15ed5		union.probes.1 = 0x060c00cd		union.probes.2 = 0x0b4f2614
	-- capitol.probes.count = 0xb6be1add	capitol.probes.1 = 0x19289df3	capitol.probes.2 = 0x146bbb2a

	local stack = eeObj.GetGpr(gpr.sp)
	local completed1Key = eeObj.ReadMem32(stack+0)
	local completed1Value = eeObj.ReadMem32(stack+8)
	local completed2Key = eeObj.ReadMem32(stack+16)
	local completed2Value = eeObj.ReadMem32(stack+24)
	local countKey = eeObj.ReadMem32(stack+32)
	local countValue = eeObj.ReadMem32(stack+40)
	
--	print(string.format("countKey = 0x%08x", countKey))
--	print(string.format("countValue = 0x%08x", countValue))
--	print(string.format("completed1Key = 0x%08x", completed1Key))
--	print(string.format("completed1Value = 0x%08x", completed1Value))
--	print(string.format("completed2Key = 0x%08x", completed2Key))
--	print(string.format("completed2Value = 0x%08x", completed2Value))
	
	if countKey == 0x54abd989 then -- farm.probes.count
		local count = countBits(completed1Value) + countBits(completed2Value)
--		print(string.format("farm.probes: %d/%d", count, countValue))
		if count >= countValue then
			unlockTrophy(DOWN_HOME_COUNTRY_PROBING)
		end
	elseif countKey == 0x9296ed86 then -- rockwell.probes.count
		local count = countBits(completed1Value) + countBits(completed2Value)
--		print(string.format("rockwell.probes: %d/%d", count, countValue))
		if count >= countValue then
			unlockTrophy(SATURDAY_EVENING_PROBE)
		end
	elseif countKey == 0x77357d89 then -- santa.probes.count
		local count = countBits(completed1Value) + countBits(completed2Value)
--		print(string.format("santa.probes: %d/%d", count, countValue))
		if count >= countValue then
			unlockTrophy(SUN_SURF_AND_PROBES)
		end
	elseif countKey == 0x00011209 then -- area42.probes.count
		local count = countBits(completed1Value) + countBits(completed2Value)
--		print(string.format("area42.probes: %d/%d", count, countValue))
		if count >= countValue then
			unlockTrophy(A_CONSPIRACY_OF_PROBES)
		end
	elseif countKey == 0xffa15ed5 then -- union.probes.count
		local count = countBits(completed1Value) + countBits(completed2Value)
--		print(string.format("union.probes: %d/%d", count, countValue))
		if count >= countValue then
			unlockTrophy(PROBE_TOWN_USA)
		end
	elseif countKey == 0xb6be1add then -- capitol.probes.count
		local count = countBits(completed1Value) + countBits(completed2Value)
--		print(string.format("capitol.probes: %d/%d", count, countValue))
		if count >= countValue then
			unlockTrophy(PROBES_WITH_A_CAPITOL_P)
		end
	end
	
	checkAllProbes()
end

local H4 = function() -- luaB_print
	local strptr = eeObj.GetGpr(gpr.s1)
	local strlen = eeObj.GetGpr(gpr.s0)
	
	if strlen > 0 then
		local str = eeObj.ReadMemStr(strptr)
--		print("GAMELUA: " .. str)
		
		if str == "PS4_GAME_LUA_PATCHED" then
			bulletproofEnabled = false
		elseif str == "PS4_CHEAT_BULLETPROOF" then
			bulletproofEnabled = true
		elseif strlen > 12 and string.sub(str, 1, 11) == "PS4_GIVEDNA" then
			local dna = tonumber(string.sub(str, 13))
			if dna ~= 1337 then -- Mmm… Brains! Cheat
				SaveData.dnaCount = SaveData.dnaCount + dna
				if SaveData.dnaCount >= 50000 then
					unlockTrophy(GRAY_MATTERS) -- this will trigger a save, so don't mark it dirty
				else
					SaveDataDirty = true
				end
			end
		elseif strlen > 13 and string.sub(str, 1, 13) == "100% Complete" then
			unlockTrophy(ALIEN_OVERLORD)
		end
	end
end

local H5 = function() -- UFO::Progress::AddF32
	local stack = eeObj.GetGpr(gpr.sp)
	local keycrc = eeObj.ReadMem32(stack)
	local value = eeObj.ReadMemFloat(stack+8)
	
--	print(string.format("keyCRC 0x%08x: %f", keycrc, value))
	
	-- stat_v_total (0x44aaa7df)
	-- stat_kill_brainextraction (0x59a5d3c3)
	-- stat_holo_unique (0x49345989)
	-- stat_h_total (0x76d34624)
	-- cowsPK (0x9b74a5b7) = 14.000000 (AddF32)
	-- stat_r_robot (0xd306bfeb)
	-- stat_h_politician (0x220b73cd)
	
	if keycrc == 0x76d34624 and value == 1000 then --  Kill a total of 1,000 humans.
		unlockTrophy(TERROR_FROM_BEYOND_THE_STARS)
	elseif keycrc == 0x44aaa7df and value == 500 then -- Destroy 500 vehicles.
		unlockTrophy(TRAIL_OF_WRECKAGE)
	elseif keycrc == 0x59a5d3c3 and value == 250 then -- Extract 250 brains.
		unlockTrophy(FOOD_FOR_THOUGHT)
	elseif keycrc == 0x9b74a5b7 and value == 100 then -- Tip 100 cows.
		unlockTrophy(THERES_THE_BEEF)
	elseif keycrc == 0x49345989 and value == 40 then -- Assume 40 identities.
		unlockTrophy(IDENTITY_THIEF)
	elseif keycrc == 0xd306bfeb and value == 50 then -- Destroy 50 robots.
		unlockTrophy(ALIEN_CONQUEROR_VS_ROBOT_SOLDIER)	
	elseif keycrc == 0x220b73cd and value == 50 then -- Assassinate 50 politicians.
		unlockTrophy(TERM_LIMITED)
	end
end

local hook1 = eeObj.AddHook(0x308B18, 0x27bdfff0, H1) -- Graphics::Script::SetFrame
local hook2 = eeObj.AddHook(0x278268, 0x0200202d, H2) -- UFO::Progress::AddKey
local hook3 = eeObj.AddHook(0x2623A4, 0xdfb00030, H3) -- UFO::PickupManager::SetPickedUp
local hook4 = eeObj.AddHook(0x336FA4, 0x0040802d, H4) -- luaB_print
local hook5 = eeObj.AddHook(0x2783E4, 0x0200202d, H5) -- UFO::Progress::AddF32
