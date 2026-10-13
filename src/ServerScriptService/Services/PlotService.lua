-- ServerScriptService/Services/PlotService.lua
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlotAndPrestigeConfig = require(ReplicatedStorage.Shared.Config.PlotAndPrestigeConfig)
local MachineConfig = require(ReplicatedStorage.Shared.Config.MachineConfig)
local ResourceConfig = require(ReplicatedStorage.Shared.Config.ResourceConfig)
local ModelFactory = require(ReplicatedStorage.Shared.ModelFactory)

local PlotService = {}
PlotService.Plots = {}

function PlotService.Init()
	local plotsFolder = Workspace:FindFirstChild("Plots") or Instance.new("Folder")
	plotsFolder.Name = "Plots"
	plotsFolder.Parent = Workspace

	local customAssets = ReplicatedStorage:FindFirstChild("CustomAssets") or Instance.new("Folder")
	customAssets.Name = "CustomAssets"
	customAssets.Parent = ReplicatedStorage

	local machinesAssets = customAssets:FindFirstChild("Machines") or Instance.new("Folder")
	machinesAssets.Name = "Machines"
	machinesAssets.Parent = customAssets

	local resourcesAssets = customAssets:FindFirstChild("Resources") or Instance.new("Folder")
	resourcesAssets.Name = "Resources"
	resourcesAssets.Parent = customAssets

	for _, container in ipairs({ Workspace, ReplicatedStorage }) do
		for _, child in ipairs(container:GetChildren()) do
			if child:IsA("Model") or child:IsA("BasePart") then
				for machineId, _ in pairs(MachineConfig.Definitions) do
					if string.lower(child.Name) == string.lower(machineId) or string.find(string.lower(child.Name), string.lower(machineId), 1, true) then
						local existing = machinesAssets:FindFirstChild(machineId)
						if existing then existing:Destroy() end
						child.Name = machineId
						child.Parent = machinesAssets
						break
					end
				end
				for resId, _ in pairs(ResourceConfig.Items) do
					if string.lower(child.Name) == string.lower(resId) then
						local existing = resourcesAssets:FindFirstChild(resId)
						if existing then existing:Destroy() end
						child.Name = resId
						child.Parent = resourcesAssets
						break
					end
				end
			end
		end
	end

	local maxPlotSize = 16 * PlotAndPrestigeConfig.CellSize

	for i = 1, 8 do
		local row = (i <= 4) and 0 or 1
		local col = (i - 1) % 4
		local posX = (col - 1.5) * (maxPlotSize + 28)
		local posZ = (row == 0) and -75 or 75

		local plotModel = Instance.new("Model")
		plotModel.Name = "Plot_" .. tostring(i)
		plotModel.Parent = plotsFolder

		local startDim = PlotAndPrestigeConfig.PlotTiers[1].Cells * PlotAndPrestigeConfig.CellSize
		local base = Instance.new("Part")
		base.Name = "PlotBase"
		base.Size = Vector3.new(startDim, 1, startDim)
		base.Position = Vector3.new(posX, 0.5, posZ)
		base.Anchored = true
		base.Color = Color3.fromRGB(48, 52, 62)
		base.Material = Enum.Material.Concrete
		base.Parent = plotModel

		local signPost = Instance.new("Part")
		signPost.Name = "Sign"
		signPost.Size = Vector3.new(16, 4, 1)
		signPost.Position = Vector3.new(posX, 5, posZ + (row == 0 and 55 or -55))
		signPost.Anchored = true
		signPost.Color = Color3.fromRGB(22, 26, 35)
		signPost.Parent = plotModel

		local signGui = Instance.new("BillboardGui")
		signGui.Size = UDim2.new(0, 220, 0, 50)
		signGui.StudsOffset = Vector3.new(0, 2, 0)
		signGui.MaxDistance = 160
		signGui.Parent = signPost

		local signLabel = Instance.new("TextLabel")
		signLabel.Size = UDim2.new(1, 0, 1, 0)
		signLabel.BackgroundColor3 = Color3.fromRGB(18, 22, 32)
		signLabel.TextColor3 = Color3.fromRGB(255, 210, 60)
		signLabel.Font = Enum.Font.GothamBold
		signLabel.TextScaled = true
		signLabel.Text = "Parcelle Libre #" .. tostring(i)
		signLabel.Parent = signGui

		local machinesFolder = Instance.new("Folder")
		machinesFolder.Name = "Machines"
		machinesFolder.Parent = plotModel

		PlotService.Plots[i] = {
			Index = i,
			CenterPos = Vector3.new(posX, 0.5, posZ),
			OwnerUserId = nil,
			BasePart = base,
			MachinesFolder = machinesFolder,
			SignLabel = signLabel,
			AssignedTime = 0,
			ActiveChaosEffects = {},
			CargoStolenByUserId = nil,
		}
	end
end

-- CORRECTION DU BUG D'AGRANDISSEMENT DE LA DALLE
function PlotService.ApplyPlotTierSize(plotIndex: number, plotTier: number)
	local plot = PlotService.Plots[plotIndex]
	if not plot then return end
	local tierCfg = PlotAndPrestigeConfig.PlotTiers[plotTier] or PlotAndPrestigeConfig.PlotTiers[1]
	local startTierCfg = PlotAndPrestigeConfig.PlotTiers[1]
	
	local dim = tierCfg.Cells * PlotAndPrestigeConfig.CellSize
	local startDim = startTierCfg.Cells * PlotAndPrestigeConfig.CellSize
	
	plot.BasePart.Size = Vector3.new(dim, 1, dim)
	
	-- Garde la case en haut à gauche physiquement fixe au lieu de s'agrandir par le centre !
	local offset = (dim - startDim) / 2
	plot.BasePart.Position = plot.CenterPos + Vector3.new(offset, 0, offset)
	plot.BasePart:SetAttribute("Cells", tierCfg.Cells)
end

function PlotService.GridToWorldCFrame(plotIndex: number, cellsCount: number, gridX: number, gridZ: number, rotation: number, machineType: string, baseHeightOverride: number?): CFrame
	local plot = PlotService.Plots[plotIndex]
	local cellSize = PlotAndPrestigeConfig.CellSize
	
	-- Utilise toujours la dimension de base pour l'origine, ainsi la Grille ne se décale jamais
	local startDim = PlotAndPrestigeConfig.PlotTiers[1].Cells * cellSize
	local originX = plot.CenterPos.X - (startDim / 2)
	local originZ = plot.CenterPos.Z - (startDim / 2)

	local worldX = originX + (gridX - 0.5) * cellSize
	local worldZ = originZ + (gridZ - 0.5) * cellSize
	local cfg = MachineConfig.Get(machineType)
	local baseHeight = baseHeightOverride or ((cfg and cfg.IsBelt) and 0.3 or 0.3)
	
	local floorTopY = plot.CenterPos.Y + 0.5 -- Épaisseur de la dalle
	local worldY = floorTopY + (baseHeight / 2)

	return CFrame.new(worldX, worldY, worldZ) * CFrame.Angles(0, math.rad(-rotation), 0)
end

function PlotService.SpawnMachineModel(plotIndex: number, cellsCount: number, machineData: any)
	local plot = PlotService.Plots[plotIndex]
	if not plot then return end

	local model = ModelFactory.CreateMachineModel(machineData.Type, false)
	model.Name = machineData.Id
	model:SetAttribute("MachineId", machineData.Id)
	model:SetAttribute("MachineType", machineData.Type)
	model:SetAttribute("GridX", machineData.GridX)
	model:SetAttribute("GridZ", machineData.GridZ)
	model:SetAttribute("Rotation", machineData.Rotation)
	model:SetAttribute("Level", machineData.Level)

	local baseHeight = model.PrimaryPart and model.PrimaryPart.Size.Y or 0.3
	local cf = PlotService.GridToWorldCFrame(plotIndex, cellsCount, machineData.GridX, machineData.GridZ, machineData.Rotation, machineData.Type, baseHeight)
	ModelFactory.PivotMachineModel(model, cf)
	model.Parent = plot.MachinesFolder
end

function PlotService.RebuildPlotModels(plotIndex: number, playerData: any)
	local plot = PlotService.Plots[plotIndex]
	if not plot then return end
	PlotService.ApplyPlotTierSize(plotIndex, playerData.PlotTier)
	plot.MachinesFolder:ClearAllChildren()

	local tierCfg = PlotAndPrestigeConfig.PlotTiers[playerData.PlotTier] or PlotAndPrestigeConfig.PlotTiers[1]
	for _, m in ipairs(playerData.Machines) do
		PlotService.SpawnMachineModel(plotIndex, tierCfg.Cells, m)
	end
end

function PlotService.AssignPlot(player: Player, playerData: any)
	for i, plot in ipairs(PlotService.Plots) do
		if plot.OwnerUserId == nil then
			plot.OwnerUserId = player.UserId
			plot.AssignedTime = os.time()
			plot.SignLabel.Text = "Usine de " .. player.Name .. " [Prestige " .. tostring(playerData.Prestige) .. "]"
			player:SetAttribute("PlotIndex", i)
			PlotService.RebuildPlotModels(i, playerData)

			player.CharacterAdded:Connect(function(char)
				task.wait(0.2)
				local hrp = char:FindFirstChild("HumanoidRootPart")
				if hrp then hrp.CFrame = CFrame.new(plot.CenterPos + Vector3.new(0, 6, 35)) end
			end)
			if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
				player.Character.HumanoidRootPart.CFrame = CFrame.new(plot.CenterPos + Vector3.new(0, 6, 35))
			end
			return i
		end
	end
	return nil
end

function PlotService.GetPlotByPlayer(player: Player)
	for _, plot in ipairs(PlotService.Plots) do
		if plot.OwnerUserId == player.UserId then return plot end
	end
	return nil
end

function PlotService.ReleasePlot(player: Player)
	local plot = PlotService.GetPlotByPlayer(player)
	if plot then
		plot.MachinesFolder:ClearAllChildren()
		plot.OwnerUserId = nil
		plot.ActiveChaosEffects = {}
		plot.CargoStolenByUserId = nil
		plot.SignLabel.Text = "Parcelle Libre #" .. tostring(plot.Index)
		PlotService.ApplyPlotTierSize(plot.Index, 1)
	end
end

return PlotService