-- The King of Fighters 2000

apiRequest(1.1)


local emuObj 	= getEmuObject()
--will fix sprite rendering artifact
ndx = 28
val = 0x86
-- spriteCorrectionTab[ndx] = val
emuObj.SetGsTitleFix( "globalSet",  "reserved", { fixSpriteDivTab = val | ( ndx<<16) })

