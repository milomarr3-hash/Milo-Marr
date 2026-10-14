-- EXPECT warning[gui-writes-per-frame]: ImageLabel.ImageTransparency
-- Test module: writes 12 GUI images every frame
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
	local images = {}
	for i = 1, 12 do
		local g = Instance.new("BillboardGui")
		g.Size = UDim2.new(2, 0, 2, 0)
		g.Parent = part
		local im = Instance.new("ImageLabel")
		im.Size = UDim2.fromScale(1, 1)
		im.BackgroundTransparency = 1
		im.Image = "rbxassetid://88172507927269"
		im.Parent = g
		images[i] = im
	end
	local fx = {}
	function fx.update(dt, s)
		cfs[1] = s.cf * CFrame.new(0, 3 + s.hover, 0)
		workspace:BulkMoveTo(parts, cfs, Enum.BulkMoveMode.FireCFrameChanged)
		for i, im in ipairs(images) do im.ImageTransparency = 0.3 + 0.2 * math.sin(s.t + i) end
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
