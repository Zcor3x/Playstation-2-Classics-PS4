apiRequest(0.1)	-- request version 0.1 API. Calling apiRequest() is mandatory.

-- Bug#9147
-- workaround ... -2104(gp) value is something wrong. the value comes from CCamera::Process().
--                unfortunately accurate math or any other flags don't help for this problem,
--				  even though it should be calculation error issue.
--				  for here, it's just given 0 radian for CSprite::RenderBufferedOneXLUSprite_Rotate_Dimension()
--				  actually the cloud is a billboard, so it should have 0 degree in view-space.
--				  so given 0 degree must be OK.... but could cause some corruption (wrong perspective or something)
eeInsnReplace(0x335d74,	0xc792f8c8, 0x44809000) -- 	lwc1	$f18,-1848(gp)
