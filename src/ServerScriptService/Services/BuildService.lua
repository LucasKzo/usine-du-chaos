-- ServerScriptService/Services/BuildService.lua
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ConfigFolder = ReplicatedStorage.Shared.Config
local PlotAndPrestigeConfig = require(ConfigFolder.PlotAndPrestigeConfig)
local MachineConfig = require(ConfigFolder.MachineConfig)
local ModelFactory = require(ReplicatedStorage.Shared.ModelFactory)

local PlayerDataService = require(script.Parent.PlayerDataService)
local PlotService = require(script.Parent.PlotService)

local BuildService = {}

local function countDeliveryCenters(machines): number
	local count = 0
	for _, m in ipairs(machines) do
		if m.Type == "DeliveryCenter" then
			count = count + 1
		end
	end
	return count
end

function BuildService.PlaceMachine(player: Player, machineType: string, gridX: number, gridZ: number, rotation: number)
	local data = PlayerDataService.GetData(player)
	local plot = PlotService.GetPlotByPlayer(player)
	if not data or not plot then return false, "Parcelle introuvable." end

	local cfg = MachineConfig.Get(machineType)
	if not cfg then return false, "Machine inconnue." end

	local tierCfg = PlotAndPrestigeConfig.PlotTiers[data.PlotTier] or PlotAndPrestigeConfig.PlotTiers[1]
	gridX = math.floor(tonumber(gridX) or 0)
	gridZ = math.floor(tonumber(gridZ) or 0)
	rotation = (math.floor((tonumber(rotation) or 0) / 90) * 90) % 360

	if gridX < 1 or gridX > tierCfg.Cells or gridZ < 1 or gridZ > tierCfg.Cells then
		return false, "Hors de ton terrain actuel (" .. tierCfg.Cells .. "x" .. tierCfg.Cells .. "). Agrandis ta parcelle !"
	end

	if #data.Machines >= tierCfg.MaxMachines then
		return false, "Limite de machines atteinte (" .. tierCfg.MaxMachines .. "). Agrandis ta parcelle !"
	end

	for _, m in ipairs(data.Machines) do
		if m.GridX == gridX and m.GridZ == gridZ then
			return false, "Cette case est déjà occupée."
		end
	end

	-- Calcul du prix (exponentiel si c'est un Centre de Livraison)
	local price = cfg.Price
	if machineType == "DeliveryCenter" then
		local existingCenters = countDeliveryCenters(data.Machines)
		price = PlotAndPrestigeConfig.GetDeliveryCenterCost(existingCenters)
	end

	if data.Credits < price then
		return false, "Crédits insuffisants (" .. tostring(price) .. "$ requis)."
	end

	data.Credits = data.Credits - price
	local newMachine = {
		Id = "m_" .. HttpService:GenerateGUID(false):sub(1, 8),
		Type = machineType,
		GridX = gridX,
		GridZ = gridZ,
		Rotation = rotation,
		Level = 1,
		PaidPrice = price,
		InputBuffer = {},
		OutputBuffer = {},
	}
	table.insert(data.Machines, newMachine)

	PlotService.SpawnMachineModel(plot.Index, tierCfg.Cells, newMachine)
	PlayerDataService.AdvanceContract(player, "BuildActions", 1)
	PlayerDataService.SyncToClient(player)
	return true, cfg.Name .. " placé !"
end

-- Rotation directe en 1 clic d'une machine ou d'un tapis déjà posé
function BuildService.RotateExistingMachine(player: Player, machineId: string)
	local data = PlayerDataService.GetData(player)
	local plot = PlotService.GetPlotByPlayer(player)
	if not data or not plot then return false, "Erreur de parcelle." end

	local tierCfg = PlotAndPrestigeConfig.PlotTiers[data.PlotTier] or PlotAndPrestigeConfig.PlotTiers[1]
	for _, m in ipairs(data.Machines) do
		if m.Id == machineId then
			m.Rotation = (m.Rotation + 90) % 360
			local model = plot.MachinesFolder:FindFirstChild(m.Id)
			if model then
				model:SetAttribute("Rotation", m.Rotation)
				local cf = PlotService.GridToWorldCFrame(plot.Index, tierCfg.Cells, m.GridX, m.GridZ, m.Rotation, m.Type)
				ModelFactory.PivotMachineModel(model, cf)
			end
			PlayerDataService.SyncToClient(player)
			return true, "Orientation tournée à 90° !"
		end
	end
	return false, "Machine introuvable."
end

-- Amélioration plafonnée au Niveau 3
function BuildService.UpgradeMachine(player: Player, machineId: string)
	local data = PlayerDataService.GetData(player)
	local plot = PlotService.GetPlotByPlayer(player)
	if not data or not plot then return false, "Erreur de parcelle." end

	for _, m in ipairs(data.Machines) do
		if m.Id == machineId then
			if m.Level >= PlotAndPrestigeConfig.MaxMachineLevel then
				return false, "Niveau maximum (3) atteint ! Construis des machines du palier supérieur."
			end
			local cost = MachineConfig.GetUpgradeCost(m.Type, m.Level)
			if data.Credits < cost then
				return false, "Il te faut " .. tostring(cost) .. "$ pour améliorer."
			end

			data.Credits = data.Credits - cost
			m.Level = m.Level + 1
			local model = plot.MachinesFolder:FindFirstChild(m.Id)
			if model then model:SetAttribute("Level", m.Level) end

			PlayerDataService.AdvanceContract(player, "BuildActions", 1)
			PlayerDataService.SyncToClient(player)
			return true, "Machine améliorée au Niveau " .. tostring(m.Level) .. " !"
		end
	end
	return false, "Machine introuvable."
end

function BuildService.MoveMachine(player: Player, machineId: string, newX: number, newZ: number, newRot: number)
	local data = PlayerDataService.GetData(player)
	local plot = PlotService.GetPlotByPlayer(player)
	if not data or not plot then return false, "Erreur de parcelle." end

	local tierCfg = PlotAndPrestigeConfig.PlotTiers[data.PlotTier] or PlotAndPrestigeConfig.PlotTiers[1]
	newX = math.floor(tonumber(newX) or 1)
	newZ = math.floor(tonumber(newZ) or 1)
	newRot = (math.floor((tonumber(newRot) or 0) / 90) * 90) % 360

	if newX < 1 or newX > tierCfg.Cells or newZ < 1 or newZ > tierCfg.Cells then
		return false, "Emplacement hors des limites de ta parcelle."
	end

	for _, other in ipairs(data.Machines) do
		if other.GridX == newX and other.GridZ == newZ and other.Id ~= machineId then
			return false, "Case déjà occupée."
		end
	end

	for _, m in ipairs(data.Machines) do
		if m.Id == machineId then
			m.GridX = newX
			m.GridZ = newZ
			m.Rotation = newRot
			local model = plot.MachinesFolder:FindFirstChild(m.Id)
			if model then
				model:SetAttribute("GridX", newX)
				model:SetAttribute("GridZ", newZ)
				model:SetAttribute("Rotation", newRot)
				local cf = PlotService.GridToWorldCFrame(plot.Index, tierCfg.Cells, newX, newZ, newRot, m.Type)
				ModelFactory.PivotMachineModel(model, cf)
			end
			PlayerDataService.SyncToClient(player)
			return true, "Machine déplacée !"
		end
	end
	return false, "Machine introuvable."
end

function BuildService.SellMachine(player: Player, machineId: string)
	local data = PlayerDataService.GetData(player)
	local plot = PlotService.GetPlotByPlayer(player)
	if not data or not plot then return false, "Erreur de parcelle." end

	for idx, m in ipairs(data.Machines) do
		if m.Id == machineId then
			local cfg = MachineConfig.Get(m.Type)
			local paid = m.PaidPrice or (cfg and cfg.Price or 0)
			local refund = math.floor(paid * 0.7)

			table.remove(data.Machines, idx)
			local model = plot.MachinesFolder:FindFirstChild(m.Id)
			if model then model:Destroy() end

			data.Credits = data.Credits + refund
			PlayerDataService.SyncToClient(player)
			return true, "Machine vendue (+" .. tostring(refund) .. "$)"
		end
	end
	return false, "Machine introuvable."
end

-- Agrandissement de la parcelle (6x6 -> 8x8 -> 10x10 -> 12x12 -> 16x16)
function BuildService.UpgradePlotTier(player: Player)
	local data = PlayerDataService.GetData(player)
	local plot = PlotService.GetPlotByPlayer(player)
	if not data or not plot then return false, "Erreur de parcelle." end

	local nextTier = data.PlotTier + 1
	local nextCfg = PlotAndPrestigeConfig.PlotTiers[nextTier]
	if not nextCfg then
		return false, "Ta parcelle a déjà atteint la taille maximale (16x16) !"
	end

	if data.Credits < nextCfg.Cost then
		return false, "Il te faut " .. tostring(nextCfg.Cost) .. "$ pour débloquer " .. nextCfg.Name .. "."
	end

	data.Credits = data.Credits - nextCfg.Cost
	data.PlotTier = nextTier
	PlotService.RebuildPlotModels(plot.Index, data)
	PlayerDataService.SyncToClient(player)
	return true, "Parcelle agrandie : " .. nextCfg.Name .. " débloqué !"
end

-- Système de Prestige (Rebirth)
function BuildService.TriggerPrestige(player: Player)
	local data = PlayerDataService.GetData(player)
	local plot = PlotService.GetPlotByPlayer(player)
	if not data or not plot then return false, "Erreur de parcelle." end

	local reqCost = PlotAndPrestigeConfig.GetPrestigeCost(data.Prestige)
	if data.Credits < reqCost then
		return false, "Il te faut " .. tostring(reqCost) .. "$ pour passer au Prestige " .. tostring(data.Prestige + 1) .. "."
	end

	data.Prestige = data.Prestige + 1
	data.Credits = PlotAndPrestigeConfig.StartingCredits
	data.PlotTier = 1
	data.Machines = {}

	plot.SignLabel.Text = "Usine de " .. player.Name .. " [Prestige " .. tostring(data.Prestige) .. "]"
	PlotService.RebuildPlotModels(plot.Index, data)
	PlayerDataService.SyncToClient(player)

	local mult = PlotAndPrestigeConfig.GetPrestigeMultiplier(data.Prestige)
	return true, "PRESTIGE " .. tostring(data.Prestige) .. " ATTEINT ! Tes ventes rapportent désormais x" .. tostring(mult) .. " de façon permanente !"
end

return BuildService