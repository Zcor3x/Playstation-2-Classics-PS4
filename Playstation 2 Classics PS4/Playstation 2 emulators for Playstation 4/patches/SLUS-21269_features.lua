-- Lua 5.3
-- Title: Bully (USA)    SLUS-21269
--        Bully (Japan)  SLPS-25879
--        Bully (Europe) SLES-53561
-- Features version 1.00
-- Author: David Haywood
-- Date: Novemeber 16, 2015


require( "ee-gpr-alias" ) -- you can access EE GPR by alias (gpr.a0 / gpr["a0"])

apiRequest(0.7)	-- request version 0.7 API. Calling apiRequest() is mandatory.

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
local Region = 0


local SetAspectFunc = function()
	
	local a0 = eeObj.GetGPR(gpr.a0)
	
	a0 = a0 & 1
	
	if a0 == 1 then
		print( string.format("********* Request WIDE SCREEN mode **************" ) )
		emuObj.SetDisplayAspectWide()		
	else
		print( string.format("********* Request 4:3 mode **************" ) )
		emuObj.SetDisplayAspectNormal()	
	end

end

if Region == 2 then
	SetAspectHook = eeObj.AddHook(0x04aa7a0,0x27bdfff0, SetAspectFunc)
elseif Region == 0 then
	SetAspectHook = eeObj.AddHook(0x04a9d10,0x27bdfff0, SetAspectFunc)
elseif Region == 1 then
	SetAspectHook = eeObj.AddHook(0x04ab6c0,0x27bdfff0, SetAspectFunc)
end

--[[ clip from Settings::Initialize() 

can't we detect native aspect of the system with sceScfGetAspect, rather than forcing it to widescreen by default?

0020c648    (0c14fb46:F...) jal     0x0053ed18 --   0053ED18 00000040 .text   sceScfGetAspect	(libscf.a libscf.o/      )
0020c64c    (00000000:....) nop
0020c650    (24030002:...$) li      $v1,2
0020c654    (14430005:..C.) bne     $v0,$v1,0x0020c66c
0020c658    (00000000:....) nop

]]

local DefaultAspectFunc = function()
	
	local v0 = eeObj.GetGPR(gpr.v0)
	
	v0 = 2

	eeObj.SetGPR(gpr.v0, v0)
	emuObj.SetDisplayAspectWide()

end

if Region == 2 then
	SetAspectHook = eeObj.AddHook(0x020c650,0x24030002, DefaultAspectFunc)
elseif Region == 0 then
	SetAspectHook = eeObj.AddHook(0x020c080,0x24030002, DefaultAspectFunc)
elseif Region == 1 then
	SetAspectHook = eeObj.AddHook(0x020c780,0x24030002, DefaultAspectFunc)
end




--[[

 004AA7A0 000000A4 .text   FEOptions::SetAspectRatio(bool)	(FEOptions.cpp)
004aa7a0    (27bdfff0:...') addiu   $sp,$sp,-0x10
004aa7a4    (3c02006c:l..<) lui     $v0,0x006c
004aa7a8    (ffbf0000:....) sd      $ra,0($sp)
004aa7ac    (10800005:....) beqz    $a0,0x004aa7c4

004aa7b0    (a0447c9e:.|D.) sb      $a0,0x7c9e($v0)
004aa7b4    (3c023f40:@?.<) lui     $v0,0x3f40
004aa7b8    (44820000:...D) mtc1    $v0,$fpr0
004aa7bc    (10000003:....) j       0x004aa7cc
004aa7c0    (00000000:....) nop

004aa7c4    (3c023f80:.?.<) lui     $v0,0x3f80
004aa7c8    (44820000:...D) mtc1    $v0,$fpr0

004aa7cc    (50800005:...P) beql    $a0,$zero,0x004aa7e4

004aa7d0    (3c023f80:.?.<) lui     $v0,0x3f80
004aa7d4    (3c023f40:@?.<) lui     $v0,0x3f40
004aa7d8    (44821000:...D) mtc1    $v0,$fpr2
004aa7dc    (10000003:....) j       0x004aa7ec
004aa7e0    (3c023f80:.?.<) lui     $v0,0x3f80

004aa7e4    (44821000:...D) mtc1    $v0,$fpr2
004aa7e8    (3c023f80:.?.<) lui     $v0,0x3f80

004aa7ec    (e7809240:@...) swc1    $fpr0,-0x6dc0($gp)
004aa7f0    (44820800:...D) mtc1    $v0,$fpr1
004aa7f4    (00000000:....) nop
004aa7f8    (46000803:...F) div.s   $fpr0,$fpr1,$fpr0
004aa7fc    (e7809248:H...) swc1    $fpr0,-0x6db8($gp)
004aa800    (46020803:...F) div.s   $fpr0,$fpr1,$fpr2
004aa804    (e7809258:X...) swc1    $fpr0,-0x6da8($gp)
004aa808    (c78088e4:....) lwc1    $fpr0,-0x771c($gp)
004aa80c    (e7829250:P...) swc1    $fpr2,-0x6db0($gp)
004aa810    (c78288e8:....) lwc1    $fpr2,-0x7718($gp)
004aa814    (e7809254:T...) swc1    $fpr0,-0x6dac($gp)
004aa818    (c7818114:....) lwc1    $fpr1,-0x7eec($gp)
004aa81c    (c78088ec:....) lwc1    $fpr0,-0x7714($gp)
004aa820    (e7829244:D...) swc1    $fpr2,-0x6dbc($gp)
004aa824    (e781924c:L...) swc1    $fpr1,-0x6db4($gp)
004aa828    (0c050b0c:....) jal     0x00142c30   00142C30 00000088 .text   CHud::LoadHUDData()	(hud.cpp)
004aa82c    (e780925c:\...) swc1    $fpr0,-0x6da4($gp)
004aa830    (0c12cc58:X...) jal     0x004b3160    004B3160 000000B0 .text   FrontEnd::LoadFrontEndData()	(FrontEnd.cpp)
004aa834    (00000000:....) nop
004aa838    (dfbf0000:....) ld      $ra,0($sp)
004aa83c    (03e00008:....) jr      $ra
004aa840    (27bd0010:...') addiu   $sp,$sp,0x10
004aa844    (00000000:....) nop

]]

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

