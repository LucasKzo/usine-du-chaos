-- ServerScriptService/Services/ProductionService.lua
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ConfigFolder = ReplicatedStorage.Shared.Config
local PlotAndPrestigeConfig = require(ConfigFolder.PlotAndPrestigeConfig)
local ResourceConfig = require(ConfigFolder.ResourceConfig)
local MachineConfig = require(ConfigFolder.MachineConfig)

local PlayerDataService = require(script.Parent.PlayerDataService)
local PlotService = require(script.Parent.PlotService)

local ProductionService = {}
ProductionService.ActiveWorldEvent = nil
ProductionService.GlobalBlackoutUntil = 0

local TICK_INTERVAL = 0.25

local function getDirectionOffset(rotation: number): (number, number)
	local r = rotation % 360
	if r == 0 then return 0, -1
	elseif r == 90 then return 1, 0
	elseif r == 180 then return 0, 1
	else return -1, 0 end
end

local function countBuffer(buf: { [string]: number }): number
	local total = 0
	for _, qty in pairs(buf) do total = total + qty end
	return total
end

local function getFirstItem(buf: { [string]: number }): string
	for resId, qty in pairs(buf) do
		if qty > 0 then return resId end
	end
	return ""
end

-- Vérifie combien d'exemplaires de `resId` une machine cible peut encore accepter (évite qu'un seul ingrédient bloque une machine d'alliage !)
local function getAvailableSpaceForResource(targetMachine: any, targetCfg: any, resId: string, reservedTotal: number, reservedForRes: number): number
	if targetCfg.IsBelt then
		local currentTotal = countBuffer(targetMachine.InputBuffer) + countBuffer(targetMachine.OutputBuffer) + reservedTotal
		return math.max(0, 3 - currentTotal)
	elseif targetMachine.Type == "DeliveryCenter" or targetMachine.Type == "Storage" then
		local maxCap = (targetCfg.InputCapacity or 50) * (targetMachine.Level or 1)
		local currentTotal = countBuffer(targetMachine.InputBuffer) + reservedTotal
		return math.max(0, maxCap - currentTotal)
	elseif targetCfg.Recipes then
		local maxReq = 0
		for _, recipe in ipairs(targetCfg.Recipes) do
			local req = recipe.Inputs and recipe.Inputs[resId]
			if req and req > maxReq then
				maxReq = req
			end
		end
		-- Si la machine n'utilise pas cette ressource dans ses recettes, elle la refuse !
		if maxReq <= 0 then
			return 0
		end
		local maxPerIngredient = math.max(maxReq * 3, 4)
		local currentOfThisRes = (targetMachine.InputBuffer[resId] or 0) + reservedForRes
		return math.max(0, maxPerIngredient - currentOfThisRes)
	end
	return 0
end

local function updateBillboard(plot, machineData, text: string, color: Color3)
	local model = plot.MachinesFolder:FindFirstChild(machineData.Id)
	if not model or not model.PrimaryPart then return end

	local gui = model.PrimaryPart:FindFirstChild("StatusGui")
	if not gui then return end
	local bg = gui:FindFirstChild("Background")
	if not bg then return end

	local cfg = MachineConfig.Get(machineData.Type)
	local titleLbl = bg:FindFirstChild("TitleLabel")
	local statusLbl = bg:FindFirstChild("StatusLabel")
	if titleLbl and cfg then
		titleLbl.Text = cfg.IsBelt and cfg.Name or (cfg.Name .. " [Nv." .. tostring(machineData.Level or 1) .. "]")
	end
	if statusLbl then
		statusLbl.Text = text
		statusLbl.TextColor3 = color
	end
end

function ProductionService.Start()
	task.spawn(function()
		while true do
			task.wait(TICK_INTERVAL)
			local eventId = ProductionService.ActiveWorldEvent and ProductionService.ActiveWorldEvent.Id or nil
			for _, player in ipairs(Players:GetPlayers()) do
				local plot = PlotService.GetPlotByPlayer(player)
				local data = PlayerDataService.GetData(player)
				if plot and data then
					ProductionService.SimulatePlot(player, plot, data, TICK_INTERVAL, eventId)
				end
			end
		end
	end)
end

function ProductionService.SimulatePlot(player: Player, plot: any, data: any, dt: number, activeEventId: string?)
	local gridMap = {}
	local baseEnergy = (activeEventId == "GridStrain") and 10 or 20
	local energyProduced = baseEnergy
	local energyConsumed = 0

	for _, m in ipairs(data.Machines) do
		m.InputBuffer = m.InputBuffer or {}
		m.OutputBuffer = m.OutputBuffer or {}
		m.Progress = m.Progress or 0
		gridMap[tostring(m.GridX) .. "_" .. tostring(m.GridZ)] = m

		local cfg = MachineConfig.Get(m.Type)
		if cfg then
			energyProduced = energyProduced + (cfg.EnergyProduction * (m.Level or 1))
			energyConsumed = energyConsumed + cfg.EnergyConsumption
		end
	end

	if os.time() < ProductionService.GlobalBlackoutUntil then
		energyConsumed = math.ceil(energyConsumed * 1.5)
	end
	local hasEnoughEnergy = (energyProduced >= energyConsumed)
	local prestigeMult = PlotAndPrestigeConfig.GetPrestigeMultiplier(data.Prestige or 0)

	-- =========================================================================
	-- 1. VENTE AU CENTRE DE LIVRAISON (+50% par niveau + Event ChaosBounty + Piratage)
	-- =========================================================================
	for _, m in ipairs(data.Machines) do
		if m.Type == "DeliveryCenter" then
			local totalEarned = 0
			local totalSoldItems = 0
			local centerMult = 1 + (((m.Level or 1) - 1) * 0.50)

			for resId, qty in pairs(m.InputBuffer) do
				if qty > 0 then
					local itemCfg = ResourceConfig.Items[resId]
					local val = math.floor((itemCfg and itemCfg.Value or 5) * prestigeMult * centerMult)
					if activeEventId == "BullMarket" then val = val * 2 end
					totalEarned = totalEarned + (val * qty)
					totalSoldItems = totalSoldItems + qty
					m.InputBuffer[resId] = nil
				end
			end

			if totalEarned > 0 then
				-- CORRECTION : Créditer le Chaos AVANT AddCredits pour que SyncToClient mette à jour le HUD !
				if activeEventId == "ChaosBounty" then
					data.ChaosTokens = (data.ChaosTokens or 0) + (3 * totalSoldItems)
				end

				if plot.CargoStolenByUserId then
					local thief = Players:GetPlayerByUserId(plot.CargoStolenByUserId)
					plot.CargoStolenByUserId = nil
					if thief then
						PlayerDataService.AddCredits(thief, totalEarned, true)
						PlayerDataService.Notify(thief, "Livraison piratée : +" .. tostring(totalEarned) .. "$ !", "Success")
						PlayerDataService.Notify(player, "Une vente de " .. tostring(totalEarned) .. "$ a été piratée !", "Warning")
						PlayerDataService.SyncToClient(player)
					else
						PlayerDataService.AddCredits(player, totalEarned, true)
					end
				else
					PlayerDataService.AddCredits(player, totalEarned, true)
				end

				updateBillboard(plot, m, "Vendu +" .. tostring(totalEarned) .. "$", Color3.fromRGB(90, 255, 130))
			else
				updateBillboard(plot, m, "En attente (x" .. tostring(prestigeMult * centerMult) .. ")", Color3.fromRGB(180, 225, 190))
			end
		end
	end

	-- =========================================================================
	-- 2. TRANSFERT DES MINERAIS (Virages 90°, Trieur & Filtre de Recettes)
	-- =========================================================================
	local transfersToExecute = {}
	local reservedTotalOnTarget = {}
	local reservedPerResOnTarget = {}

	for _, m in ipairs(data.Machines) do
		local cfg = MachineConfig.Get(m.Type)
		if not cfg or countBuffer(m.OutputBuffer) <= 0 then continue end

		local chaos = plot.ActiveChaosEffects[m.Id]
		if chaos and os.time() >= chaos.ExpiresAt then
			plot.ActiveChaosEffects[m.Id] = nil
			chaos = nil
		end

		local baseRot = m.Rotation or 0
		if chaos and chaos.EffectType == "Inverter" then
			baseRot = (baseRot + 180) % 360
		end

		local transferRate = cfg.IsBelt and (cfg.TransferRate or 1) or ((cfg.TransferRate or 1) * (m.Level or 1))
		local transferred = 0

		for resId, qty in pairs(m.OutputBuffer) do
			if qty > 0 and transferred < transferRate then
				local outRot = baseRot
				if cfg.TurnType == "Left" then
					outRot = (baseRot - 90) % 360
				elseif cfg.TurnType == "Right" then
					outRot = (baseRot + 90) % 360
				elseif cfg.TurnType == "Sorter" then
					local itemInfo = ResourceConfig.Items[resId]
					if itemInfo and itemInfo.IsRaw then
						outRot = (baseRot + 90) % 360
					else
						-- Si une machine existe à gauche (-90°), le trieur envoie les produits raffinés à gauche, sinon tout droit
						local lx, lz = getDirectionOffset((baseRot - 90) % 360)
						if gridMap[tostring(m.GridX + lx) .. "_" .. tostring(m.GridZ + lz)] then
							outRot = (baseRot - 90) % 360
						end
					end
				end

				local dx, dz = getDirectionOffset(outRot)
				local targetMachine = gridMap[tostring(m.GridX + dx) .. "_" .. tostring(m.GridZ + dz)]

				if targetMachine then
					local targetCfg = MachineConfig.Get(targetMachine.Type)
					if targetCfg then
						local resKey = targetMachine.Id .. "_" .. resId
						local spaceLeft = getAvailableSpaceForResource(
							targetMachine,
							targetCfg,
							resId,
							reservedTotalOnTarget[targetMachine.Id] or 0,
							reservedPerResOnTarget[resKey] or 0
						)

						if spaceLeft > 0 then
							local moveAmt = math.min(qty, transferRate - transferred, spaceLeft)
							m.OutputBuffer[resId] = qty - moveAmt
							if m.OutputBuffer[resId] <= 0 then m.OutputBuffer[resId] = nil end
							transferred = transferred + moveAmt

							reservedTotalOnTarget[targetMachine.Id] = (reservedTotalOnTarget[targetMachine.Id] or 0) + moveAmt
							reservedPerResOnTarget[resKey] = (reservedPerResOnTarget[resKey] or 0) + moveAmt

							table.insert(transfersToExecute, {
								FromMachine = m,
								ToMachine = targetMachine,
								ResId = resId,
								Amount = moveAmt,
							})
						end
					end
				end
			end
		end
	end

	for _, tr in ipairs(transfersToExecute) do
		tr.ToMachine.InputBuffer[tr.ResId] = (tr.ToMachine.InputBuffer[tr.ResId] or 0) + tr.Amount
		local model = plot.MachinesFolder:FindFirstChild(tr.FromMachine.Id)
		if model then
			model:SetAttribute("LastMovedItem", tr.ResId)
			model:SetAttribute("TargetMachineId", tr.ToMachine.Id)
			model:SetAttribute("TransferSeq", (model:GetAttribute("TransferSeq") or 0) + 1)
		end
	end

	-- =========================================================================
	-- 3. AVANCÉE INTERNE DES TAPIS ET STOCKAGES
	-- =========================================================================
	for _, m in ipairs(data.Machines) do
		local cfg = MachineConfig.Get(m.Type)
		if cfg and (cfg.IsBelt or m.Type == "Storage") then
			local maxCap = cfg.IsBelt and 3 or (cfg.OutputCapacity * (m.Level or 1))
			for resId, qty in pairs(m.InputBuffer) do
				if qty > 0 and countBuffer(m.OutputBuffer) < maxCap then
					local space = maxCap - countBuffer(m.OutputBuffer)
					local moveQty = math.min(qty, space)
					m.OutputBuffer[resId] = (m.OutputBuffer[resId] or 0) + moveQty
					m.InputBuffer[resId] = qty - moveQty
					if m.InputBuffer[resId] <= 0 then m.InputBuffer[resId] = nil end
				end
			end
			if cfg.IsBelt then
				local model = plot.MachinesFolder:FindFirstChild(m.Id)
				if model then
					local held = getFirstItem(m.OutputBuffer)
					if held == "" then held = getFirstItem(m.InputBuffer) end
					model:SetAttribute("HeldItem", held)
				end
			end
		end
	end

	-- =========================================================================
	-- 4. FABRICATION (Mines, Raffineries, Alliages & Progression des Quêtes)
	-- =========================================================================
	local totalCraftedThisTick = 0

	for _, m in ipairs(data.Machines) do
		local cfg = MachineConfig.Get(m.Type)
		if not cfg or m.Type == "DeliveryCenter" or cfg.IsBelt or m.Type == "Storage" then continue end

		local chaos = plot.ActiveChaosEffects[m.Id]
		if chaos and os.time() >= chaos.ExpiresAt then
			plot.ActiveChaosEffects[m.Id] = nil
			chaos = nil
		end

		local speedMult = 1 + (((m.Level or 1) - 1) * 0.45)
		if activeEventId == "Overclock" then speedMult = speedMult * 2.0 end

		if chaos then
			if chaos.EffectType == "Jammer" then
				speedMult = speedMult * 0.4
			elseif chaos.EffectType == "Overload" then
				if (chaos.ExpiresAt - os.time()) > 10 then
					speedMult = speedMult * 2.0
				else
					updateBillboard(plot, m, "SURCHARGE (Arrêt)", Color3.fromRGB(255, 80, 80))
					continue
				end
			end
		end

		if cfg.EnergyConsumption > 0 and not hasEnoughEnergy then
			updateBillboard(plot, m, "Manque Énergie (" .. energyProduced .. "/" .. energyConsumed .. ")", Color3.fromRGB(255, 90, 70))
			continue
		end

		if cfg.Recipes then
			local maxOut = math.min(cfg.OutputCapacity * (m.Level or 1), 6)
			if countBuffer(m.OutputBuffer) >= maxOut then
				updateBillboard(plot, m, "Sortie pleine", Color3.fromRGB(255, 175, 60))
			else
				local matchedRecipe = nil
				for _, recipe in ipairs(cfg.Recipes) do
					local ok = true
					for reqItem, reqQty in pairs(recipe.Inputs) do
						if (m.InputBuffer[reqItem] or 0) < reqQty then
							ok = false
							break
						end
					end
					if ok then
						matchedRecipe = recipe
						break
					end
				end

				if matchedRecipe then
					m.Progress = m.Progress + (dt * speedMult)
					local pct = math.clamp(math.floor((m.Progress / cfg.ProcessTime) * 100), 0, 100)

					if m.Progress >= cfg.ProcessTime then
						m.Progress = 0
						updateBillboard(plot, m, "En cours : 100%", Color3.fromRGB(110, 240, 145))

						local isCrafting = (next(matchedRecipe.Inputs) ~= nil)
						for reqItem, reqQty in pairs(matchedRecipe.Inputs) do
							m.InputBuffer[reqItem] = m.InputBuffer[reqItem] - reqQty
							if m.InputBuffer[reqItem] <= 0 then m.InputBuffer[reqItem] = nil end
						end

						local producedCount = 0
						for outItem, outQty in pairs(matchedRecipe.Outputs) do
							m.OutputBuffer[outItem] = (m.OutputBuffer[outItem] or 0) + outQty
							producedCount = producedCount + outQty
						end

						if isCrafting then
							totalCraftedThisTick = totalCraftedThisTick + math.max(1, producedCount)
						end
					else
						updateBillboard(plot, m, "En cours : " .. tostring(pct) .. "%", Color3.fromRGB(110, 240, 145))
					end
				else
					m.Progress = 0
					updateBillboard(plot, m, "Attente ressource", Color3.fromRGB(235, 200, 90))
				end
			end
		elseif cfg.EnergyProduction > 0 then
			updateBillboard(plot, m, "+" .. tostring(cfg.EnergyProduction * (m.Level or 1)) .. " Énergie", Color3.fromRGB(255, 230, 80))
		end
	end

	-- CORRECTION QUÊTE : Avance le contrat CraftItems et synchronise immédiatement avec le client !
	if totalCraftedThisTick > 0 then
		PlayerDataService.AdvanceContract(player, "CraftItems", totalCraftedThisTick)
		PlayerDataService.SyncToClient(player)
	end
end

return ProductionService