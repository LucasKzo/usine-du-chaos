-- ServerScriptService/Services/ChaosAndEventService.lua
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ChaosAndEventsConfig = require(ReplicatedStorage.Shared.Config.ChaosAndEventsConfig)
local PlayerDataService = require(script.Parent.PlayerDataService)
local PlotService = require(script.Parent.PlotService)
local ProductionService = require(script.Parent.ProductionService)

local ChaosAndEventService = {}
ChaosAndEventService.Cooldowns = {}

function ChaosAndEventService.Init()
	task.spawn(function()
		while true do
			task.wait(75)
			local list = ChaosAndEventsConfig.WorldEvents
			local ev = list[math.random(1, #list)]
			ProductionService.ActiveWorldEvent = ev

			local remotes = ReplicatedStorage:FindFirstChild("Remotes")
			if remotes and remotes:FindFirstChild("WorldEventUpdate") then
				remotes.WorldEventUpdate:FireAllClients(ev)
			end

			task.delay(ev.Duration, function()
				ProductionService.ActiveWorldEvent = nil
				if remotes and remotes:FindFirstChild("WorldEventUpdate") then
					remotes.WorldEventUpdate:FireAllClients(nil)
				end
			end)
		end
	end)
end

function ChaosAndEventService.ActivateShield(player: Player)
	local data = PlayerDataService.GetData(player)
	if not data then return end
	local now = os.time()

	if now < (data.ShieldCooldownUntil or 0) then
		PlayerDataService.Notify(player, "Bouclier en recharge (" .. tostring(data.ShieldCooldownUntil - now) .. "s).", "Warning")
		return
	end
	if data.ChaosTokens < 15 then
		PlayerDataService.Notify(player, "15 Jetons de Chaos requis.", "Warning")
		return
	end

	data.ChaosTokens = data.ChaosTokens - 15
	data.ShieldUntil = now + 45
	data.ShieldCooldownUntil = now + 90

	local plot = PlotService.GetPlotByPlayer(player)
	if plot then
		plot.ActiveChaosEffects = {}
		plot.CargoStolenByUserId = nil
	end

	PlayerDataService.SyncToClient(player)
	PlayerDataService.Notify(player, "Bouclier activé (45s) ! Sabotages purgés.", "Success")
end

function ChaosAndEventService.UseGadget(attacker: Player, gadgetId: string, targetUserId: number)
	local attackerData = PlayerDataService.GetData(attacker)
	local gadget = ChaosAndEventsConfig.Gadgets[gadgetId]
	if not attackerData or not gadget then return end

	if attackerData.ChaosTokens < gadget.Cost then
		PlayerDataService.Notify(attacker, "Jetons de Chaos insuffisants (" .. tostring(gadget.Cost) .. " requis).", "Warning")
		return
	end

	local now = os.time()
	ChaosAndEventService.Cooldowns[attacker.UserId] = ChaosAndEventService.Cooldowns[attacker.UserId] or {}
	local cd = ChaosAndEventService.Cooldowns[attacker.UserId]
	if (cd[gadgetId] or 0) > now then
		PlayerDataService.Notify(attacker, gadget.Name .. " en recharge (" .. tostring(cd[gadgetId] - now) .. "s).", "Warning")
		return
	end

	if gadgetId == "Blackout" then
		attackerData.ChaosTokens = attackerData.ChaosTokens - gadget.Cost
		cd[gadgetId] = now + gadget.Cooldown
		ProductionService.GlobalBlackoutUntil = now + gadget.Duration
		PlayerDataService.SyncToClient(attacker)
		for _, p in ipairs(Players:GetPlayers()) do
			PlayerDataService.Notify(p, attacker.Name .. " a déclenché une PANNE GÉNÉRALE (" .. tostring(gadget.Duration) .. "s) !", "Warning")
		end
		return
	end

	local targetPlayer = Players:GetPlayerByUserId(tonumber(targetUserId) or 0)
	if not targetPlayer or targetPlayer == attacker then
		PlayerDataService.Notify(attacker, "Aucun adversaire disponible sur le serveur.", "Warning")
		return
	end

	local targetData = PlayerDataService.GetData(targetPlayer)
	local targetPlot = PlotService.GetPlotByPlayer(targetPlayer)
	if not targetData or not targetPlot or #targetData.Machines == 0 then
		PlayerDataService.Notify(attacker, "L'usine adverse est vide.", "Warning")
		return
	end

	if (targetData.ShieldUntil or 0) > now then
		PlayerDataService.Notify(attacker, targetPlayer.Name .. " est protégé par un Bouclier !", "Warning")
		return
	end

	attackerData.ChaosTokens = attackerData.ChaosTokens - gadget.Cost
	cd[gadgetId] = now + gadget.Cooldown

	if gadgetId == "CargoThief" then
		targetPlot.CargoStolenByUserId = attacker.UserId
	else
		local randMachine = targetData.Machines[math.random(1, #targetData.Machines)]
		targetPlot.ActiveChaosEffects[randMachine.Id] = {
			EffectType = gadgetId,
			ExpiresAt = now + gadget.Duration,
		}
	end

	PlayerDataService.SyncToClient(attacker)
	PlayerDataService.Notify(attacker, gadget.Name .. " lancé sur " .. targetPlayer.Name .. " !", "Success")
	PlayerDataService.Notify(targetPlayer, "ALERTE CHAOS : " .. attacker.Name .. " a utilisé [" .. gadget.Name .. "] sur ton usine !", "Warning")
end

return ChaosAndEventService