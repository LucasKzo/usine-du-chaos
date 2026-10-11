-- ServerScriptService/Bootstrap.server.lua
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remotes = ReplicatedStorage:FindFirstChild("Remotes") or Instance.new("Folder")
remotes.Name = "Remotes"
remotes.Parent = ReplicatedStorage

local remoteNames = {
	"PlaceMachine", "RotateMachine", "UpgradeMachine", "MoveMachine", "SellMachine",
	"UpgradePlotTier", "TriggerPrestige", "UseChaosGadget", "ActivateShield",
	"SyncPlayerData", "Notification", "WorldEventUpdate",
}
for _, name in ipairs(remoteNames) do
	if not remotes:FindFirstChild(name) then
		local re = Instance.new("RemoteEvent")
		re.Name = name
		re.Parent = remotes
	end
end

local Services = script.Parent:WaitForChild("Services")
local PlayerDataService = require(Services.PlayerDataService)
local PlotService = require(Services.PlotService)
local ProductionService = require(Services.ProductionService)
local BuildService = require(Services.BuildService)
local ChaosAndEventService = require(Services.ChaosAndEventService)

PlotService.Init()
ProductionService.Start()
ChaosAndEventService.Init()

remotes.PlaceMachine.OnServerEvent:Connect(function(player, mType, gx, gz, rot)
	local ok, msg = BuildService.PlaceMachine(player, tostring(mType), tonumber(gx), tonumber(gz), tonumber(rot))
	if msg then PlayerDataService.Notify(player, msg, ok and "Success" or "Warning") end
end)

remotes.RotateMachine.OnServerEvent:Connect(function(player, machineId)
	local ok, msg = BuildService.RotateExistingMachine(player, tostring(machineId))
	if msg then PlayerDataService.Notify(player, msg, ok and "Info" or "Warning") end
end)

remotes.UpgradeMachine.OnServerEvent:Connect(function(player, machineId)
	local ok, msg = BuildService.UpgradeMachine(player, tostring(machineId))
	if msg then PlayerDataService.Notify(player, msg, ok and "Success" or "Warning") end
end)

remotes.MoveMachine.OnServerEvent:Connect(function(player, machineId, gx, gz, rot)
	local ok, msg = BuildService.MoveMachine(player, tostring(machineId), tonumber(gx), tonumber(gz), tonumber(rot))
	if msg then PlayerDataService.Notify(player, msg, ok and "Info" or "Warning") end
end)

remotes.SellMachine.OnServerEvent:Connect(function(player, machineId)
	local ok, msg = BuildService.SellMachine(player, tostring(machineId))
	if msg then PlayerDataService.Notify(player, msg, ok and "Info" or "Warning") end
end)

remotes.UpgradePlotTier.OnServerEvent:Connect(function(player)
	local ok, msg = BuildService.UpgradePlotTier(player)
	if msg then PlayerDataService.Notify(player, msg, ok and "Success" or "Warning") end
end)

remotes.TriggerPrestige.OnServerEvent:Connect(function(player)
	local ok, msg = BuildService.TriggerPrestige(player)
	if msg then PlayerDataService.Notify(player, msg, ok and "Success" or "Warning") end
end)

remotes.UseChaosGadget.OnServerEvent:Connect(function(player, gadgetId, targetUserId)
	ChaosAndEventService.UseGadget(player, tostring(gadgetId), tonumber(targetUserId))
end)

remotes.ActivateShield.OnServerEvent:Connect(function(player)
	ChaosAndEventService.ActivateShield(player)
end)

local function onPlayerAdded(player: Player)
	local data = PlayerDataService.LoadProfile(player)
	PlotService.AssignPlot(player, data)
	task.wait(0.8)
	PlayerDataService.SyncToClient(player)
	PlayerDataService.Notify(
		player,
		"Bienvenue ! Ouvre la [Boutique] pour poser ton 1er Centre de Livraison GRATUIT, tes tapis et ta Mine de Fer.",
		"Success"
	)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(function(player)
	PlayerDataService.SaveProfile(player)
	PlotService.ReleasePlot(player)
	PlayerDataService.Profiles[player.UserId] = nil
end)

for _, p in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, p)
end