-- Lua 5.3
-- Title: Star Ocean: Till the End of Time - SLES-82028 (Europe, Disc 1) v1.01
-- Author: Nicola Salmoria
-- Date: 22 August, 2016

-- 20160512: Added impose menu disc switch API support. TGL
-- 20160628: Added replacement formatted memorycard to fix Battle Trophy

local gpr = require( "ee-gpr-alias" )

apiRequest(1.3)

local eeObj		= getEEObject()
local emuObj	= getEmuObject()

emuObj.EnableImposeMenu(false)
emuObj.SetFormattedCard("custom_formatted.card")

local FH1 =	-- initialize the progressive mode flag
	function()
		local at = eeObj.GetGpr(gpr.at)
		eeObj.WriteMem8(at + 23684, 1)
	end

local FH2 =	-- set up display parameters
	function()
		local height = eeObj.GetGpr(gpr.a3)
		eeObj.SetGpr(gpr.a3, 2 * height)	-- double screen height since we forced progressive mode
	end

local FH3 =	-- initialize the widescreen flag on boot
	function()
		local s0 = eeObj.GetGpr(gpr.s0)
		eeObj.WriteMem8(s0 + 396, 1)
	end

local FH4A =	-- setup player faces for battle HUD
	function()
		-- replicate SLUS behavior when progressive mode is enabled
		local gp = eeObj.GetGpr(gpr.gp)
		local textureTransManager = eeObj.ReadMem32(gp - 31348)
		local textureId = eeObj.ReadMem16(textureTransManager + 1532)
		local s3 = eeObj.GetGpr(gpr.s3)
		eeObj.WriteMem16(s3 + 90, textureId)
	end

local FH4B =	-- initialize font manager for battle
	function()
		-- force values for progressive mode, taken from SLUS
		eeObj.SetGpr(gpr.a1, 256)
		eeObj.SetGpr(gpr.a2, 96)
	end

local function updateAspect(reg)
	local isWidescreen = eeObj.GetGpr(reg)

	if isWidescreen == 0 then
		emuObj.SetDisplayAspectNormal()
	else
		emuObj.SetDisplayAspectWide()
	end
end

local FH5 =	-- init screen aspect on boot
	function()
		updateAspect(gpr.v0)
	end

local FH6 =	-- update screen aspect on initial settings menu
	function()
		updateAspect(gpr.v1)
	end

local FH7 =	-- update screen aspect on in-game setting menu
	function()
		updateAspect(gpr.s0)
	end

local FH8 =	-- update camera aspect 
	function()
		updateAspect(gpr.v1)
	end

local originalMsg    = "\x40\x36\x3C\xE8\x01\x37\x39\x2C\x3A\x3A\xE8\x01\x9D\x80\x21\x0C\x80\x80\x13\x36\x39\xE8\x01\x2C\x3F\x28\x34\x37\x33\x2C\x82\x02\xE8\x01\x3B\x39\x40\xE8\x01\x37\x39\x2C\x3A\x3A\x30\x35\x2E\xE8\x01\x2F\x28\x39\x2B\xE8\x01\x36\x39\xE8\x01\x33\x36"
local replacementMsg = "\x33\x36\x35\x2E\xE8\x01\x40\x36\x3C\xE8\x01\x37\x39\x2C\x3A\x3A\xE8\x01\x9D\x80\x21\xE8\x01\x28\x35\x2B\xE8\x01\x3E\x2F\x2C\x3B\x2F\x2C\x39\xE8\x01\x40\x36\x3C\xE8\x01\x28\x33\x3A\x36\xE8\x01\x2F\x36\x33\x2B\xE8\x01\x9D\x80\x26\x0C\x84\x80\x00"

local FH9A =	-- load strings for environment
	function()
		local buffer = eeObj.GetGpr(gpr.a1)
		local patchAddr = buffer + 0x323 + 0x4d

		local found = eeObj.ReadMemStr(patchAddr)

		-- replace Dragon Flute instructions message
		if string.sub(found, 1, string.len(originalMsg)) == originalMsg then
			eeObj.WriteMemStrZ(patchAddr, replacementMsg)
		end
	end

local originalDescription    = "\x2B\x2C\x37\x2C\x35\x2B\x30\x35\x2E\xE8\x01\x36\x35\xE8\x01\x80\x80\x2F\x36\x3E\xE8\x01\x33\x36\x35\x2E\xE8\x01\x28\x35\x2B\xE8\x01\x3A\x3B\x39\x36\x35\x2E\xE8"
local replacementDescription = "\x29\x40\xE8\x01\x37\x39\x2C\x3A\x3A\x30\x35\x2E\xE8\x01\x9D\x80\x14\xE8\x01\x3E\x2F\x30\x33\x2C\xE8\x01\x2F\x36\x33\x2B\x30\x35\x2E\xE8\x01\x9D\x80\x1A\x0C\x00"

local FH9B =	-- load strings for inventory
	function()
		local buffer = eeObj.GetGpr(gpr.s1)
		local patchAddr = buffer + 0x1c71f + 0x4d

		local found = eeObj.ReadMemStr(patchAddr)

		-- replace Dragon Flute description message
		if string.sub(found, 1, string.len(originalDescription)) == originalDescription then
			eeObj.WriteMemStrZ(patchAddr, replacementDescription)
		end
	end

local origButton = 0;

local FH10A =	-- process input for Dragon Flute
	function()
		origButton = eeObj.GetGpr(gpr.s2)
		eeObj.SetGpr(gpr.s2, 0x0100)	-- replace Circle/Cross with L2
	end

local FH10B =	-- process input for Dragon Flute
	function()
		eeObj.SetGpr(gpr.s2, origButton)	-- set back to Circle/Cross

		local analog = eeObj.GetGpr(gpr.s1)
		if analog > 0 then	-- L2 pressed
			eeObj.SetGpr(gpr.s1, 255)	-- always pretend fully pressed
		end
	end

local DH1 =	-- request disc switch
	function()
		local manager = eeObj.GetGpr(gpr.s2)
		local discId = eeObj.ReadMem8(manager + 35) + 1

		-- instantly switch to the requested disc
		emuObj.SwitchDisc(discId)

		eeObj.SetGpr(gpr.v1, 10)	-- skip waiting for tray to open/close
	end

local DH2 =	-- delay during disc switch
	function()
		eeObj.SetFpr(1, 0.0)	-- skip delay
	end

local DH3 =	-- play sound during disc switch
	function()
		eeObj.SetGpr(gpr.t0, 0)	-- force volume to 0
	end

local DH4 =	-- check disc tray
	function()
		eeObj.SetGpr(gpr.v0, 0)	-- always report tray as closed
	end


-- register hooks

local OV_1 = 0x1dd580
local OV_2 = 0x3e6880
local OV_3 = 0x32b400
local OV_4 = 0x347f80

local ovlAddresses = {
	-- overlay group 1
	["boot.bin"]			= OV_1,
	["i"]					= OV_1,
	["y"]					= OV_1,

	-- overlay group 2
	["Lib.bin"]				= OV_2,

	-- overlay group 3
	["SPBaalArea4.bin"]		= OV_3,

	-- overlay group 4
	["cconfig.bin"]			= OV_4,
	["citem.bin"]			= OV_4,
}

local ovlChk = function(opcode, pc, expectedName, expectedOpcode)
	local address = ovlAddresses[expectedName]
	local name = eeObj.ReadMemStr(address + 32)

	if name == expectedName then
		assert(opcode == expectedOpcode, string.format("Overlay opcode mismatch @ 0x%06x: expected 0x%08x, found %08x", pc, expectedOpcode, opcode))
		return true
	else
		return false
	end
end

local hooks = {
	eeObj.AddHook(0x101320, 0xa0205c84, FH1),	-- <CBios::__ct(void)>:

	eeObj.AddHook(0x4e0330, function(op, pc) return ovlChk(op, pc, "Lib.bin",         0x27bdff90) end, FH2),	-- <CDB::SetDispEnviroment(short, short, short)>:
	eeObj.AddHook(0x459344, function(op, pc) return ovlChk(op, pc, "Lib.bin",         0xa200018c) end, FH3),	-- <CStarOceanTET::Initialize(void)>:

	eeObj.AddHook(0x1e0790, function(op, pc) return ovlChk(op, pc, "i",               0xa662005a) end, FH4A),	-- <Battle::CSystemInit::BaseSystemInit( (void))>:
	eeObj.AddHook(0x1deeec, function(op, pc) return ovlChk(op, pc, "i",               0x0000302d) end, FH4B),	-- <Battle::CBattleApp::Init( (void))>:

	eeObj.AddHook(0x1eb938, function(op, pc) return ovlChk(op, pc, "boot.bin",        0x9042018c) end, FH5),	-- <Title::CTitleApp::Run( (void))>:
	eeObj.AddHook(0x1ead08, function(op, pc) return ovlChk(op, pc, "boot.bin",        0x9043018c) end, FH6),	-- <Title::CTitleApp::ChangeAspectRatio( (void))>:

	eeObj.AddHook(0x351c18, function(op, pc) return ovlChk(op, pc, "cconfig.bin",     0x9050018c) end, FH7),	-- <Camp::CConfigView::ReqImgageWideCheck( (void))>:

	eeObj.AddHook(0x22558c, function(op, pc) return ovlChk(op, pc, "y",               0x9043018c) end, FH8),	-- <Fld::CCameraProcess::SetAspectRatio( (CCamera *))>:
	eeObj.AddHook(0x217eb4, function(op, pc) return ovlChk(op, pc, "y",               0x8ea5054c) end, FH9A),	-- <Snr::CScenario::Initialize( (unsigned char const *, unsigned char const *, unsigned char))>:

	eeObj.AddHook(0x353298, function(op, pc) return ovlChk(op, pc, "citem.bin",       0x8f84858c) end, FH9B),	-- <Camp::CItemView::SetFontFile(unsigned char*)>:

	eeObj.AddHook(0x32b988, function(op, pc) return ovlChk(op, pc, "SPBaalArea4.bin", 0x94520002) end, FH10A),	-- <Fld::CBaalArea4FluteManager::Run( (void))>:
	eeObj.AddHook(0x32b99c, function(op, pc) return ovlChk(op, pc, "SPBaalArea4.bin", 0x00118c3f) end, FH10B),	-- <Fld::CBaalArea4FluteManager::Run( (void))>:

	-- handle disc switches
	eeObj.AddHook(0x3005b8, function(op, pc) return ovlChk(op, pc, "y",               0x24030008) end, DH1),	-- <Fld::CChangeDiscManager::Run( (void))>:
	eeObj.AddHook(0x300610, function(op, pc) return ovlChk(op, pc, "y",               0x46011041) end, DH2),	-- <Fld::CChangeDiscManager::Run( (void))>:
	eeObj.AddHook(0x300778, function(op, pc) return ovlChk(op, pc, "y",               0x46011041) end, DH2),	-- <Fld::CChangeDiscManager::Run( (void))>:
	eeObj.AddHook(0x300564, function(op, pc) return ovlChk(op, pc, "y",               0x2408007f) end, DH3),	-- <Fld::CChangeDiscManager::Run( (void))>:
	eeObj.AddHook(0x300900, function(op, pc) return ovlChk(op, pc, "y",               0x2408007f) end, DH3),	-- <Fld::CChangeDiscManager::Run( (void))>:

	eeObj.AddHook(0x11c794, 0x30420001, DH4),	-- <CStorage::GetShellOpen(void)>:
}
