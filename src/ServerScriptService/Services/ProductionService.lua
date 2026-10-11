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

local TICK_INTERVAL = 0.5

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

local function getFirstItemInBuffers(m): string?
	for resId, qty in pairs(m.OutputBuffer) do
		if qty > 0 then return resId end
	end
	for resId, qty in pairs(m.InputBuffer) do
		if qty > 0 then return resId end
	end
	return nil
end

local function updateBillboard(plot, machineData, text: string, color: Color3)
	local model = plot.MachinesFolder:FindFirstChild(machineData.Id)
	if not model or not model.PrimaryPart then return end

	-- Mettre à jour l'attribut VisualItem pour l'affichage 3D du minerai sur le tapis
	model:SetAttribute("VisualItem", getFirstItemInBuffers(machineData) or "")

	local gui = model.PrimaryPart:FindFirstChild("StatusGui")
	if not gui then return end
	local bg = gui:FindFirstChild("Background")
	if not bg then return end

	local cfg = MachineConfig.Get(machineData.Type)
	local titleLbl = bg:FindFirstChild("TitleLabel")
	local statusLbl = bg:FindFirstChild("StatusLabel")
	if titleLbl and cfg then
		titleLbl.Text = cfg.IsBelt and cfg.Name or (cfg.Name .. " [Nv." .. tostring(machineData.Level) .. "]")
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
			energyProduced = energyProduced + (cfg.EnergyProduction * m.Level)
			energyConsumed = energyConsumed + cfg.EnergyConsumption
		end
	end

	if os.time() < ProductionService.GlobalBlackoutUntil then
		energyConsumed = math.ceil(energyConsumed * 1.5)
	end

	local hasEnoughEnergy = (energyProduced >= energyConsumed)
	local prestigeMult = PlotAndPrestigeConfig.GetPrestigeMultiplier(data.Prestige or 0)

	for _, m in ipairs(data.Machines) do
		local cfg = MachineConfig.Get(m.Type)
		if not cfg then continue end

		local chaos = plot.ActiveChaosEffects[m.Id]
		if chaos and os.time() >= chaos.ExpiresAt then
			plot.ActiveChaosEffects[m.Id] = nil
			chaos = nil
		end

		local speedMult = 1 + ((m.Level - 1) * 0.45)
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

		-- CAS 1 : Centre de Livraison
		if m.Type == "DeliveryCenter" then
			local totalEarned = 0
			for resId, qty in pairs(m.InputBuffer) do
				if qty > 0 then
					local itemCfg = ResourceConfig.Items[resId]
					local val = (itemCfg and itemCfg.Value or 5) * prestigeMult
					if activeEventId == "BullMarket" then val = val * 2 end
					totalEarned = totalEarned + (val * qty)
					m.InputBuffer[resId] = nil
				end
			end

			if totalEarned > 0 then
				if plot.CargoStolenByUserId then
					local thief = Players:GetPlayerByUserId(plot.CargoStolenByUserId)
					plot.CargoStolenByUserId = nil
					if thief then
						PlayerDataService.AddCredits(thief, totalEarned, true)
						PlayerDataService.Notify(thief, "Livraison piratée : +" .. tostring(totalEarned) .. "$ !", "Success")
						PlayerDataService.Notify(player, "Une vente de " .. tostring(totalEarned) .. "$ a été piratée !", "Warning")
					else
						PlayerDataService.AddCredits(player, totalEarned, true)
					end
				else
					PlayerDataService.AddCredits(player, totalEarned, true)
				end

				if activeEventId == "ChaosBounty" then
					data.ChaosTokens = data.ChaosTokens + 3
				end
				updateBillboard(plot, m, "Vendu +" .. tostring(totalEarned) .. "$", Color3.fromRGB(90, 255, 130))
			else
				updateBillboard(plot, m, "En attente (x" .. tostring(prestigeMult) .. ")", Color3.fromRGB(180, 225, 190))
			end
			continue
		end

		-- CAS 2 : Tapis roulants, virages 90°, jonctions et silos
		if cfg.IsBelt or m.Type == "Storage" then
			local maxCap = cfg.OutputCapacity * m.Level
			for resId, qty in pairs(m.InputBuffer) do
				if qty > 0 and countBuffer(m.OutputBuffer) < maxCap then
					local space = maxCap - countBuffer(m.OutputBuffer)
					local moveQty = math.min(qty, space)
					m.OutputBuffer[resId] = (m.OutputBuffer[resId] or 0) + moveQty
					m.InputBuffer[resId] = qty - moveQty
					if m.InputBuffer[resId] <= 0 then m.InputBuffer[resId] = nil end
				end
			end
		end

		-- CAS 3 : Machines à recettes (Mines, Raffineries et Forges d'Alliages)
		if cfg.Recipes then
			local maxOut = cfg.OutputCapacity * m.Level
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
					updateBillboard(plot, m, "En cours : " .. tostring(pct) .. "%", Color3.fromRGB(110, 240, 145))

					if m.Progress >= cfg.ProcessTime then
						m.Progress = 0
						local isCrafting = (next(matchedRecipe.Inputs) ~= nil)
						for reqItem, reqQty in pairs(matchedRecipe.Inputs) do
							m.InputBuffer[reqItem] = m.InputBuffer[reqItem] - reqQty
							if m.InputBuffer[reqItem] <= 0 then m.InputBuffer[reqItem] = nil end
						end
						for outItem, outQty in pairs(matchedRecipe.Outputs) do
							m.OutputBuffer[outItem] = (m.OutputBuffer[outItem] or 0) + outQty
						end
						if isCrafting then
							PlayerDataService.AdvanceContract(player, "CraftItems", 1)
						end
					end
				else
					m.Progress = 0
					updateBillboard(plot, m, "Attente ressource", Color3.fromRGB(235, 200, 90))
				end
			end
		elseif cfg.EnergyProduction > 0 then
			updateBillboard(plot, m, "+" .. tostring(cfg.EnergyProduction * m.Level) .. " Énergie", Color3.fromRGB(255, 230, 80))
		end

		-- 4. Transfert vers la case cible et déclenchement de l'animation 3D
		if countBuffer(m.OutputBuffer) > 0 then
			local baseRot = m.Rotation
			if chaos and chaos.EffectType == "Inverter" then
				baseRot = (baseRot + 180) % 360
			end

			local transferRate = (cfg.TransferRate or 2) * m.Level
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
						end
					end

					local dx, dz = getDirectionOffset(outRot)
					local targetMachine = gridMap[tostring(m.GridX + dx) .. "_" .. tostring(m.GridZ + dz)]

					if targetMachine then
						local targetCfg = MachineConfig.Get(targetMachine.Type)
						local targetMaxIn = targetCfg and (targetCfg.InputCapacity * targetMachine.Level) or 0
						local spaceLeft = targetMaxIn - countBuffer(targetMachine.InputBuffer)

						if spaceLeft > 0 then
							local moveAmt = math.min(qty, transferRate - transferred, spaceLeft)
							targetMachine.InputBuffer[resId] = (targetMachine.InputBuffer[resId] or 0) + moveAmt
							m.OutputBuffer[resId] = qty - moveAmt
							if m.OutputBuffer[resId] <= 0 then m.OutputBuffer[resId] = nil end
							transferred = transferred + moveAmt

							-- Signaler au client le glissement 3D de la ressource vers la machine cible
							local model = plot.MachinesFolder:FindFirstChild(m.Id)
							if model then
								model:SetAttribute("LastMovedItem", resId)
								model:SetAttribute("TargetMachineId", targetMachine.Id)
								model:SetAttribute("TransferSeq", (model:GetAttribute("TransferSeq") or 0) + 1)
							end

							if cfg.IsBelt then
								local rName = ResourceConfig.Items[resId] and ResourceConfig.Items[resId].Name or resId
								updateBillboard(plot, m, rName, Color3.fromRGB(135, 205, 255))
							end
						end
					end
				end
			end
		elseif cfg.IsBelt then
			updateBillboard(plot, m, "Vide", Color3.fromRGB(175, 185, 200))
		end
	end
end

return ProductionService