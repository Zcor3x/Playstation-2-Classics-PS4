-- Lua 5.3
-- Title:   Rogue Galaxy PS2 - SCES-54552 (Europe)
-- Author:  Nicola Salmoria

-- Changelog:
-- 20150326 NS removed use of AddLoginHook
-- 20150330 NS rewritten trophy 15 to check for successful Burning Strike attack
--             rewritten trophy 17 to check for level -> 99 instead of HP -> 999
-- 20150404 NS added credits at the end of the file
--             added code to force the game to NTSC mode
-- 20150430 NS fixed bug #8413
-- 20150611 NS fixed video mode initialization (was using PAL instead of NTSC)


require( "ee-gpr-alias" ) -- you can access EE GPR by alias (gpr.a0 / gpr["a0"])
require( "ee-cpr0-alias" ) -- for EE CPR

apiRequest(0.1)	-- request version 0.1 API. Calling apiRequest() is mandatory.

local eeObj		= getEEObject()
local emuObj	= getEmuObject()
local trophyObj	= getTrophyObject()

-- if a print is uncommented, then that trophy trigger is untested.


-- persistent state handling
local userId = 0
local saveData = emuObj.LoadConfig(userId)

local SAVEDATA_THROWN_KILLS_COUNT = "Thrown"


local TROPHY_STELLAR_STYLE				=  1
local TROPHY_SPACE_BEATLES				=  2
local TROPHY_TRASH_DIGGER				=  3
local TROPHY_MIRROR_MIRROR				=  4
local TROPHY_NIMBLE_FINGERS				=  5
local TROPHY_THE_DEPARTURE				=  6
local TROPHY_THE_JUNGLE_PLANET			=  7
local TROPHY_THE_STAR_GODS_ALTAR		=  8
local TROPHY_THE_GREAT_ESCAPE			=  9
local TROPHY_THE_MASTER_HACKER			= 10
local TROPHY_THE_GUIDE					= 11
local TROPHY_SUCCESSFUL_PRODUCTION		= 12
local TROPHY_GIMME_SOMETHIN_TASTY		= 13
local TROPHY_A_SKILLED_SWASHBUCKLER		= 14
local TROPHY_HOT_KNIFE_THROUGH_BUTTER	= 15
local TROPHY_WHATEVER_WORKS				= 16
local TROPHY_A_STRONG_CONSTITUTION		= 17
local TROPHY_OUCH						= 18
local TROPHY_SPACE_WHIZ					= 19
local TROPHY_GHOST_SHIP_CONQUEROR		= 20
local TROPHY_DEFINITELY_NOT_TREASURE	= 21
local TROPHY_UNLOCKING_THE_GALAXY		= 22
local TROPHY_VALKOGS_AMBITION			= 23
local TROPHY_CHASING_A_LEGEND			= 24
local TROPHY_MYSTERY_OF_EDEN			= 25
local TROPHY_THE_ILLUSORY_OASIS			= 26
local TROPHY_THE_LEGENDARY_PLANET		= 27
local TROPHY_ALL_GOOD_THINGS			= 28
local TROPHY_LORD_OF_THE_BUGS			= 29
local TROPHY_FACTORY_WORKER				= 30
local TROPHY_BOUNTY_HUNTER				= 31
local TROPHY_KEEPER_OF_THE_BLADES		= 32
local TROPHY_BEST_IN_THE_GALAXY			= 33
local TROPHY_ONCE_AND_FOR_ALL			= 34


-- some constants to access the game objects

local offs_CommonUnitStatus_UnitId = 4
local offs_CommonUnitStatus_ClassId = 8
local offs_CommonUnitStatus_CurrentHP = 20

local offs_CharaStatus_CharaParams = 560
local offs_CharaParams_Name = 4

local offs_MonsterStatus_MonsterParams = 564
local offs_MonsterStatus_Letter = 568

local offs_MonsterParams_Name = 4

local classId_SubCharaStatus = 1001
local classId_MainCharaStatus = 1002
local classId_HeroCharaStatus = 1003
local classId_StandardMonsterStatus = 2001
local classId_BossMonsterStatus = 2501
local classId_BossPartMonsterStatus = 2502

local offs_Possession_ItemId = 12



local function unitStatusGetClassId(statusPtr)
	return eeObj.ReadMem32(statusPtr + offs_CommonUnitStatus_ClassId)
end

local function unitStatusGetUnitId(statusPtr)
	return eeObj.ReadMem32(statusPtr + offs_CommonUnitStatus_UnitId)
end

local function charaStatusGetName(statusPtr)
	local paramPtr = eeObj.ReadMem32(statusPtr + offs_CharaStatus_CharaParams)
	local namePtr = eeObj.ReadMem32(paramPtr + offs_CharaParams_Name)
	return eeObj.ReadMemStr(namePtr)
end

local function monsterStatusGetName(statusPtr)
	local paramPtr = eeObj.ReadMem32(statusPtr + offs_MonsterStatus_MonsterParams)
	local namePtr = eeObj.ReadMem32(paramPtr + offs_MonsterParams_Name)
	return eeObj.ReadMemStr(namePtr)
end

local function monsterStatusGetFullName(statusPtr)
	local name = monsterStatusGetName(statusPtr)
	local letter = 0xff & eeObj.ReadMem32(statusPtr + offs_MonsterStatus_Letter)

	if letter == 0 then
		return name
	else
		return string.format("%s %c", name, letter)
	end
end

local function isCharaClassId(classId)
	return (classId == classId_HeroCharaStatus or
			classId == classId_MainCharaStatus)
end

local function isMonsterClassId(classId)
	return (classId == classId_StandardMonsterStatus or
			classId == classId_BossMonsterStatus or
			classId == classId_BossPartMonsterStatus)
end

-- convert unsigned int to signed
local function asSigned(n)
	local MAXINT = 2 ^ 31
	return (n >= MAXINT and n - 2*MAXINT) or n
end


local H1 =	-- set flag for item obtained
	function()
		-- NB at the point of the hook, 16000 has been subtracted from the item ID, so we add it back
		local itemId = eeObj.GetGpr(gpr.s1) + 16000
		local gotIt = eeObj.GetGpr(gpr.s0)	-- seems to always be 1 (flags are not reset for discarded items)

		if gotIt ~= 0 then
			-- there are 1280 flags, stored in a bitfield of 160 bytes
			local sp = eeObj.GetGpr(gpr.sp)
			local bitfield = eeObj.ReadMem32(sp + 56)

			--	print( string.format("obtained item %d", itemId) )
		
			if itemId == 16758 then		-- Rakshasa Heart
				local trophy_id = TROPHY_TRASH_DIGGER
				--	print( string.format("trophy_id=%d", trophy_id) )
				trophyObj.Unlock(trophy_id)
			elseif itemId == 16754 then	-- Mirror of Truth
				local trophy_id = TROPHY_MIRROR_MIRROR
				--	print( string.format("trophy_id=%d", trophy_id) )
				trophyObj.Unlock(trophy_id)
			elseif itemId == 16650 then	-- Key to the Underworld
				local trophy_id = TROPHY_SPACE_WHIZ
				--	print( string.format("trophy_id=%d", trophy_id) )
				trophyObj.Unlock(trophy_id)
			elseif 	itemId == 16641 or		-- Earth Key
					itemId == 16642 or		-- Star Key
					itemId == 16643 then	-- Sun Key

				-- extract the bits related to all the keys
				local flags = eeObj.ReadMem8(bitfield + 80) & 0x0e

				-- check if all keys have been obtained
				if flags == 0x0e then	-- 16641..16643
					local trophy_id = TROPHY_UNLOCKING_THE_GALAXY
					--	print( string.format("trophy_id=%d", trophy_id) )
					trophyObj.Unlock(trophy_id)
				end
			elseif	itemId == 16062 or		-- Earthshaker
					itemId == 16066 or		-- Kingdom Master
					itemId == 16070 or		-- Dark Cloud
					itemId == 16074 or		-- Babylon Reborn
					itemId == 16078 or		-- Ragnarok
					itemId == 16082 or		-- Guard Axis
					itemId == 16086 then	-- Gryphon Lord

				-- extract the bits related to all the seven star swords
				local flags0 = eeObj.ReadMem8(bitfield +  7) & 0xf8
				local flags1 = eeObj.ReadMem8(bitfield +  8)
				local flags2 = eeObj.ReadMem8(bitfield +  9)
				local flags3 = eeObj.ReadMem8(bitfield + 10) & 0x7f

				-- check if all swords have been obtained
				if		flags0 == 0xf8 and 	-- 16059..16063
						flags1 == 0xff and	-- 16064..16071
						flags2 == 0xff and	-- 16072..16079
						flags3 == 0x7f then	-- 16080..16086
					local trophy_id = TROPHY_KEEPER_OF_THE_BLADES
					--	print( string.format("trophy_id=%d", trophy_id) )
					trophyObj.Unlock(trophy_id)
				end
			end
		end
	end


local H1A =	-- check if item position is in range owned by player (i.e., not shop)
	function()
		local position = eeObj.GetGpr(gpr.s1)

		if 710 <= position and position < 726 then	-- inside extraordinary bag
			eeObj.SetGpr(gpr.at, 0)	-- affirm that it's owned by the player
		end
	end


local H2 =	-- set character costume
	function()
		local possessionPtr = eeObj.GetGpr(gpr.s0)	-- instance of Possession class
		local itemId = eeObj.ReadMem32(possessionPtr + offs_Possession_ItemId)

		-- check if it's an alternate costume
		if		itemId ~= 16514 and		-- Desert-Dweller's Clothes (Jaster's default)
				itemId ~= 16519 and		-- Light Skirt (Kisala's default)
				itemId ~= 16525 and		-- Spacesuit (Simon's default)
				itemId ~= 16530 and		-- Titanium Armor (Steve's default)
				itemId ~= 16535 and		-- Ebony Coat (Zegram's default)
				itemId ~= 16540 and		-- Warrior's Clothes (Lilika's default)
				itemId ~= 16545 and 	-- Leather Wear (Jupi's default)
				itemId ~= 16550 and		-- Taurus Attachment (Deego's default)
				itemId ~= 16555 then	-- Traveler's Clothes (Hooded Man's one and only)
			local trophy_id = TROPHY_STELLAR_STYLE
			--	print( string.format("trophy_id=%d", trophy_id) )
			trophyObj.Unlock(trophy_id)
		end
	end


local H3 =	-- assign ability to character
	function()
		local abilityId = eeObj.GetGpr(gpr.a1)

		-- check if it's one of Jaster's level three abilities
		if		abilityId ==  103 or	-- Flash Sword Lv3
				abilityId ==  143 or	-- Desert Wind Lv3
				abilityId ==  173 or	-- Fated Passion Lv3
				abilityId ==  183 or	-- Supernova Lv3
				abilityId == 1323 or	-- Attack Up Lv3
				abilityId == 1003 or	-- Fire Resistance  Lv3 [sic double space]
				abilityId == 1343 then	-- Burning Strike Lv3
			local trophy_id = TROPHY_A_SKILLED_SWASHBUCKLER
			--	print( string.format("trophy_id=%d", trophy_id) )
			trophyObj.Unlock(trophy_id)
		end
	end


local H4 =	-- get a text message
	function()
		local msgId = eeObj.GetGpr(gpr.a0)

		if msgId == 20 then	-- "Successfully disarmed the trap"
			local trophy_id = TROPHY_NIMBLE_FINGERS
			--	print( string.format("trophy_id=%d", trophy_id) )
			trophyObj.Unlock(trophy_id)
		end
	end


local H5 =	-- set new character level
	function()
		local newLevel = eeObj.GetGpr(gpr.a0)

		if newLevel >= 99 then
			local trophy_id = TROPHY_A_STRONG_CONSTITUTION
			--	print( string.format("trophy_id=%d", trophy_id) )
			trophyObj.Unlock(trophy_id)
		end
	end


local H6 =	-- process Burning Strike attack
	function()
		local sp = eeObj.GetGpr(gpr.sp)
		local numHits = eeObj.ReadMem16(sp + 270)
		local maxHits = eeObj.ReadMem16(sp + 272)

		if numHits == maxHits then	-- successful attack
			local trophy_id = TROPHY_HOT_KNIFE_THROUGH_BUTTER
			--	print( string.format("trophy_id=%d", trophy_id) )
			trophyObj.Unlock(trophy_id)
		end
	end


local H7 =	-- set global flag bit
	function()
		local flagNum = eeObj.GetGpr(gpr.s3)
		local flagValue = eeObj.GetGpr(gpr.s2)

		if		flagNum >= 500 and flagNum <= 521 and	-- quarry flag
				flagValue ~= 0 then						-- quarry completed

			--	print( string.format("Quarry completed! %d = %d", flagNum, flagValue) )

			-- there are 2048 flags, stored in a bitfield of 256 bytes
			local sp = eeObj.GetGpr(gpr.sp)
			local bitfield = eeObj.ReadMem32(sp + 96)

			-- extract the bits related to all the quarries
			local flags0 = eeObj.ReadMem8(bitfield + 62) & 0xf0
			local flags1 = eeObj.ReadMem8(bitfield + 63)
			local flags2 = eeObj.ReadMem8(bitfield + 64)
			local flags3 = eeObj.ReadMem8(bitfield + 65) & 0x03

			-- check if all quarries are completed
			if		flags0 == 0xf0 and 	-- 500..503
					flags1 == 0xff and	-- 504..511
					flags2 == 0xff and	-- 512..519
					flags3 == 0x03 then	-- 520..521
				local trophy_id = TROPHY_BOUNTY_HUNTER
				--	print( string.format("trophy_id=%d", trophy_id) )
				trophyObj.Unlock(trophy_id)
			end
		end
	end


local H8 =	-- change chapter ID
	function()
		local newChapter = 0xffff & eeObj.GetGpr(gpr.s0)
--		local oldChapter = 0xffff & eeObj.GetGpr(gpr.v0)

		--	print( string.format("SET CURRENT CHAPTER %d", newChapter) )
		
		if newChapter == 2 then
			local trophy_id = TROPHY_THE_DEPARTURE
			--	print( string.format("trophy_id=%d", trophy_id) )
			trophyObj.Unlock(trophy_id)
		elseif newChapter == 3 then
			local trophy_id = TROPHY_THE_JUNGLE_PLANET
			--	print( string.format("trophy_id=%d", trophy_id) )
			trophyObj.Unlock(trophy_id)
		elseif newChapter == 4 then
			local trophy_id = TROPHY_THE_STAR_GODS_ALTAR
			--	print( string.format("trophy_id=%d", trophy_id) )
			trophyObj.Unlock(trophy_id)
		elseif newChapter == 5 then
			local trophy_id = TROPHY_THE_GREAT_ESCAPE
			--	print( string.format("trophy_id=%d", trophy_id) )
			trophyObj.Unlock(trophy_id)
		elseif newChapter == 6 then
			local trophy_id = TROPHY_THE_MASTER_HACKER
			--	print( string.format("trophy_id=%d", trophy_id) )
			trophyObj.Unlock(trophy_id)
		elseif newChapter == 7 then
			local trophy_id = TROPHY_THE_GUIDE
			print( string.format("trophy_id=%d", trophy_id) )
			trophyObj.Unlock(trophy_id)
		elseif newChapter == 8 then
			local trophy_id = TROPHY_VALKOGS_AMBITION
			print( string.format("trophy_id=%d", trophy_id) )
			trophyObj.Unlock(trophy_id)
		elseif newChapter == 9 then
			local trophy_id = TROPHY_CHASING_A_LEGEND
			print( string.format("trophy_id=%d", trophy_id) )
			trophyObj.Unlock(trophy_id)
		elseif newChapter == 10 then
			local trophy_id = TROPHY_MYSTERY_OF_EDEN
			print( string.format("trophy_id=%d", trophy_id) )
			trophyObj.Unlock(trophy_id)
		elseif newChapter == 11 then
			local trophy_id = TROPHY_THE_ILLUSORY_OASIS
			print( string.format("trophy_id=%d", trophy_id) )
			trophyObj.Unlock(trophy_id)
		elseif newChapter == 12 then
			local trophy_id = TROPHY_THE_LEGENDARY_PLANET
			print( string.format("trophy_id=%d", trophy_id) )
			trophyObj.Unlock(trophy_id)
		elseif newChapter == 13 then
			local trophy_id = TROPHY_ALL_GOOD_THINGS
			print( string.format("trophy_id=%d", trophy_id) )
			trophyObj.Unlock(trophy_id)
		end
	end


local H9 =	-- increment monster kill count
	function()
		local monsterId = eeObj.GetGpr(gpr.a1)

--		print( string.format("Killed Monster %d", monsterId) )

		if		monsterId == 12031 then	-- Valkog
			local trophy_id = TROPHY_ONCE_AND_FOR_ALL
			--	print( string.format("trophy_id=%d", trophy_id) )
			trophyObj.Unlock(trophy_id)
		elseif monsterId == 12422 then	-- Doppelganger
			local trophy_id = TROPHY_GHOST_SHIP_CONQUEROR
			--	print( string.format("trophy_id=%d", trophy_id) )
			trophyObj.Unlock(trophy_id)
		elseif	monsterId == 13116 or	-- any of the Mimics
				monsterId == 13127 or
				monsterId == 13128 or
				monsterId == 13166 or
				monsterId == 13167 or
				monsterId == 13168 or
				monsterId == 13194 or
				monsterId == 13195 or
				monsterId == 13212 or
				monsterId == 13213 or
				monsterId == 13266 or
				monsterId == 13267 or
				monsterId == 13268 or
				monsterId == 13303 or
				monsterId == 13304 or
				monsterId == 13305 or
				monsterId == 13494 or
				monsterId == 13667 or
				monsterId == 13767 then
			local trophy_id = TROPHY_DEFINITELY_NOT_TREASURE
			--	print( string.format("trophy_id=%d", trophy_id) )
			trophyObj.Unlock(trophy_id)
		end
	end


local H10 =	-- add synthesized weapon to inventory
	function()
		local trophy_id = TROPHY_GIMME_SOMETHIN_TASTY
		--	print( string.format("trophy_id=%d", trophy_id) )
		trophyObj.Unlock(trophy_id)
	end


local H11 =	-- set during which game phase a blueprint item has been built in the factory
	function()
		local table = 2112 + eeObj.GetGpr(gpr.a0)

		local itemId = eeObj.GetGpr(gpr.a1)
		local phase = eeObj.GetGpr(gpr.a2)
		--	print( string.format("Factory: Developed item %d in phase %d!", itemId, phase) )

		if phase ~= 0xff then	-- seems to always be true, but just in case
			local trophy_id = TROPHY_SUCCESSFUL_PRODUCTION
			print( string.format("trophy_id=%d", trophy_id) )
			trophyObj.Unlock(trophy_id)
		end

		-- check if all 36 items have been completed
		local allCompleted = true
		for i = 0,35 do
			if eeObj.ReadMem8(table + i) == 0xff then
				allCompleted = false
			end
		end

		if allCompleted then
			local trophy_id = TROPHY_FACTORY_WORKER
			print( string.format("trophy_id=%d", trophy_id) )
			trophyObj.Unlock(trophy_id)
		end
	end


local H12 =	-- increment damage in Burning Strike combo
	function()
		local totalDamage = eeObj.GetGpr(gpr.v0)

		if totalDamage >= 14000 then
			local trophy_id = TROPHY_OUCH
			--	print( string.format("trophy_id=%d", trophy_id) )
			trophyObj.Unlock(trophy_id)
		end
	end


local H13 =	-- won match in Insector tournament
	function()
		local trophy_id = TROPHY_SPACE_BEATLES
		print( string.format("trophy_id=%d", trophy_id) )
		trophyObj.Unlock(trophy_id)
	end


local H14 =	-- won Insector tournament
	function()
		local rankPtr = eeObj.GetGpr(gpr.a0) + 296 + 6*2
		local rank = eeObj.ReadMem16(rankPtr)

		if rank >= 6 then	-- rank S
			local trophy_id = TROPHY_LORD_OF_THE_BUGS
			print( string.format("trophy_id=%d", trophy_id) )
			trophyObj.Unlock(trophy_id)
		end
	end


local H15 =	-- process damage caused by a hit
	function()
		local s0 = eeObj.GetGpr(gpr.s0)
		local attacker = eeObj.ReadMem16(s0 + 134)
		local attType = eeObj.ReadMem32(s0 + 124)
		local controlChara = 0xffff & eeObj.GetGpr(gpr.fp)

		local statusPtr = eeObj.GetGpr(gpr.s2)	-- instance of CommonBtlUnitStatus class
		local newHP = eeObj.ReadMem32(statusPtr + offs_CommonUnitStatus_CurrentHP)

		if 		attType == 13 and				-- thrown object
				attacker == controlChara and	-- attacker is the character controlled by the player
				newHP == 0 then					-- unit killed by the hit
			if saveData[SAVEDATA_THROWN_KILLS_COUNT] == nil then
				saveData[SAVEDATA_THROWN_KILLS_COUNT] = 0
			end

			saveData[SAVEDATA_THROWN_KILLS_COUNT] = saveData[SAVEDATA_THROWN_KILLS_COUNT] + 1
			emuObj.SaveConfig(userId, saveData)

			if saveData[SAVEDATA_THROWN_KILLS_COUNT] >= 10 then	-- Killed 10 enemies with thrown objects
				local trophy_id = TROPHY_WHATEVER_WORKS
				--	print( string.format("trophy_id=%d", trophy_id) )
				trophyObj.Unlock(trophy_id)
			end
		end
end


local O3H1 =	-- prepare rank change message after exchanging points
	function()
		local newRank = eeObj.GetGpr(gpr.s0)
		local oldRank = eeObj.GetGpr(gpr.s1)
		--	print( string.format("ranking %d -> %d", oldRank, newRank) )

		if oldRank > 1 and newRank == 1 then	-- reached #1
			local trophy_id = TROPHY_BEST_IN_THE_GALAXY
			--	print( string.format("trophy_id=%d", trophy_id) )
			trophyObj.Unlock(trophy_id)
		end
	end


local O7H1 =	-- proceed from language select screen
	function()
		eeObj.SetGpr(gpr.v0, 5)	-- go directly back to game
	end




local CH1 =	-- set HP
	function()
		local statusPtr = eeObj.GetGpr(gpr.a0)	-- instance of CommonBtlUnitStatus class
		local classId = unitStatusGetClassId(statusPtr)
		local newHP = asSigned(eeObj.GetGpr(gpr.a1))

		if isCharaClassId(classId) then	-- character
			if newHP <= 0 then	-- about to die
				eeObj.SetGpr(gpr.a1, 1)	-- don't let them die

				local name = charaStatusGetName(statusPtr)
--				print( string.format("RESUSCITATED %s", name) )
			end
		elseif isMonsterClassId(classId) then	-- monster
			if newHP > 0 then
				eeObj.SetGpr(gpr.a1, 0)	-- kill immediately
--			if newHP <= 0 then	-- about to die
--				eeObj.SetGpr(gpr.a1, 1)	-- don't let them die

				local unitId = unitStatusGetUnitId(statusPtr)
				local name = monsterStatusGetFullName(statusPtr)
--				print( string.format("ONE-HIT KILLED %d %s", unitId, name) )
			end
		end
	end


local CH2 =	-- set Action Gauge
	function()
		local statusPtr = eeObj.GetGpr(gpr.a0)	-- instance of CommonBtlUnitStatus class
		local classId = unitStatusGetClassId(statusPtr)

		if isCharaClassId(classId) then	-- character
--			local newAG = eeObj.GetFpr(12)
			eeObj.SetFpr(12, 1000.0)	-- keep Action Gauge at maximum
--			print( string.format("AG %d -> %f", classId, newAG) )
		end
	end


local forceItems = { 16610, 16611, 16612 }
local forceItemIdx = 1
					
local CH3 =	-- add an item to the inventory
	function()
		local a2 = eeObj.GetGpr(gpr.a2)
		local t1 = eeObj.GetGpr(gpr.t1)

		if a2 == 0 and t1 == 0 then	-- to be added to party inventory (not sure if this is the actual meaning)
			if forceItemIdx <= #forceItems then
				local forced = forceItems[forceItemIdx]

				print( string.format("Replacing obtained item with %d!", forced) )

				eeObj.SetGpr(gpr.a1, forced)
				forceItemIdx = forceItemIdx + 1
			end
		end
	end



-- register hooks
local hook1  = eeObj.AddHook(0x3d40c4, 0x24020001, H1)	-- <CFlagStatusManager::SetItemGetFlag(int, bool)>:
local hook1a = eeObj.AddHook(0x3cf538, 0x0051082a, H1A)	-- <CPartyStatusManager::CreatePossession(int, int)>:
local hook2  = eeObj.AddHook(0x3b4f20, 0xa6220242, H2)	-- <CCharaStatus::SetCostume(CPossession *)>:
local hook3  = eeObj.AddHook(0x3b5420, 0x27bdff10, H3)	-- <CCharaStatus::AssignAbility(int)>:
local hook4  = eeObj.AddHook(0x27af50, 0x27bdfff0, H4)	-- <GetSystemMessage(int)>:
local hook5  = eeObj.AddHook(0x3b3090, 0xa6840010, H5)	-- <CCharaStatus::AdjustLevelByExp(int, int *)>:
local hook6  = eeObj.AddHook(0x389cf4, 0xa7a20110, H6)	-- <CChainComboMngr2::Step(void)>:
local hook7  = eeObj.AddHook(0x3d4cc8, 0x8f84e9a0, H7)	-- <CFlagStatusManager::SetBitFlag(int, bool, bool)>:
local hook8  = eeObj.AddHook(0x3d5564, 0x24050001, H8)	-- <CFlagStatusManager::SetCurrentChapter(int)>:
local hook9  = eeObj.AddHook(0x3cb3c4, 0x8f82e974, H9)	-- <CPartyStatusManager::AddDefeatMonsterInfo(int)>:
local hook10 = eeObj.AddHook(0x3cbb84, 0x0000482d, H10)	-- <CPartyStatusManager::GAMAMake(int, bool &, bool &, int &)>:
local hook11 = eeObj.AddHook(0x3d3ca4, 0xa0660840, H11)	-- <CFlagStatusManager::SetDevelopedItemPhase(int, int)>:
local hook12 = eeObj.AddHook(0x389d90, 0xae220010, H12)	-- <CChainComboMngr2::Step(void)>:
local hook13 = eeObj.AddHook(0x31f7fc, 0x24060001, H13)	-- <gmIsEndInsectron(void)>:
local hook14 = eeObj.AddHook(0x31f71c, 0x24050006, H14)	-- <gmIsEndInsectron(void)>:
local hook15 = eeObj.AddHook(0x2f51c4, 0x87a203ba, H15)	-- <gmBattleDamage(JDG_OBJ_INFO *)>:

-- overlays need special handling
local ov3h1 = nil
local ov7h1 = nil

local OverlayHook =
	function()
		local overlayId = eeObj.GetGpr(gpr.a0)

		--	print( string.format("LoadOverlay %d", overlayId) )

		if overlayId == 3 then
			if ov3h1 == nil then
				--	print("INSTALLING Hook OV3H1")
				ov3h1 = eeObj.AddHook(0x52c72c, 0x24a54820, O3H1)	-- unknown symbol in normal.bin
			end
		else
			if ov3h1 ~= nil then
				--	print("REMOVING Hook OV3H1")
				eeObj.RemoveHook(ov3h1)
				ov3h1 = nil
			end
		end

		if overlayId == 7 then
			if ov7h1 == nil then
				--	print("INSTALLING Hook OV7H1")
				-- skip PAL/NTSC select screens on startup
				ov7h1 = eeObj.AddHook(0x4f6f18, 0x24020001, O7H1)	-- unknown symbol in language.bin
			end
		else
			if ov7h1 ~= nil then
				--	print("REMOVING Hook OV7H1")
				eeObj.RemoveHook(ov7h1)
				ov7h1 = nil
			end
		end
	end

local ovrly = eeObj.AddHook(0x1c25f0, 0x27bdffc0, OverlayHook)	-- <LoadOverlay(int)>:

-- replace PAL with NTSC on startup
eeInsnReplace(0x1c2330, 0x24040011, 0x24040002)	-- li	$a0,17			->  li	$a0,2
eeInsnReplace(0x1c233c, 0x0c071818, 0x0c071828)	-- jal	<SetPAL(void)>	->  jal	<SetNTSC(void)>


-- cheats; disable for release
-- invincibility, one hit kill
--local cheat1 = eeObj.AddHook(0x3c0070, 0x27bdffe0, CH1)	-- <CCommonBtlUnitStatus::SetHP(int)>:
-- infinite Action Gauge
--local cheat2 = eeObj.AddHook(0x3be5d4, 0x0080882d, CH2)	-- <CCommonBtlUnitStatus::SetAttackTurnGuage(float)>:
-- force getting the items we want
--local cheat3 = eeObj.AddHook(0x3ce500, 0x27bdfbe0, CH3)	-- <CPartyStatusManager::AddPossession(int, int, int, int, bool, int *)>:



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
-- Special thanks to R&D
