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

	if not cfg.IsBelt then
		local realMachineCount = 0
		for _, m in ipairs(data.Machines) do
			local mCfg = MachineConfig.Get(m.Type)
			if mCfg and not mCfg.IsBelt then
				realMachineCount = realMachineCount + 1
			end
		end

		if realMachineCount >= tierCfg.MaxMachines then
			PlayerDataService.Notify(player, "Limite de machines atteinte (" .. tierCfg.MaxMachines .. "). Agrandis ta parcelle !", "Warning")
			return false, "Limite de machines atteinte."
		end
	end

	for _, m in ipairs(data.Machines) do
		if m.GridX == gridX and m.GridZ == gridZ then
			return false, "Cette case est déjà occupée."
		end
	end

	local price = cfg.Cost or cfg.Price or 0
	if machineType == "DeliveryCenter" then
		local existingCenters = countDeliveryCenters(data.Machines)
		price = PlotAndPrestigeConfig.GetDeliveryCenterCost(existingCenters)
	end

	if data.Credits < price then
		PlayerDataService.Notify(player, "Crédits insuffisants (" .. tostring(price) .. "$ requis).", "Warning")
		return false, "Crédits insuffisants."
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

	-- DÉBLOCAGE WIKI : Si le joueur pose un extracteur, on débloque sa filière dans le Wiki !
	data.UnlockedExtractors = data.UnlockedExtractors or {}
	if cfg.Category == "Extractors" and not data.UnlockedExtractors[machineType] then
		data.UnlockedExtractors[machineType] = true
		PlayerDataService.Notify(player, "📘 Nouveau schéma débloqué dans le Wiki : " .. cfg.Name .. " !", "Success")
	end

	PlotService.SpawnMachineModel(plot.Index, tierCfg.Cells, newMachine)
	PlayerDataService.AdvanceContract(player, "BuildActions", 1)
	PlayerDataService.SyncToClient(player)
	return true, cfg.Name .. " placé !"
end

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
				local baseHeight = model.PrimaryPart and model.PrimaryPart.Size.Y or 0.3
				local cf = PlotService.GridToWorldCFrame(plot.Index, tierCfg.Cells, m.GridX, m.GridZ, m.Rotation, m.Type, baseHeight)
				ModelFactory.PivotMachineModel(model, cf)
			end
			PlayerDataService.SyncToClient(player)
			return true, "Orientation tournée à 90° !"
		end
	end
	return false, "Machine introuvable."
end

function BuildService.UpgradeMachine(player: Player, machineId: string)
	local data = PlayerDataService.GetData(player)
	local plot = PlotService.GetPlotByPlayer(player)
	if not data or not plot then return false, "Erreur de parcelle." end

	for _, m in ipairs(data.Machines) do
		if m.Id == machineId then
			local cfg = MachineConfig.Get(m.Type)
			if cfg and cfg.IsBelt then
				return false, "Les tapis n'ont pas de niveaux."
			end
			local maxLevel = (cfg and cfg.MaxLevel) or 3
			if m.Level >= maxLevel then
				return false, "Niveau maximum (" .. tostring(maxLevel) .. ") atteint !"
			end

			local cost = MachineConfig.GetUpgradeCost(m.Type, m.Level)
			if data.Credits < cost then
				PlayerDataService.Notify(player, "Il te faut " .. tostring(cost) .. "$ pour améliorer.", "Warning")
				return false, "Crédits insuffisants."
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
				local baseHeight = model.PrimaryPart and model.PrimaryPart.Size.Y or 0.3
				local cf = PlotService.GridToWorldCFrame(plot.Index, tierCfg.Cells, newX, newZ, newRot, m.Type, baseHeight)
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
			local paid = m.PaidPrice or (cfg and (cfg.Cost or cfg.Price) or 0)
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
		PlayerDataService.Notify(player, "Il te faut " .. tostring(nextCfg.Cost) .. "$ pour agrandir.", "Warning")
		return false, "Il te faut " .. tostring(nextCfg.Cost) .. "$."
	end

	data.Credits = data.Credits - nextCfg.Cost
	data.PlotTier = nextTier
	PlotService.RebuildPlotModels(plot.Index, data)
	PlayerDataService.SyncToClient(player)
	return true, "Parcelle agrandie : " .. nextCfg.Name .. " débloqué !"
end

function BuildService.TriggerPrestige(player: Player)
	local data = PlayerDataService.GetData(player)
	local plot = PlotService.GetPlotByPlayer(player)
	if not data or not plot then return false, "Erreur de parcelle." end

	local reqCost = PlotAndPrestigeConfig.GetPrestigeCost(data.Prestige)
	if data.Credits < reqCost then
		PlayerDataService.Notify(player, "Il te faut " .. tostring(reqCost) .. "$ pour le Prestige !", "Warning")
		return false, "Crédits insuffisants."
	end

	data.Prestige = data.Prestige + 1
	data.Credits = PlotAndPrestigeConfig.StartingCredits
	data.PlotTier = 1
	data.Machines = {}
	-- Si tu veux que le Wiki se réinitialise à chaque Prestige, décommente la ligne ci-dessous :
	-- data.UnlockedExtractors = {}

	plot.SignLabel.Text = "Usine de " .. player.Name .. " [Prestige " .. tostring(data.Prestige) .. "]"
	PlotService.RebuildPlotModels(plot.Index, data)
	PlayerDataService.SyncToClient(player)

	local mult = PlotAndPrestigeConfig.GetPrestigeMultiplier(data.Prestige)
	PlayerDataService.Notify(player, "🌟 PRESTIGE " .. tostring(data.Prestige) .. " ATTEINT ! Multiplicateur x" .. tostring(mult) .. " !", "Success")
	return true, "PRESTIGE " .. tostring(data.Prestige) .. " ATTEINT !"
end

return BuildService