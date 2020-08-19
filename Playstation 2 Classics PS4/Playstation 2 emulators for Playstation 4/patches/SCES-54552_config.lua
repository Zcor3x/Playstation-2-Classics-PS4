require("ee-gpr-alias")
apiRequest(0.1)	-- request version 0.1 API. Calling apiRequest() is mandatory.

-- Bug#8404 WORKAROUND
-- See https://pss.usrd.scea.com/bugzilla/show_bug.cgi?id=8404
eeInsnReplace( 0x124898, 0x3442ffff, 0x3442fffe) -- 	ori	v0,v0,0xffff
