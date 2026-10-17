-- EXPECT warning[flicker]: PointLight.Brightness
-- Test module: a light that strobes
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local End = {}
End.pose = { hover = 2, bob = 0.2, bobSpeed = 1.2, idle = { Root = { 2, 0, 0 } }, glide = { Root = { -15, 0, 0 } }, breathe = { Waist = { 1, 0, 0 } }, suppress = { Root = 0.5 } }

function End.build(ctx)
	local folder = Instance.new("Folder")
	folder.Name = "Test_" .. ctx.char.Name
	local part = Instance.new("Part")
	part.Name = "Core"
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Size = Vector3.new(1, 1, 1)
	part.Color = Color3.fromRGB(230, 232, 240)
	part.Transparency = 0.2
	part.Parent = folder
	local parts, cfs = { part }, { CFrame.identity }
	local light = Instance.new("PointLight")
	light.Parent = part
	local n = 0
	local fx = {}
	function fx.update(dt, s)
		cfs[1] = s.cf * CFrame.new(0, 3 + s.hover, 0)
		workspace:BulkMoveTo(parts, cfs, Enum.BulkMoveMode.FireCFrameChanged)
		n += 1
		light.Brightness = (n // 6) % 2 == 0 and 3 or 0.5
	end
	function fx.setVisible(on) folder.Parent = on and ctx.container or nil end
	function fx.setDetail(isNear) end
	function fx.destroy()
		folder:Destroy()
	end
	folder.Parent = ctx.container
	return fx
end

return End
