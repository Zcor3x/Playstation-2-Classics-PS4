-- Lua 5.3
-- Title:   Destroy All Humans! 2 PS2 - SLES-54384 (EUR)
-- Author:  Ernesto Corvi, Adam McInnis

-- Changelog:

apiRequest(1.1)	-- request version 1.1 API. Calling apiRequest() is mandatory.

local eeObj		= getEEObject()
local emuObj	= getEmuObject()
local trophyObj	= getTrophyObject()
local gpr = require( "ee-gpr-alias" ) -- you can access EE GPR by alias (gpr.a0 / gpr["a0"])

local MAKE_WAR_NOT_LOVE						=  0 -- Unlock all other trophies. (automatic)
local FROM_RUSSIA_WITH_HATE					=  1 -- Complete "Furon Loathing in Bay City."
local ATTACK_THE_ROCK						=  2 -- Complete "The Guns of Alcatraz."
local EYES_IN_THE_SKY						=  3 -- Complete "On Natalya's Secret Service."
local LATE_NIGHT_CREATURE_FEATURE			=  4 -- Complete "Kojira Kaiju Battle."
local BALLROOM_BLISK						=  5 -- Complete "The Good, the Bad, and the Furon."
local SUCCESSFUL_REENTRY					=  6 -- Complete "Milenkov," and the game.
local THE_RAGE_OF_AQUARIUS					=  7 -- Complete all the Odd Jobs in Bay City.
local BRITISH_INVASION						=  8 -- Complete all the Odd Jobs in Albion.
local MARTIAN_YAKUZA						=  9 -- Complete all the Odd Jobs in Takoshima.
local COMING_IN_FROM_THE_COLD				= 10 -- Complete all the Odd Jobs in Tunguska.
local BAD_DAY_ON_THE_MOON					= 11 -- Complete the Odd Job in Solaris. (There's only the one, but now we're stuck with this theme.)
local HAVE_YOU_HEARD_THE_NEWS				= 12 -- Complete all the Cult of Arkvoodle missions in Bay City.
local SPREADING_THE_GOOD_WORD				= 13 -- Complete all the Cult of Arkvoodle missions in Albion.
local CULT_CLASSIC							= 14 -- Complete all the Cult of Arkvoodle missions in Takoshima.
local OODLES_AND_OODLES_OF_ARKVOODLE		= 15 -- Complete all Cult missions.
local BAY_LOW_CELL_HIGH						= 16 -- Collect all the Furotech Cells in Bay City.
local YOU_CAN_FIND_ANYTHING_IN_LONDON		= 17 -- Collect all the Furotech Cells in Albion.
local JAPANESE_COLLECTORS_EDITION			= 18 -- Collect all the Furotech Cells in Takoshima.
local VINTAGE_HARDWARE						= 19 -- Collect all the Furotech Cells in Tunguska.
local SOLAR_CELL							= 20 -- Collect all the Furotech Cells in Solaris.
local TO_US_THEY_ARE_JUST_ARTIFACTS			= 21 -- Collect all the Alien Artifacts in Bay City.
local REALLY_NOTHING_SPECIAL				= 22 -- Collect all the Alien Artifacts in Albion.
local SERIOUSLY_GUYS_THEY_ARE_NO_BIG_DEAL	= 23 -- Collect all the Alien Artifacts in Takoshima.
local ALL_RIGHT_IF_YOU_CARE_THAT_MUCH		= 24 -- Collect all the Alien Artifacts in Tunguska.
local JUST_WAIT_UNTIL_THEY_INVENT_EBAY		= 25 -- Collect all the Alien Artifacts in Solaris.
local DESTROY_ALL_BLISKS_TOO				= 26 -- Achieve 100% completion. (All story missions, all Side Jobs, all collectibles.)
local AND_ADD_SOME_SPINNING_RIMS			= 27 -- Collect all the Datacores. (The Gastro's Music Datacore doesn't "count" for completion in-game, so it probably shouldn't count for this trophy either.)
local BAY_CITY_SMOOTHIE						= 28 -- Complete all the Bay City Gene Blends.
local ALBION_SPECIAL_BLEND					= 29 -- Complete all the Albion Gene Blends.
local TAKOSHIMA_TINCTURE					= 30 -- Complete all the Takoshima Gene Blends
local TUNGUSKA_TONIC						= 31 -- Complete all the Tunguska Gene Blends. (This will also unlock all entries in the Gallery.)
local WHY_YES_IT_IS_A_COOKBOOK				= 32 -- Complete all Gene Blends at least once, including the Solaris and common "recipes."
local SHOCK_TREATMENT						= 33 -- Purchase all the upgrades for the Zap-O-Matic.
local WALL_TO_WALL_NOTHING_AT_ALL			= 34 -- Purchase all the upgrades for the Quantum Deconstructor.
local TICKET_TO_RIDE						= 35 -- Purchase all the upgrades for the Disclocator.
local A_CLASSIC_FOR_A_REASON				= 36 -- Purchase all the upgrades for the Death Ray.
local ITS_DISINTE_GREAT						= 37 -- Purchase all the upgrades for the Disintegrator Ray.
local WE_ALL_FLOAT_UP_HERE					= 38 -- Purchase all the upgrades for the Anti-Gravity Field.
local WE_ARE_ALL_HAVING_A_BLAST				= 39 -- Purchase all the upgrades for the Ion Detonator.
local SPACE_ROCK_AND_ROLL					= 40 -- Purchase all the upgrades for the Meteor Strike.
local FISH_GOTTA_SWIM_BEASTS_GOTTA_EAT		= 41 -- Purchase all the upgrades for the Burrow Beast. (To unlock it, collect 30 Alien Artifacts and finish the last Arkvoodle mission.)

local SaveData = emuObj.LoadConfig(0)

function initsaves()
	local needsSave = false
	
	if SaveData.t == nil then
		SaveData.t = {}
		needsSave = true
	end
	
	for x = 0, 41 do
		if SaveData.t[x] == nil then
			SaveData.t[x] = 0
			needsSave = true
		end
	end
	
	if (needsSave == true) then
		emuObj.SaveConfig(0, SaveData)
	end
	
end

initsaves()

function unlockTrophy(trophy_id)
	if SaveData.t[trophy_id] ~= 1 then
		SaveData.t[trophy_id] = 1
		trophyObj.Unlock(trophy_id)
		emuObj.SaveConfig(0, SaveData)
	end
end

-----------------------------------------------------------------

local getKeyProgress = function()
	local progress = eeObj.ReadMem32(0x50326C) -- from UFO::Progress::Get
	local keyTable = progress+0x0c -- from UFO::Progress::Record::FindKey
	local storage = keyTable+4
	local count = eeObj.ReadMem32(keyTable)
	local keys = {}

	for x = 0, count - 1 do
		local key = eeObj.ReadMem32(storage+(x*8))
		keys[key] = x
	end
	
	return keys
end

local getIntProgress = function()
	local progress = eeObj.ReadMem32(0x50326C) -- from UFO::Progress::Get
	local keyTable = progress+0x3e14 -- from UFO::Progress::Record::FindS32
	local storage = keyTable+4
	local count = eeObj.ReadMem32(keyTable)
	local keys = {}

	for x = 0, count - 1 do
		local key = eeObj.ReadMem32(storage+(x*12))
		local value = eeObj.ReadMem32(storage+(x*12)+8)
		keys[key] = value
	end
	
	return keys
end

local checkAllGeneBlends = function()
	local progress = getKeyProgress()
	local gCount = 0
	local lCount = 0
	local globalKeys = {0x10590fea, 0xeb84084b, 0xe6c72e92, 0x784b3ec2, 0x7508181b, 0x314116d2, 0x3c02300b, 0x2ab4d1b3, 0x27f7f76a, 0x7bbd4017,
						0x76fe66ce, 0x1b4a1bd1, 0x16093d08, 0x542d40a5, 0xb46f061b, 0x242a4cea, 0x146994ca, 0x8fb314f2, 0xe6cf9f72, 0x73af9176}
	local localKeys = {0x9c348b5e, 0x98f596e9, 0x88307075, 0x8cf16dc2, 0x4a224a49, 0xf770f868,				-- bc: 6
					   0x513b69d6, 0x55fa7461, 0x7166bdf7, 0x75a7a040, 0xd56904d7, 0x0e2635ea, 0xc2b59b4a,	-- ab: 7
					   0x0d5783e1, 0x7b08f600, 0x7fc9ebb7, 0x988e25f5, 0x5f7e1d69,							-- tk: 5
					   0xd9b3504a, 0xdd724dfd, 0x6d9c2bc7,													-- tu: 3
					   0x59a97c63}																			-- mb: 1
	
	for x = 1, #globalKeys do
		if progress[globalKeys[x]] ~= nil then
			gCount = gCount + 1
		end
	end
	
	for x = 1, #localKeys do
		if progress[localKeys[x]] ~= nil then
			lCount = lCount + 1
		end
	end
	
	if gCount == 20 and lCount == 22 then
		unlockTrophy(WHY_YES_IT_IS_A_COOKBOOK)
	end
end

local checkAllCults = function(crc)
	local progress = getKeyProgress()
	progress[crc] = 1
	local count = 0
	local cults = {0x2c4fc4d5, 0x6542a358, 0xbe550bcf, 0xf7586c42, 0xd004a92b, 0x4374e7b2, 0x98634f25,	-- bc
				   0x211e4551, 0xfa09edc6, 0x7dd38917, 0xa0b55c8a, 0xdc3fa92c,							-- ab
				   0xe099d26a, 0x3b8e7afd, 0x31b5a55b, 0xc6af9680}										-- tk

	for x = 1, #cults do
		if progress[cults[x]] ~= nil then
			count = count + 1
		end
	end

	if count >= 16 then
		unlockTrophy(OODLES_AND_OODLES_OF_ARKVOODLE)
	end
end

local checkAllOJbc = function(key)				-- Check all Odd Jobs Bay City
	local progress = getKeyProgress()
	progress[key] = 1							-- force setting of progress since wont be set by function...yet.	
	if progress[0x4cab897f] ~= nil and progress[0x49dddfef] ~= nil and progress[0x92ca7778] ~= nil and progress[0x4c77db7a] ~= nil and progress[0xfe9997e3] ~= nil and progress[0x057abcf7] ~= nil and progress[0xde6d1460] ~= nil then
		unlockTrophy(THE_RAGE_OF_AQUARIUS)		-- Complete all the Odd Jobs in Albion.
	end
end

local checkAllOJal = function(key)				-- Check all Odd Jobs Albion
	local progress = getKeyProgress()
	progress[key] = 1							-- force setting of progress since wont be set by function...yet.	
	if progress[0xb724fa31] ~= nil and progress[0xd4399d90] ~= nil and progress[0xd967899a] ~= nil and progress[0x0270210d] ~= nil and progress[0xbdc0799e] ~= nil and progress[0x0f2e3507] ~= nil then
		unlockTrophy(BRITISH_INVASION)			-- Complete all the Odd Jobs in Albion.
	end
end

local checkAllOJtk = function(key)				-- Check all Odd Jobs Takoshima
	local progress = getKeyProgress()
	progress[key] = 1							-- force setting of progress since wont be set by function...yet.
	if progress[0xcd220c08] ~= nil and progress[0x1635a49f] ~= nil and progress[0x99f52a75] ~= nil and progress[0x42e282e2] ~= nil and progress[0x943e0cbd] ~= nil and progress[0x62160161] ~= nil and progress[0xb901a9f6] ~= nil then
		unlockTrophy(MARTIAN_YAKUZA)			-- Complete all the Odd Jobs in Takoshima.
	end
end

local checkAllOJtu = function(key)				-- Check all Odd Jobs Tunguska
	local progress = getKeyProgress()
	progress[key] = 1							-- force setting of progress since wont be set by function...yet.
	if progress[0x7aa32949] ~= nil and progress[0x2f2f05c0] ~= nil and progress[0x5a8b6026] ~= nil and progress[0x9dc14959] ~= nil and progress[0x6622624d] ~= nil and progress[0xa1b481de] ~= nil then
		unlockTrophy(COMING_IN_FROM_THE_COLD)	-- Complete all the Odd Jobs in Tunguska.
	end
end

local checkAllOJmb = function(key)				-- Check all Odd Jobs Solaris (mb - moon base)
	local progress = getKeyProgress()
	progress[key] = 1							-- force setting of progress since wont be set by function...yet.
	if progress[0x2b30b9b9] ~= nil then
		unlockTrophy(BAD_DAY_ON_THE_MOON)		-- Complete the Odd Job in Solaris. (There's only the one, but now we're stuck with this theme.)
	end
end

local checkAllCompleted = function(key)			-- Achieve 100% completion. (All story missions, all Side Jobs, all collectibles.)
	local progress = getKeyProgress()
	progress[key] = 1							-- force setting of progress since wont be set by function...yet.

	-- Check all Mission, Odd Jobs & Arkvoodle. Format: 1st line: Missions, 2nd line: Odd Jobs, 3rd line: Arkvoodle cults
	local completedKeys = {
		-- Bay City
		0x25526d71, 0xfe45c5e6, 0xb748a26b, 0xb748a26b, 0xdeb14665,
		0x4cab897f, 0x49dddfef, 0x92ca7778, 0x4c77db7a, 0xfe9997e3, 0x057abcf7, 0xde6d1460,
		0x2c4fc4d5, 0x6542a358, 0xbe550bcf, 0xf7586c42, 0xd004a92b, 0x4374e7b2, 0x98634f25,
		-- Albion
		0x6c3352a6, 0xfe299dbc, 0x05cab6a8, 0x4cc7d125, 0x97d079b2,
		0xb724fa31, 0xd4399d90, 0xd967899a, 0x0270210d, 0xbdc0799e, 0x0f2e3507,
		0x211e4551, 0xfa09edc6, 0x7dd38917, 0xa0b55c8a, 0xdc3fa92c,
		-- Takoshima
		0xcc1a6da8, 0x170dc53f, 0x5e00a2b2, 0xa5e389a6, 0xeceeee2b, 0x37f946bc,
		0xcd220c08, 0x1635a49f, 0x99f52a75, 0x42e282e2, 0x943e0cbd, 0x62160161, 0xb901a9f6,
		0xe099d26a, 0x3b8e7afd, 0x31b5a55b, 0xc6af9680,
		-- Tunguska
		0x684bc056, 0xb35c68c1, 0xfa510f4c, 0x01b22458, 0x48bf43d5, 0x93a8eb42,
		0x7aa32949, 0x2f2f05c0, 0x5a8b6026, 0x9dc14959, 0x6622624d, 0xa1b481de,
		-- Solaris
		0x2730ded2, 0xfc277645, 0x4ec93adc, 0xb52a11c8, 0x07c45d51, 0xdcd3f5c6,
		0x2b30b9b9}

	for x = 1, #completedKeys do
		if progress[completedKeys[x]] == nil then
			return
		end
	end

	-- Check Datacores
	local intprogress = getIntProgress()
	local total = 0
	local datacores = { 0x09d61ebe, 0xf861bc5a, 0xb5ad0bbf, 0xd8608c9d} -- stats.bc.datacores, .ab, .tk, .tu

	for x = 1, #datacores do
		if intprogress[datacores[x]] ~= nil then
			total = total + intprogress[datacores[x]]
		end
	end
	if total < 16 then
		return
	end

	-- Check all Global & Local Geneblends
	local count = 0
	local genes = {0x10590fea, 0xeb84084b, 0xe6c72e92, 0x784b3ec2, 0x7508181b, 0x314116d2, 0x3c02300b, 0x2ab4d1b3, 0x27f7f76a, 0x7bbd4017, -- global: 20
				   0x76fe66ce, 0x1b4a1bd1, 0x16093d08, 0x542d40a5, 0xb46f061b, 0x242a4cea, 0x146994ca, 0x8fb314f2, 0xe6cf9f72, 0x73af9176,
				   0x9c348b5e, 0x98f596e9, 0x88307075, 0x8cf16dc2, 0x4a224a49, 0xf770f868,				-- bc: 6
				   0x513b69d6, 0x55fa7461, 0x7166bdf7, 0x75a7a040, 0xd56904d7, 0x0e2635ea, 0xc2b59b4a,	-- ab: 7
				   0x0d5783e1, 0x7b08f600, 0x7fc9ebb7, 0x988e25f5, 0x5f7e1d69,							-- tk: 5
				   0xd9b3504a, 0xdd724dfd, 0x6d9c2bc7,													-- tu: 3
				   0x59a97c63}																			-- mb: 1

	for x = 1, #genes do
		if progress[genes[x]] ~= nil then
			count = count + 1
		end
	end
	if count < 42 then
		return
	end
		
	-- Check all Furotech Cells & Alien Artifacts
	if intprogress[0x02dcfc18] == 40 and intprogress[0x2260f95e] == 40 and intprogress[0xa1303dc8] == 40
	and intprogress[0x36c5d2cf] == 40 and intprogress[0x0f42928b] == 40 and intprogress[0x280bb42c] == 10
	and intprogress[0xd9bc16c8] == 10 and intprogress[0x9470a12d] == 10 and intprogress[0xf9bd260f] == 10
	and intprogress[0xf9d082e0] == 10 then	
		unlockTrophy(DESTROY_ALL_BLISKS_TOO)	-- Achieve 100% completion. (All story missions, all Side Jobs, all collectibles.)
	end	
	
end

-------------- Main Hooks ---------------

local H1 = function() -- UFO::Progress::Record::AddKey
	local crc = eeObj.ReadMem32(eeObj.GetGpr(gpr.a1))
	
-- *** MISSIONS ***	
-- Bay City
	if crc == 0x25526d71 then						-- Mission 1: Complete "Furon Loathing in Bay City." (bc.m1.win)
		unlockTrophy(FROM_RUSSIA_WITH_HATE)			-- Complete "Furon Loathing in Bay City."
	elseif crc == 0x4cab897f then					-- Odd Job 1: I Left My Parts In San Fran... Err, Bay City (bc.m4.win)
		checkAllOJbc(0x4cab897f)
	elseif crc == 0xdeb14665 then					-- Mission 5: The Guns of Alcatraz (bc.m6.win)
		unlockTrophy(ATTACK_THE_ROCK)				-- Complete "The Guns of Alcatraz." (bc.m6.win)
	elseif crc == 0xfe9997e3 then					-- Odd Job 5: Assassination - Rudolph the Red-Nosed Cop (bc.ass02.win)
		checkAllOJbc(0xfe9997e3)
	elseif crc == 0x4c77db7a then					-- Odd Job 4: Assassination - Private Danza (bc.ass04.win)
		checkAllOJbc(0x4c77db7a)
	elseif crc == 0x057abcf7 then					-- Odd Job 6:  Assassination - Outfoxed (bc.ass05.win)
		checkAllOJbc(0x057abcf7)
	elseif crc == 0xde6d1460 then					-- Odd Job 7: Assassination - The Equalizer (bc.ass06.win)
		checkAllOJbc(0xde6d1460)
	elseif crc == 0x98634f25 then					-- Arkvoodle 7: Freakin' Art (bc.cultleader02.win)
		unlockTrophy(HAVE_YOU_HEARD_THE_NEWS)		-- Complete all the Cult of Arkvoodle missions in Bay City.
		checkAllCults(crc)
	elseif crc == 0x49dddfef then					-- Odd Job 2: Ruin Lives - The Secretary! (bc.ruinlives01.win)
		checkAllOJbc(0x49dddfef)
	elseif crc == 0x92ca7778 then					-- Odd Job 3: Ruin Lives - The Draft Dodger (bc.ruinlives02.win)
		checkAllOJbc(0x92ca7778)

-- Albion
	elseif crc == 0xb724fa31 then					-- Odd Job 8: Rage of Aquarius (ab.m2.win)
		checkAllOJal(0xb724fa31)
	elseif crc == 0x97d079b2 then					-- Mission 10:  On Natalya's Secret Service (ab.m6.win)
		unlockTrophy(EYES_IN_THE_SKY)				-- Complete "On Natalya's Secret Service."
	elseif crc == 0xd4399d90 then					-- Odd Job 9: Assassination - Plugging Terry Squire (ab.ass01.win)
		checkAllOJal(0xd4399d90)
	elseif crc == 0x0f2e3507 then					-- Odd Job 13:  Assassination - Secret Agent, Red Weasel (ab.ass02.win)
		checkAllOJal(0x0f2e3507)
	elseif crc == 0xbdc0799e then					-- Odd Job 12:  Assassination - Luka Out (ab.ass04.win)
		checkAllOJal(0xbdc0799e)
	elseif crc == 0xdc3fa92c then					-- Arkvoodle 12: Freaky Flyers (ab.cultleader01.win)
		unlockTrophy(SPREADING_THE_GOOD_WORD)		-- Complete all the Cult of Arkvoodle missions in Albion.
		checkAllCults(crc)
	elseif crc == 0xd967899a then					-- Odd Job 10: Ruin Lives - Take It Like a Man (ab.ruinlives01.win)
		checkAllOJal(0xd967899a)
	elseif crc == 0x0270210d then					-- Odd Job 11: Ruin Lives - Algernon's Change of Heart (ab.ruinlives02.win)
		checkAllOJal(0x0270210d)

-- Takoshima
	elseif crc == 0x37f946bc then					-- Mission 16: Kojira Kaiju Battle (tk.m6.win)
		unlockTrophy(LATE_NIGHT_CREATURE_FEATURE)	-- Complete "Kojira Kaiju Battle."
	elseif crc == 0x99f52a75 then					-- Odd Job 16: Assassination - Kenji Mojo Called Out
		checkAllOJtk(0x99f52a75)
	elseif crc == 0x42e282e2 then					-- Odd Job 17: Assassination - Double-Tap into the Power (tk.ass02.win)
		checkAllOJtk(0x42e282e2)
	elseif crc == 0xb901a9f6 then					-- Odd Job 20: Assassination - Shearing the Llama (tk.ass05.win)
		checkAllOJtk(0xb901a9f6)
	elseif crc == 0x62160161 then					-- Odd Job 19: Assassination - Red Flush (tk.ass06.win)
		checkAllOJtk(0x62160161)
	elseif crc == 0xc6af9680 then					-- Arkvoodle 16:  The Coming of Arkvoodle (tk.cultleader01.win)
		unlockTrophy(CULT_CLASSIC)					-- Complete all the Cult of Arkvoodle missions in Takoshima.
		checkAllCults(crc)
	elseif crc == 0x943e0cbd then					-- Odd Job 18: The Ravages of Mohgra (tk.debunk01.win)
		checkAllOJtk(0x943e0cbd)
	elseif crc == 0xcd220c08 then					-- Odd Job 14: Ruin Lives - The Executive (tk.ruinlives01.win)
		checkAllOJtk(0xcd220c08)
	elseif crc == 0x1635a49f then					-- Odd Job 15: Ruin Lives - The Executive: Part 2 (tk.ruinlives02.win)
		checkAllOJtk(0x1635a49f)
		
-- Tunguska
	elseif crc == 0x93a8eb42 then					-- Mission 22:  The Good, the Bad, and the Furon (tu.m6.win)
		unlockTrophy(BALLROOM_BLISK)				-- Complete "The Good, the Bad, and the Furon." (tu.m6.win)
	elseif crc == 0x2f2f05c0 then					-- Odd Job 22: Assassination - Food Line in the Sky (tu.ass02.win)
		checkAllOJtu(0x2f2f05c0)
	elseif crc == 0x6622624d then					-- Odd Job 25: Assassination - At Least It's Not the Gulag (tu.ass03.win)
		checkAllOJtu(0x6622624d)
	elseif crc == 0x9dc14959 then					-- Odd Job 24: Assassination - Victor Isn't (tu.ass04.win)
		checkAllOJtu(0x9dc14959)
	elseif crc == 0x5a8b6026 then					-- Odd Job 23: The Abominable Yeti (tu.debunk01.win)
		checkAllOJtu(0x5a8b6026)
	elseif crc == 0x7aa32949 then					-- Odd Job 21: Ruin Lives - What, Me? Subversive? (tu.ruinlives01.win)
		checkAllOJtu(0x7aa32949)
	elseif crc == 0xa1b481de then					-- Odd Job 26: Ruin Lives - Bad Luck for Zablitsky (tu.ruinlives02.win)
		checkAllOJtu(0xa1b481de)
		
-- Soloris?
	elseif crc == 0xdcd3f5c6 then					-- Mission 28:  Milenkov (mb.m6.win)
		unlockTrophy(SUCCESSFUL_REENTRY)			-- Complete "Milenkov," and the game.
	elseif crc == 0x2b30b9b9 then					-- Odd Job 27:  Lights Out for Lobsters (mb.debunk01.win)
		checkAllOJmb(0x2b30b9b9)
	end
	
	checkAllCompleted(crc)	-- check if game 100% complete
end

local H2 = function() -- UFO::Progress::AddKey
	local crc = eeObj.ReadMem32(eeObj.GetGpr(gpr.sp))
	
-- *** Gene Blends ***
-- (Bay City)
	if crc == 0x9c348b5e or crc == 0x98f596e9 or crc == 0x88307075 or crc == 0x8cf16dc2 or crc == 0x4a224a49 or crc == 0xf770f868 then
		local progress = getKeyProgress()
		if progress[0x9c348b5e] ~= nil and progress[0x98f596e9] ~= nil and progress[0x88307075] ~= nil and progress[0x8cf16dc2] ~= nil and progress[0x4a224a49] ~= nil and progress[0xf770f868] ~= nil then
			unlockTrophy(BAY_CITY_SMOOTHIE)	-- Complete all the Bay City Gene Blends.
		end
	end
	
-- (Albion)
	if crc == 0x513b69d6 or crc == 0x55fa7461 or crc == 0x75a7a040 or crc == 0x7166bdf7 or crc == 0xd56904d7 or crc == 0x0e2635ea or crc == 0xc2b59b4a then
		local progress = getKeyProgress()
		if progress[0x513b69d6] ~= nil and progress[0x55fa7461] ~= nil and progress[0x75a7a040] ~= nil and progress[0x7166bdf7] ~= nil and progress[0xd56904d7] ~= nil and progress[0x0e2635ea] ~= nil and progress[0xc2b59b4a] ~= nil then
			unlockTrophy(ALBION_SPECIAL_BLEND)	-- Complete all the Albion Gene Blends.
		end
	end
	
-- (Takoshima)
	if crc == 0x0d5783e1 or crc == 0x7b08f600 or crc == 0x7fc9ebb7 or crc == 0x988e25f5 or crc == 0x5f7e1d69 then
		local progress = getKeyProgress()
		if progress[0x0d5783e1] ~= nil and progress[0x7b08f600] ~= nil and progress[0x7fc9ebb7] ~= nil and progress[0x988e25f5] ~= nil and progress[0x5f7e1d69] ~= nil then
			unlockTrophy(TAKOSHIMA_TINCTURE)	-- Complete all the Takoshima Gene Blends.
		end
	end
	
-- (Tunguska)
	if crc == 0xd9b3504a or crc == 0xdd724dfd or crc == 0x6d9c2bc7 then
		local progress = getKeyProgress()
		if progress[0xd9b3504a] ~= nil and progress[0xdd724dfd] ~= nil and progress[0x6d9c2bc7] ~= nil then
			unlockTrophy(TUNGUSKA_TONIC)	-- Complete all the Tunguska Gene Blends.
		end
	end

-- check for all Local and Global Gene Blends for trophy: WHY_YES_IT_IS_A_COOKBOOK	
	checkAllGeneBlends()
end

local H3 = function() -- luaB_print
	local strptr = eeObj.GetGpr(gpr.s1)
	local strlen = eeObj.GetGpr(gpr.s0)
	
	if strlen > 0 then
		local str = eeObj.ReadMemStr(strptr)
		
		if strlen > 20 and string.find(str, "Saving abduction Vault") ~= nil then
			local progress = getIntProgress()

			-- Furotech Cells --
			if progress[0x02dcfc18] == 40 then
				unlockTrophy(BAY_LOW_CELL_HIGH)						-- Collect all the Furotech Cells in Bay City. (stats.bc.weaponcells)
			end
			if progress[0x2260f95e] == 40 then
				unlockTrophy(YOU_CAN_FIND_ANYTHING_IN_LONDON)		-- Collect all the Furotech Cells in Albion. (stats.ab.weaponcells)
			end
			if progress[0xa1303dc8] == 40 then
				unlockTrophy(JAPANESE_COLLECTORS_EDITION)			-- Collect all the Furotech Cells in Takoshima. (stats.tk.weaponcells)
			end
			if progress[0x36c5d2cf] == 40 then
				unlockTrophy(VINTAGE_HARDWARE)						-- Collect all the Furotech Cells in Tunguska. (stats.tu.weaponcells)
			end
			if progress[0x0f42928b] == 40 then
				unlockTrophy(SOLAR_CELL)							-- Collect all the Furotech Cells in Solaris. (stats.mb.weaponcells)
			end
						
			-- Artifacts --
			if progress[0x280bb42c] == 10 then
				unlockTrophy(TO_US_THEY_ARE_JUST_ARTIFACTS)			-- Collect all the Alien Artifacts in Bay City. (stats.bc.artifacts)
			end
			if progress[0xd9bc16c8] == 10 then
				unlockTrophy(REALLY_NOTHING_SPECIAL)				-- Collect all the Alien Artifacts in Albion. (stats.ab.artifacts)
			end
			if progress[0x9470a12d] == 10 then
				unlockTrophy(SERIOUSLY_GUYS_THEY_ARE_NO_BIG_DEAL)	-- Collect all the Alien Artifacts in Takoshima. (stats.tk.artifacts)
			end
			if progress[0xf9bd260f] == 10 then
				unlockTrophy(ALL_RIGHT_IF_YOU_CARE_THAT_MUCH)		-- Collect all the Alien Artifacts in Tunguska. (stats.tu.artifacts)
			end
			if progress[0xf9d082e0] == 10 then
				unlockTrophy(JUST_WAIT_UNTIL_THEY_INVENT_EBAY)		-- Collect all the Alien Artifacts in Solaris. (stats.mb.artifacts)
			end

			-- Test Datacores
			local total = 0
			local datacores = { 0x09d61ebe, 0xf861bc5a, 0xb5ad0bbf, 0xd8608c9d} -- stats.bc.datacores, .ab, .tk, .tu
		
			for x = 1, #datacores do
				if progress[datacores[x]] ~= nil then
					total = total + progress[datacores[x]]
				end
			end
			if total >= 16 then
				unlockTrophy(AND_ADD_SOME_SPINNING_RIMS)			-- Collect all the Datacores. (The Gastro's Music Datacore doesn't "count" for completion in-game, so it probably shouldn't count for this trophy either.) (stats.datacores)
			end
		end
	end
end
						
local WeaponCRC = 0
local H4 = function() -- UFO::Progress::Record::AddKey (top of function to get WeaponCRC)
	local crc = eeObj.GetGpr(gpr.a1)
	WeaponCRC = crc
end

local H5 = function() -- UFO::Progress::Record::AddKey (in middle of function to get upgrade values)
	local value = eeObj.GetGpr(gpr.v1)
	
	if WeaponCRC == 0x776dc256 and value == 0x2a then
		unlockTrophy(SHOCK_TREATMENT)					-- Purchase all the upgrades for the Zap-O-Matic.
	elseif WeaponCRC == 0x90162f6c and value == 0x29 then
		unlockTrophy(WALL_TO_WALL_NOTHING_AT_ALL)		-- Purchase all the upgrades for the Quantum Deconstructor.
	elseif WeaponCRC == 0x781d8615 and value == 0x08 then
		unlockTrophy(TICKET_TO_RIDE)					-- Purchase all the upgrades for the Disclocator.
	elseif WeaponCRC == 0xd2b802bd and value == 0x28 then
		unlockTrophy(A_CLASSIC_FOR_A_REASON)			-- Purchase all the upgrades for the Death Ray.
	elseif WeaponCRC == 0x02cb0f11 and value == 0x0e then
		unlockTrophy(ITS_DISINTE_GREAT)					-- Purchase all the upgrades for the Disintegrator Ray.
	elseif WeaponCRC == 0x4beafa67 and value == 0x28 then
		unlockTrophy(WE_ALL_FLOAT_UP_HERE)				-- Purchase all the upgrades for the Anti-Gravity Field.
	elseif WeaponCRC == 0x5295e63f and value == 0x0e then
		unlockTrophy(WE_ARE_ALL_HAVING_A_BLAST)			-- Purchase all the upgrades for the Ion Detonator.
	elseif WeaponCRC == 0x5003ca71 and value == 0x2b then
		unlockTrophy(SPACE_ROCK_AND_ROLL)				-- Purchase all the upgrades for the Meteor Strike.
	elseif WeaponCRC == 0x2e7a170c and value == 0x28 then
		unlockTrophy(FISH_GOTTA_SWIM_BEASTS_GOTTA_EAT)	-- Purchase all the upgrades for the Burrow Beast. (To unlock it, collect 30 Alien Artifacts and finish the last Arkvoodle mission.)
	end
end

local hook1 = eeObj.AddHook(0x26E138, 0x27bdff70, H1) -- UFO::Progress::Record::AddKey
local hook2 = eeObj.AddHook(0x2702CC, 0x38470001, H2) -- UFO::Progress::AddKey
local hook3 = eeObj.AddHook(0x3723C4, 0x0040802d, H3) -- luaB_print
local hook4 = eeObj.AddHook(0x26EEA0, 0x27bdffc0, H4) -- UFO::Progress::Record::SetWeaponUpgrade
local hook5 = eeObj.AddHook(0x26EEFC, 0x00851825, H5) -- UFO::Progress::Record::SetWeaponUpgrade


--[[
FAQS: http://www.gamefaqs.com/ps2/932584-destroy-all-humans-2/faqs/46658
Furotech Cells & Artifacts: http://www.gamefaqs.com/ps2/932584-destroy-all-humans-2/faqs/46258
]]--