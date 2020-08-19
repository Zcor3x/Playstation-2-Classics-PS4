apiRequest(0.4)

-- Fix black screen SLUS-20064

eeInsnReplace(0x1CF3CC, 0x4100ffff, 0x00000000)	-- nop, mftgpr  $ra, $zero


