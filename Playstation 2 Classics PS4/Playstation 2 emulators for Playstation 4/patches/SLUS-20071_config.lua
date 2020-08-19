apiRequest(0.1)

-- Fix sound driver module

eeInsnReplace(0x002b06ec,24060001,24060000) --change TLSNDDRV RPC to blocking
eeInsnReplace(0x2B06EC, 0x24060001, 0x24060000)
eeInsnReplace(0x2b0868, 0x10400014, 0x10000014)
iopInsnReplace(0x001D77E4,2404002B,27C40010) --TLSNDDRV fix
iopInsnReplace(001D77E8,0C0032B3,0C0032B7) --TLSNDDRV fix
iopInsnReplace(001D77EC,27C50010,00000000) --TLSNDDRV fix

