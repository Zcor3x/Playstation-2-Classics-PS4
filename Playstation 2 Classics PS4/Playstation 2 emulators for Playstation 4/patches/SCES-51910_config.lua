require("ee-gpr-alias")
apiRequest(0.1)	-- request version 0.1 API. Calling apiRequest() is mandatory.

eeObj = getEEObject()

-- EU ver patch for Bug#8359 (SCUS-97231)
skip_fade_flag = { map_name = false, file_name = false }
eeObj.AddHook( 0x13c4e4, 0x8e0500c0, function()
				   -- print(skip_fade_flag.map_name)
				   -- print(skip_fade_flag.file_name)
				   if skip_fade_flag.map_name and skip_fade_flag.file_name then
					  -- print("SKIP FADE")
					  eeObj.SetPc(0x13c4f0)
					  skip_fade_flag.map_name = false
					  skip_fade_flag.file_name = false
				   end
end)
eeObj.AddHook( 0x13db70, 0x27bdffc0, function()
				 local filename = eeObj.ReadMemStr(eeObj.GetGpr(gpr.a0))
				 -- print(string.format("cmd_read_file %s", filename))
				 if "chara/evt_camera/evt03B_07_0.moc" == filename then
					-- print("skip_fade!")
					skip_fade_flag.file_name = true
				 else
					skip_fade_flag.file_name = false
				 end
end)

eeObj.AddHook( 0x13f290, 0x2c8200ff, function()
				 addr = eeObj.GetGpr(gpr.a0)
				 if addr > 255 then 
					local mapname = eeObj.ReadMemStr(addr)
					print(string.format("cmd_map_name %s", mapname))
					if "Scrappe Plateau" == mapname then
					   -- print("skip_fade!")
					   skip_fade_flag.map_name = true
					else
					   skip_fade_flag.map_name = false
					end
				 end
end)
