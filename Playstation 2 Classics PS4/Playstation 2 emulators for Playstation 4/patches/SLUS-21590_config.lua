-- Red Faction [US]

apiRequest(1.6)

-- title uses memcpy() to write to VU1 memory, so some instances will be hotfixed to
-- use slowpath_memcpy() at runtime.

eeNativeFunction(0x259820, 0x0080402d, 'memcpy')
eeNativeFunction(0x2599d8, 0x2cc20008, 'memset')

eeNativeFunction(0x253870, 0x27bdffd0, 'ieee754_acosf')
eeNativeFunction(0x254620, 0x44026000, 'ieee754_sqrtf')
eeNativeFunction(0x255a50, 0x44026000, 'cosf')
eeNativeFunction(0x255df0, 0x44026000, 'sinf')
eeNativeFunction(0x256318, 0x27bdffa0, 'acosf')

eeInsnReplace(0x24d7e0, 0x24030064, 0x03e00008)                 -- <FlushCache>
eeInsnReplace(0x24d7e4, 0x0000000c, 0x00000000)
eeNativeHook (0x24d7e0, 0x03e00008,'AdvanceClock',0xa00)
eeInsnReplace(0x24d810, 0x2403ff98, 0x03e00008)                 -- <iFlushCache>
eeInsnReplace(0x24d814, 0x0000000c, 0x00000000)
eeNativeHook (0x24d810, 0x03e00008,'AdvanceClock',0xa00)

eeInsnReplace(0x24de20, 0x27bdffe0, 0x03e00008)                 -- <SyncDCache>
eeInsnReplace(0x24de24, 0x0080302d, 0x00000000)
eeNativeHook (0x24de20, 0x03e00008,'AdvanceClock',0x600)
eeInsnReplace(0x24de98, 0x3c02ffff, 0x03e00008)                 -- <iSyncDCache>
eeInsnReplace(0x24de9c, 0x3442ffc0, 0x00000000)
eeNativeHook (0x24de98, 0x03e00008,'AdvanceClock',0x600)
eeInsnReplace(0x24df58, 0x27bdffe0, 0x03e00008)                 -- <InvalidDCache>
eeInsnReplace(0x24df5c, 0x0080302d, 0x00000000)
eeNativeHook (0x24df58, 0x03e00008,'AdvanceClock',0x600)
eeInsnReplace(0x24dfd0, 0x3c02ffff, 0x03e00008)                 -- <iInvalidDCache>
eeInsnReplace(0x24dfd4, 0x3442ffc0, 0x00000000)
eeNativeHook (0x24dfd0, 0x03e00008,'AdvanceClock',0x600)