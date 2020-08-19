apiRequest(0.1)

-- Possible fix for black screen (skip video)

eeInsnReplace(0x1CF3CC, 0x4100ffff, 0x00000000)	-- nop, mftgpr  $ra, $zero
