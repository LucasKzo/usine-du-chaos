-- StarterPlayer/StarterPlayerScripts/Controllers/HUDController.lua
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlotAndPrestigeConfig = require(ReplicatedStorage.Shared.Config.PlotAndPrestigeConfig)
local MachineConfig = require(ReplicatedStorage.Shared.Config.MachineConfig)

local UITheme = require(script.Parent.UITheme)
local BuildController = require(script.Parent.BuildController)
local ModalController = require(script.Parent.ModalController)

local HUDController = {}

local localPlayer = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")

function HUDController.Init()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "UsineDuChaosHUD"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = localPlayer:WaitForChild("PlayerGui")

	ModalController.Init(screenGui)

	-- 1. Barre Supérieure (Crédits, Chaos, Prestige, Terrain)
	local topBar = Instance.new("Frame")
	topBar.Size = UDim2.new(0, 620, 0, 46)
	topBar.Position = UDim2.new(0.5, -310, 0, 10)
	UITheme.StyleFrame(topBar, Color3.fromRGB(16, 20, 30), 10)
	topBar.Parent = screenGui

	local creditsLbl = UITheme.CreateLabel(topBar, "Crédits : 500 $", UDim2.new(0.36, 0, 1, 0), UDim2.new(0, 0, 0, 0), Color3.fromRGB(90, 245, 130), 15)
	local chaosLbl = UITheme.CreateLabel(topBar, "Chaos : 25", UDim2.new(0.28, 0, 1, 0), UDim2.new(0.36, 0, 0, 0), Color3.fromRGB(255, 115, 200), 15)
	local prestigeLbl = UITheme.CreateLabel(topBar, "Prestige 0 (x1)", UDim2.new(0.36, 0, 1, 0), UDim2.new(0.64, 0, 0, 0), Color3.fromRGB(255, 215, 70), 15)

	-- 2. Bannière Contrat Infini & Événements Mondiaux
	local bannerLbl = UITheme.CreateLabel(screenGui, "Contrat #1 en cours...", UDim2.new(0, 620, 0, 30), UDim2.new(0.5, -310, 0, 62), Color3.fromRGB(230, 240, 255), 13)
	UITheme.StyleFrame(bannerLbl, Color3.fromRGB(30, 40, 62), 8)

	-- 3. Notification Toast
	local toastLbl = UITheme.CreateLabel(screenGui, "", UDim2.new(0, 480, 0, 36), UDim2.new(0.5, -240, 0, 98), Color3.new(1, 1, 1), 14)
	UITheme.StyleFrame(toastLbl, Color3.fromRGB(40, 155, 80), 8)
	toastLbl.Visible = false

	-- 4. Contrôles de Placement (Tourner / Quitter)
	local buildBar = Instance.new("Frame")
	buildBar.Size = UDim2.new(0, 360, 0, 44)
	buildBar.Position = UDim2.new(0.5, -180, 1, -120)
	UITheme.StyleFrame(buildBar, Color3.fromRGB(24, 28, 40), 8)
	buildBar.Visible = false
	buildBar.Parent = screenGui

	local rotPreviewBtn = UITheme.CreateButton(buildBar, "Tourner 90° (R)", UDim2.new(0.46, 0, 0.8, 0), UDim2.new(0.03, 0, 0.1, 0), Color3.fromRGB(55, 135, 225), 14)
	rotPreviewBtn.Activated:Connect(BuildController.RotatePreview)

	local cancelBuildBtn = UITheme.CreateButton(buildBar, "Fermer Mode (X)", UDim2.new(0.46, 0, 0.8, 0), UDim2.new(0.51, 0, 0.1, 0), Color3.fromRGB(210, 60, 60), 14)
	cancelBuildBtn.Activated:Connect(BuildController.CancelMode)

	BuildController.OnModeChanged = function(isActive: boolean)
		buildBar.Visible = isActive
	end

	-- 5. Inspecteur de Machine Posée (avec Rotation 90° en 1 clic !)
	local inspector = Instance.new("Frame")
	inspector.Size = UDim2.new(0, 290, 0, 215)
	inspector.Position = UDim2.new(1, -305, 0.5, -105)
	UITheme.StyleFrame(inspector, Color3.fromRGB(20, 25, 38), 10)
	inspector.Visible = false
	inspector.Parent = screenGui

	local inspTitle = UITheme.CreateLabel(inspector, "Machine", UDim2.new(1, -16, 0, 32), UDim2.new(0, 8, 0, 6), Color3.new(1, 1, 1), 15)
	local rotateNowBtn = UITheme.CreateButton(inspector, "Tourner le sens de 90°", UDim2.new(1, -20, 0, 34), UDim2.new(0, 10, 0, 42), Color3.fromRGB(235, 155, 40), 13)
	local upgradeBtn = UITheme.CreateButton(inspector, "Améliorer", UDim2.new(1, -20, 0, 34), UDim2.new(0, 10, 0, 82), Color3.fromRGB(45, 180, 95), 13)
	local moveBtn = UITheme.CreateButton(inspector, "Déplacer", UDim2.new(0.47, 0, 0, 32), UDim2.new(0, 10, 0, 122), Color3.fromRGB(55, 130, 215), 13)
	local sellBtn = UITheme.CreateButton(inspector, "Vendre", UDim2.new(0.47, 0, 0, 32), UDim2.new(0.5, 4, 0, 122), Color3.fromRGB(210, 65, 65), 13)
	local closeInspBtn = UITheme.CreateButton(inspector, "Fermer", UDim2.new(1, -20, 0, 28), UDim2.new(0, 10, 0, 162), Color3.fromRGB(60, 65, 80), 13)

	closeInspBtn.Activated:Connect(function() inspector.Visible = false end)

	local selId, selType, selRot = nil, nil, 0
	BuildController.OnMachineClicked = function(model: Model)
		selId = model:GetAttribute("MachineId")
		selType = model:GetAttribute("MachineType")
		selRot = model:GetAttribute("Rotation") or 0
		local lvl = model:GetAttribute("Level") or 1
		local cfg = MachineConfig.Get(selType)
		if not cfg then return end

		inspTitle.Text = cfg.Name .. " [Nv." .. tostring(lvl) .. "/3]"
		if lvl >= PlotAndPrestigeConfig.MaxMachineLevel then
			upgradeBtn.Text = "Niveau Max (3)"
		else
			local cost = MachineConfig.GetUpgradeCost(selType, lvl)
			upgradeBtn.Text = "Améliorer Nv." .. tostring(lvl + 1) .. " (" .. tostring(cost) .. "$)"
		end
		inspector.Visible = true
	end

	rotateNowBtn.Activated:Connect(function()
		if selId then remotes.RotateMachine:FireServer(selId) end
	end)

	upgradeBtn.Activated:Connect(function()
		if selId then
			remotes.UpgradeMachine:FireServer(selId)
			inspector.Visible = false
		end
	end)

	moveBtn.Activated:Connect(function()
		if selId and selType then
			BuildController.StartMoveMode(selId, selType, selRot)
			inspector.Visible = false
		end
	end)

	sellBtn.Activated:Connect(function()
		if selId then
			remotes.SellMachine:FireServer(selId)
			inspector.Visible = false
		end
	end)

	-- 6. Dock Inférieur (4 Boutons : Machines, Tapis 90°, Terrain/Prestige, Chaos)
	local dock = Instance.new("Frame")
	dock.Size = UDim2.new(0, 580, 0, 52)
	dock.Position = UDim2.new(0.5, -290, 1, -62)
	UITheme.StyleFrame(dock, Color3.fromRGB(16, 20, 30), 12)
	dock.Parent = screenGui

	UITheme.CreateButton(dock, "Machines", UDim2.new(0.23, 0, 0.78, 0), UDim2.new(0.015, 0, 0.11, 0), Color3.fromRGB(45, 175, 95), 14).Activated:Connect(function()
		ModalController.OpenShop("Machines")
	end)
	UITheme.CreateButton(dock, "Tapis & 90°", UDim2.new(0.23, 0, 0.78, 0), UDim2.new(0.26, 0, 0.11, 0), Color3.fromRGB(55, 135, 225), 14).Activated:Connect(function()
		ModalController.OpenShop("Belts")
	end)
	UITheme.CreateButton(dock, "Terrain & Prestige", UDim2.new(0.25, 0, 0.78, 0), UDim2.new(0.505, 0, 0.11, 0), Color3.fromRGB(220, 145, 35), 14).Activated:Connect(function()
		ModalController.OpenPlotAndPrestige()
	end)
	UITheme.CreateButton(dock, "Chaos", UDim2.new(0.21, 0, 0.78, 0), UDim2.new(0.77, 0, 0.11, 0), Color3.fromRGB(205, 55, 135), 14).Activated:Connect(function()
		ModalController.OpenChaos()
	end)

	-- 7. Synchronisation avec le serveur
	remotes.SyncPlayerData.OnClientEvent:Connect(function(data)
		ModalController.PlayerData = data
		creditsLbl.Text = "Crédits : " .. tostring(math.floor(data.Credits)) .. " $"
		chaosLbl.Text = "Chaos : " .. tostring(math.floor(data.ChaosTokens))
		local mult = PlotAndPrestigeConfig.GetPrestigeMultiplier(data.Prestige or 0)
		prestigeLbl.Text = "Prestige " .. tostring(data.Prestige) .. " (x" .. tostring(mult) .. ")"

		if data.ActiveContract then
			local c = data.ActiveContract
			bannerLbl.Text = c.Title .. " : " .. c.Description .. " (" .. tostring(c.Progress) .. "/" .. tostring(c.Target) .. ")"
		end
	end)

	remotes.Notification.OnClientEvent:Connect(function(msg: string, notifType: string)
		toastLbl.Text = msg
		toastLbl.BackgroundColor3 = (notifType == "Warning") and Color3.fromRGB(205, 65, 55)
			or (notifType == "Success" and Color3.fromRGB(40, 165, 85) or Color3.fromRGB(50, 115, 200))
		toastLbl.Visible = true
		task.delay(4, function()
			if toastLbl.Text == msg then toastLbl.Visible = false end
		end)
	end)

	remotes.WorldEventUpdate.OnClientEvent:Connect(function(ev)
		if ev then
			bannerLbl.BackgroundColor3 = Color3.fromRGB(175, 95, 25)
			bannerLbl.Text = "ÉVÉNEMENT MONDIAL : " .. ev.Name .. " — " .. ev.Description
		else
			bannerLbl.BackgroundColor3 = Color3.fromRGB(30, 40, 62)
		end
	end)
end

return HUDController