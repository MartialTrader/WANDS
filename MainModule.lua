local rstore = game:GetService("ReplicatedStorage")
local sstore = game:GetService("ServerStorage")
local debris = game:GetService("Debris")
local events = rstore:WaitForChild("Events")
local clientAssets = rstore:WaitForChild("clientAssets")
local serverAssets = sstore:WaitForChild("serverAssets")
local serverEffects = serverAssets:WaitForChild("Effects")
local spells = clientAssets:WaitForChild("SpellData")
local spellEffects = serverAssets:WaitForChild("SpellEffects")
local spellFolder = game.Workspace:WaitForChild("SpellConfiguration")
local activeSpells = spellFolder:WaitForChild("ActiveSpells")
local afterEffects = spellFolder:WaitForChild("Burns")

sounds = {635561297, 545192890, 635560990, 192616186, 211364696, 216866742, 378522452, 551063503} 
animation = {6169566080}
admins = {"Martial_Trader"}

Debug = false

function checkForCharacter(hit,mode)
	for i,p in pairs(game.Workspace:GetChildren())do
		if game.Players:FindFirstChild(p.Name) or p.Name == "WandTestDummy" or p.Name == "Dummy" then
			for i,v in pairs(p:GetDescendants()) do
				if v == hit then
					if mode == "GiveChar" then
						return p
					elseif mode == "tellIfChar" then
						return "is apart of a character"
					end

				end
			end
		end
	end
	if mode == "GiveChar" then
		return nil
	elseif mode == "tellIfChar" then
		return "not apart of a character"
	end

end

function getHitSurfaceCFrame(hitp,hit)
	local surfaceCF = {
		{"Back",hit.CFrame * CFrame.new(0,0,hit.Size.z)};
		{"Bottom",hit.CFrame * CFrame.new(0,-hit.Size.y,0)};
		{"Front",hit.CFrame * CFrame.new(0,0,-hit.Size.z)};
		{"Left",hit.CFrame * CFrame.new(-hit.Size.x,0,0)};
		{"Right",hit.CFrame * CFrame.new(hit.Size.x,0,0)};
		{"Top",hit.CFrame * CFrame.new(0,hit.Size.y,0)}
	}
	local closestDist = math.huge
	local closestSurface = nil
	for _,v in pairs(surfaceCF) do
		local surfaceDist = (hitp - v[2].p).magnitude
		if surfaceDist < closestDist then
			closestDist = surfaceDist
			closestSurface = v
		end
	end
	return closestSurface[2]
end

function selfInflict (caster,spellName)
	local spellEffect = spellEffects[spellName]:Clone()
	spellEffect.Parent = caster
	spellEffect.Disabled = false
end

function apparate (caster,arguments)
	caster.Character:MoveTo(caster.Character:WaitForChild("mouseTarget").Value)
end

local module = {}
module.Functions = {}

module.Functions.deflectSpell = function (plr,deflecting,arguments)
	local hitp = arguments.hitp
	local spellName = arguments.spellName
	local caster = plr
	local hrp = caster.Character:WaitForChild("HumanoidRootPart")
	module.Functions.CastSpell(deflecting,{spellName = spellName,a = hitp,b = hrp.Position,tool = arguments.tool})
end
module.Functions.onHitHandling = function (caster,arguments)
	local spell = spells[arguments.spellName]
	local color = spell.Value
	local hit = arguments.hit
	local hitp = arguments.hitp
	local normal = arguments.normal
	local surfaceCF = getHitSurfaceCFrame(hitp, hit)
	local surfaceDir = CFrame.new(hit.CFrame.p, surfaceCF.p)
	local surfaceDist = surfaceDir.lookVector * (hit.CFrame.p - surfaceCF.p).magnitude / 2
	local surfaceOffset = hitp - surfaceCF.p + surfaceDist
	local surfaceCFrame = surfaceDir + surfaceDist + surfaceOffset
	if checkForCharacter(hit,"tellIfChar") == "is apart of a character" then
		local chr = checkForCharacter(hit,"GiveChar")
		if chr:FindFirstChild("Protego") ~= true and chr:FindFirstChild("Protection") ~= true then
			local a = spellEffects[spell.Name]:Clone()
			a.Name = spell.Name
			local b = Instance.new("ObjectValue",a)
			b.Name = "HitBy"
			b.Value = caster
			a.Parent = chr
			a.Disabled = false
		else
			if chr:FindFirstChild("Protego") then
				print("Protego")
			end
			if chr:FindFirstChild("Protection") then
				print("User is protected")
			end
		end
	elseif checkForCharacter(hit,"tellIfChar") == "not apart of a character" then
		if (hit.Name == "Reflect") then
			module.Functions.deflectSpell(caster,"isDeflecting",{hitp = surfaceCFrame.Position,spellName = arguments.spellName,tool = arguments.tool})
		elseif (hit.Name == "Protego") then
			hit:Destroy()
		else
			coroutine.wrap(function()
				if caster.Character.CastedSpell.Value == Color3.fromRGB(255, 170, 0) then
					local d = serverEffects.Hit:Clone()
					debris:AddItem(d,10)
					d.Parent = afterEffects
					d.CFrame = surfaceCFrame
					local e = Instance.new("Explosion", d)
					e.BlastPressure = 0
					e.Position = d.Position
				elseif caster.Character.CastedSpell.Value == Color3.fromRGB(85, 255, 127) then
					local e = serverEffects.Flower:Clone()
					debris:AddItem(e, 10)
					e.Parent = afterEffects
					e.CFrame = surfaceCFrame
				else
					local p = serverEffects.Hit:Clone()
					debris:AddItem(p,10)
					p.Parent = afterEffects
					p.CFrame = surfaceCFrame
					p.Middle.glow.Color = color
					p.Middle.spark.Color = ColorSequence.new(color)
					p.Middle.spark:Emit(70)
					wait(.1)
					p.Middle.spark:Emit(0)		
					wait(1)	
					p.Middle.glow.Enabled = false
				end
			end) ();
		end
	end
end
module.Functions.CastSpell = function (deflecting,arguments)
	local spellName = arguments.spellName
	local spell = spells[spellName]
	local speed = 700
	local range = 700
	local color = spell.Value
	local zigzag = 500
	local spellType = spell.spellType.Value
	local wand = arguments.tool
	local casterChr = wand.Parent
	local caster = game.Players:GetPlayerFromCharacter(casterChr)
	
	if casterChr.Humanoid:GetState() == Enum.HumanoidStateType.PlatformStanding then return end
	if casterChr.IsClashing.Value == true then return end
	if casterChr.HumanoidRootPart.Anchored == true then return end
	if casterChr.HumanoidRootPart:FindFirstChild("ABBAE") then return end
	if casterChr.Humanoid.WalkSpeed > 16 then return end
	if casterChr.Humanoid.WalkSpeed < 16 then return end
	if casterChr:FindFirstChild("Rock") then return end
	if casterChr:FindFirstChild("Ice") then return end
	
	local d = Instance.new("Animation")
	d.AnimationId = "http://www.roblox.com/Asset?ID=6169566080"
	local e = casterChr:FindFirstChild("Humanoid"):LoadAnimation(d)
	e:Play()

	local hrp = casterChr:WaitForChild("HumanoidRootPart")
	local spellsounds = {"rbxassetid://211364758","rbxassetid://216866651"}
	local Sound = spellsounds[math.random(1, #spellsounds)]
	local soundobj = Instance.new("Sound", hrp)
	soundobj.SoundId = Sound
	soundobj.Looped = false
	soundobj:Play()

	if spell == "PROTEGO" then
		print("nop")
	else
		debris:AddItem(soundobj, 5.5)
	end
	
	local plrSpellEffects = game.Workspace.SpellConfiguration.Players[caster.Name]
	
	if spellType == "selfInflict" then
		selfInflict(casterChr,spellName)
	elseif spellType == "teleport" then
		apparate(caster)
	else
		if arguments.castingMode == "onClient" then
			events.onSpellCast:FireAllClients("isNotDeflecting",arguments)
		else
			local start = arguments.a
			local ending = arguments.b
			local cf = CFrame.new(start,ending)
			if spellType == "followMouse" then
				cf = CFrame.new(start,casterChr:WaitForChild("mouseTarget").Value)
			end
			local projectile = serverEffects.Projectile:Clone()
			local owner = Instance.new("StringValue", projectile)
			owner.Name = "OwnerValue"
			owner.Value = caster.Name
			projectile.CFrame = cf
			projectile.Name = spellName
			projectile.Color = color
			projectile.Middle.Trails.Outter.Color = ColorSequence.new(color)
			projectile.light.Color = color
			casterChr.CastedSpell.Value = color
			local start = arguments.a
			local ending = arguments.b
			projectile.Parent = activeSpells
			local dir = (ending - start).unit
			local origin = cf.Position
			local ignore = {casterChr,activeSpells}
			if deflecting == "isDeflecting" then
				ignore = {activeSpells}
			end
			local nothit = true
			while nothit == true do
				wait(1/1000)
				game:GetService("RunService").Heartbeat:Wait()
				local ray = Ray.new(origin,dir*speed/50)
				local hit,hitp,normal = game.Workspace:FindPartOnRayWithIgnoreList(ray,ignore)
				projectile.Position = hitp + Vector3.new(math.random()*zigzag/500,math.random()*zigzag/500,0)
				origin = hitp
				if nothit ~= true then
					break
				end
				if (cf.Position - projectile.Position).magnitude >= range then
					projectile.Anchored = true
					debris:AddItem(projectile,.1)
					break
				end
				if hit then
					local args = {
						hit = hit,
						hitp = hitp,
						normal = normal,
						spellName = spellName,
						tool = wand
					}
					nothit = false
					module.Functions.onHitHandling(caster,args)
					break
				end
			end
			debris:AddItem(projectile,.1)
		end
	end
end
return module
