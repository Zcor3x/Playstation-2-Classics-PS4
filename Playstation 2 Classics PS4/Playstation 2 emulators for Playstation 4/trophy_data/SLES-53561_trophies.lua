-- Lua 5.3
-- Title: Bully (USA)    SLUS-21269
--        Bully (Japan)  SLPS-25879
--        Bully (Europe) SLES-53561
-- Trophies version: 1.50
-- Author: David Haywood
-- Date: August 16, 2015

-- Changelog
-- 15 August 2015 Initial submission
-- 16 August 2016 Replaced some trophies with improved ones
--                Added Europe / Japan support
-- 23 September 2015 Removed cheat code
-- 30 October 2015 Fixed false positive 'FatPockets' trigger
--                 Changed curfew trophy from 5 hours REAL time to 5 hours GAME time
-- Jan 2016 Changed Chapter trophies to be based on final cutscene of each chapter, previously
--                  based on yearbook photos but these could be triggered early

require( "ee-gpr-alias" ) -- you can access EE GPR by alias (gpr.a0 / gpr["a0"])

apiRequest(0.1)	-- request version 0.1 API. Calling apiRequest() is mandatory.

-- obtain necessary objects.
local eeObj			= getEEObject()
local emuObj		= getEmuObject()
local trophyObj		= getTrophyObject()
local dmaObj		= getDmaObject()

-- load configuration if exist
local SaveData		= emuObj.LoadConfig(0)

-- 0 for US
-- 1 for Japan
-- 2 for Europe
local Region = 2

local ReadyToCheck = 0

--[[###################################################################################################################
#######################################################################################################################

  Adjusted Memory Read/Write operations

  when data stored in memory differs by a common offset between regions these functions are handy

###################################################################################################################--]]

-- Initial offsets based on US version
local AdjustForRegion = 0
local Adjust2 = 0

if (Region==1) then
	AdjustForRegion = 0x8FF0 -- Japan (based on Sodas Bought address)
	Adjust2 = 0x217B0
end

if (Region==2) then
	AdjustForRegion = 0xC70 -- Europe (based on Soads Bought)
	Adjust2 = 0xC80
end

function Adjusted_WM32(base, data)
	eeObj.WriteMem32(base + AdjustForRegion, data)
end

function Adjusted_WM16(base, data)
	eeObj.WriteMem16(base + AdjustForRegion, data)
end

function Adjusted_WM8(base, data)
	eeObj.WriteMem8(base + AdjustForRegion, data)
end

function Adjusted_WMFloat(base, data)
	eeObj.WriteMemFloat(base + AdjustForRegion, data)
end


function Adjusted_RM32(base)
	return eeObj.ReadMem32(base + AdjustForRegion)
end

function Adjusted_RM16(base)
	return eeObj.ReadMem16(base + AdjustForRegion)
end

function Adjusted_RM8(base)
	return eeObj.ReadMem8(base + AdjustForRegion)
end

function Adjusted_RMStr(base)
	return eeObj.ReadMemStr(base + AdjustForRegion)
end

function Adjusted_RMFloat(base)
	return eeObj.ReadMemFloat(base + AdjustForRegion)
end

--[[###################################################################################################################
#######################################################################################################################

  Generic Award Function

###################################################################################################################--]]


function AwardTrophy(trophynum, savetext)
	local trophy_id = trophynum
	print( string.format("############################## AWARDING trophy_id=%d (%s) #########################", trophy_id, savetext) )
	trophyObj.Unlock(trophy_id)		 
	SaveData[savetext] = 1
	emuObj.SaveConfig(0, SaveData)

end


--[[###################################################################################################################
#######################################################################################################################

  Generic Helper Functions

###################################################################################################################--]]

function InitSave(savetext, trophyid)
	if SaveData[savetext] == nil then
		SaveData[savetext] = 0
		emuObj.SaveConfig(0, SaveData)
	end
end


InitSave("Curfew5", 1) -- 
InitSave("Flowers50", 2) --
InitSave("Kisses25", 3) -- 
InitSave("Egg25", 4) --
InitSave("Soccer100", 5)--
InitSave("Marbles25", 6)--
InitSave("HighScores", 7)
InitSave("KO200", 8) --
InitSave("Soda100", 9) -- 

InitSave("Skate50k", 24) --
InitSave("Taunt100", 25) --
InitSave("Stink50", 26) --
InitSave("Wedgie50", 27) --
InitSave("Gallery300", 28) --

InitSave("Foot100k", 30) --
InitSave("Wheelie200", 31) --
InitSave("Clothes250", 32)
InitSave("Bike100km", 33) --

InitSave("Errand10", 11) --
InitSave("Errand20", 12) --
InitSave("Errand30", 29) --

InitSave("Class3", 13)--
InitSave("Class6", 14)--
--InitSave("Class9", 37)-- Was 9 Classes

InitSave("Chapter1", 20)
InitSave("Chapter2", 21)
InitSave("Chapter3", 22)
InitSave("Chapter4", 23)
InitSave("Chapter5", 34)

--InitSave("Carnival4", 15) -- was Play all Carnival games once
--InitSave("AllBike", 16) -- Was Complete all bike races
InitSave("HalfKart", 10)
InitSave("AllKart", 17)
--InitSave("AllMow", 18) -- Was Complete all mowing Mission
--InitSave("AllPaper", 19) -- Was Complete all Paper Routes
--InitSave("AllMissions", 35) -- Was All Missions
--InitSave("Complete", 36) -- Was 100% everything

-- Replacements
InitSave("Authority", 15)
InitSave("GrandTheft", 16)
InitSave("Mow10", 18)
InitSave("FatPockets", 19)
InitSave("Troublemaker", 35)
InitSave("Kleptomaniac", 36)
InitSave("ClassAll", 37)

--[[###################################################################################################################
#######################################################################################################################

  Unused functions / notes etc.

###################################################################################################################--]]


--[[
local CompleteCheck = function()
	-- 100% completion (but only updates when you view the stats menu??)
	-- 005e7020 : 00000000 00000000 00000004 42c80000
	
	-- Gold	Bully™	36	Perfectionist					Earn 100% completion.
	local PercentComplete = Adjusted_RMFloat(0x05e702c)	
	if SaveData["Complete"] ~= 1 then
		if (PercentComplete >= 100) then
			AwardTrophy(36, "Complete")
		end
	end	
end
--]]

--[[

these only seem to be set on loading a game, not during gameplay?

0x73caf2 = 0x0078 = high striker played
0x73caf4 = 0x0075 = high striker won

0x73caf8 = 0x0008 = Baseball Toss Played
0x73cafa = 0x0002 = Baseball Toss Won

0x73cafe = 0x0006 = Shooting Gallery Played
0x73cb00 = 0x0006 = Shooting Gallery Won

0x73cb04 = 0x0003 = Dunk Tank Played
0x73cb06 = 0x0003 = Shooting Gallery Won
--]]

--[[
local CarnivalChecks  = function()
	-- Bronze	Bully™	15	It's All in the Wrists			Complete all four of the Carnival games once.
	local xxx = 0
	
	if SaveData["Carnival4"] ~= 1 then
		if (xxx >= 3) then
			AwardTrophy(15, "Carnival4")
		end
	end		
end
--]]

-- Old Notes

--[[

these flags are set on chapter complete BUT ARE YEARBOOK PHOTOS

006c8690 : 00020000   possible progress flag? end of chapter 1

chap2
006c8680 : 00000000 00000000 00000000 efddbfff                    
006c8690 : 0feffff7 00000000 00000001 0000001c    
bully_end_chapt2_mission_0000.snapbin
006c8680 : 00000000 00000000 00000000 efddffff    < 0x0004000 = chapter 2 done?                 
006c8690 : 0feffff7 00000000 00000001 0000001c    

chap 3
006c8680 : 00000000 00000000 00000000 efddffff                    
006c8690 : 0fefffff 00000000 00000001 00000010 
bully_end_chapt3_mission_0000.snapbin
006c8680 : 00000000 00000000 00000000 ffddffff  << 0x10000000 = chapter 3 done?                  
006c8690 : 0fefffff 00000000 00000001 00000010    



chap 4 start
006c8680 : 00000000 00000000 00000000 ffdfffff                    
006c8690 : 0fefffff 00000000 00000001 00000010     
bully_end_chaptfour_0000.snapbin               
006c8680 : 00000000 00000000 00000000 ffdfffff                    
006c8690 : 0fffffff 00000000 00000001 00000010  <0x00100000

chap5
006c8680 : 00000000 00000000 00000000 ffdfffff                    
006c8690 : 0fffffff 00000000 00000001 00000001         
after
006c8680 : 00000000 00000000 00000000 ffffffff                    
006c8690 : 0fffffff 00000000 00000001 00000001    

shop class success
-- 006C86C4 00000001 00000020

-- class passes
0x6C86b0 = art
0x6C86b4 = chemistry
0x6C86b8 = English
0x6C86bc = gym
0x6C86C0 = photography
0x6C86C4 = shop

--]]


--[[###################################################################################################################
#######################################################################################################################

  Trophy Handlers

###################################################################################################################--]]

local RespectCheck  = function()
	-- Bronze	Bully™	15	Respect My Authoritah!	Gain 100% respect from 2 cliques simultaneously

	local count = 0
	
	local NerdRespect = Adjusted_RM32(0x6c86d0)
	local JockRespect = Adjusted_RM32(0x6c86d4)
	local TownRespect = Adjusted_RM32(0x6c86d8)
	local GreaRespect = Adjusted_RM32(0x6c86dc)
	local PrepRespect = Adjusted_RM32(0x6c86e0)
	local BullRespect = Adjusted_RM32(0x6c86f8)

	if NerdRespect >= 100 then count = count + 1 end
	if JockRespect >= 100 then count = count + 1 end
	if TownRespect >= 100 then count = count + 1 end
	if GreaRespect >= 100 then count = count + 1 end
	if PrepRespect >= 100 then count = count + 1 end
	if BullRespect >= 100 then count = count + 1 end
	
	
	if SaveData["Authority"] ~= 1 then
		if (count >= 2) then
			AwardTrophy(15, "Authority")
		end
	end	
	
	
end



local HighScoreChecks  = function()
	-- Bronze	Bully™	7	Dual Nebula						Achieve a high score on Consumo, Nut Shots, and Monkey Fling arcade games.
	
	local count = 0
	
	local ConSumoHighScore = Adjusted_RM32(0x6C73C8) -- Consumo High Score
	local MonkeyFlingHighScore = Adjusted_RM32(0x6C73D4) -- Monkey Sling
	local NutShotsHighScore = Adjusted_RM32(0x6C73E0) -- Nut Slots
	
	if (ConSumoHighScore > 1010) then
		count = count + 1 
	end
	
	if (MonkeyFlingHighScore > 333) then
		count = count + 1 
	end
	
	if (NutShotsHighScore > 69900) then
		count = count + 1 
	end

	if SaveData["HighScores"] ~= 1 then
		if (count >= 3) then
			AwardTrophy(7, "HighScores")
		end
	end			
end


-- Maybe
local ClothingChecks  = function()
	-- Silver	Bully™	32	Sharp Dressed Man				Purchase 250 clothing items.
	-- 739d40 << this seems to be a structure related to available clothing items, trophy clarified as purcahsed, so don't have to parse this
	local ClothingPurchased = Adjusted_RM32(0x06c7168)	
	
	if SaveData["Clothes250"] ~= 1 then
		if (ClothingPurchased >= 250) then
			AwardTrophy(32, "Clothes250")
		end
	end	
end

-- these are keyed on Carnival Go-Kart races (the first set of races) and Street Go-Kart races (the 2nd set of races)
local GoKartCheck =  function()
	-- Bronze	Bully™	10	Speed Freak	Complete Carnival Go Kart Races
	-- Bronze	Bully™	17	Pole Position	Complete Go Kart Street Races

	local xxx = 0
	
--006c7130 : 0000002f 00000048 00000005 00000005    /   H           
--006c7140 : 00000003 00000003 00000dac 0000079e	

	local CarnvalWon =  Adjusted_RM32(0x06c713c)
	local StreetWon   = Adjusted_RM32(0x06c7144)
	
	
	if SaveData["HalfKart"] ~= 1 then
		if (CarnvalWon >= 5) then
			AwardTrophy(10, "HalfKart")
		end
	end	
		
	if SaveData["AllKart"] ~= 1 then
		if (StreetWon >= 3) then
			AwardTrophy(17, "AllKart")
		end
	end		
end


local ClassChecks  = function()
	local ArtPass =  Adjusted_RM32(0x6C86b0)
	local ChemPass = Adjusted_RM32(0x6C86b4)
	local EngPass =  Adjusted_RM32(0x6C86b8)
	local GymPass =  Adjusted_RM32(0x6C86bc)
	local FotPass =  Adjusted_RM32(0x6C86c0)
	local ShpPass =  Adjusted_RM32(0x6C86c4)

	local TotalPass = ArtPass + ChemPass + EngPass + GymPass + FotPass + ShpPass

	-- Bronze	Bully™	13	Keener							Complete three classes.
	-- Bronze	Bully™	14	Teacher's Pet					Complete six classes.
	-- Gold	Bully™	37	Boy Genius	Complete all 5 classes for every subject.


	if SaveData["Class3"] ~= 1 then
		if (TotalPass >= 3) then
			AwardTrophy(13, "Class3")
		end
	end	
	
	if SaveData["Class6"] ~= 1 then
		if (TotalPass >= 6) then
			AwardTrophy(14, "Class6")
		end
	end	
	
	if SaveData["ClassAll"] ~= 1 then
		if (TotalPass >= (6*5)) then
			AwardTrophy(37, "ClassAll")
		end
	end		
	
end

--[[ wrong, yearbook photos
local FlagChecks  = function()
	local FlagGroup1 = Adjusted_RM32(0x6c868c)
	local FlagGroup2 = Adjusted_RM32(0x6c8690)
	
	-- FlagGroup1 |  ---3 ---- --5- ----  -2-- ---- ---- ----
	-- FlagGroup2 |  ---- ---- ---4 --1-  ---- ---- ---- ----
	
	-- 1 to 5 = chapter done flags
	
	local Chapter1Done = FlagGroup2 & 0x00020000
	local Chapter2Done = FlagGroup1 & 0x00004000
	local Chapter3Done = FlagGroup1 & 0x10000000
	local Chapter4Done = FlagGroup2 & 0x00100000
	local Chapter5Done = FlagGroup1 & 0x00200000

	
--Bronze	Bully™	20	Freshman						Complete Chapter 1.
--Bronze	Bully™	21	Sophomore						Complete Chapter 2.
--Bronze	Bully™	22	Junior							Complete Chapter 3.
--Bronze	Bully™	23	Senior							Complete Chapter 4.
--Gold	    Bully™	34	Graduate						Complete Chapter 5.
	
	if SaveData["Chapter1"] ~= 1 then
		if (Chapter1Done ~= 0) then
			AwardTrophy(20, "Chapter1")
		end
	end	

	if SaveData["Chapter2"] ~= 1 then
		if (Chapter2Done ~= 0) then
			AwardTrophy(21, "Chapter2")
		end
	end	

	if SaveData["Chapter3"] ~= 1 then
		if (Chapter3Done ~= 0) then
			AwardTrophy(22, "Chapter3")
		end
	end	

	if SaveData["Chapter4"] ~= 1 then
		if (Chapter4Done ~= 0) then
			AwardTrophy(23, "Chapter4")
		end
	end	

	if SaveData["Chapter5"] ~= 1 then
		if (Chapter5Done ~= 0) then
			AwardTrophy(34, "Chapter5")
		end
	end	

--	print( string.format("Debug (20) Chapter1 %08x @@@@@@@#######@@@@@@@", Chapter1Done, complete) )
--	print( string.format("Debug (21) Chapter2 %08x @@@@@@@#######@@@@@@@", Chapter2Done, complete) )
--	print( string.format("Debug (22) Chapter3 %08x @@@@@@@#######@@@@@@@", Chapter3Done, complete) )
--	print( string.format("Debug (23) Chapter4 %08x @@@@@@@#######@@@@@@@", Chapter4Done, complete) )
--	print( string.format("Debug (34) Chapter5 %08x @@@@@@@#######@@@@@@@", Chapter5Done, complete) )
	
end
--]]

local ErrandChecks = function()
	local firstaddress = 0x6c8704
	local lastaddress = 0x6c87c8
	local total1 = 0
	local complete = 0
	
	-- this is a table xxxxyyyy for each errand, with number of times attempted / succeeded
	for i = firstaddress, lastaddress, 4 do
		total1 = total1 + Adjusted_RM16(i) -- attempted
		complete = complete + Adjusted_RM16(i+2)
	end
	
-- Bronze	Bully™	11	Helping Hand					Complete 10 Errand missions.
-- Bronze	Bully™	12	Little Angel					Complete 20 Errand missions.
-- Silver	Bully™	29	Momma's Boy						Complete 30 Errand missions.	
	
	if SaveData["Errand10"] ~= 1 then
		if (complete >= 10) then
			AwardTrophy(11, "Errand10")
		end
	end	
	
	if SaveData["Errand20"] ~= 1 then
		if (complete >= 20) then
			AwardTrophy(12, "Errand20")
		end
	end	
	
	if SaveData["Errand30"] ~= 1 then
		if (complete >= 30) then
			AwardTrophy(29, "Errand30")
		end
	end	
	
--	print( string.format("Debug (11,12,29) Errands %d %d @@@@@@@#######@@@@@@@", total1, complete) )
end


local MainChecks = function()
	-- ensure we're not running these during the initial loading
	if ReadyToCheck == 0 then
		return
	end
	
	ErrandChecks()
	--FlagChecks()
	ClassChecks()
	
	--CarnivalChecks()
	ClothingChecks()
	HighScoreChecks()
	GoKartCheck()
	--BikeChecks()
	--PaperRouteChecks()
	--LawnCheck()
	--MissionCheck()
	--CompleteCheck()
	RespectCheck()

	-- general checks
	
	local CarsEgged = Adjusted_RM32(0x6C70B8)
	local BallsKicked = Adjusted_RM32(0x6C710C)	
	local Wedgies = Adjusted_RM32(0x6C70E0)
	local MarbleTrips =	Adjusted_RM32(0x6C7198)
	local SodasBought = Adjusted_RM32(0x6C7368) -- 0x6d0358 (Japan)   -- 0x6c7fd8 (Euro)
	local Taunts = Adjusted_RM32(0x6C7374)
	local StinkHits = Adjusted_RM32(0x6C718C)
	--local FlowersFound = Adjusted_RM32(0x6C70F8)
	local FlowersObtained = Adjusted_RM32(0x6C70FC)
	local KissesReceived = Adjusted_RM32(0x6C7264)
	local GalleryBottles = Adjusted_RM32(0x6C7418)
	local Wheelies = Adjusted_RM32(0x6C7124)
	local PeopleKnockedOut = Adjusted_RM32(0x6c7378)
	local CurfewTime = Adjusted_RM32(0x6c72d0)
	local DistanceFoot = Adjusted_RMFloat(0x6C7074)
	local DistanceSkate = Adjusted_RMFloat(0x6C7078)
	local DistanceBike = Adjusted_RMFloat(0x6C707C)
	local LawnsMowed = Adjusted_RM32(0x6c7314)
	local RoomTrophies = Adjusted_RM16(0x6c7064) 
	local TroublePoints = Adjusted_RM32(0x6c72c8) 
	local BikesJacked = Adjusted_RM32(0x6c7118)
	

	
	-- Bronze	Bully™	4	Eggsellent!						Egg 25 cars.
	if SaveData["Egg25"] ~= 1 then
		if (CarsEgged >= 25) then
			AwardTrophy(4, "Egg25")
		end
	end
	
	-- Bronze	Bully™	5	Kickin' the Balls				Kick 100 soccer balls.
	if SaveData["Soccer100"] ~= 1 then
		if (BallsKicked >= 100) then
			AwardTrophy(5, "Soccer100")
		end
	end	
	
	-- Silver	Bully™	27	Skidmark						Give 50 wedgies.
	if SaveData["Wedgie50"] ~= 1 then
		if (Wedgies >= 50) then
			AwardTrophy(27, "Wedgie50")
		end
	end	
	
	-- Bronze	Bully™	6	Watch Your Step					Trip 25 people with marbles.
	if SaveData["Marbles25"] ~= 1 then
		if (MarbleTrips >= 25) then
			AwardTrophy(6, "Marbles25")
		end
	end	
	
	-- Bronze	Bully™	9	Soda 'Licious					Buy 100 sodas.
	if SaveData["Soda100"] ~= 1 then
		if (SodasBought >= 100) then
			AwardTrophy(9, "Soda100")
		end
	end			
		
	-- Silver	Bully™	25	Smart Mouth						Say 100 taunts.	
	if SaveData["Taunt100"] ~= 1 then
		if (Taunts >= 100) then
			AwardTrophy(25, "Taunt100")
		end
	end		
	
	-- Silver	Bully™	26	Smell Ya Later					Hit people with stink bombs 50 times.
	if SaveData["Stink50"] ~= 1 then
		if (StinkHits >= 50) then
			AwardTrophy(26, "Stink50")
		end
	end			
	
	-- Bronze	Bully™	2	Green Thumbs Up					Pick 50 flowers.
	if SaveData["Flowers50"] ~= 1 then
		if (FlowersObtained >= 50) then
			AwardTrophy(2, "Flowers50")
		end
	end		
	
	-- Bronze	Bully™	3	Casanova						Receive 25 kisses.
	if SaveData["Kisses25"] ~= 1 then
		if (KissesReceived >= 25) then
			AwardTrophy(3, "Kisses25")
		end
	end			
	
	-- Silver	Bully™	28	Glass Dismissed					Break 300 bottles of the shooting gallery.
	if SaveData["Gallery300"] ~= 1 then
		if (GalleryBottles >= 300) then
			AwardTrophy(28, "Gallery300")
		end
	end	

	-- Silver	Bully™	31	The Wheel Deal					Perform 200 wheelies on the bike.
	if SaveData["Wheelie200"] ~= 1 then
		if (Wheelies >= 200) then
			AwardTrophy(31, "Wheelie200")
		end
	end		
	
	-- Bronze	Bully™	8	Down for the Count				Knock out 200 opponents.
	if SaveData["KO200"] ~= 1 then
		if (PeopleKnockedOut >= 200) then
			AwardTrophy(8, "KO200")
		end
	end	
	-- Bronze	Bully™	1	After Hours						Spend 5 hours out after curfew.
	if SaveData["Curfew5"] ~= 1 then
		
		--local Hours5 = (1000 * 60 * 60 * 5) -- 5 hours of REAL time
		local Hours5 = (1000 * 60 * 5) -- 5 hours of GAME time (1 second real time = 1 minute game time)
	
		if (CurfewTime >= Hours5) then
			AwardTrophy(1, "Curfew5")
		end
	end		
	
	-- Silver	Bully™	30	Marathon						Travel 100,000 meters on foot.
	if SaveData["Foot100k"] ~= 1 then
			
		if (DistanceFoot >= 100000.00) then
			AwardTrophy(30, "Foot100k")
		end
	end		
	
	-- Silver	Bully™	24	Skate Pro						Travel 50,000 meters on the skateboard.
	if SaveData["Skate50k"] ~= 1 then
			
		if (DistanceSkate >= 50000.00) then
			AwardTrophy(24, "Skate50k")
		end
	end			
	
	
	-- Silver	Bully™	33	Tour de Bullworth				Travel 100 km on the bike.
	if SaveData["Bike100km"] ~= 1 then
			
		if (DistanceBike >= 100000.00) then
			AwardTrophy(33, "Bike100km")
		end
	end		
	
	-- Bronze	Bully™	16	Grand Theft Bicycle	Jack 20 Bicycles
	if SaveData["GrandTheft"] ~= 1 then
			
		if (BikesJacked >= 20) then
			AwardTrophy(16, "GrandTheft")
		end
	end	
	
	-- Bronze	Bully™	18	Green Thumb	Mow the lawn 10 times
	if SaveData["Mow10"] ~= 1 then
			
		if (LawnsMowed >= 10) then
			AwardTrophy(18, "Mow10")
		end
	end		
	
	

	-- Gold	Bully™	35	Professional Troublemaker	Amass 160,000 trouble points
	if SaveData["Troublemaker"] ~= 1 then
			
		if (TroublePoints >= 160000) then
			AwardTrophy(35, "Troublemaker")
		end
	end	
	
	-- Gold	Bully™	36	Kleptomaniac	Acquire All Room Trophies.
	if SaveData["Kleptomaniac"] ~= 1 then
			
		if (RoomTrophies >= 0x24) then
			AwardTrophy(36, "Kleptomaniac")
		end
	end	
			
end

MainHook = emuObj.AddVsyncHook(MainChecks)

local GameLogicUpdate = function()
	--print( string.format("############################## logig update #########################" ) )

	-- this gets set after the initial loading is complete
	ReadyToCheck = 1

	-- don't check this one unless the actual game logic is running, the RAM is used for temporary storage during loading etc.
	local PocketChange = eeObj.ReadMem32(0x1C68AB0 + Adjust2)
	
	-- Bronze	Bully™	19	Fat Pockets	Have $1,000 in Pocket Change
	if SaveData["FatPockets"] ~= 1 then
			
		if (PocketChange >= 100000) then
			AwardTrophy(19, "FatPockets")
		end
	end	
			
	
end

if Region == 2 then
	GameLogicUpdateHook = eeObj.AddHook(0x01f1f60,0x27bdffb0, GameLogicUpdate)
elseif Region == 0 then
	GameLogicUpdateHook = eeObj.AddHook(0x01f1b30,0x27bdffb0, GameLogicUpdate)
elseif Region == 1 then
	GameLogicUpdateHook = eeObj.AddHook(0x01f2110,0x27bdffb0, GameLogicUpdate)
end


-- Trigger chapter trophies based on cutscenes

--[[
  001EB420 00000054 .text   CFileMgr::GetCdFile(const char*,unsigned int&,unsigned int&)	(FileMgr.cpp)
  001EB480 0000002C .text   CFileMgr::InitCd()	(FileMgr.cpp)
  001EB4B0 00000024 .text   CFileMgr::InitCdSystem()	(FileMgr.cpp)
  001EB4E0 00000008 .text   CFileMgr::CloseFile(int)	(FileMgr.cpp)
  001EB4F0 00000008 .text   CFileMgr::Tell(int)	(FileMgr.cpp)
  001EB500 0000002C .text   CFileMgr::ReadLine(int,char*,int)	(FileMgr.cpp)
  001EB530 00000024 .text   CFileMgr::Seek(int,int,int)	(FileMgr.cpp)
  001EB560 00000010 .text   CFileMgr::Write(int,char*,int)	(FileMgr.cpp)
  001EB570 00000010 .text   CFileMgr::Read(int,char*,int)	(FileMgr.cpp)
  001EB580 00000008 .text   CFileMgr::OpenFile(const char*,const char*)	(FileMgr.cpp)
  001EB590 00000064 .text   CFileMgr::GetFileSize(const char*)	(FileMgr.cpp)
  001EB600 00000094 .text   CFileMgr::LoadFile(const char*,unsigned char*,int,const char*)	(FileMgr.cpp)
  001EB6A0 0000000C .text   CFileMgr::Initialise()	(FileMgr.cpp)
--]]

--[[
  0015BBF0 000002E0 .text   CCutsceneMgr::setupAM_AnimatedCam()	(CutsceneMgr.cpp)
  0015BED0 00000030 .text   CCutsceneMgr::GetNthPropAnimToUpdate(int)	(CutsceneMgr.cpp)
  0015BF00 0000000C .text   CCutsceneMgr::GetNumberOfPropAnimsToUpdate()	(CutsceneMgr.cpp)
  0015BF10 00000054 .text   CCutsceneMgr::AddPAnimToNextCutscene(CPropAnim*)	(CutsceneMgr.cpp)
  0015BF70 00000038 .text   CCutsceneMgr::FinishMiniCutscene()	(CutsceneMgr.cpp)
  0015BFB0 00000054 .text   CCutsceneMgr::StartMiniCutscene()	(CutsceneMgr.cpp)
  0015C010 000000A4 .text   CCutsceneMgr::SetMiniCutsceneSound(const char*,float,bool)	(CutsceneMgr.cpp)
  0015C0C0 00000054 .text   CCutsceneMgr::GetCutsceneTimeInMilleseconds()	(CutsceneMgr.cpp)
  0015C120 0000009C .text   CCutsceneMgr::UpdateFrameInfo()	(CutsceneMgr.cpp)
  0015C1C0 00000178 .text   CCutsceneMgr::DrawSubtitles()	(CutsceneMgr.cpp)
  0015C340 00000220 .text   CCutsceneMgr::Update()	(CutsceneMgr.cpp)
  0015C560 0000000C .text   CCutsceneMgr::StopActionNode()	(CutsceneMgr.cpp)
  0015C570 000000B0 .text   CCutsceneMgr::SetActionNode(ActionNode*)	(CutsceneMgr.cpp)
  0015C620 00000080 .text   CCutsceneMgr::SetActionNode(const char*,const char*)	(CutsceneMgr.cpp)
  0015C6A0 0000064C .text   CCutsceneMgr::StartCutscene()	(CutsceneMgr.cpp)
  0015CCF0 00000080 .text   CCutsceneMgr::CutSceneStartInitialization()	(CutsceneMgr.cpp)
  0015CD70 00000150 .text   CCutsceneMgr::CreateCutsceneObject(int)	(CutsceneMgr.cpp)
  0015CEC0 000003E0 .text   CCutsceneMgr::DeleteCutsceneData()	(CutsceneMgr.cpp)
  0015D2A0 00000094 .text   CCutsceneMgr::LoadCutsceneSound(const char*)	(CutsceneMgr.cpp)
  0015D340 00001A0C .text   CCutsceneMgr::LoadCutsceneData(const char*,bool)	(CutsceneMgr.cpp)
  0015ED50 00000124 .text   CCutsceneMgr::RemoveEverythingBecauseCutsceneDoesntFitInMemory()	(CutsceneMgr.cpp)
  0015EE80 00000008 .text   CCutsceneMgr::Reset()	(CutsceneMgr.cpp)
  0015EE90 000000C0 .text   CCutsceneMgr::Initialise()	(CutsceneMgr.cpp)
--]]

local LoadCutsceneData = function()
	local a0 = eeObj.GetGPR(gpr.a0)	
	local st1 = eeObj.ReadMemStr(a0)
	
	
	print( string.format("*************** LOADING CUTSCENE DATA (%s) *********************", st1) )
--	eeObj.WriteMem8(a0+0,0x32) -- 2
--	eeObj.WriteMem8(a0+1,0x2d) -- -
--	eeObj.WriteMem8(a0+2,0x42) -- B
--	eeObj.WriteMem8(a0+3,0x42) -- B
--	eeObj.WriteMem8(a0+4,0x00) -- \0
--	eeObj.WriteMem8(a0+5,0x00) -- \0
	
--	eeObj.WriteMem8(a0+0,0x31) -- 1
--	eeObj.WriteMem8(a0+1,0x2d) -- -
--	eeObj.WriteMem8(a0+2,0x53) -- S
--	eeObj.WriteMem8(a0+3,0x30) -- 0
--	eeObj.WriteMem8(a0+4,0x31) -- 1
--	eeObj.WriteMem8(a0+5,0x00) -- \0
	
--	eeObj.WriteMem8(a0+0,0x33) -- 3
--	eeObj.WriteMem8(a0+1,0x2d) -- -
--	eeObj.WriteMem8(a0+2,0x42) -- B
--	eeObj.WriteMem8(a0+3,0x44) -- D
--	eeObj.WriteMem8(a0+4,0x00) -- \0
--	eeObj.WriteMem8(a0+5,0x00) -- \0	
	
--	eeObj.WriteMem8(a0+0,0x34) -- 4
--	eeObj.WriteMem8(a0+1,0x2d) -- -
--	eeObj.WriteMem8(a0+2,0x42) -- B
--	eeObj.WriteMem8(a0+3,0x32) -- 2
--	eeObj.WriteMem8(a0+4,0x42) -- B
--	eeObj.WriteMem8(a0+5,0x00) -- \0

-- this is the final 'boss' but not the end of the chapter
--	eeObj.WriteMem8(a0+0,0x35) -- 5
--	eeObj.WriteMem8(a0+1,0x2d) -- -
--	eeObj.WriteMem8(a0+2,0x42) -- B
--	eeObj.WriteMem8(a0+3,0x43) -- C
--	eeObj.WriteMem8(a0+4,0x00) -- \0
--	eeObj.WriteMem8(a0+5,0x00) -- \0	
	
-- After beating Gary (end of Chapter)
--	eeObj.WriteMem8(a0+0,0x36) -- 6
--	eeObj.WriteMem8(a0+1,0x2d) -- -
--	eeObj.WriteMem8(a0+2,0x42) -- B
--	eeObj.WriteMem8(a0+3,0x43) -- C
--	eeObj.WriteMem8(a0+4,0x00) -- \0
--	eeObj.WriteMem8(a0+5,0x00) -- \0		
	

	
	-- Last cutscene of Chapter 1
	if st1 == "1-BC" then
		if SaveData["Chapter1"] ~= 1 then
			AwardTrophy(20, "Chapter1")
		end	
	end
	
	-- Last cutscene of Chapter 2
	if st1 == "2-BB" then
		if SaveData["Chapter2"] ~= 1 then
			AwardTrophy(21, "Chapter2")
		end		
	end
	
	-- Last cutscene of Chapter 3
	if st1 == "3-BD" then	
		if SaveData["Chapter3"] ~= 1 then
			AwardTrophy(22, "Chapter3")
		end	
	end
	
	-- Last cutscene of Chapter 4
	if st1 == "4-B2B" then	
		if SaveData["Chapter4"] ~= 1 then
			AwardTrophy(23, "Chapter4")
		end	
	end
	
	-- Last cutscene of Chapter 5
	if st1 == "6-BC" then	
		if SaveData["Chapter5"] ~= 1 then
			AwardTrophy(34, "Chapter5")
		end	
	end	
end

if Region == 2 then
	LoadCutsceneDataHook = eeObj.AddHook(0x015D340,0x27BDFB50, LoadCutsceneData)
elseif Region == 0 then
	LoadCutsceneDataHook = eeObj.AddHook(0x015cef0,0x27BDFB50, LoadCutsceneData)
elseif Region == 1 then
	LoadCutsceneDataHook = eeObj.AddHook(0x015d330,0x27BDFB50, LoadCutsceneData)
end

-- 001EB580 00000008 .text   CFileMgr::OpenFile(const char*,const char*)	(FileMgr.cpp)
-- 001EB580    080C163A	j           0x003058E8          .. .. .. BR .. .. .. ..  
-- 003058E8 000000F0 .text   RwFopen	(librtfsyst.a rtfsmgr.obj/   )
-- 003058E8    27BDFFA0	addiu       sp,sp,-0x60         IX .. .. .. .. .. .. ..  
-- 003058EC    7FB20030	sq          s2,0x0030(sp)       .. .. LS .. .. .. .. ..  [01] REG 

local OpenFileF = function()
	local a0 = eeObj.GetGPR(gpr.a0)	
	local st1 = eeObj.ReadMemStr(a0)

--	print( string.format("*************** OPENING FILE!! (%s) *********************", st1) )
end


if Region == 2 then
	OpenFileHook = eeObj.AddHook(0x003058E8,0x27BDFFA0, OpenFileF)
elseif Region == 0 then
	OpenFileHook = eeObj.AddHook(0x003052f8,0x27BDFFA0, OpenFileF)
elseif Region == 1 then
	OpenFileHook = eeObj.AddHook(0x00305a18,0x27BDFFA0, OpenFileF)
end



--[[
local FrameCount = 0

local StartupTimer = function()
	-- ensure we're not running these during the initial loading
	if ReadyToCheck == 0 then
		FrameCount = FrameCount + 1;
	
		if FrameCount == (60*60) then -- 60fps, 60 seconds
			ReadyToCheck = 1
		end
	
	end
end

StartUpHook = emuObj.AddVsyncHook(StartupTimer)
--]]

	

-- Credits

-- Trophy design and development by SCEA ISD SpecOps
-- David Thach                  Senior Director
-- George Weising               Executive Producer
-- Tim Lindquist                Senior Technical PM
-- Clay Cowgill                 Engineering
-- Nicola Salmoria              Engineering
-- David Haywood                Engineering
-- Warren Davis                 Engineering
-- Jenny Murphy                 Producer
-- David Alonzo                 Assistant Producer
-- Tyler Chan                   Associate Producer
-- Karla Quiros                 Manager Business Finance & Ops
-- Mayene de la Cruz            Art Production Lead
-- Thomas Hindmarch             Production Coordinator
-- Special thanks to R&D

