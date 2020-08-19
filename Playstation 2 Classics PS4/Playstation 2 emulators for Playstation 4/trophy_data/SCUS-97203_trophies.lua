-- Lua 5.3
-- Title:   Wild Arms 3 PS2 - SCUS-97203 (USA) v1.01
-- Author:  Nicola Salmoria

-- Changelog:


require( "ee-gpr-alias" ) -- you can access EE GPR by alias (gpr.a0 / gpr["a0"])
require( "ee-cpr0-alias" ) -- for EE CPR

apiRequest(0.1)	-- request version 0.1 API. Calling apiRequest() is mandatory.

local eeObj		= getEEObject()
local emuObj	= getEmuObject()
local trophyObj	= getTrophyObject()

-- if a print is uncommented, then that trophy trigger is untested.


local TROPHY_JUST_GETTING_STARTED		=  1
local TROPHY_INTRO_TO_THE_ELEMENTS		=  2
local TROPHY_NOVICE_GUNSLINGER			=  3
local TROPHY_NOVICE_NOMAD				=  4
local TROPHY_MINOR_UPGRADES				=  5
local TROPHY_NIMBLE_FINGERS				=  6
local TROPHY_SHADY_BUSINESS				=  7
local TROPHY_BEST_OF_LUCK				=  8
local TROPHY_HIDDEN_HORTICULTURE		=  9
local TROPHY_JOURNEYMAN_GUNSLINGER		= 10
local TROPHY_MASTER_GUNSLINGER			= 11
local TROPHY_MASTER_MIGRANT				= 12
local TROPHY_FULLY_UPGRADED				= 13
local TROPHY_NOT_OVER_YET				= 14
local TROPHY_LIKE_NO_TOMORROW			= 15
local TROPHY_TAKING_TO_THE_SKIES		= 16
local TROPHY_STORY_TIME					= 17
local TROPHY_PACKING_A_PUNCH			= 18
local TROPHY_YOU_SAID_THE_MAGIC_WORD	= 19
local TROPHY_ARK_SMASH					= 20
local TROPHY_GUARDIANS_OF_FILGAIA		= 21
local TROPHY_MOTHER_OF_THE_UFOS			= 22
local TROPHY_OUT_OF_THE_ABYSS			= 23
local TROPHY_UNCHARTED_TERRITORY		= 24
local TROPHY_CLEVER_GIRL				= 25
local TROPHY_DEMON_DEFEATER				= 26
local TROPHY_DOMINANT_DRIFTERS			= 27



-- convert unsigned int to signed
local function asSigned(n)
	local MAXINT = 0x80000000
	return (n >= MAXINT and n - 2*MAXINT) or n
end

local function asSigned16(n)
	local MAXINT = 0x8000
	return (n >= MAXINT and n - 2*MAXINT) or n
end

-- count elements in a table
local function tableLength(T)
	local count = 0
	for _ in pairs(T) do
		count = count + 1
	end
	return count
end


-- the base of the game state
local function getGameStatePtr()
	return 0x664890
end

local function getCharaPtr(charaId)	-- 0 = Virginia, 1 = Jet, 2 = Clive, 3 = Gallows
	return getGameStatePtr() + 340 + 176 * charaId
end

local function getInventoryPtr()
	return getGameStatePtr() + 14996
end

local function getBattleId()
	local battleAddr = 0x5bece6
	return eeObj.ReadMem16(battleAddr)
end

local function getBattleFlags()
	local flagsAddr = 0x58e340
	return eeObj.ReadMem32(flagsAddr)
end

local function getSandcraftWeaponId()
	local weaponAddr = 0x664d2a
	return eeObj.ReadMem8(weaponAddr)
end

local function isPlayerChara(charaId)
	if charaId >= 0 and charaId <= 3 then
		return true
	else
		local battleFlags = getBattleFlags()
		local isVehicle = ((battleFlags & 0x18) ~= 0)	-- Sandcraft or Lombardia
		if isVehicle and charaId == 5 then	-- the vehicle is 'chara' 5
			return true
		else
			return false
		end
	end
end

local function getInventoryItemCount(requestedItemId)
	local inventoryBase = getInventoryPtr()

	for idx = 0,179	do -- Inventory has 180 slots
		local p = inventoryBase + 10 * idx

		local itemId = eeObj.ReadMem16(p + 0)
		local count = eeObj.ReadMem16(p + 2)

		if itemId == requestedItemId and count > 0 then
			return count
		end
	end
	
	return 0
end

local function checkMediumEquipped(requestedMediumId)
	for charaId = 0,3 do
		local charaPtr = getCharaPtr(charaId)
		local mediumPtr = charaPtr + 76
		for slot = 0,2 do
			local addr = mediumPtr + 2 * slot
			local itemId = eeObj.ReadMem16(addr)

			if itemId == requestedMediumId then
				return true
			end
		end
	end
	
	return false
end

local function checkMediumOwnedOrEquipped(requestedItemId)
	-- convert item id to medium id
	local requestedMediumId = requestedItemId - 243

	return	getInventoryItemCount(requestedItemId) > 0 or
			checkMediumEquipped(requestedMediumId)
end



-- get the minimum level of all party members
local function getMinLevel(base)
	local minLevel = 999
	for i = 0,3 do
		local lv = eeObj.ReadMem16(base + 176 * i)
		minLevel = math.min(minLevel, lv)
	end
	return minLevel
end

local H1 =	-- level up a character
	function()
		local charaLvlPtr = eeObj.GetGpr(gpr.t0)
		local offset = eeObj.GetGpr(gpr.s1)
		local base = charaLvlPtr - offset
		
		local minLevel = getMinLevel(base)
		if minLevel >= 90 then	-- all members at level 90 or above
			local trophy_id = TROPHY_DOMINANT_DRIFTERS
			--	print( string.format("trophy_id=%d", trophy_id) )
			trophyObj.Unlock(trophy_id)
		elseif minLevel >= 50 then	-- all members at level 50 or above
			local trophy_id = TROPHY_GUARDIANS_OF_FILGAIA
			--	print( string.format("trophy_id=%d", trophy_id) )
			trophyObj.Unlock(trophy_id)
		end
	end



local ADDITEM_CALLER_SCRIPT = 1	-- items found in chests, enemy drops, story progression, etc.
local ADDITEM_CALLER_CODE = 2	-- items bought in shops, menu interaction, etc.

local function addItem(itemId, newCount, caller)
	if itemId == 95 then	-- Migrant Seal
		local level = newCount + 1	-- Migrant Level = # of seals + 1

		if level >= 20 then	-- Migrant Level 20
			local trophy_id = TROPHY_MASTER_MIGRANT
			--	print( string.format("trophy_id=%d", trophy_id) )
			trophyObj.Unlock(trophy_id)
		elseif level >= 5 then	-- Migrant Level 5
			local trophy_id = TROPHY_NOVICE_NOMAD
			--	print( string.format("trophy_id=%d", trophy_id) )
			trophyObj.Unlock(trophy_id)
		end
	end

	if caller == ADDITEM_CALLER_SCRIPT then	-- only if added by scripts
		local medium1 = 243	-- Terra Roar
		local medium2 = 244	-- Aqua Wisp
		local medium3 = 245	-- Fiery Rage
		local medium4 = 246	-- Gale Claw
		if		itemId == medium1 or	-- one of the first four mediums
				itemId == medium2 or
				itemId == medium3 or
				itemId == medium4 then
			if		checkMediumOwnedOrEquipped(medium1) and	-- have all four mediums
					checkMediumOwnedOrEquipped(medium2) and
					checkMediumOwnedOrEquipped(medium3) and
					checkMediumOwnedOrEquipped(medium4) then
				local trophy_id = TROPHY_INTRO_TO_THE_ELEMENTS
				--	print( string.format("trophy_id=%d", trophy_id) )
				trophyObj.Unlock(trophy_id)
			end
		end
	end
end


local H2A =	-- increase quantity of item already in inventory (called by scripts)
	function()
		local itemId = eeObj.GetGpr(gpr.a0)
		local count = eeObj.GetGpr(gpr.v0)

		addItem(itemId, count, ADDITEM_CALLER_SCRIPT)
	end


local H2B =	-- add item to inventory (called by scripts)
	function()
		local itemId = eeObj.GetGpr(gpr.a0)
		local count = eeObj.GetGpr(gpr.v1)	-- always 1

		addItem(itemId, count, ADDITEM_CALLER_SCRIPT)
	end


local H2C =	-- increase quantity of item in inventory (called by code)
	function()
		local itemId = eeObj.GetGpr(gpr.s1)
		local count = eeObj.GetGpr(gpr.v0)

		addItem(itemId, count, ADDITEM_CALLER_CODE)
	end


local H3 =	-- won a battle (the same function is hooked at two different addresses)
	function()
		local battleId = getBattleId()
		local battleFlags = getBattleFlags()
		local isSandcraft = ((battleFlags & 0x08) ~= 0)
		local isLombardia = ((battleFlags & 0x10) ~= 0)

		if battleId == 32 then	-- Janus, Dario, and Romero at end of Prologue
			local trophy_id = TROPHY_JUST_GETTING_STARTED
			--	print( string.format("trophy_id=%d", trophy_id) )
			trophyObj.Unlock(trophy_id)
		elseif battleId == 50 then	-- Janus at end of Chapter 1
			local trophy_id = TROPHY_NOT_OVER_YET
			--	print( string.format("trophy_id=%d", trophy_id) )
			trophyObj.Unlock(trophy_id)
		elseif battleId == 80 then	-- Leehalt, Melody, and Malik at end of Chapter 2
			local trophy_id = TROPHY_LIKE_NO_TOMORROW
			--	print( string.format("trophy_id=%d", trophy_id) )
			trophyObj.Unlock(trophy_id)
		elseif battleId == 103 then	-- Dragna Sieg at end of Chapter 3
			local trophy_id = TROPHY_TAKING_TO_THE_SKIES
			--	print( string.format("trophy_id=%d", trophy_id) )
			trophyObj.Unlock(trophy_id)
		elseif battleId == 158 then	-- Armordrake (last battle of Gunner's Heaven Novice Division)
			local trophy_id = TROPHY_NOVICE_GUNSLINGER
			--	print( string.format("trophy_id=%d", trophy_id) )
			trophyObj.Unlock(trophy_id)
		elseif battleId == 167 then	-- 8x Egregori (last battle of Gunner's Heaven Journeyman Division)
			local trophy_id = TROPHY_JOURNEYMAN_GUNSLINGER
			--	print( string.format("trophy_id=%d", trophy_id) )
			trophyObj.Unlock(trophy_id)
		elseif battleId == 174 then	-- Bad News (last optional boss at Gunner's Heaven)
			local trophy_id = TROPHY_MASTER_GUNSLINGER
			--	print( string.format("trophy_id=%d", trophy_id) )
			trophyObj.Unlock(trophy_id)
		elseif battleId == 108 then	-- Lolithia at Mimir's Well
			local trophy_id = TROPHY_YOU_SAID_THE_MAGIC_WORD
			--	print( string.format("trophy_id=%d", trophy_id) )
			trophyObj.Unlock(trophy_id)
		elseif battleId == 154 then	-- Mothership
			local trophy_id = TROPHY_MOTHER_OF_THE_UFOS
			--	print( string.format("trophy_id=%d", trophy_id) )
			trophyObj.Unlock(trophy_id)
		elseif battleId == 95 then	-- Ragu O Ragla (second time)
			local trophy_id = TROPHY_OUT_OF_THE_ABYSS
			--	print( string.format("trophy_id=%d", trophy_id) )
			trophyObj.Unlock(trophy_id)
		elseif battleId == 128 then	-- Nega Filgaia at end of Chapter 4 (end of game)
			local trophy_id = TROPHY_DEMON_DEFEATER
			--	print( string.format("trophy_id=%d", trophy_id) )
			trophyObj.Unlock(trophy_id)
		end

		if		isSandcraft and						-- won Sandcraft battle
				getSandcraftWeaponId() == 7 then	-- Ark Smasher
			local trophy_id = TROPHY_ARK_SMASH
			--	print( string.format("trophy_id=%d", trophy_id) )
			trophyObj.Unlock(trophy_id)
		end
	end


local H4 =	-- increased an ARM attribute
	function()
		local level = eeObj.GetGpr(gpr.v1) - 1	-- NB need to subtract 1 to get real level!

		if level >= 5 then
			local trophy_id = TROPHY_MINOR_UPGRADES
			--	print( string.format("trophy_id=%d", trophy_id) )
			trophyObj.Unlock(trophy_id)
		end
	end


local H5 =	-- increased overall ARM level
	function()
		local level = eeObj.GetGpr(gpr.v1) - 1	-- NB need to subtract 1 to get real level!

		if level >= 15 then
			local trophy_id = TROPHY_FULLY_UPGRADED
			--	print( string.format("trophy_id=%d", trophy_id) )
			trophyObj.Unlock(trophy_id)
		end
	end


local H6 =	-- disarmed a trapped treasure chest
	function()
		local trophy_id = TROPHY_NIMBLE_FINGERS
		--	print( string.format("trophy_id=%d", trophy_id) )
		trophyObj.Unlock(trophy_id)
	end


local H7 =	-- bought something from the Black Market
	function()
		local trophy_id = TROPHY_SHADY_BUSINESS
		--	print( string.format("trophy_id=%d", trophy_id) )
		trophyObj.Unlock(trophy_id)
	end


local function getCharaLCK(charaId)
	local charaPtr = getCharaPtr(charaId)
	return eeObj.ReadMem16(charaPtr + 70)
end

local H8 =	-- computed new LCK for one character
	function()
		local lck = eeObj.GetGpr(gpr.v0)
		local charaId = eeObj.GetGpr(gpr.s0)

		-- NB the new LCK hasn't yet been stored in the chacter parameters!
		-- so getCharaLCK for that character returns the previous value
		if lck == 4	and getCharaLCK(charaId) < 4 then -- LCK of character increased to BEST
			local allBest = true
			for id = 0,3 do
				if id ~= charaId and getCharaLCK(id) ~= 4 then	-- LCK of other character is not BEST
					allBest = false
				end
			end

			if allBest then
				local trophy_id = TROPHY_BEST_OF_LUCK
				--	print( string.format("trophy_id=%d", trophy_id) )
				trophyObj.Unlock(trophy_id)
			end
		end
	end


local H9 =	-- set a global flag
	function()
		local flagNum = eeObj.GetGpr(gpr.a0)
		local flagAddr = eeObj.GetGpr(gpr.a2)
		local bitmapBase = eeObj.GetGpr(gpr.v1)
		
		local currValue = eeObj.ReadMem32(flagAddr)
		local flagMask = 1 << (flagNum & 0x1f)
		local nextValue = currValue | flagMask

		if flagNum == 2311 then	-- got EX File Key from Kaitlyn
			local trophy_id = TROPHY_STORY_TIME
			--	print( string.format("trophy_id=%d", trophy_id) )
			trophyObj.Unlock(trophy_id)
		end
		
		if flagNum >= 501 and flagNum <= 520 then	-- solved one of the Millennium Puzzles
			local allSolved = true
			for i = 501,520 do
				if i ~= flagNum then
					local idx = i >> 5
					local msk = 1 << (i & 0x1f)
					local addr = bitmapBase + 4 * idx
					local v = eeObj.ReadMem32(addr)
					if (v & msk) == 0 then
						allSolved = false
					end
				end				
			end

			if allSolved then	-- solved all 20 Millennium Puzzles
				local trophy_id = TROPHY_CLEVER_GIRL
				--	print( string.format("trophy_id=%d", trophy_id) )
				trophyObj.Unlock(trophy_id)
			end
		end
	end


local H10 =	-- set flag for visited map block
	function()
		local flagNum = eeObj.GetGpr(gpr.a0)
		local flagAddr = eeObj.GetGpr(gpr.a2)
		local bitmapBase = eeObj.GetGpr(gpr.v1)

		local currValue = eeObj.ReadMem32(flagAddr)
		local flagMask = 1 << (flagNum & 0x1f)
		local nextValue = currValue | flagMask

		if currValue ~= 0xffffffff and nextValue == 0xffffffff then	-- visited all blocks stored at this address
			local flagIdx = flagNum >> 5
			local allVisited = true
			for idx = 0,127 do
				if		idx ~= flagIdx and
						eeObj.ReadMem32(bitmapBase + 4 * idx) ~= 0xffffffff then
					allVisited = false
				end
			end
			
			if allVisited then	-- explored 100% of map
				local trophy_id = TROPHY_UNCHARTED_TERRITORY
				--	print( string.format("trophy_id=%d", trophy_id) )
				trophyObj.Unlock(trophy_id)
			end
		end
	end


local H11 =	-- subtract value from character HP
	function()
		local charaId = eeObj.GetGpr(gpr.a0)
		local amount = asSigned(eeObj.GetGpr(gpr.a1))

		if 		not isPlayerChara(charaId) and		-- enemy character
				amount >= 50000 then				-- more than 50,000 damage
			local trophy_id = TROPHY_PACKING_A_PUNCH
			--	print( string.format("trophy_id=%d", trophy_id) )
			trophyObj.Unlock(trophy_id)
		end
	end


local H12 =	-- increment the growing probability of a plant
	function()
		local trophy_id = TROPHY_HIDDEN_HORTICULTURE
		--	print( string.format("trophy_id=%d", trophy_id) )
		trophyObj.Unlock(trophy_id)
	end




local CH1A =	-- subtract value from character HP
	function()
		local charaId = eeObj.GetGpr(gpr.a0)

		if isPlayerChara(charaId) then	-- player character
			eeObj.SetGpr(gpr.a1, 0)	-- don't change
		else							-- enemy
			eeObj.SetGpr(gpr.a1, 999999)	-- max damage
		end
	end

local CH1B =	-- subtract value from character HP
	function()
		local hp = eeObj.GetGpr(gpr.t0)
		local damage = eeObj.GetGpr(gpr.t1)
		eeObj.SetGpr(gpr.t0, hp + damage)	-- undo damage
	end

local CH1C =	-- subtract value from character HP
	function()
		local hp = eeObj.GetGpr(gpr.t0)
		local damage = eeObj.GetGpr(gpr.t2)
		eeObj.SetGpr(gpr.t0, hp + damage)	-- undo damage
	end

local CH2 =	-- decrease ECN
	function()
		eeObj.SetGpr(gpr.v1, 0)	-- don't change
	end

local CH3 =	-- check if trigger random encounter
	function()
		eeObj.SetGpr(gpr.at, 0)	-- never encounter
	end

local CH4 =	-- compute EXP increment
	function()
		eeObj.SetGpr(gpr.v1, 9999999)	-- lots of EXP
	end

local CH5 =	-- compute Gella increment
	function()
		eeObj.SetGpr(gpr.v0, 9999999)	-- lots of Gella
	end

local CH6 =	-- divider for rng of dropped items
	function()
		eeObj.SetGpr(gpr.v1, 1)
	end

local CH7A =	-- test whether trap disarmed
	function()
		eeObj.SetGpr(gpr.at, 0)	-- always disarm
	end

local CH7B =	-- test whether trap disarmed
	function()
		eeObj.SetGpr(gpr.at, 1)	-- never disarm
	end




-- register hooks
local hook1  = eeObj.AddHook(0x18e054, 0xa5030000, H1)	-- <Prty_LevelUp>:
local hook2a = eeObj.AddHook(0x172150, 0xa4c20000, H2A)	-- <AddItm>:
local hook2b = eeObj.AddHook(0x172208, 0xa4430000, H2B)	-- <AddItm>:
local hook2b = eeObj.AddHook(0x18d42c, 0xa4620000, H2C)	-- <AddItem>:
local hook3a = eeObj.AddHook(0x233514, 0x3c010059, H3)	-- <prcWin>:
local hook3b = eeObj.AddHook(0x23374c, 0x3c01005c, H3)	-- <prcWin>:
local hook4  = eeObj.AddHook(0x29287c, 0xa4c30000, H4)	-- <_menuu_armsPrc>:
local hook5  = eeObj.AddHook(0x292888, 0xa4a30000, H5)	-- <_menuu_armsPrc>:
local hook6  = eeObj.AddHook(0x232900, 0xa422ec56, H6)	-- <PrcTBox>:
local hook7  = eeObj.AddHook(0x299324, 0x24020061, H7)	-- <_menuu_shopPrc>:
local hook8  = eeObj.AddHook(0x18df70, 0xdfbf0010, H8)	-- <Calc_LCK>:
local hook9  = eeObj.AddHook(0x1719bc, 0x00653021, H9)	-- <SetFlag>:
local hook10 = eeObj.AddHook(0x171b8c, 0x00653021, H10)	-- <SetOutFlag>:
local hook11 = eeObj.AddHook(0x1fd710, 0x27bdffc0, H11)	-- <ChgHP>:
local hook12 = eeObj.AddHook(0x2720a4, 0x24630001, H12)	-- <_menuu_gurdPrc>:



-- cheats; disable for release
-- invincibility in battle + one hit kills
-- disable to get past the end of Chapter 2 and other 'spectator' battles!
--local cheat1a = eeObj.AddHook(0x1fd714, 0x7fb10010, CH1A)	-- <ChgHP>:
-- no damage from traps
--local cheat1b = eeObj.AddHook(0x230f0c, 0x01094023, CH1B)	-- <Set_Damage>:
-- no damage from poison
--local cheat1c = eeObj.AddHook(0x13ed94, 0x010a4023, CH1C)	-- <Prc_Doku>:
-- infinite ECN
--local cheat2 = eeObj.AddHook(0x1f82d0, 0x00031c3f, CH2)	-- <Encount>:
-- avoid random encounters
-- NB disable to fight Diobarg and UFOs!
--local cheat3 = eeObj.AddHook(0x1f802c, 0x0083082a, CH3)	-- <Encount>:
-- lots of EXP at end of battle
--local cheat4 = eeObj.AddHook(0x234278, 0x00641821, CH4)	-- <_menub_campSet>:
-- lots of Gella at end of battle
--local cheat5 = eeObj.AddHook(0x233e78, 0x8c420000, CH5)	-- <_menub_campSet>:



-- Credits

-- Trophy design and development by SCEA ISD SpecOps
-- David Thach Senior Director
-- George Weising Executive Producer
-- Tim Lindquist Senior Technical PM
-- Clay Cowgill Engineering
-- Nicola Salmoria Engineering
-- Jenny Murphy Producer
-- David Alonzo Assistant Producer
-- Tyler Chan Associate Producer
-- Karla Quiros Manager Business Finance & Ops
-- Special thanks to A-R&D
