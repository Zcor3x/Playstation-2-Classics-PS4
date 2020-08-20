-- Lua 5.3
-- Title:   Arc the Lad Twilight - SCES-51910 v1.00 (EU)
-- Version: 1.0.2
-- Date:    Mar. 30th, 2015
-- Author(s):  Clay Cowgill, clay@embeddedengineeringllc.com for SCEA and Tim Lindquist

-- bugfix #8316 20150403 CNC. Changed routine to skip entry #2 when checking companion levels since #2 is Darc.

-- bugfiz 20150407 TGL. Typo in hook07 PC address.

-- bugfix #8339 20150414 TGL. Moved hook location to eliminate possible false positives.

-- Bugfix 8375 20150422 TGL. Changed enemy ID from 112 (Altered Deimos) to 116 (Demon Droguza).

-- bugfix 8385 20150430 TGL. Change from 32 bit read to 16 bit read.



require( "ee-gpr-alias" ) -- you can access EE GPR by alias (gpr.a0 / gpr["a0"])

apiRequest(0.1)	-- request version 0.1 API. Calling apiRequest() is mandatory.

local eeObj			= getEEObject()
local emuObj			= getEmuObject()
local trophyObj		= getTrophyObject()

local TROPHY_FULLY_RECOVERED=01     -- true positive tested 20150319 TGL
local TROPHY_EXPENSIVE_TASTE=02     -- tested with cheat 20150320 TGL.
local TROPHY_CH1=03                 -- true positive tested 20150319 TGL
local TROPHY_CH2=04                 -- untested
local TROPHY_CH3=05                 -- untested
local TROPHY_CH4=06                 -- untested
local TROPHY_STICKY_FINGERS=07      -- true positive tested 20150319 TGL
local TROPHY_ON_THE_HOUSE=08        -- true positive tested 20150321 TGL
local TROPHY_DOUBLE_TEAMED=09       -- true positive tested 20150319 TGL
local TROPHY_BOUNTIFUL=10           -- true positive tested 20150319 TGL
local TROPHY_PUPPET_MASTER=11       -- true positive tested 20150319 TGL
local TROPHY_FEED_PYRON=12          -- true positive tested 20150321 TGL
local TROPHY_CH5=13                 -- untested
local TROPHY_CH6=14                 -- untested
local TROPHY_CH7=15                 -- untested
local TROPHY_CH8=16                 -- untested
local TROPHY_CH9=17                 -- untested
local TROPHY_CH10=18                -- untested
local TROPHY_CH11=19                -- untested
local TROPHY_HIGH_CLASS_COMBAT=20   -- true positive tested 20150319 TGL
local TROPHY_STRENGTH_HUMANS=21     -- true positive tested 20150403 TGL
local TROPHY_STRENGTH_DIEMOS=22     -- tested with cheat 20150403 TGL.
local TROPHY_DECIPHERING_SPIRITS=23 -- tested with cheat 20150321 TGL.
local TROPHY_KEEPER_TABLETS=24      -- tested with cheat 20150321 TGL.
local TROPHY_ANCIENT_CURIOSITY=25   -- true positive tested 20150321 TGL
local TROPHY_YOU_RANG=26			-- true positive tested 20150321 TGL
local TROPHY_STRENGTH_NUMBERS=27    -- true positive tested 20150403 TGL
local TROPHY_TRUE_DEIMOS=28         -- tested with cheat 20150322 TGL.
local TROPHY_WELL_VERSED=29         -- true positive tested 20150321 TGL
local TROPHY_SPIRITUAL_VICTORY=30   -- tested with cheat 20150322 TGL.
local TROPHY_CROWD_PLEASER=31		-- true positive tested 20150321 TGL

local SaveData = emuObj.LoadConfig(0)

local vsync_timer=0

if not next(SaveData) then
	SaveData.t  = {}
end

local arena_name

function initsaves()
	local x = 0
	for x = 1, 31 do
		if SaveData.t[x] == nil then
			SaveData.t[x] = 0
			emuObj.SaveConfig(0, SaveData)
		end
	end
end

-- No update needed for EU
 -- #28, #30
local HX_KILL = -- Check for death
	function()
		local dead = eeObj.ReadMem16(eeObj.GetGpr(gpr.v1) + 0x4) & 8
		local enemy = eeObj.ReadMem8(eeObj.GetGpr(gpr.v1) + 0x1c)
		if dead == 8 and enemy == 0x7b then
			local trophy_id = TROPHY_SPIRITUAL_VICTORY
			initsaves()
			if SaveData.t[trophy_id] ~= 1 then
				SaveData.t[trophy_id] = 1
				trophyObj.Unlock(trophy_id)
				emuObj.SaveConfig(0, SaveData)
			end
		end
		if dead == 8 and enemy == 0x74 then -- Bugfix 8375 20150422 TGL.
			local trophy_id = TROPHY_TRUE_DEIMOS
			initsaves()
			if SaveData.t[trophy_id] ~= 1 then
				SaveData.t[trophy_id] = 1
				trophyObj.Unlock(trophy_id)
				emuObj.SaveConfig(0, SaveData)
			end
		end
		 -- one hit kills (disable for release)
--		if dead ~= 8 and enemy > 0x0f then
--			eeObj.WriteMem16(eeObj.GetGpr(gpr.v1) + 0x4, eeObj.ReadMem16(eeObj.GetGpr(gpr.v1) + 0x4) ~ 8)
--		end
	end

-- Updated for EU
 -- #20, #29
local HX_SKILL = -- Learn a skill
	function()
		if SaveData.darc == nil then SaveData.darc = 0 end
		if SaveData.kharg == nil then SaveData.kharg = 0 end
		local x,y,z = 0,0,0
		local skillPtr = eeObj.GetGpr(gpr.s2) + 0x6c
		local skillLevel = eeObj.ReadMem8(eeObj.GetGpr(gpr.a1))
		if skillLevel == 8 then
			local trophy_id = TROPHY_HIGH_CLASS_COMBAT
			initsaves()
			if SaveData.t[trophy_id] ~= 1 then
				SaveData.t[trophy_id] = 1
				trophyObj.Unlock(trophy_id)
				emuObj.SaveConfig(0, SaveData)			
			end
		end
		if skillPtr == (0x23d1b8 - 0x1B9C) then -- Learning a Kharg skill
			for y = 0,30,2 do
				skillPtr = 0x23d1b8 - 0x1b9c + y
				z = eeObj.ReadMem16(skillPtr)
				if z ~= 0xffff then x = x + 1 end
			end
			if x == 16 then -- Learned all Kharg skills
				if SaveData.kharg ~= 1 then
					SaveData.kharg = 1
					emuObj.SaveConfig(0, SaveData)
				end
			else x,y,z = 0,0,0
			end
		end
		if skillPtr == (0x23d35c - 0x1B9C) then -- Learning a Darc skill
			for y = 0,30,2 do
				skillPtr = 0x23d35c - 0x1b9c + y
				z = eeObj.ReadMem16(skillPtr)
				if z ~= 0xffff then x = x + 1 end
			end
			if x == 16 then -- Learned all Darc skills
				if SaveData.darc ~= 1 then
					SaveData.darc = 1
					emuObj.SaveConfig(0, SaveData)
				end
			else x,y,z = 0,0,0
			end
		end
		if SaveData.darc + SaveData.kharg == 2 then -- Learned all skills for both characters
			local trophy_id = TROPHY_WELL_VERSED
			initsaves()
			if SaveData.t[trophy_id] ~= 1 then
				SaveData.t[trophy_id] = 1
				trophyObj.Unlock(trophy_id)
				emuObj.SaveConfig(0, SaveData)			
			end
		end
	end

-- No update needed for EU
 -- #11
local HX_MIND = -- mind steal
	function()
		local control = eeObj.ReadMem16(eeObj.GetGpr(gpr.a0)+8) 
		if control == 0x2000 then
			local trophy_id = TROPHY_PUPPET_MASTER
			initsaves()
			if SaveData.t[trophy_id] ~= 1 then
				SaveData.t[trophy_id] = 1
				trophyObj.Unlock(trophy_id)
				emuObj.SaveConfig(0, SaveData)			
			end
		end
	end

-- No update needed for EU
-- #07
local HX_STEAL = -- steal
	function()
		local s4 = eeObj.GetGpr(gpr.s4)
		if s4 >= 0 then
			trophy_id = TROPHY_STICKY_FINGERS
			initsaves()
			if SaveData.t[trophy_id] ~= 1 then
				SaveData.t[trophy_id] = 1
				trophyObj.Unlock(trophy_id)
				emuObj.SaveConfig(0, SaveData)			
			end
		end
	end

-- No update needed for EU
-- #09a
local HX_DUAL1 = -- dual attack type 1
	function()
		trophy_id = TROPHY_DOUBLE_TEAMED
		initsaves()
		if SaveData.t[trophy_id] ~= 1 then
			SaveData.t[trophy_id] = 1
			trophyObj.Unlock(trophy_id)
			emuObj.SaveConfig(0, SaveData)			
		end
	end

-- No update needed for EU
-- #09b
local HX_DUAL2 = -- dual attack type 2
	function()
		trophy_id = TROPHY_DOUBLE_TEAMED -- untested
		initsaves()
		if SaveData.t[trophy_id] ~= 1 then
			SaveData.t[trophy_id] = 1
			trophyObj.Unlock(trophy_id)
			emuObj.SaveConfig(0, SaveData)			
		end
	end

-- Updated for EU
local HX_VSYNC=
	function()
		
		if vsync_timer <= 730 then
			vsync_timer=vsync_timer+1
		end
		if vsync_timer >= 730 then
--			print("tick... arena_name=",arena_name)
--			vsync_timer=0
--		end
		
			local kharg_level= eeObj.ReadMem8(0x23D152 - 0x1B9C) -- #21
			local darc_level = eeObj.ReadMem8(0x23D2F6 - 0x1B9C) -- #22
			local kharg_ring = eeObj.ReadMem8(0x23CFB0 - 0x1B9C) -- #02
			local darc_ring  = eeObj.ReadMem8(0x23D0EC - 0x1B9C) -- #02
			local kharg_goddess = eeObj.ReadMem8(0x23CFB8 - 0x1B9C) -- #24 
			local darc_goddess  = eeObj.ReadMem8(0x23D0F4 - 0x1B9C) -- #24
			local kharg_bandana = eeObj.ReadMem8(0x23CF7C - 0x1B9C) -- #23 
			local darc_bandana  = eeObj.ReadMem8(0x23D0B8 - 0x1B9C) -- #23
			
			initsaves()
			if (kharg_level>=50) then
				local trophy_id = TROPHY_STRENGTH_HUMANS 
				if SaveData.t[trophy_id] ~= 1 then
					SaveData.t[trophy_id] = 1
					trophyObj.Unlock(trophy_id)
					emuObj.SaveConfig(0, SaveData)			
		--			print("Trophy: Strength of the Humans")
				end
			end
			if (darc_level>=50) then
				local trophy_id = TROPHY_STRENGTH_DIEMOS 
				if SaveData.t[trophy_id] ~= 1 then
					SaveData.t[trophy_id] = 1
					trophyObj.Unlock(trophy_id)
					emuObj.SaveConfig(0, SaveData)			
		--			print("Trophy: Strength of the Diemos")
				end
			end
			if ((kharg_ring > 0) or (darc_ring > 0)) then
				local trophy_id = TROPHY_EXPENSIVE_TASTE 
				if SaveData.t[trophy_id] ~= 1 then
					SaveData.t[trophy_id] = 1
					trophyObj.Unlock(trophy_id)
					emuObj.SaveConfig(0, SaveData)			
		--			print("Trophy: Expensive Taste")
				end
			end
			if ((kharg_goddess > 0) or (darc_goddess > 0)) then
				local trophy_id = TROPHY_KEEPER_TABLETS 
				if SaveData.t[trophy_id] ~= 1 then
					SaveData.t[trophy_id] = 1
					trophyObj.Unlock(trophy_id)
					emuObj.SaveConfig(0, SaveData)			
		--			print("Trophy: Keeper of the Tablets")
				end
			end
			if ((kharg_bandana > 0) or (darc_bandana > 0)) then
				local trophy_id = TROPHY_DECIPHERING_SPIRITS 
				if SaveData.t[trophy_id] ~= 1 then
					SaveData.t[trophy_id] = 1
					trophyObj.Unlock(trophy_id)
					emuObj.SaveConfig(0, SaveData)			
		--			print("Trophy: Deciphering the Spirits")
				end
			end

			-- "It's on the House = Equip one character with three Romantic Earrings"
			-- 0x23cfb3 is Kharg Inventory for Romantic Earrings (US)
			-- 0x23d0ef is Darc Inventory for Romantic Earrings (US)
			local earring_count
			for j=0,15 do
				earring_count=0
				for i=0,2 do -- 0x23d306 (US) base for Darc equiped accessories (stats are 140 bytes apart per character)
					if ((eeObj.ReadMem16((0x23D306-0x1B9C+(j*140)+(i*2))))==0x00d1) then
						earring_count=earring_count+1
					end
					if (earring_count==3) then
						local trophy_id = TROPHY_ON_THE_HOUSE 
						if SaveData.t[trophy_id] ~= 1 then
							SaveData.t[trophy_id] = 1
							trophyObj.Unlock(trophy_id)
							emuObj.SaveConfig(0, SaveData)			
		--					print("Trophy: It's on the House (Darc)")
						end
					end
				end
				earring_count=0
				for i=0,2 do -- 0x23d162 (US) base for Kharg equiped accessories (stats are 140 bytes apart per character)
					if ((eeObj.ReadMem16((0x23D162-0x1B9C+(j*140)+(i*2))))==0x00d1) then
						earring_count=earring_count+1
					end
					if (earring_count==3) then
						local trophy_id = TROPHY_ON_THE_HOUSE 
						if SaveData.t[trophy_id] ~= 1 then
							SaveData.t[trophy_id] = 1
							trophyObj.Unlock(trophy_id)
							emuObj.SaveConfig(0, SaveData)			
					--		print("Trophy: It's on the House (Kharg)")
						end
					end
				end
			end
			-- [CNC 04-03-2015, revised to check only party members excluding Darc to address Bug ID #8316]
			-- check other characters level 50 (can never skip more than one at a time, and 'uninitialized' 
			-- can be 0xFF, so for unsigned comparison just checking vs. 50 for equality seems best.)
			for j=0,14 do
				-- 0x23D1DE (US) base for Kharg party levels (stats are 140 bytes apart per character)
				if ((eeObj.ReadMem8(0x23D1DE-0x1B9C+(j*140))==50) and (j~=2)) then
					local trophy_id = TROPHY_STRENGTH_NUMBERS 
					if SaveData.t[trophy_id] ~= 1 then
						SaveData.t[trophy_id] = 1
						trophyObj.Unlock(trophy_id)
						emuObj.SaveConfig(0, SaveData)			
						--print("Trophy: Strength in Numbers")
					end 
				end
			end	
		end
	end

-- no update needed for EU
-- #12
local HX_PYRON =
	function()
		local trophy_id = TROPHY_FEED_PYRON -- Can't Fly on an Empty Stomach
		initsaves()
		if SaveData.t[trophy_id] ~= 1 then
			SaveData.t[trophy_id] = 1
			trophyObj.Unlock(trophy_id)
			emuObj.SaveConfig(0, SaveData)			
--			print("Trophy: Can't Fly on an Empty Stomach")
		end
	end

-- no update needed for EU
-- #01
local HX_HEALER =
	function()
		local trophy_id = TROPHY_FULLY_RECOVERED -- Fully Recovered
		initsaves()
		if SaveData.t[trophy_id] ~= 1 then
			SaveData.t[trophy_id] = 1
			trophyObj.Unlock(trophy_id)
			emuObj.SaveConfig(0, SaveData)			
--			print("Trophy: Fully Recovered")
		end
	end

-- no update needed for EU
-- #10
local HX_BOUNTIFUL =
	function()
		local trophy_id = TROPHY_BOUNTIFUL -- Eat Your Fruits and Vegetables
		initsaves()
		if SaveData.t[trophy_id] ~= 1 then
			SaveData.t[trophy_id] = 1
			trophyObj.Unlock(trophy_id)
			emuObj.SaveConfig(0, SaveData)			
	--		print("Trophy: Eat Your Fruits and Vegetables")
		end
	end

-- no update needed for EU
-- #03, #04, #05, #06, #13, #14, #15, #16, #17, #18, #19
local HX_CHAPTER = 
	function()
		local string = eeObj.GetGPR(gpr.a0) -- pull Chapter message index from register
	
		-- #03, "The First Battle" 
		if (string == 6) then -- "The First Battle"
			local trophy_id = TROPHY_CH1 
			initsaves()
			if SaveData.t[trophy_id] ~= 1 then
				SaveData.t[trophy_id] = 1
				trophyObj.Unlock(trophy_id)
				emuObj.SaveConfig(0, SaveData)			
	--			print("Trophy: The First Battle")
			end
		end
		-- #04, "Awakening" 
		if (string == 1) then -- "Awakening"
			local trophy_id = TROPHY_CH2
			initsaves()
			if SaveData.t[trophy_id] ~= 1 then
				SaveData.t[trophy_id] = 1
				trophyObj.Unlock(trophy_id)
				emuObj.SaveConfig(0, SaveData)			
	--			print("Trophy: Awakening")
			end
		end
		-- #05, "Setting Out" 
		if (string == 7) then -- "Setting Out"
			local trophy_id = TROPHY_CH3 
			initsaves()
			if SaveData.t[trophy_id] ~= 1 then
				SaveData.t[trophy_id] = 1
				trophyObj.Unlock(trophy_id)
				emuObj.SaveConfig(0, SaveData)			
--				print("Trophy: Setting Out")
			end
		end
		-- #06, "Ambition" 
		if (string == 2) then -- "Ambition"
			local trophy_id = TROPHY_CH4
			initsaves()
			if SaveData.t[trophy_id] ~= 1 then
				SaveData.t[trophy_id] = 1
				trophyObj.Unlock(trophy_id)
				emuObj.SaveConfig(0, SaveData)			
--				print("Trophy: Ambition")
			end
		end
		-- #13, "Conflict" 
		if (string == 8) then -- "Conflict"
			local trophy_id = TROPHY_CH5
			initsaves()
			if SaveData.t[trophy_id] ~= 1 then
				SaveData.t[trophy_id] = 1
				trophyObj.Unlock(trophy_id)
				emuObj.SaveConfig(0, SaveData)			
--				print("Trophy: Conflict")
			end
		end
		-- #14, "Love and Hate" 
		if (string == 3) then -- "Love and Hate"
			local trophy_id = TROPHY_CH6
			initsaves()
			if SaveData.t[trophy_id] ~= 1 then
				SaveData.t[trophy_id] = 1
				trophyObj.Unlock(trophy_id)
				emuObj.SaveConfig(0, SaveData)			
--				print("Trophy: Love and Hate")
			end
		end
		-- #15, "Rage" 
		if (string == 9) then -- "Rage"
			local trophy_id = TROPHY_CH7
			initsaves()
			if SaveData.t[trophy_id] ~= 1 then
				SaveData.t[trophy_id] = 1
				trophyObj.Unlock(trophy_id)
				emuObj.SaveConfig(0, SaveData)			
--				print("Trophy: Rage")
			end
		end
		-- #16, "Reunion" 
		if (string == 4) then -- "Reunion"
			local trophy_id = TROPHY_CH8
			initsaves()
			if SaveData.t[trophy_id] ~= 1 then
				SaveData.t[trophy_id] = 1
				trophyObj.Unlock(trophy_id)
				emuObj.SaveConfig(0, SaveData)			
--				print("Trophy: Reunion")
			end
		end
		-- #17, "Truth" 
		if (string == 10) then -- "Truth"
			local trophy_id = TROPHY_CH9
			initsaves()
			if SaveData.t[trophy_id] ~= 1 then
				SaveData.t[trophy_id] = 1
				trophyObj.Unlock(trophy_id)
				emuObj.SaveConfig(0, SaveData)			
--				print("Trophy: Truth")
			end
		end
		-- #18, "Evolution" 
		if (string == 5) then -- "Evolution"
			local trophy_id = TROPHY_CH10
			initsaves()
			if SaveData.t[trophy_id] ~= 1 then
				SaveData.t[trophy_id] = 1
				trophyObj.Unlock(trophy_id)
				emuObj.SaveConfig(0, SaveData)			
--				print("Trophy: Evolution")
			end
		end
		-- #19, "Rivalry" 
		if (string == 11) then -- "Rivalry"
			local trophy_id = TROPHY_CH11
			initsaves()
			if SaveData.t[trophy_id] ~= 1 then
				SaveData.t[trophy_id] = 1
				trophyObj.Unlock(trophy_id)
				emuObj.SaveConfig(0, SaveData)			
--				print("Trophy: Rivalry")
			end
		end
	end

-- updated for EU
local ARENA_NAME=
	function()
		local arena_index = eeObj.GetGPR(gpr.v1) -- pull arena name pointer value
		
		if (arena_index==0x2f) then
			arena_name=1
			--print("Orcon Arena")
		end
		if (arena_index==0x30) then
			arena_name=2
			--print("Rueloon Arena")
		end
		if (arena_index==0x2e) then
			arena_name=3
			--print("Cathena Arena")
		end
		if (arena_index==0x2d) then
			arena_name=4
			--print("Lamda Arena")
		end
		-- Orcon Arena   0x2f
		-- Rueloon Arena 0x30
		-- Cathena Arena 0x2e
		-- Lamda Arena   0x2d
	end

-- updated for EU
-- #25, #26, #31
local HX_ARENA=
	function()
		local round_number= eeObj.ReadMem16(0x0023ccf0-0x1B9C) -- round number -- bugfix 8385 20150430 TGL.
--		print("Trophy round number=",round_number)
--		print("Trophy arena name=",arena_name)
		if ((arena_name==3) and (round_number==0x13)) then-- if Cathena Arena and 20th round complete
			local trophy_id = TROPHY_ANCIENT_CURIOSITY-- An Ancient Curiosity
			initsaves()
			if SaveData.t[trophy_id] ~= 1 then
				SaveData.t[trophy_id] = 1
				trophyObj.Unlock(trophy_id)
				emuObj.SaveConfig(0, SaveData)			
--				print("Trophy: An Ancient Curiosity")
			end
		end
		if ((arena_name==2) and (round_number==0x1d)) then-- if Rueloon Arena and 30th round complete
			local trophy_id = TROPHY_YOU_RANG-- You Rang?
			initsaves()
			if SaveData.t[trophy_id] ~= 1 then
				SaveData.t[trophy_id] = 1
				trophyObj.Unlock(trophy_id)
				emuObj.SaveConfig(0, SaveData)			
--				print("Trophy: You Rang?")
			end
		end
		if ((arena_name==1) and (round_number==0x1d)) then-- if Orcon Arena and 30th round complete
			initsaves()
			if SaveData.Orcon_Arena ~= 1 then
				SaveData.Orcon_Arena = 1
				emuObj.SaveConfig(0, SaveData)			
--				print("Trophy: logged Orcon Arena")
			end
		end
		if ((arena_name==4) and (round_number==0x1d)) then-- if Lamda Arena and 30th round complete
			initsaves()
			if SaveData.Lamda_Arena ~= 1 then
				SaveData.Lamda_Arena = 1
				emuObj.SaveConfig(0, SaveData)			
	--			print("Trophy: logged Lamda Arena")
			end
		end
		arena_name=0
		if ((SaveData.Lamda_Arena==1) and (SaveData.Orcon_Arena==1) and 
			(SaveData.t[TROPHY_YOU_RANG] == 1) and (SaveData.t[TROPHY_ANCIENT_CURIOSITY] == 1)) then
			local trophy_id = TROPHY_CROWD_PLEASER-- You Rang?
			initsaves()
			if SaveData.t[trophy_id] ~= 1 then
				SaveData.t[trophy_id] = 1
				trophyObj.Unlock(trophy_id)
				emuObj.SaveConfig(0, SaveData)			
	--			print("Trophy: Crowd Pleaser")
			end
		end
	end


hook28 = eeObj.AddHook(0x1c39ec,0x8c620004, HX_KILL) -- #28, #30 -- updated for EU
hook20 = eeObj.AddHook(0x1871dc,0x94a40004, HX_SKILL) -- #20, #29 -- updated for EU
hook11 = eeObj.AddHook(0x105370,0x27bdffb0, HX_MIND) -- #11 -- updated for EU
hook07 = eeObj.AddHook(0x114a54,0x0280282d, HX_STEAL) -- #07 -- updated for EU -- bugfix 20150407 TGL. -- Bugfix 8339 20150414 TGL.
hook09a = eeObj.AddHook(0x1ca06c,0xc7b400b0, HX_DUAL1) -- #09a -- updated for EU
hook09b = eeObj.AddHook(0x1ca9e4,0xc7b40250, HX_DUAL2) -- #09b -- updated for EU
Hook01 = eeObj.AddHook(0x13e2f8,0x8f828cb4, HX_HEALER)    -- #01, Fully Recovered -- updated for EU
Hook12 = eeObj.AddHook(0x19b508,0x27BDFF40, HX_PYRON)     -- #12, Can't Fly on an Empty Stomach -- updated for EU
Hook10 = eeObj.AddHook(0x11d2c8,0x27BDFFE0, HX_BOUNTIFUL) -- #10, Eat Your Fruits and Vegetables -- updated for EU
Hook03 = eeObj.AddHook(0x145c80,0x27bdffd0, HX_CHAPTER)   -- #03, #04, #05, #06, #13, #14, #15, #16, #17, #18, #19 -- updated for EU
Hook25 = eeObj.AddHook(0x181790,0x90430001, ARENA_NAME) -- updated for EU
Hook26 = eeObj.AddHook(0x16f3a8,0x27bdffc0, HX_ARENA)     -- #25, #26, An Ancient Curiosity, You Rang? -- updated for EU
emuObj.AddVsyncHook(HX_VSYNC) -- #02, #21, #22, #23, #24

-- Credits

-- Trophy design and development by SCEA ISD SpecOps
-- David Thach		Senior Director
-- George Weising	Executive Producer
-- Tim Lindquist	Senior Technical PM
-- Clay Cowgill		Engineering
-- Nicola Salmoria	Engineering
-- Jenny Murphy		Producer
-- David Alonzo		Assistant Producer
-- Tyler Chan		Associate Producer
-- Karla Quiros		Manager Business Finance & Ops
-- Special thanks to R&D