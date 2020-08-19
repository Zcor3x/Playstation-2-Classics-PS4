-- Lua 5.3
-- Title:   Siren SCUS-97355 (USA)
-- Version: 1.0.3 Aug 27th, 2015
--    * Changed to call initsaves() less often.
-- 1.0.2 Jul. 28th, 2015
--    * Added "Parasol" weapon detection in HXSTATE11 and use it for trigger on HXTROPHY08
-- 1.0.1 Jul. 1st, 2015
--    * changed trigger and method for trophy #08 (address and register values) to avoid object moving around in heap
--    * changed trigger and method for Trophy #11 to avoid object moving around in heap
-- Original Date:    1.0.0, Apr. 28th, 2015
-- Author(s):  Clay Cowgill, clay@embeddedengineeringllc.com for SCEA

require( "ee-gpr-alias" ) -- you can access EE GPR by alias (gpr.a0 / gpr["a0"])

apiRequest(0.1)	-- request version 0.1 API. Calling apiRequest() is mandatory.

local eeObj			= getEEObject()
local emuObj		= getEmuObject()
local trophyObj		= getTrophyObject()

local TROPHY_JUMP_START=00                    -- tested in game, CNC, 4/28/2015
local TROPHY_SAVIOR=01                        -- snapshot tested, CNC, 4/29/2015 
local TROPHY_ENDLESS_CHALLENGE=02             -- tested in game, CNC, 4/29/2015
local TROPHY_FUN_FAMILY=03                    -- tested in game, CNC, 4/29/2015
local TROPHY_SHORTCUT=04                      -- tested with debugger, CNC, 4/29/2015 
local TROPHY_AVID_COLLECTOR=05                -- snapshot tested, CNC, 4/29/2015 
local TROPHY_HARD_DAYS_WORK=06                -- tested with debugger, CNC, 4/29/2015
local TROPHY_FORK_IN_ROAD=07                  -- snapshot tested, CNC, 4/28/2015
local TROPHY_SIBLING_RIVALRY=08               -- tested in game, CNC, 4/29/2015
local TROPHY_WORKING_OVERTIME=09              -- tested with debugger, CNC, 4/29/2015 
local TROPHY_SIREN_MANIAC=10                  -- tested with debugger, CNC, 4/29/2015
local TROPHY_DIVINE_RETRIBUTION=11            -- tested with cheats, CNC, 4/29/2015

local SWORD =1
local PARASOL =2
local NOT_SWORD =0
local weapon = NOT_SWORD

local USA_levels     = 0x01A97C60
local USA_archive    = 0x01A97B60
local USA_nurse      = 0x01236640 -- find in CSibito::damaged(EVENT_damage_deal *), 0x001599F8

local ES_levels     = 0x01A97C60+0x300
local ES_archive    = 0x01A97B60+0x300
local ES_nurse      = 0x01235830 -- find in CSibito::damaged(EVENT_damage_deal *), 0x00159968, 001599A0    8C23A74C	lw          v1,0xA74C(at) ;0x0122FF7C =0x000000DC (full HP)


-- set up base and size for different SKU's (could make this an array with differnt indices per SKU, but... diminishing returns)
local level_base = ES_levels
local archive_base = ES_archive
local nurse = ES_nurse

local SaveData = emuObj.LoadConfig(0)
local boss_flag=0

-- offsets in to 'level_base'
local day_one = {0x1, 0x2, 0x7, 0x8, 0xD, 0xE, 0x11, 0x12, 0x14, 0x15, 0x18, 0x1a, 0x1b, 0x1e, 0x1f} -- 15
local day_two = {0x3, 0x4, 0x5, 0x9, 0xA, 0x13, 0x16, 0x1d} -- 8

local vsync_timer=0

if not next(SaveData) then
	SaveData.t  = {}
end

function initsaves()
	local x = 0
		for x = 0, 11 do -- number of trophies is hardwired
			if SaveData.t[x] == nil then
				SaveData.t[x] = 0
				emuObj.SaveConfig(0, SaveData)
			end
		end
	end

initsaves()

-- #02
local HX_TROPHY02 =
	function()
		local trophy_id = TROPHY_ENDLESS_CHALLENGE
		
		if SaveData.t[trophy_id] ~= 1 then
			SaveData.t[trophy_id] = 1
			trophyObj.Unlock(trophy_id)
			emuObj.SaveConfig(0, SaveData)			
--			print("Trophy: Look Both Ways ",TROPHY_ENDLESS_CHALLENGE)
		end
	end

-- #03
local HX_TROPHY03 =
	function()
		local trophy_id = TROPHY_FUN_FAMILY
		
		if SaveData.t[trophy_id] ~= 1 then
			SaveData.t[trophy_id] = 1
			trophyObj.Unlock(trophy_id)
			emuObj.SaveConfig(0, SaveData)			
--			print("Trophy: Look Both Ways ",TROPHY_FUN_FAMILY)
		end
	end

-- #07
local HX_TROPHY07 =
	function()
		local trophy_id = TROPHY_FORK_IN_ROAD
		
		if SaveData.t[trophy_id] ~= 1 then
			SaveData.t[trophy_id] = 1
			trophyObj.Unlock(trophy_id)
			emuObj.SaveConfig(0, SaveData)			
--			print("Trophy: Only Way is Up ",TROPHY_FORK_IN_ROAD)
		end
	end

local HX_TROPHY08 =
	function()
		print("Level=",eeObj.ReadMem32(level_base+0x174))
		print("Damage =",(eeObj.GetGpr(gpr.v1)))
		
		if (weapon == PARASOL) then
			print("Weapon = Parasol")
		end
		
		-- OK, this is dumb, but I was having trouble with signed vs. unsigned, so I just check for hitpoints higher than possible (ie, negative signed)
		if (((eeObj.GetGpr(gpr.v1)>0x00FFFFFF) or (eeObj.GetGpr(gpr.v1)==0x00000000)) and (eeObj.ReadMem32(level_base+0x174)==0x00000016) and (weapon==PARASOL) ) then -- level_base+0x174 = fire extinguisher used, v1 = nurse HP (<=0 means dead)
			print("Trophy: Sibling Rivalry ",TROPHY_SIBLING_RIVALRY)
			
			local trophy_id = TROPHY_SIBLING_RIVALRY
			if SaveData.t[trophy_id] ~= 1 then
				SaveData.t[trophy_id] = 1
				trophyObj.Unlock(trophy_id)
				emuObj.SaveConfig(0, SaveData)			
	--			print("Trophy: Sibling Rivalry ",TROPHY_SIBLING_RIVALRY)
			end
		end
		
	end
	
local HX_TROPHY11 = 
	function()
		--print("Level=",eeObj.ReadMem32(level_base+0x174))
		--print("Damage =",(eeObj.GetGpr(gpr.v1)))
		
		-- trophy 11
		if (((eeObj.GetGpr(gpr.v1)>0x00FFFFFF) or (eeObj.GetGpr(gpr.v1)==0x00000000)) and (weapon==SWORD) and (eeObj.ReadMem32(level_base+0x174)==0x00000007) ) then -- boss level using sword results in <0= HP on enemy
		--	print("Trophy: TROPHY_DIVINE_RETRIBUTION")
			
			local trophy_id = TROPHY_DIVINE_RETRIBUTION 
			if SaveData.t[trophy_id] ~= 1 then
				SaveData.t[trophy_id] = 1
				trophyObj.Unlock(trophy_id)
				emuObj.SaveConfig(0, SaveData)			
				--print("Trophy: TROPHY_DIVINE_RETRIBUTION")
			end
		end
	end

local HX_STATE11 =
	function()
--	print("a1 = ",eeObj.GetGpr(gpr.a1))
		weapon = NOT_SWORD
	
		if (eeObj.ReadMem32((eeObj.GetGpr(gpr.a1)+0x00000010))==0x4C425F57) then -- "W_BL ADE" in hex
			weapon = SWORD
--			print("SWORD")
		end
		if (eeObj.ReadMem32((eeObj.GetGpr(gpr.a1)+0x00000010))==0x41505F57) then -- "W_PA RASOL" in hex
			weapon = PARASOL
--			print("PARASOL")
		end

--		if (weapon == NOT_SWORD) then
--			print("NOT SWORD")
--		end
	end
	
local HX_VSYNC=
	function()
		local i=0
		local count=0
		
		local hook_0_check=eeObj.ReadMem32(level_base+0x180) -- #0
		local hook_1_check=eeObj.ReadMem8(level_base-0xCA) -- #1
		local hook_4a_check=eeObj.ReadMem8(level_base+0x180) -- #4
		local hook_4b_check=eeObj.ReadMem32(level_base+0x1A4) -- #4
		
		

		-- simple little round-robin tasker; only perform one 'hook' check per vblank
		-- worst case latency for check to run ~117ms
		vsync_timer=vsync_timer+1
		if (vsync_timer>=7) then
			vsync_timer=0
		end
		
		if (vsync_timer==0) then -- check for #5 and #10
			count=0
			for i=archive_base, (archive_base+100) do
				if (eeObj.ReadMem8(i)>0) then
					count=count+1

					if (count>=50) then -- check for #5
						local trophy_id = TROPHY_AVID_COLLECTOR 
						if SaveData.t[trophy_id] ~= 1 then
							SaveData.t[trophy_id] = 1
							trophyObj.Unlock(trophy_id)
							emuObj.SaveConfig(0, SaveData)			
				--			print("Trophy: TROPHY_AVID_COLLECTOR")
						end
					end
					
					if (count>=100) then -- check for #10
						local trophy_id = TROPHY_SIREN_MANIAC 
						if SaveData.t[trophy_id] ~= 1 then
							SaveData.t[trophy_id] = 1
							trophyObj.Unlock(trophy_id)
							emuObj.SaveConfig(0, SaveData)			
				--			print("Trophy: TROPHY_SIREN_MANIAC")
						end
					end

				end
			end
		end
		
		if (vsync_timer==1) then -- check for #0
			if (hook_0_check==0x00000002) then
				local trophy_id = TROPHY_JUMP_START 
				if SaveData.t[trophy_id] ~= 1 then
					SaveData.t[trophy_id] = 1
					trophyObj.Unlock(trophy_id)
					emuObj.SaveConfig(0, SaveData)			
		--			print("Trophy: TROPHY_JUMP_START")
				end
			end
		end
		
		if (vsync_timer==2) then -- check for #1
			if (hook_1_check==0x01) then
				local trophy_id = TROPHY_SAVIOR 
				if SaveData.t[trophy_id] ~= 1 then
					SaveData.t[trophy_id] = 1
					trophyObj.Unlock(trophy_id)
					emuObj.SaveConfig(0, SaveData)			
		--			print("Trophy: TROPHY_SAVIOR")
				end
			end
		end
		
		-- check for #4 (every frame)
		-- level number is (level_base+174), Kei Makino Day 1 12:00 is = 0x0F
		-- (Incidentally, the game timer runs at 30Hz regardless of video refresh rate.)
		if (((hook_4a_check==0x02) or (hook_4a_check==0x03)) and ((eeObj.ReadMem8(level_base+0x174))==0x0F)) then
			if (hook_4b_check<=0x672) then
				local trophy_id = TROPHY_SHORTCUT 
				if SaveData.t[trophy_id] ~= 1 then
					SaveData.t[trophy_id] = 1
					trophyObj.Unlock(trophy_id)
					emuObj.SaveConfig(0, SaveData)			
		--			print("Trophy: TROPHY_SHORTCUT")
				end
			end
		end
		
		if (vsync_timer==4) then -- check for #6
			count=0;
			for i=1,15 do
				count=count+eeObj.ReadMem8(level_base+day_one[i])
			end
			if (count==30) then -- all events are 0x02
				local trophy_id = TROPHY_HARD_DAYS_WORK 
				if SaveData.t[trophy_id] ~= 1 then
					SaveData.t[trophy_id] = 1
					trophyObj.Unlock(trophy_id)
					emuObj.SaveConfig(0, SaveData)			
		--			print("Trophy: TROPHY_HARD_DAYS_WORK")
				end
			end
		end
		
		if (vsync_timer==5) then -- check for #9
			count=0;
			for i=1,8 do
				count=count+eeObj.ReadMem8(level_base+day_two[i])
			end
			if (count==16) then -- all events are 0x02
				local trophy_id = TROPHY_WORKING_OVERTIME 
				if SaveData.t[trophy_id] ~= 1 then
					SaveData.t[trophy_id] = 1
					trophyObj.Unlock(trophy_id)
					emuObj.SaveConfig(0, SaveData)			
		--			print("Trophy: TROPHY_WORKING_OVERTIME")
				end
			end
		end

	end
	
-- hook02 = eeObj.AddHook(0x0020F470,0x27BDFFF0, HX_TROPHY02) -- #02 SCUS
-- hook03 = eeObj.AddHook(0x00222010,0x27BDFFD0, HX_TROPHY03) -- #03 SCUS
-- hook07 = eeObj.AddHook(0x0021BFA0,0x27BDFFE0, HX_TROPHY07) -- #07 SCUS
-- hook08 = eeObj.AddHook(0x0015996C,0x02610821, HX_TROPHY08) -- #08 SCUS

hook02 = eeObj.AddHook(0x0020F5D0,0x27BDFFF0, HX_TROPHY02) -- #02 SCES
hook03 = eeObj.AddHook(0x002223A0,0x27BDFFD0, HX_TROPHY03) -- #03 SCES
hook07 = eeObj.AddHook(0x0021C140,0x27BDFFE0, HX_TROPHY07) -- #07 SCES
hook08 = eeObj.AddHook(0x001599F4,0xAC23A74C, HX_TROPHY08) -- #08 SCES
hook11 = eeObj.AddHook(0x001599F8,0x3C010001, HX_TROPHY11) -- #11 SCES  
hook11a = eeObj.AddHook(0x0015ef10,0x27BDFFB0, HX_STATE11) -- #11 SCES helper function

emuObj.AddVsyncHook(HX_VSYNC) -- #0, #1, #4, #5, #6, #9, #10, #11

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