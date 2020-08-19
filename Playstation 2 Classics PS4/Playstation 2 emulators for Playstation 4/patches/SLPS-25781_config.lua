
apiRequest(1.4)

eeNativeFunction(0x11fa9c, 0x0080402d, 'memcpy')
eeNativeFunction(0x11fb48, 0x2cc20008, 'memset')

eeInsnReplace(0x1279d0, 0x27bdffc0, 0x03e00008)                 -- <SyncDCache>
eeInsnReplace(0x1279d4, 0xffb20020, 0x00000000)
eeNativeHook (0x1279d0, 0x03e00008,'AdvanceClock',0xa00)
eeInsnReplace(0x127b00, 0x27bdffc0, 0x03e00008)                 -- <InvalidDCache>
eeInsnReplace(0x127b04, 0xffb20020, 0x00000000)
eeNativeHook (0x127b00, 0x03e00008,'AdvanceClock',0xa00)
eeInsnReplace(0x12a258, 0x3c19ffff, 0x03e00008)                 -- <sceSifWriteBackDCache>
eeInsnReplace(0x12a25c, 0x3739ffc0, 0x00000000)
eeNativeHook (0x12a258, 0x03e00008,'AdvanceClock',0x1700)

require("ee-gpr-alias")

local eeObj = getEEObject()
local emuObj = getEmuObject()

-- *** viBufBeginPut (1)
--eeInsnReplace(0x105628, 0x0c049c78, 0) -- 	jal	1271e0 <WaitSema>
eeInsnReplace(0x1056c8, 0x0c049c70, 0) -- 	jal	1271c0 <SignalSema>
-- *** viBufEndPut (1)
eeInsnReplace(0x105708, 0x0c049c78, 0) -- 	jal	1271e0 <WaitSema>
--eeInsnReplace(0x105730, 0x0c049c70, 0) -- 	jal	1271c0 <SignalSema>
-- *** viBufFlush (1)
--eeInsnReplace(0x105a88, 0x0c049c78, 0) -- 	jal	1271e0 <WaitSema>
--eeInsnReplace(0x105ab8, 0x0c049c70, 0) -- 	jal	1271c0 <SignalSema>
-- *** viBufPutTs (1)
eeInsnReplace(0x105c10, 0x0c049c78, 0) -- 	jal	1271e0 <WaitSema>
eeInsnReplace(0x105cf4, 0x0c049c70, 0) -- 	jal	1271c0 <SignalSema>

-- it's redundant calling of _waitIpuIdle in libmpeg... not so huge impact tho.
eeInsnReplace(0x118620,	0x0c04672a, 0) -- 	jal	119ca8 <_waitIpuIdle>

-- bug# 9972
local emuObj = getEmuObject()
emuObj.SetGsTitleFix( "ignoreSubBuffCov", "reserved", { } )
