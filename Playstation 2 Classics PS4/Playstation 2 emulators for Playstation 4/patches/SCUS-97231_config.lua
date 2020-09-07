require("ee-gpr-alias")
apiRequest(0.1)	-- request version 0.1 API. Calling apiRequest() is mandatory.

eeObj = getEEObject()

-- Bug#8359 (see bugzilla for the detail)
-- Skip FadeSet call if map is 'Scrappe Plateau' and the latest loaded script file is 'evt03B_07_0.moc'.
-- This game seems to have a problem (sensitive) with frame count on the script engine.
-- On our emulator, frame counting is slightly different from the original.
-- therefore it reads out 'overun' script command, which is 'cmd_fade' to fade-in.
-- At here, we will skip FADE-IN command if the situation meets the requirement.
skip_fade_flag = { map_name = false, file_name = false }

-- fade skip Bug#8359. skip FadeSet if skip_fade_flag meets the requirement.
eeObj.AddHook(  0x13c464,	0x8e0500c0, function()
				   -- print(skip_fade_flag.map_name)
				   -- print(skip_fade_flag.file_name)
				   if skip_fade_flag.map_name and skip_fade_flag.file_name then
					  -- print("SKIP FADE")
					  eeObj.SetPc(0x13c470)
					  skip_fade_flag.map_name = false
					  skip_fade_flag.file_name = false
				   end
end)

-- cmd_read_file(const char* filename)
eeObj.AddHook(0x13dad0, 0x27bdffc0, function()
				 local filename = eeObj.ReadMemStr(eeObj.GetGpr(gpr.a0))
				 -- print(string.format("cmd_read_file %s", filename))
				 if "chara/evt_camera/evt03B_07_0.moc" == filename then
					-- print("skip_fade!")
					skip_fade_flag.file_name = true
				 else
					skip_fade_flag.file_name = false
				 end
end)

-- cmd_map_name(const char* mapname)
eeObj.AddHook(0x13f138,	0x0080282d, function()
				 local mapname = eeObj.ReadMemStr(eeObj.GetGpr(gpr.a0))
				 -- print(string.format("cmd_map_name %s", mapname))
				 if "Scrappe Plateau" == mapname then
					-- print("skip_fade!")
					skip_fade_flag.map_name = true
				 else
					skip_fade_flag.map_name = false
				 end
end)
