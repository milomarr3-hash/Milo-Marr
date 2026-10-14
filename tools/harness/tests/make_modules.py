#!/usr/bin/env python3
"""Writes tests/modules/*.lua: small AuraFX modules, each with ONE deliberate defect (or none: good_minimal).

The header lines tell run_tests.py what the harness must report:
  -- EXPECT error: <substring>              an error whose message contains <substring>
  -- EXPECT warning[<code>]: <substring>    a warning of that code whose message contains <substring>
  -- EXPECT clean                           no errors and no warnings
  -- SCENARIOS: a,b                         scenarios to run (default day_idle)
  -- ARGS: --mono                           extra run_aura.py arguments
Re-run this script after editing it; the generated modules are committed so the tests run without it.
"""
import os
import re

SKELETON = '''{header}
-- Test module: {title}
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local End = {{}}
End.pose = {pose}

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
	local parts, cfs = {{ part }}, {{ CFrame.identity }}
{build}
	local fx = {{}}
	function fx.update(dt, s)
		cfs[1] = s.cf * CFrame.new(0, 3 + s.hover, 0)
		workspace:BulkMoveTo(parts, cfs, Enum.BulkMoveMode.FireCFrameChanged)
{update}
	end
	function fx.setVisible(on) folder.Parent = on and ctx.container or nil end
{setDetail}
	function fx.destroy()
		folder:Destroy()
{destroy}
	end
	folder.Parent = ctx.container
	return fx
end

return End
'''
POSE = ('{ hover = 2, bob = 0.2, bobSpeed = 1.2, idle = { Root = { 2, 0, 0 } }, glide = { Root = { -15, 0, 0 } }, '
        'breathe = { Waist = { 1, 0, 0 } }, suppress = { Root = 0.5 } }')
SET_DETAIL = "\tfunction fx.setDetail(isNear) end"

MODULES = {
    "good_minimal": dict(header="-- EXPECT clean\n-- SCENARIOS: day_idle,night_idle,far,reequip,r6_character", title="a correct minimal aura"),
    "bad_unknown_property": dict(header="-- EXPECT error: Transparancy is not a valid member of Part",
                                 title="misspelt property", build="\tpart.Transparancy = 0.5"),
    "bad_enum": dict(header="-- EXPECT error: EnumItem of type Material cannot be assigned to a property of type Enum.PartType",
                     title="enum of the wrong type", build="\tpart.Shape = Enum.Material.Neon"),
    "bad_enum_name": dict(header="-- EXPECT error: Invalid value \"Upward\" for enum NormalId",
                          title="enum name that does not exist",
                          build='\tlocal pe = Instance.new("ParticleEmitter")\n\tpe.EmissionDirection = "Upward"\n\tpe.Parent = part'),
    "bad_numbersequence": dict(header="-- EXPECT error: NumberSequence time must start at 0, and end at 1",
                               title="NumberSequence that stops at 0.8",
                               build='\tlocal pe = Instance.new("ParticleEmitter")\n'
                                     '\tpe.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.8, 0) })\n'
                                     '\tpe.Parent = part'),
    "bad_nil_update": dict(header="-- EXPECT error: attempt to index nil with 'Y'",
                           title="update reads a field that does not exist",
                           update="\t\tlocal groundY = s.groundd.Y -- (typo: s.ground)\n\t\tpart.Size = Vector3.new(1, groundY, 1)"),
    "bad_leaked_connection": dict(header="-- EXPECT warning[leak-connections]: Heartbeat on RunService\n"
                                         "-- EXPECT warning[leak-instances]: TestGlow (Attachment)",
                                  title="a Heartbeat connection and a character attachment that destroy() forgets",
                                  build='\tlocal spin = 0\n\tRunService.Heartbeat:Connect(function(dt) spin += dt end)\n'
                                        '\tlocal glow = Instance.new("Attachment")\n\tglow.Name = "TestGlow"\n\tglow.Parent = ctx.hrp'),
    "bad_gui_writes": dict(header="-- EXPECT warning[gui-writes-per-frame]: ImageLabel.ImageTransparency",
                           title="writes 12 GUI images every frame",
                           build='\tlocal images = {}\n\tfor i = 1, 12 do\n\t\tlocal g = Instance.new("BillboardGui")\n'
                                 '\t\tg.Size = UDim2.new(2, 0, 2, 0)\n\t\tg.Parent = part\n\t\tlocal im = Instance.new("ImageLabel")\n'
                                 '\t\tim.Size = UDim2.fromScale(1, 1)\n\t\tim.BackgroundTransparency = 1\n'
                                 '\t\tim.Image = "rbxassetid://88172507927269"\n\t\tim.Parent = g\n\t\timages[i] = im\n\tend',
                           update="\t\tfor i, im in ipairs(images) do im.ImageTransparency = 0.3 + 0.2 * math.sin(s.t + i) end"),
    "bad_flicker": dict(header="-- EXPECT warning[flicker]: PointLight.Brightness",
                        title="a light that strobes",
                        build='\tlocal light = Instance.new("PointLight")\n\tlight.Parent = part\n\tlocal n = 0',
                        update="\t\tn += 1\n\t\tlight.Brightness = (n // 6) % 2 == 0 and 3 or 0.5"),
    "bad_palette": dict(header="-- EXPECT warning[palette]: (0, 200, 255)\n-- ARGS: --mono",
                        title="a cyan colour on THE END", build="\tpart.Color = Color3.fromRGB(0, 200, 255)"),
    "bad_meshid": dict(header="-- EXPECT error: Unable to assign property MeshId. Script write access is restricted",
                       title="sets MeshPart.MeshId at runtime",
                       build='\tlocal mp = Instance.new("MeshPart")\n\tmp.MeshId = "rbxassetid://105160126126488"\n\tmp.Parent = folder'),
    "bad_wait_for_child": dict(header="-- EXPECT warning[build-yield]: End.build yielded\n"
                                      "-- EXPECT warning[infinite-yield]: Infinite yield possible on 'ReplicatedStorage:WaitForChild(\"TheEndTemplates\")'\n"
                                      "-- EXPECT error: never returned",
                               title="waits for a folder that never exists",
                               build='\tlocal templates = game:GetService("ReplicatedStorage"):WaitForChild("TheEndTemplates")'),
    "bad_readonly": dict(header="-- EXPECT error: Unable to assign property MoveDirection. Property is read only",
                         title="writes a read-only Humanoid property", build="\tctx.hum.MoveDirection = Vector3.zero"),
    "bad_bulkmove": dict(header="-- EXPECT error: must have the same number of elements",
                         title="BulkMoveTo with mismatched lists",
                         build='\tlocal extra = part:Clone()\n\textra.Parent = folder\n\ttable.insert(parts, extra)'),
    "bad_instances_per_frame": dict(header="-- EXPECT warning[instances-per-frame]: new instances created per steady frame",
                                    title="creates a new part every frame",
                                    update='\t\tlocal spark = Instance.new("Part")\n\t\tspark.Anchored = true\n\t\tspark.Parent = folder\n'
                                           '\t\tgame:GetService("Debris"):AddItem(spark, 0.5)'),
    "bad_tween": dict(header="-- EXPECT error: is not a data type that can be tweened",
                      title="tweens a NumberSequence",
                      build='\tlocal a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")\n\ta0.Parent, a1.Parent = part, part\n'
                            '\tlocal beam = Instance.new("Beam")\n\tbeam.Attachment0, beam.Attachment1 = a0, a1\n\tbeam.Parent = part\n'
                            '\tTweenService:Create(beam, TweenInfo.new(1), { Transparency = NumberSequence.new(0) }):Play()'),
    "bad_pose": dict(header="-- EXPECT warning[pose]: End.pose.idle.LeftShouldr is not an R15 Motor6D name\n"
                            "-- EXPECT error: End.pose.idle.Root must be { x, y, z }",
                     title="pose with a typo and a 2-number angle",
                     pose='{ hover = 2, bob = 0.2, bobSpeed = 1.2, idle = { Root = { 2, 0 }, LeftShouldr = { 5, 0, 0 } }, glide = {}, breathe = {}, suppress = {} }'),
    "bad_build_return": dict(header="-- EXPECT error: fx.setDetail is missing", title="fx without setDetail", setDetail=""),
    "bad_lifetime": dict(header="-- EXPECT warning[lifetime-clamp]: Roblox clamps particle lifetime to 0..20 s",
                         title="particles that live 30 s",
                         build='\tlocal pe = Instance.new("ParticleEmitter")\n\tpe.Lifetime = NumberRange.new(25, 30)\n\tpe.Parent = part'),
    "bad_http": dict(header="-- EXPECT error: HTTP requests are OFF",
                     title="tries an HTTP request (pcall'd)",
                     build='\tpcall(function() return game:GetService("HttpService"):GetAsync("https://example.com/tex.png") end)'),
    "bad_csg": dict(header="-- EXPECT error: cannot run on a client at runtime",
                    title="builds a union at runtime",
                    build='\tlocal cut = Instance.new("Part")\n\tlocal ring = part:SubtractAsync({ cut })'),
    "bad_weld_character": dict(header="-- EXPECT warning[weld-anchors-character]: joins anchored part",
                               title="welds an anchored part to the character",
                               build='\tlocal w = Instance.new("WeldConstraint")\n\tw.Part0 = ctx.hrp\n\tw.Part1 = part\n\tw.Parent = part'),
    "bad_asset_id": dict(header="-- EXPECT warning[asset-id]: is not a Roblox asset id format",
                         title="a texture id without rbxassetid://",
                         build='\tlocal pe = Instance.new("ParticleEmitter")\n\tpe.Texture = "105160126126488"\n\tpe.Parent = part'),
    "bad_require_yield": dict(header="-- EXPECT error: yielded while being required",
                              title="waits at module level", pre="task.wait(1)"),
    "bad_infinite_loop": dict(header="-- EXPECT timeout\n-- ARGS: --timeout 4", title="spins forever once faded in",
                              update="\t\tif s.alpha > 0.5 then while true do end end"),
    "bad_type_assign": dict(header="-- EXPECT error: Unable to assign property Color. Color3 expected, got Vector3",
                            title="Vector3 where a Color3 belongs", build="\tpart.Color = Vector3.new(1, 1, 1)"),
}

here = os.path.dirname(os.path.abspath(__file__))
outdir = os.path.join(here, "modules")
os.makedirs(outdir, exist_ok=True)
for name, m in MODULES.items():
    src = SKELETON.format(header=m["header"], title=m["title"], pose=m.get("pose", POSE), build=m.get("build", ""),
                          update=m.get("update", ""), setDetail=m.get("setDetail", SET_DETAIL), destroy=m.get("destroy", ""))
    if m.get("pre"):
        src = src.replace("local End = {}", m["pre"] + "\nlocal End = {}", 1)
    src = re.sub(r"\n\n(\t+end)", r"\n\1", src)
    with open(os.path.join(outdir, name + ".lua"), "w", encoding="utf-8") as f:
        f.write(src)
print("wrote %d modules to %s" % (len(MODULES), outdir))
