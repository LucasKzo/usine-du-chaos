-- ServerScriptService/Services/PlayerDataService.lua
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ConfigFolder = ReplicatedStorage.Shared.Config
local PlotAndPrestigeConfig = require(ConfigFolder.PlotAndPrestigeConfig)

local PlayerDataService = {}
PlayerDataService.Profiles = {}

local DATASTORE_NAME = "UsineDuChaos_Endless_v2"
local dataStore = nil
pcall(function()
	dataStore = DataStoreService:GetDataStore(DATASTORE_NAME)
end)

-- Génère un contrat infini adapté au numéro de contrat actuel
function PlayerDataService.GenerateContract(contractNumber: number)
	local scale = math.floor(1.55 ^ (contractNumber - 1))
	local mod = (contractNumber - 1) % 3

	if mod == 0 then
		local target = 150 * scale
		return {
			Number = contractNumber,
			Title = "Contrat Financier #" .. tostring(contractNumber),
			Description = "Gagner " .. tostring(target) .. " Crédits en vendant ta production",
			Type = "EarnCredits",
			Progress = 0,
			Target = target,
			RewardCredits = math.floor(target * 0.6),
			RewardChaos = 10 + (contractNumber * 2),
		}
	elseif mod == 1 then
		local target = 8 + (contractNumber * 4)
		return {
			Number = contractNumber,
			Title = "Cadence Industrielle #" .. tostring(contractNumber),
			Description = "Transformer ou raffiner " .. tostring(target) .. " ressources dans tes machines",
			Type = "CraftItems",
			Progress = 0,
			Target = target,
			RewardCredits = 200 * scale,
			RewardChaos = 12 + (contractNumber * 2),
		}
	else
		local target = 3 + math.min(20, contractNumber * 2)
		return {
			Number = contractNumber,
			Title = "Expansion Logistique #" .. tostring(contractNumber),
			Description = "Poser ou améliorer " .. tostring(target) .. " machines ou tapis",
			Type = "BuildActions",
			Progress = 0,
			Target = target,
			RewardCredits = 250 * scale,
			RewardChaos = 15 + (contractNumber * 2),
		}
	end
end

local function getDefaultData()
	return {
		SchemaVersion = 2,
		Credits = PlotAndPrestigeConfig.StartingCredits, -- 500$ au départ
		ChaosTokens = 25,
		Prestige = 0,
		PlotTier = 1, -- Démarre en 6x6 vide
		ContractNumber = 1,
		ActiveContract = PlayerDataService.GenerateContract(1),
		ShieldUntil = 0,
		ShieldCooldownUntil = 0,
		Machines = {}, -- Terrain 100% vierge au départ !
	}
end

function PlayerDataService.LoadProfile(player: Player)
	local key = "Player_" .. tostring(player.UserId)
	local loaded = nil
	if dataStore then
		pcall(function()
			loaded = dataStore:GetAsync(key)
		end)
	end

	local data = getDefaultData()
	if type(loaded) == "table" and loaded.SchemaVersion == 2 then
		for k, v in pairs(loaded) do
			data[k] = v
		end
	end

	PlayerDataService.Profiles[player.UserId] = { Data = data }

	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local credStat = Instance.new("IntValue")
	credStat.Name = "Crédits"
	credStat.Value = math.floor(data.Credits)
	credStat.Parent = leaderstats

	local presStat = Instance.new("IntValue")
	presStat.Name = "Prestige"
	presStat.Value = data.Prestige
	presStat.Parent = leaderstats

	return data
end

function PlayerDataService.SaveProfile(player: Player)
	local profile = PlayerDataService.Profiles[player.UserId]
	if not profile or not dataStore then return end
	local key = "Player_" .. tostring(player.UserId)
	pcall(function()
		dataStore:SetAsync(key, profile.Data)
	end)
end

function PlayerDataService.GetData(player: Player)
	local profile = PlayerDataService.Profiles[player.UserId]
	return profile and profile.Data or nil
end

function PlayerDataService.SyncToClient(player: Player)
	local data = PlayerDataService.GetData(player)
	if not data then return end

	local ls = player:FindFirstChild("leaderstats")
	if ls then
		if ls:FindFirstChild("Crédits") then ls["Crédits"].Value = math.floor(data.Credits) end
		if ls:FindFirstChild("Prestige") then ls["Prestige"].Value = data.Prestige end
	end

	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	if remotes and remotes:FindFirstChild("SyncPlayerData") then
		remotes.SyncPlayerData:FireClient(player, data)
	end
end

function PlayerDataService.AdvanceContract(player: Player, actionType: string, amount: number)
	local data = PlayerDataService.GetData(player)
	if not data or not data.ActiveContract then return end

	if data.ActiveContract.Type == actionType then
		data.ActiveContract.Progress = data.ActiveContract.Progress + amount
		if data.ActiveContract.Progress >= data.ActiveContract.Target then
			local rewardCr = data.ActiveContract.RewardCredits
			local rewardCh = data.ActiveContract.RewardChaos
			data.Credits = data.Credits + rewardCr
			data.ChaosTokens = data.ChaosTokens + rewardCh
			PlayerDataService.Notify(
				player,
				"Contrat #" .. tostring(data.ContractNumber) .. " terminé ! +" .. tostring(rewardCr) .. "$ & +" .. tostring(rewardCh) .. " Chaos",
				"Success"
			)
			data.ContractNumber = data.ContractNumber + 1
			data.ActiveContract = PlayerDataService.GenerateContract(data.ContractNumber)
		end
	end
end

function PlayerDataService.AddCredits(player: Player, amount: number, isSale: boolean?)
	local data = PlayerDataService.GetData(player)
	if not data then return end
	data.Credits = math.max(0, math.floor(data.Credits + amount))
	if isSale and amount > 0 then
		PlayerDataService.AdvanceContract(player, "EarnCredits", amount)
	end
	PlayerDataService.SyncToClient(player)
end

function PlayerDataService.Notify(player: Player, message: string, notifType: string?)
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	if remotes and remotes:FindFirstChild("Notification") then
		remotes.Notification:FireClient(player, message, notifType or "Info")
	end
end

return PlayerDataService