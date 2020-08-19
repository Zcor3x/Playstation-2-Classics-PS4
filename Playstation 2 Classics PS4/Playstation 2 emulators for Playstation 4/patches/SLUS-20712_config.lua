apiRequest(0.1)

-- Possible fix for SLUS-20712

eeInsnReplace(0x3D0290, 0x27BDFFC0, 0x03E00008)
eeInsnReplace(0x3D0294, 0x3C03004C, 0x00000000)

-- Cli can require additional --fpu-accurate-muldiv-range=0x3046E0,0x305E44 or --fpu-accurate-addsub-range=0x3046E0,0x305E44