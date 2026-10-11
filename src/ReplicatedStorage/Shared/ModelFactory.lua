-- ReplicatedStorage/Shared/ModelFactory.lua
local PlotAndPrestigeConfig = require(script.Parent.Config.PlotAndPrestigeConfig)
local MachineConfig = require(script.Parent.Config.MachineConfig)
local ResourceConfig = require(script.Parent.Config.ResourceConfig)

local ModelFactory = {}

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

-- Crée le modèle 3D d'une ressource (Minerai, Lingot, Bloc, Diamant, Cellule, Cœur)
function ModelFactory.CreateResourceModel(resourceId: string): Model
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

	if info.Shape == "Ore" then
		root.Size = Vector3.new(1.3, 1.1, 1.3)
		addPart(model, "Chunk1", Vector3.new(0.9, 0.9, 0.9), root.CFrame * CFrame.new(0.3, 0.2, 0.2) * CFrame.Angles(0.5, 0.4, 0.2), info.Color, root.Material)
		addPart(model, "Chunk2", Vector3.new(0.8, 1.0, 0.8), root.CFrame * CFrame.new(-0.3, 0.1, -0.2) * CFrame.Angles(-0.3, 0.8, 0.4), info.Color, root.Material)
	elseif info.Shape == "Ingot" then
		root.Size = Vector3.new(1.1, 0.55, 1.8)
		root.Reflectance = 0.25
		addPart(model, "TopBevel", Vector3.new(0.85, 0.2, 1.55), root.CFrame * CFrame.new(0, 0.3, 0), info.Color, root.Material)
	elseif info.Shape == "Block" then
		root.Size = Vector3.new(1.6, 1.6, 1.6)
		root.Reflectance = 0.15
		addPart(model, "Band", Vector3.new(1.68, 0.35, 1.68), root.CFrame, Color3.fromRGB(45, 50, 60), Enum.Material.Metal)
	elseif info.Shape == "Gem" then
		root.Size = Vector3.new(1.2, 1.5, 1.2)
		root.Transparency = 0.15
		addPart(model, "Facet", Vector3.new(1.2, 1.2, 1.2), root.CFrame * CFrame.Angles(math.rad(45), math.rad(45), 0), info.Color, Enum.Material.Neon)
	elseif info.Shape == "Canister" then
		root.Shape = Enum.PartType.Cylinder
		root.Size = Vector3.new(1.7, 1.1, 1.1)
		addPart(model, "Cap1", Vector3.new(0.3, 1.2, 1.2), root.CFrame * CFrame.new(0.75, 0, 0), Color3.fromRGB(50, 55, 65), Enum.Material.Metal, Enum.PartType.Cylinder)
		addPart(model, "Cap2", Vector3.new(0.3, 1.2, 1.2), root.CFrame * CFrame.new(-0.75, 0, 0), Color3.fromRGB(50, 55, 65), Enum.Material.Metal, Enum.PartType.Cylinder)
	elseif info.Shape == "Core" then
		root.Shape = Enum.PartType.Ball
		root.Size = Vector3.new(1.5, 1.5, 1.5)
		addPart(model, "Ring", Vector3.new(0.2, 2.1, 2.1), root.CFrame * CFrame.Angles(0, 0, math.rad(45)), Color3.fromRGB(255, 240, 150), Enum.Material.Neon, Enum.PartType.Cylinder)
	end

	if info.Glow then
		local light = Instance.new("PointLight")
		light.Color = info.Color
		light.Range = 7
		light.Brightness = 1.5
		light.Parent = root
	end

	return model
end

-- Crée le modèle 3D détaillé d'une machine ou d'un tapis
function ModelFactory.CreateMachineModel(machineType: string, isPreview: boolean?): Model
	local cfg = MachineConfig.Get(machineType) or MachineConfig.Get("IronExtractor")

	local model = Instance.new("Model")
	model.Name = machineType

	local cellSize = PlotAndPrestigeConfig.CellSize
	local isBelt = cfg.IsBelt == true
	local baseHeight = isBelt and 0.6 or 0.8

	-- Socle de base (sert de PrimaryPart pour l'alignement sur la grille 6x6)
	local base = Instance.new("Part")
	base.Name = "PrimaryPart"
	base.Size = Vector3.new(cellSize - 0.4, baseHeight, cellSize - 0.4)
	base.Anchored = true
	base.CanCollide = not isPreview
	base.Color = isBelt and Color3.fromRGB(35, 38, 45) or Color3.fromRGB(45, 50, 60)
	base.Material = Enum.Material.Metal
	base.TopSurface = Enum.SurfaceType.Smooth
	base.BottomSurface = Enum.SurfaceType.Smooth
	base.Parent = model
	model.PrimaryPart = base

	local bc = base.CFrame

	-- ==================== 1. TAPIS ROULANTS, VIRAGES 90° & AIGUILLAGES ====================
	if isBelt then
		-- Rails latéraux colorés selon la gamme du tapis
		addPart(model, "RailL", Vector3.new(0.45, 0.45, cellSize - 0.4), bc * CFrame.new(-(cellSize / 2 - 0.45), 0.35, 0), cfg.Color, Enum.Material.Metal)
		addPart(model, "RailR", Vector3.new(0.45, 0.45, cellSize - 0.4), bc * CFrame.new((cellSize / 2 - 0.45), 0.35, 0), cfg.Color, Enum.Material.Metal)

		-- Rouleaux métalliques sur le tapis
		for offsetZ = -1.8, 1.8, 1.8 do
			addPart(model, "Roller", Vector3.new(cellSize - 1.3, 0.35, 0.35), bc * CFrame.new(0, 0.22, offsetZ) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(80, 85, 95), Enum.Material.DiamondPlate, Enum.PartType.Cylinder)
		end

		if machineType == "Merger" then
			-- Arche de fusion 3-en-1
			addPart(model, "MergerArch", Vector3.new(cellSize - 0.8, 1.8, 1.4), bc * CFrame.new(0, 1.1, 0), cfg.Color, Enum.Material.Metal)
		elseif machineType == "Sorter" then
			-- Portique scanner avec laser de tri
			addPart(model, "ScannerTop", Vector3.new(cellSize - 0.6, 0.4, 1.2), bc * CFrame.new(0, 2.2, 0), cfg.Color, Enum.Material.Metal)
			addPart(model, "ScannerBeam", Vector3.new(cellSize - 1.2, 0.15, 0.15), bc * CFrame.new(0, 1.4, 0), Color3.fromRGB(0, 255, 255), Enum.Material.Neon)
		end

	-- ==================== 2. CENTRE DE LIVRAISON & STOCKAGE ====================
	elseif machineType == "DeliveryCenter" then
		addPart(model, "PadBorder", Vector3.new(cellSize - 0.8, 0.4, cellSize - 0.8), bc * CFrame.new(0, 0.5, 0), Color3.fromRGB(245, 190, 30), Enum.Material.DiamondPlate)
		local vortex = addPart(model, "CollectionZone", Vector3.new(cellSize - 1.8, 0.5, cellSize - 1.8), bc * CFrame.new(0, 0.65, 0), Color3.fromRGB(45, 235, 115), Enum.Material.Neon)
		addPart(model, "Antenna", Vector3.new(0.5, 3.8, 0.5), bc * CFrame.new(2.0, 2.1, 2.0), Color3.fromRGB(60, 65, 75), Enum.Material.Metal)
		addPart(model, "Beacon", Vector3.new(0.9, 0.9, 0.9), bc * CFrame.new(2.0, 4.2, 2.0), Color3.fromRGB(90, 255, 130), Enum.Material.Neon, Enum.PartType.Ball)
		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(60, 255, 120)
		light.Range = 12
		light.Parent = vortex

	elseif machineType == "Storage" then
		addPart(model, "SiloTank", Vector3.new(4.2, 4.2, 4.2), bc * CFrame.new(0, 2.3, 0) * CFrame.Angles(0, 0, math.rad(90)), cfg.Color, Enum.Material.Metal, Enum.PartType.Cylinder)
		addPart(model, "Gauge", Vector3.new(0.4, 3.2, 4.35), bc * CFrame.new(0, 2.3, 0), Color3.fromRGB(110, 220, 255), Enum.Material.Neon)

	-- ==================== 3. GÉNÉRATEURS D'ÉNERGIE ====================
	elseif cfg.Category == "Energy" then
		addPart(model, "CoreHousing", Vector3.new(4.0, 2.8, 4.0), bc * CFrame.new(0, 1.6, 0), Color3.fromRGB(55, 60, 72), Enum.Material.Metal)
		local sphere = addPart(model, "EnergyCore", Vector3.new(2.6, 2.6, 2.6), bc * CFrame.new(0, 3.4, 0), cfg.Color, Enum.Material.Neon, Enum.PartType.Ball)
		addPart(model, "Coil1", Vector3.new(0.5, 3.4, 3.4), bc * CFrame.new(0, 3.4, 0), Color3.fromRGB(90, 95, 110), Enum.Material.Metal, Enum.PartType.Cylinder)
		local light = Instance.new("PointLight")
		light.Color = cfg.Color
		light.Range = 14
		light.Brightness = 2
		light.Parent = sphere

	-- ==================== 4. MINES & FOREUSES (5 MINERAIS) ====================
	elseif cfg.Category == "Extractors" then
		-- Gisement de roche colorée au sol
		addPart(model, "OreVein1", Vector3.new(2.6, 1.2, 2.6), bc * CFrame.new(0, 0.6, 0) * CFrame.Angles(0.2, 0.5, 0.1), cfg.Color, Enum.Material.Slate)
		addPart(model, "OreVein2", Vector3.new(1.8, 1.5, 1.8), bc * CFrame.new(0.8, 0.7, 0.6) * CFrame.Angles(-0.3, 0.2, 0.4), cfg.Color, Enum.Material.Neon)
		-- 4 Piliers de support + Arche supérieure
		for _, sx in ipairs({ -1.9, 1.9 }) do
			for _, sz in ipairs({ -1.9, 1.9 }) do
				addPart(model, "Pillar", Vector3.new(0.5, 4.2, 0.5), bc * CFrame.new(sx, 2.3, sz), Color3.fromRGB(65, 70, 82), Enum.Material.Metal)
			end
		end
		addPart(model, "TopRig", Vector3.new(4.5, 1.0, 4.5), bc * CFrame.new(0, 4.6, 0), cfg.Color, Enum.Material.Metal)
		-- Mèche de forage centrale (animée côté client via le nom DrillHead)
		addPart(model, "DrillHead", Vector3.new(1.3, 3.6, 1.3), bc * CFrame.new(0, 2.4, 0), Color3.fromRGB(190, 195, 205), Enum.Material.DiamondPlate)

	-- ==================== 5. RAFFINERIES & FOURS ====================
	elseif cfg.Category == "Refiners" then
		if machineType == "IndustrialFurnace" or machineType == "PlasmaArcFurnace" then
			addPart(model, "FurnaceBody", Vector3.new(4.4, 3.4, 4.4), bc * CFrame.new(0, 1.9, 0), cfg.Color, Enum.Material.Metal)
			local core = addPart(model, "MoltenCore", Vector3.new(2.8, 1.8, 4.55), bc * CFrame.new(0, 1.5, 0), Color3.fromRGB(255, 150, 40), Enum.Material.Neon)
			local chimney = addPart(model, "Chimney", Vector3.new(2.2, 1.5, 1.5), bc * CFrame.new(1.1, 4.2, 1.1) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(40, 42, 50), Enum.Material.Metal, Enum.PartType.Cylinder)
			if not isPreview then
				local particles = Instance.new("ParticleEmitter")
				particles.Color = ColorSequence.new(Color3.fromRGB(255, 170, 60), Color3.fromRGB(90, 90, 90))
				particles.Size = NumberSequence.new(0.4, 1.2)
				particles.Lifetime = NumberRange.new(1.0, 1.8)
				particles.Rate = 8
				particles.Speed = NumberRange.new(2, 4)
				particles.Parent = chimney
			end
			local light = Instance.new("PointLight")
			light.Color = core.Color
			light.Range = 10
			light.Parent = core
		elseif machineType == "HydraulicPress" then
			addPart(model, "Anvil", Vector3.new(3.6, 0.8, 3.6), bc * CFrame.new(0, 0.6, 0), Color3.fromRGB(80, 85, 95), Enum.Material.Metal)
			addPart(model, "FrameL", Vector3.new(0.6, 4.2, 1.2), bc * CFrame.new(-1.9, 2.3, 0), cfg.Color, Enum.Material.Metal)
			addPart(model, "FrameR", Vector3.new(0.6, 4.2, 1.2), bc * CFrame.new(1.9, 2.3, 0), cfg.Color, Enum.Material.Metal)
			addPart(model, "TopBeam", Vector3.new(4.6, 0.9, 1.8), bc * CFrame.new(0, 4.5, 0), cfg.Color, Enum.Material.Metal)
			addPart(model, "Piston", Vector3.new(2.6, 1.4, 2.6), bc * CFrame.new(0, 2.6, 0), Color3.fromRGB(210, 180, 50), Enum.Material.DiamondPlate)
		elseif machineType == "LaserCutter" then
			addPart(model, "Gantry", Vector3.new(4.4, 3.6, 1.4), bc * CFrame.new(0, 2.0, 0), Color3.fromRGB(50, 55, 68), Enum.Material.Metal)
			addPart(model, "LaserEmitter", Vector3.new(1.2, 1.2, 1.2), bc * CFrame.new(0, 3.8, 0), cfg.Color, Enum.Material.Metal)
			addPart(model, "LaserBeam", Vector3.new(0.25, 3.2, 0.25), bc * CFrame.new(0, 2.0, 0), Color3.fromRGB(255, 45, 130), Enum.Material.Neon)
		else
			-- Cuves Chimiques / Ultrasons / Centrifugeuses / Cryo
			addPart(model, "VatWall", Vector3.new(4.4, 2.4, 4.4), bc * CFrame.new(0, 1.4, 0), Color3.fromRGB(60, 68, 82), Enum.Material.Metal)
			addPart(model, "GlowingLiquid", Vector3.new(3.8, 2.1, 3.8), bc * CFrame.new(0, 1.65, 0), cfg.Color, Enum.Material.Neon)
			addPart(model, "GlassChamber", Vector3.new(3.2, 2.2, 3.2), bc * CFrame.new(0, 3.4, 0), cfg.Color, Enum.Material.Glass)
		end

	-- ==================== 6. CHAMBRES D'ALLIAGES & HAUTE TECHNOLOGIE ====================
	else
		addPart(model, "ChamberLeft", Vector3.new(1.6, 3.4, 4.2), bc * CFrame.new(-1.5, 1.9, 0), Color3.fromRGB(55, 60, 75), Enum.Material.Metal)
		addPart(model, "ChamberRight", Vector3.new(1.6, 3.4, 4.2), bc * CFrame.new(1.5, 1.9, 0), Color3.fromRGB(55, 60, 75), Enum.Material.Metal)
		local fusionCore = addPart(model, "FusionCore", Vector3.new(2.2, 2.8, 2.8), bc * CFrame.new(0, 2.2, 0), cfg.Color, Enum.Material.Neon)
		addPart(model, "TopArch", Vector3.new(4.6, 0.7, 2.2), bc * CFrame.new(0, 4.0, 0), cfg.Color, Enum.Material.Metal)
		local light = Instance.new("PointLight")
		light.Color = cfg.Color
		light.Range = 11
		light.Parent = fusionCore
	end

	-- ==================== FLÈCHE DIRECTIONNELLE DE SORTIE ====================
	local turnAngle = 0
	if cfg.TurnType == "Left" then
		turnAngle = 90
	elseif cfg.TurnType == "Right" then
		turnAngle = -90
	end

	local arrowPivot = bc * CFrame.Angles(0, math.rad(turnAngle), 0)
	local arrowY = isBelt and (baseHeight / 2 + 0.12) or (baseHeight / 2 + 0.15)
	local arrowZ = isBelt and -0.7 or -2.1

	addPart(model, "DirectionIndicator", Vector3.new(0.85, 0.2, 1.5), arrowPivot * CFrame.new(0, arrowY, arrowZ), Color3.fromRGB(255, 255, 255), Enum.Material.Neon)

	local tip = Instance.new("WedgePart")
	tip.Name = "ArrowTip"
	tip.Size = Vector3.new(0.2, 1.3, 0.85)
	tip.Anchored = true
	tip.CanCollide = false
	tip.CanQuery = false
	tip.Color = Color3.fromRGB(255, 230, 65)
	tip.Material = Enum.Material.Neon
	tip.CFrame = arrowPivot * CFrame.new(0, arrowY, arrowZ - 0.95) * CFrame.Angles(0, 0, math.rad(90))
	tip.Parent = model

	if isPreview then
		for _, part in ipairs(model:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Transparency = 0.45
				part.CanCollide = false
			end
		end
		return model
	end

	-- Panneau d'état (BillboardGui)
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "StatusGui"
	billboard.Size = UDim2.new(0, 145, 0, 48)
	billboard.StudsOffset = Vector3.new(0, isBelt and 2.6 or 5.8, 0)
	billboard.MaxDistance = 65
	billboard.Parent = base

	local bg = Instance.new("Frame")
	bg.Name = "Background"
	bg.Size = UDim2.new(1, 0, 1, 0)
	bg.BackgroundColor3 = Color3.fromRGB(16, 20, 30)
	bg.BackgroundTransparency = 0.2
	bg.BorderSizePixel = 0
	bg.Parent = billboard

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = bg

	local titleLbl = Instance.new("TextLabel")
	titleLbl.Name = "TitleLabel"
	titleLbl.Size = UDim2.new(1, -6, 0.5, 0)
	titleLbl.Position = UDim2.new(0, 3, 0, 2)
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
	statusLbl.TextColor3 = Color3.fromRGB(150, 240, 165)
	statusLbl.Font = Enum.Font.GothamMedium
	statusLbl.TextScaled = true
	statusLbl.Parent = bg

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