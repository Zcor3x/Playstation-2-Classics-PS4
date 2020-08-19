local gpr = require("ee-gpr-alias")
require( "ee-hwaddr" )
apiRequest(1.4)

local eeObj = getEEObject()

-- function dump(addr)
--    print(string.format("=== dump %x ===", addr))
--    for i=0,0x1e do
-- 	  print(string.format("   %08x : %08x %08x %08x %08x",
-- 						  addr + i*16,
-- 						  eeObj.ReadMem32(addr + i*16 + 0),
-- 						  eeObj.ReadMem32(addr + i*16 + 4),
-- 						  eeObj.ReadMem32(addr + i*16 + 8),
-- 						  eeObj.ReadMem32(addr + i*16 +12)))
--    end
-- end

-- Bug#8285
-- This patch changes the color of background on :
--		- Language selection
--		- Company logo
--		- Start screen
--		- Some menu
-- which are in menu.bin overlay. Nothing affected in the actual game.
eeObj.DmaAddHook( 1, function()
					 if eeObj.ReadMem32(vif1_hw.TADR) == 0x1fd1c0 then
						-- On language select
						if eeObj.ReadMem32(0x4c8ef0) == 0x00ff9090 then
						   eeObj.WriteMem32(0x4c8ef0, 0)
						end
						if eeObj.ReadMem32(0x548f30) == 0x00ff9090 then
						   eeObj.WriteMem32(0x548f30, 0)
						end
						-- On company logo
						if eeObj.ReadMem32(0x4c6d70) == 0x00ff9090 then
						   eeObj.WriteMem32(0x4c6d70, 0)
						end
						if eeObj.ReadMem32(0x546db0) == 0x00ff9090 then
						   eeObj.WriteMem32(0x546db0, 0)
						end
					 end
end)


eeInsnReplace(0x103d58, 0x27bdffc0, 0x03e00008)                 -- <SyncDCache>
eeInsnReplace(0x103d5c, 0xffb20020, 0x00000000)
eeNativeHook (0x103d58, 0x03e00008,'AdvanceClock',0x600)
eeInsnReplace(0x103dd8, 0x3c02ffff, 0x03e00008)                 -- <iSyncDCache>
eeInsnReplace(0x103ddc, 0x3442ffc0, 0x00000000)
eeNativeHook (0x103dd8, 0x03e00008,'AdvanceClock',0x600)
eeInsnReplace(0x103e98, 0x27bdffc0, 0x03e00008)                 -- <InvalidDCache>
eeInsnReplace(0x103e9c, 0xffb20020, 0x00000000)
eeNativeHook (0x103e98, 0x03e00008,'AdvanceClock',0x600)
eeInsnReplace(0x103f18, 0x3c02ffff, 0x03e00008)                 -- <iInvalidDCache>
eeInsnReplace(0x103f1c, 0x3442ffc0, 0x00000000)
eeNativeHook (0x103f18, 0x03e00008,'AdvanceClock',0x600)
eeInsnReplace(0x106970, 0x3c19ffff, 0x03e00008)                 -- <sceSifWriteBackDCache>
eeInsnReplace(0x106974, 0x3739ffc0, 0x00000000)
eeNativeHook (0x106970, 0x03e00008,'AdvanceClock',0x1700)

