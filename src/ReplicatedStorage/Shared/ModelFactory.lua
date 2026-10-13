-- ReplicatedStorage/Shared/ModelFactory.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local PlotAndPrestigeConfig = require(script.Parent.Config.PlotAndPrestigeConfig)
local MachineConfig = require(script.Parent.Config.MachineConfig)
local ResourceConfig = require(script.Parent.Config.ResourceConfig)

local ModelFactory = {}

local DARK_METAL = Color3.fromRGB(32, 36, 44)
local MID_METAL = Color3.fromRGB(68, 74, 88)
local LIGHT_STEEL = Color3.fromRGB(165, 172, 185)

local function addPart(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, mat: Enum.Material, shape: Enum.PartType?): Part
	local p = Instance.new("Part")
	p.Name = name
	if shape then p.Shape = shape end
	p.Size = size
	p.CFrame = cf
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = true
	p.Color = color
	p.Material = mat
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function applyCustomMaterials(instance: Instance, cfg: any)
	local mainColor = (cfg and cfg.Color) or Color3.fromRGB(200, 200, 200)
	local mainMat = (cfg and cfg.Material) or Enum.Material.Metal

	for _, part in ipairs(instance:GetDescendants()) do
		if part:IsA("BasePart") then
			local n = string.lower(part.Name)
			if string.find(n, "dark") or string.find(n, "rock") then
				part.Color = DARK_METAL
				part.Material = Enum.Material.Metal
			elseif string.find(n, "neon") or string.find(n, "glow") then
				part.Color = mainColor
				part.Material = Enum.Material.Neon
			elseif string.find(n, "silver") or string.find(n, "drill") or string.find(n, "rotor") or string.find(n, "vein") then
				part.Color = LIGHT_STEEL
				part.Material = Enum.Material.Metal
			elseif string.find(n, "piston") then
				part.Color = Color3.fromRGB(245, 195, 35)
				part.Material = Enum.Material.Metal
			else
				part.Color = mainColor
				part.Material = mainMat
			end
		end
	end
end

local function prepareCustomModel(template: Instance, targetWidth: number, isPreview: boolean?, cfg: any?, isResource: boolean?): Model
	local wrapper = Instance.new("Model")
	wrapper.Name = template.Name

	local baseHeight = isResource and 0.1 or 0.3
	local base = Instance.new("Part")
	base.Name = "PrimaryPart"
	base.Size = Vector3.new(targetWidth - 0.2, baseHeight, targetWidth - 0.2)
	base.CFrame = CFrame.new(0, baseHeight / 2, 0)
	base.Anchored = true
	base.CanCollide = not isPreview
	base.CanQuery = not isResource
	base.Transparency = isResource and 1 or 0
	base.Color = DARK_METAL
	base.Material = Enum.Material.Metal
	base.TopSurface = Enum.SurfaceType.Smooth
	base.BottomSurface = Enum.SurfaceType.Smooth
	base.Parent = wrapper
	wrapper.PrimaryPart = base

	local clone = template:Clone()
	local parts = {}

	if clone:IsA("BasePart") then table.insert(parts, clone) end
	for _, desc in ipairs(clone:GetDescendants()) do
		if desc:IsA("LuaSourceContainer") or desc:IsA("WeldConstraint") or desc:IsA("JointInstance") then
			desc:Destroy()
		elseif desc:IsA("BasePart") then
			table.insert(parts, desc)
		end
	end

	if cfg then
		if clone:IsA("BasePart") then
			clone.Color = cfg.Color or Color3.fromRGB(200, 200, 200)
			clone.Material = cfg.Material or Enum.Material.Metal
		end
		applyCustomMaterials(clone, cfg)
	end

	if #parts > 0 then
		local minX, minY, minZ = math.huge, math.huge, math.huge
		local maxX, maxY, maxZ = -math.huge, -math.huge, -math.huge
		for _, part in ipairs(parts) do
			local cf = part.CFrame
			local s = part.Size / 2
			for _, sx in ipairs({ -s.X, s.X }) do
				for _, sy in ipairs({ -s.Y, s.Y }) do
					for _, sz in ipairs({ -s.Z, s.Z }) do
						local corner = cf * Vector3.new(sx, sy, sz)
						minX = math.min(minX, corner.X)
						minY = math.min(minY, corner.Y)
						minZ = math.min(minZ, corner.Z)
						maxX = math.max(maxX, corner.X)
						maxY = math.max(maxY, corner.Y)
						maxZ = math.max(maxZ, corner.Z)
					end
				end
			end
		end

		local centerX = (minX + maxX) / 2
		local centerZ = (minZ + maxZ) / 2
		local bottomY = minY
		local maxHoriz = math.max(maxX - minX, maxZ - minZ, 0.001)
		local scaleFactor = (isResource and targetWidth or (targetWidth - 0.6)) / maxHoriz
		local topY = isResource and 0 or baseHeight

		for _, part in ipairs(parts) do
			part.Anchored = true
			part.CanCollide = not isPreview
			part.CanQuery = not isResource
			local relX = (part.Position.X - centerX) * scaleFactor
			local relY = (part.Position.Y - bottomY) * scaleFactor
			local relZ = (part.Position.Z - centerZ) * scaleFactor
			part.Size = part.Size * scaleFactor
			part.CFrame = CFrame.new(relX, topY + relY, relZ) * part.CFrame.Rotation
			part.Parent = wrapper
		end
	end

	if clone ~= wrapper and not table.find(parts, clone) then clone:Destroy() end
	return wrapper
end

function ModelFactory.CreateResourceModel(resourceId: string): Model
	local info = ResourceConfig.Items[resourceId] or ResourceConfig.Items.IronOre
	local customFolder = ReplicatedStorage:FindFirstChild("CustomAssets")
	local customRes = (customFolder and customFolder:FindFirstChild("Resources") and customFolder.Resources:FindFirstChild(resourceId))
		or Workspace:FindFirstChild(resourceId)

	if customRes then return prepareCustomModel(customRes, 1.4, true, info, true) end

	local model = Instance.new("Model")
	model.Name = "Res_" .. resourceId

	local root = Instance.new("Part")
	root.Name = "PrimaryPart"
	root.Anchored = true
	root.CanCollide = false
	root.CanQuery = false
	root.Color = info.Color
	root.Material = info.Material or Enum.Material.SmoothPlastic
	root.Parent = model
	model.PrimaryPart = root
	local rc = root.CFrame

	if info.Shape == "Ore" then
		root.Size = Vector3.new(1.15, 0.9, 1.15)
		root.Color = Color3.fromRGB(95, 90, 85)
		root.Material = Enum.Material.Rock
		addPart(model, "Vein1", Vector3.new(0.75, 0.75, 0.75), rc * CFrame.new(0.22, 0.2, 0.18) * CFrame.Angles(0.5, 0.4, 0.2), info.Color, Enum.Material.Metal).CanQuery = false
		addPart(model, "Vein2", Vector3.new(0.65, 0.7, 0.65), rc * CFrame.new(-0.25, 0.15, -0.2) * CFrame.Angles(-0.4, 0.7, 0.3), info.Color, Enum.Material.Neon).CanQuery = false
	elseif info.Shape == "Ingot" then
		root.Size = Vector3.new(0.95, 0.4, 1.5)
		addPart(model, "Bevel", Vector3.new(0.75, 0.2, 1.3), rc * CFrame.new(0, 0.25, 0), info.Color, root.Material).CanQuery = false
	elseif info.Shape == "Block" then
		root.Size = Vector3.new(1.35, 1.35, 1.35)
		addPart(model, "FrameH", Vector3.new(1.42, 0.28, 1.42), rc, DARK_METAL, Enum.Material.Metal).CanQuery = false
		addPart(model, "CoreDot", Vector3.new(0.6, 1.4, 0.6), rc, info.Color, Enum.Material.Neon).CanQuery = false
	elseif info.Shape == "Gem" then
		root.Size = Vector3.new(0.95, 1.25, 0.95)
		root.Transparency = 0.15
		addPart(model, "Crystal1", Vector3.new(0.95, 0.95, 0.95), rc * CFrame.Angles(math.rad(45), math.rad(45), 0), info.Color, Enum.Material.Neon).CanQuery = false
	else
		root.Shape = Enum.PartType.Cylinder
		root.Size = Vector3.new(1.4, 0.95, 0.95)
	end

	return model
end

function ModelFactory.CreateMachineModel(machineType: string, isPreview: boolean?): Model
	local cfg = MachineConfig.Get(machineType) or MachineConfig.Get("IronExtractor")
	local cellSize = PlotAndPrestigeConfig.CellSize
	local isBelt = cfg.IsBelt == true

	local customFolder = ReplicatedStorage:FindFirstChild("CustomAssets")
	local customTemplate = (customFolder and customFolder:FindFirstChild("Machines") and customFolder.Machines:FindFirstChild(machineType))
		or Workspace:FindFirstChild(machineType)

	local model: Model
	local base: Part
	local baseHeight = 0.3

	if customTemplate then
		model = prepareCustomModel(customTemplate, cellSize, isPreview, cfg, false)
		base = model.PrimaryPart :: Part
	else
		model = Instance.new("Model")
		model.Name = machineType

		base = Instance.new("Part")
		base.Name = "PrimaryPart"
		base.Size = Vector3.new(cellSize - 0.3, baseHeight, cellSize - 0.3)
		base.CFrame = CFrame.new(0, baseHeight / 2, 0)
		base.Anchored = true
		base.CanCollide = not isPreview
		base.CanQuery = true
		base.Color = DARK_METAL
		base.Material = Enum.Material.Metal
		base.Parent = model
		model.PrimaryPart = base

		local bc = base.CFrame
		if isBelt then
			addPart(model, "BeltSurface", Vector3.new(4.2, 0.15, cellSize - 0.3), bc * CFrame.new(0, 0.2, 0), Color3.fromRGB(24, 26, 30), Enum.Material.Slate)
			addPart(model, "RailL", Vector3.new(0.45, 0.45, cellSize - 0.3), bc * CFrame.new(-2.35, 0.3, 0), cfg.Color, Enum.Material.Metal)
			addPart(model, "RailR", Vector3.new(0.45, 0.45, cellSize - 0.3), bc * CFrame.new(2.35, 0.3, 0), cfg.Color, Enum.Material.Metal)
			for z = -2.0, 2.0, 1.0 do
				addPart(model, "Roller", Vector3.new(0.25, 4.1, 0.25), bc * CFrame.new(0, 0.22, z) * CFrame.Angles(0, 0, math.rad(90)), MID_METAL, Enum.Material.Metal, Enum.PartType.Cylinder)
			end
		elseif machineType == "DeliveryCenter" then
			addPart(model, "HazardRim", Vector3.new(5.2, 0.35, 5.2), bc * CFrame.new(0, 0.25, 0), Color3.fromRGB(240, 180, 25), Enum.Material.DiamondPlate)
			addPart(model, "TeleporterPad", Vector3.new(0.5, 3.6, 3.6), bc * CFrame.new(0, 0.35, 0) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(45, 240, 115), Enum.Material.Neon, Enum.PartType.Cylinder)
		elseif machineType == "Storage" then
			addPart(model, "SiloCylinder", Vector3.new(4.0, 3.8, 3.8), bc * CFrame.new(0, 2.2, 0) * CFrame.Angles(0, 0, math.rad(90)), cfg.Color, Enum.Material.Metal, Enum.PartType.Cylinder)
		elseif cfg.Category == "Energy" then
			addPart(model, "ReactorPedestal", Vector3.new(4.4, 1.2, 4.4), bc * CFrame.new(0, 0.7, 0), MID_METAL, Enum.Material.Metal)
			addPart(model, "PlasmaSphere", Vector3.new(2.6, 2.6, 2.6), bc * CFrame.new(0, 2.8, 0), cfg.Color, Enum.Material.Neon, Enum.PartType.Ball)
			addPart(model, "RotorSpinner", Vector3.new(0.45, 3.6, 3.6), bc * CFrame.new(0, 2.8, 0), LIGHT_STEEL, Enum.Material.Metal, Enum.PartType.Cylinder)
		elseif cfg.Category == "Extractors" then
			addPart(model, "RockBed", Vector3.new(3.4, 0.7, 3.4), bc * CFrame.new(0, 0.4, 0), Color3.fromRGB(75, 72, 68), Enum.Material.Slate)
			for _, sx in ipairs({ -2.0, 2.0 }) do
				for _, sz in ipairs({ -2.0, 2.0 }) do
					addPart(model, "RigLeg", Vector3.new(0.55, 4.4, 0.55), bc * CFrame.new(sx, 2.35, sz), DARK_METAL, Enum.Material.Metal)
				end
			end
			addPart(model, "TopMotorBox", Vector3.new(4.8, 1.1, 4.8), bc * CFrame.new(0, 4.8, 0), cfg.Color, Enum.Material.Metal)
			addPart(model, "DrillHead", Vector3.new(1.3, 3.8, 1.3), bc * CFrame.new(0, 2.6, 0), LIGHT_STEEL, Enum.Material.DiamondPlate)
		else
			addPart(model, "FurnaceChamber", Vector3.new(4.2, 3.2, 4.2), bc * CFrame.new(0, 1.75, 0), cfg.Color, Enum.Material.Metal)
			addPart(model, "MoltenWindow", Vector3.new(2.6, 1.6, 4.35), bc * CFrame.new(0, 1.5, 0), Color3.fromRGB(255, 145, 35), Enum.Material.Neon)
		end
	end

	local baseCF = base.CFrame

	-- Ajout du déflecteur lumineux sur les tapis 90° (même avec les modèles FBX !)
	if isBelt and cfg.TurnType == "Left" then
		addPart(model, "CornerGuide", Vector3.new(0.4, 0.45, 4.4), baseCF * CFrame.new(0.4, 0.75, -0.4) * CFrame.Angles(0, math.rad(45), 0), cfg.Color, Enum.Material.Neon).CanQuery = false
	elseif isBelt and cfg.TurnType == "Right" then
		addPart(model, "CornerGuide", Vector3.new(0.4, 0.45, 4.4), baseCF * CFrame.new(-0.4, 0.75, -0.4) * CFrame.Angles(0, math.rad(-45), 0), cfg.Color, Enum.Material.Neon).CanQuery = false
	end

	-- Vrai chevron directionnel (^) placé AU-DESSUS du socle/rouleaux pour voir clairement la rotation !
	local turnAngle = (cfg.TurnType == "Left" and 90) or (cfg.TurnType == "Right" and -90) or 0
	local arrowPivot = baseCF * CFrame.Angles(0, math.rad(turnAngle), 0)
	local arrowY = isBelt and 0.72 or 0.85
	local arrowZ = isBelt and -0.8 or -2.35

	local chevL = addPart(model, "ArrowChevronL", Vector3.new(0.22, 0.18, 1.05), arrowPivot * CFrame.new(-0.3, arrowY, arrowZ) * CFrame.Angles(0, math.rad(-42), 0), Color3.fromRGB(255, 230, 50), Enum.Material.Neon)
	chevL.CanQuery = false
	local chevR = addPart(model, "ArrowChevronR", Vector3.new(0.22, 0.18, 1.05), arrowPivot * CFrame.new(0.3, arrowY, arrowZ) * CFrame.Angles(0, math.rad(42), 0), Color3.fromRGB(255, 230, 50), Enum.Material.Neon)
	chevR.CanQuery = false

	if isPreview then
		for _, part in ipairs(model:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Transparency = math.max(part.Transparency, 0.45)
				part.CanCollide = false
				part.CanQuery = false
			end
		end
		return model
	end

	if not isBelt then
		local billboard = Instance.new("BillboardGui")
		billboard.Name = "StatusGui"
		billboard.Size = UDim2.new(0, 125, 0, 36)
		billboard.StudsOffset = Vector3.new(0, 5.8, 0)
		billboard.MaxDistance = 50
		billboard.Parent = base

		local bg = Instance.new("Frame")
		bg.Name = "Background"
		bg.Size = UDim2.new(1, 0, 1, 0)
		bg.BackgroundColor3 = Color3.fromRGB(14, 18, 28)
		bg.BackgroundTransparency = 0.25
		bg.Parent = billboard
		Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 6)

		local titleLbl = Instance.new("TextLabel")
		titleLbl.Name = "TitleLabel"
		titleLbl.Size = UDim2.new(1, -6, 0.5, 0)
		titleLbl.Position = UDim2.new(0, 3, 0, 1)
		titleLbl.BackgroundTransparency = 1
		titleLbl.Text = cfg.Name
		titleLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
		titleLbl.Font = Enum.Font.GothamBold
		titleLbl.TextScaled = true
		titleLbl.Parent = bg

		local statusLbl = Instance.new("TextLabel")
		statusLbl.Name = "StatusLabel"
		statusLbl.Size = UDim2.new(1, -6, 0.45, 0)
		statusLbl.Position = UDim2.new(0, 3, 0.5, 0)
		statusLbl.BackgroundTransparency = 1
		statusLbl.Text = "Prêt"
		statusLbl.TextColor3 = Color3.fromRGB(140, 245, 160)
		statusLbl.Font = Enum.Font.GothamMedium
		statusLbl.TextScaled = true
		statusLbl.Parent = bg
	end

	return model
end

function ModelFactory.PivotMachineModel(model: Model, targetCFrame: CFrame)
	if not model.PrimaryPart then return end
	local currentPivot = model.PrimaryPart.CFrame
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") and part ~= model.PrimaryPart then
			local relative = currentPivot:ToObjectSpace(part.CFrame)
			part.CFrame = targetCFrame:ToWorldSpace(relative)
		end
	end
	model.PrimaryPart.CFrame = targetCFrame
end

return ModelFactory