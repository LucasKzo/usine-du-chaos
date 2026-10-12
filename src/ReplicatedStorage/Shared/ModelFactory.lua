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
	p.CanQuery = false
	p.Color = color
	p.Material = mat
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

-- Applique automatiquement les couleurs et matériaux Roblox aux parties du FBX Blender
local function applyCustomMaterials(instance: Instance, cfg: any)
	for _, part in ipairs(instance:GetDescendants()) do
		if part:IsA("BasePart") then
			local n = string.lower(part.Name)
			if string.find(n, "dark") then
				part.Color = DARK_METAL
				part.Material = Enum.Material.Metal
			elseif string.find(n, "main") then
				part.Color = cfg.Color
				part.Material = Enum.Material.Metal
			elseif string.find(n, "neon") or string.find(n, "glow") then
				part.Color = cfg.Color
				part.Material = Enum.Material.Neon
			elseif string.find(n, "silver") or string.find(n, "drill") or string.find(n, "rotor") then
				part.Color = LIGHT_STEEL
				part.Material = Enum.Material.Metal
			elseif string.find(n, "piston") then
				part.Color = Color3.fromRGB(245, 195, 35)
				part.Material = Enum.Material.Metal
			else
				part.Color = cfg.Color
				part.Material = Enum.Material.Metal
			end
		end
	end
end

-- Prépare, met à l'échelle (case 6x6) et centre au sol un modèle 3D importé (.fbx)
local function prepareCustomModel(template: Instance, targetWidth: number, isPreview: boolean?, cfg: any?): Model
	local wrapper = Instance.new("Model")
	wrapper.Name = template.Name

	local base = Instance.new("Part")
	base.Name = "PrimaryPart"
	base.Size = Vector3.new(targetWidth - 0.3, 0.3, targetWidth - 0.3)
	base.CFrame = CFrame.new(0, 0.15, 0)
	base.Anchored = true
	base.CanCollide = not isPreview
	base.Color = DARK_METAL
	base.Material = Enum.Material.Metal
	base.TopSurface = Enum.SurfaceType.Smooth
	base.BottomSurface = Enum.SurfaceType.Smooth
	base.Parent = wrapper
	wrapper.PrimaryPart = base

	local clone = template:Clone()
	for _, desc in ipairs(clone:GetDescendants()) do
		if desc:IsA("LuaSourceContainer") or desc:IsA("WeldConstraint") or desc:IsA("JointInstance") then
			desc:Destroy()
		elseif desc:IsA("BasePart") then
			desc.Anchored = true
			desc.CanCollide = not isPreview
			desc.CanQuery = false
		end
	end

	if cfg then
		applyCustomMaterials(clone, cfg)
	end

	if clone:IsA("Model") then
		local boxCF, boxSize = clone:GetBoundingBox()
		local maxHoriz = math.max(boxSize.X, boxSize.Z, 0.01)
		local scaleFactor = (targetWidth - 0.6) / maxHoriz
		pcall(function()
			clone:ScaleTo(clone:GetScale() * scaleFactor)
		end)

		boxCF, boxSize = clone:GetBoundingBox()
		local parts = {}
		for _, part in ipairs(clone:GetDescendants()) do
			if part:IsA("BasePart") then
				table.insert(parts, part)
			end
		end

		for _, part in ipairs(parts) do
			local offset = part.Position - boxCF.Position
			local newPos = Vector3.new(offset.X, offset.Y + (boxSize.Y / 2) + 0.3, offset.Z)
			part.CFrame = CFrame.new(newPos) * part.CFrame.Rotation
			part.Parent = wrapper
		end
		clone:Destroy()
	elseif clone:IsA("BasePart") then
		clone.Anchored = true
		clone.CanCollide = not isPreview
		clone.CanQuery = false
		if cfg then
			clone.Color = cfg.Color
			clone.Material = Enum.Material.Metal
		end
		local maxHoriz = math.max(clone.Size.X, clone.Size.Z, 0.01)
		clone.Size = clone.Size * ((targetWidth - 0.6) / maxHoriz)
		clone.CFrame = CFrame.new(0, (clone.Size.Y / 2) + 0.3, 0) * clone.CFrame.Rotation
		clone.Parent = wrapper
	end

	return wrapper
end

-- ==================== MODÈLES 3D DES 20 RESSOURCES ====================
function ModelFactory.CreateResourceModel(resourceId: string): Model
	local customFolder = ReplicatedStorage:FindFirstChild("CustomAssets")
	local customRes = (customFolder and customFolder:FindFirstChild("Resources") and customFolder.Resources:FindFirstChild(resourceId))
		or Workspace:FindFirstChild(resourceId)
	if customRes then
		return prepareCustomModel(customRes, 1.8, true, ResourceConfig.Items[resourceId])
	end

	local info = ResourceConfig.Items[resourceId] or ResourceConfig.Items.IronOre
	local model = Instance.new("Model")
	model.Name = "Res_" .. resourceId

	local root = Instance.new("Part")
	root.Name = "PrimaryPart"
	root.Anchored = true
	root.CanCollide = false
	root.CanQuery = false
	root.Color = info.Color
	root.Material = info.Material or Enum.Material.SmoothPlastic
	root.TopSurface = Enum.SurfaceType.Smooth
	root.BottomSurface = Enum.SurfaceType.Smooth
	root.Parent = model
	model.PrimaryPart = root

	local rc = root.CFrame

	if info.Shape == "Ore" then
		root.Size = Vector3.new(1.15, 0.9, 1.15)
		root.Color = Color3.fromRGB(95, 90, 85)
		root.Material = Enum.Material.Rock
		addPart(model, "Vein1", Vector3.new(0.75, 0.75, 0.75), rc * CFrame.new(0.22, 0.2, 0.18) * CFrame.Angles(0.5, 0.4, 0.2), info.Color, Enum.Material.Metal)
		addPart(model, "Vein2", Vector3.new(0.65, 0.7, 0.65), rc * CFrame.new(-0.25, 0.15, -0.2) * CFrame.Angles(-0.4, 0.7, 0.3), info.Color, Enum.Material.Neon)
	elseif info.Shape == "Ingot" then
		root.Size = Vector3.new(0.95, 0.4, 1.5)
		root.Reflectance = 0.3
		addPart(model, "Bevel", Vector3.new(0.75, 0.2, 1.3), rc * CFrame.new(0, 0.25, 0), info.Color, root.Material)
	elseif info.Shape == "Block" then
		root.Size = Vector3.new(1.35, 1.35, 1.35)
		root.Reflectance = 0.2
		addPart(model, "FrameH", Vector3.new(1.42, 0.28, 1.42), rc, DARK_METAL, Enum.Material.Metal)
		addPart(model, "CoreDot", Vector3.new(0.6, 1.4, 0.6), rc, info.Color, Enum.Material.Neon)
	elseif info.Shape == "Gem" then
		root.Size = Vector3.new(0.95, 1.25, 0.95)
		root.Transparency = 0.15
		addPart(model, "Crystal1", Vector3.new(0.95, 0.95, 0.95), rc * CFrame.Angles(math.rad(45), math.rad(45), 0), info.Color, Enum.Material.Neon)
	elseif info.Shape == "Canister" then
		root.Shape = Enum.PartType.Cylinder
		root.Size = Vector3.new(1.4, 0.95, 0.95)
	elseif info.Shape == "Core" then
		root.Shape = Enum.PartType.Ball
		root.Size = Vector3.new(1.25, 1.25, 1.25)
	end

	return model
end

-- ==================== MODÈLES 3D DES MACHINES & TAPIS ====================
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
		model = prepareCustomModel(customTemplate, cellSize, isPreview, cfg)
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
		base.Color = DARK_METAL
		base.Material = Enum.Material.Metal
		base.TopSurface = Enum.SurfaceType.Smooth
		base.BottomSurface = Enum.SurfaceType.Smooth
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
			if cfg.TurnType == "Left" then
				addPart(model, "CornerGuide", Vector3.new(0.45, 0.55, 4.6), bc * CFrame.new(0.3, 0.35, -0.3) * CFrame.Angles(0, math.rad(45), 0), cfg.Color, Enum.Material.Neon)
			elseif cfg.TurnType == "Right" then
				addPart(model, "CornerGuide", Vector3.new(0.45, 0.55, 4.6), bc * CFrame.new(-0.3, 0.35, -0.3) * CFrame.Angles(0, math.rad(-45), 0), cfg.Color, Enum.Material.Neon)
			elseif machineType == "Merger" then
				addPart(model, "ArchTop", Vector3.new(4.8, 1.8, 1.8), bc * CFrame.new(0, 1.2, 0), cfg.Color, Enum.Material.Metal)
			elseif machineType == "Sorter" then
				addPart(model, "ScannerTop", Vector3.new(4.8, 0.5, 1.4), bc * CFrame.new(0, 2.4, 0), cfg.Color, Enum.Material.Metal)
				addPart(model, "LaserGrid", Vector3.new(3.8, 1.8, 0.1), bc * CFrame.new(0, 1.2, 0), Color3.fromRGB(0, 240, 255), Enum.Material.Neon)
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
		elseif cfg.Category == "Refiners" then
			addPart(model, "FurnaceChamber", Vector3.new(4.2, 3.2, 4.2), bc * CFrame.new(0, 1.75, 0), cfg.Color, Enum.Material.Metal)
			addPart(model, "MoltenWindow", Vector3.new(2.6, 1.6, 4.35), bc * CFrame.new(0, 1.5, 0), Color3.fromRGB(255, 145, 35), Enum.Material.Neon)
		else
			addPart(model, "WingL", Vector3.new(1.3, 3.6, 4.2), bc * CFrame.new(-1.7, 1.95, 0), DARK_METAL, Enum.Material.Metal)
			addPart(model, "WingR", Vector3.new(1.3, 3.6, 4.2), bc * CFrame.new(1.7, 1.95, 0), DARK_METAL, Enum.Material.Metal)
			addPart(model, "FusionSphere", Vector3.new(2.1, 2.1, 2.1), bc * CFrame.new(0, 2.4, 0), cfg.Color, Enum.Material.Neon, Enum.PartType.Ball)
			addPart(model, "RotorSpinner", Vector3.new(2.8, 0.45, 2.8), bc * CFrame.new(0, 2.4, 0), LIGHT_STEEL, Enum.Material.Metal)
		end
	end

	-- Flèche directionnelle commune à tous les modèles (FBX comme Lua)
	local baseCF = base.CFrame
	local turnAngle = (cfg.TurnType == "Left" and 90) or (cfg.TurnType == "Right" and -90) or 0
	local arrowPivot = baseCF * CFrame.Angles(0, math.rad(turnAngle), 0)
	local arrowY = (baseHeight / 2) + 0.1
	local arrowZ = isBelt and -0.4 or -2.2

	local tip = Instance.new("WedgePart")
	tip.Name = "ArrowTip"
	tip.Size = Vector3.new(0.15, 0.9, 0.9)
	tip.Anchored = true
	tip.CanCollide = false
	tip.CanQuery = false
	tip.Color = Color3.fromRGB(255, 225, 60)
	tip.Material = Enum.Material.Neon
	tip.CFrame = arrowPivot * CFrame.new(0, arrowY, arrowZ) * CFrame.Angles(0, 0, math.rad(90))
	tip.Parent = model

	if isPreview then
		for _, part in ipairs(model:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Transparency = math.max(part.Transparency, 0.45)
				part.CanCollide = false
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
		bg.BorderSizePixel = 0
		bg.Parent = billboard

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 6)
		corner.Parent = bg

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