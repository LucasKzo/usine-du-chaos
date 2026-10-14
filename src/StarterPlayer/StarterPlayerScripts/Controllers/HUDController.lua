-- StarterPlayer/StarterPlayerScripts/Controllers/HUDController.lua
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

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
	screenGui.Name = "UsineChaosHUD"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = false
	screenGui.Parent = localPlayer:WaitForChild("PlayerGui")

	-- =========================================================================
	-- 1. BARRE DU HAUT (Crédits formatés, ⚡ Énergie, Chaos, Prestige)
	-- =========================================================================
	local topBar = Instance.new("Frame")
	topBar.Size = UDim2.new(0, 680, 0, 44)
	topBar.Position = UDim2.new(0.5, -340, 0, 8)
	UITheme.StyleFrame(topBar, Color3.fromRGB(16, 20, 30), 10)
	topBar.Parent = screenGui

	local creditsLbl = UITheme.CreateLabel(topBar, "Crédits : 500 $", UDim2.new(0.26, 0, 1, 0), UDim2.new(0, 14, 0, 0), Color3.fromRGB(95, 245, 130), 15, true)
	local energyLbl = UITheme.CreateLabel(topBar, "⚡ Énergie : 0 / 20", UDim2.new(0.26, 0, 1, 0), UDim2.new(0.27, 0, 0, 0), Color3.fromRGB(110, 220, 255), 15, true)
	local chaosLbl = UITheme.CreateLabel(topBar, "Chaos : 25", UDim2.new(0.20, 0, 1, 0), UDim2.new(0.54, 0, 0, 0), Color3.fromRGB(255, 105, 180), 15, true)
	local prestigeLbl = UITheme.CreateLabel(topBar, "Prestige 0 (x1)", UDim2.new(0.25, -10, 1, 0), UDim2.new(0.75, 0, 0, 0), Color3.fromRGB(255, 210, 60), 15, true)

	local contractLbl = UITheme.CreateLabel(screenGui, "Contrat en cours...", UDim2.new(0, 560, 0, 22), UDim2.new(0.5, -280, 0, 56), Color3.fromRGB(185, 195, 215), 13, false)

	local eventBanner = Instance.new("Frame")
	eventBanner.Size = UDim2.new(0, 520, 0, 30)
	eventBanner.Position = UDim2.new(0.5, -260, 0, 82)
	UITheme.StyleFrame(eventBanner, Color3.fromRGB(60, 25, 90), 8)
	eventBanner.Visible = false
	eventBanner.Parent = screenGui

	local eventLbl = UITheme.CreateLabel(eventBanner, "", UDim2.new(1, -16, 1, 0), UDim2.new(0, 8, 0, 0), Color3.fromRGB(255, 230, 90), 13, false)

	local notifLbl = UITheme.CreateLabel(screenGui, "", UDim2.new(0, 480, 0, 28), UDim2.new(0.5, -240, 0, 118), Color3.fromRGB(80, 245, 130), 15, false)
	notifLbl.Visible = false

	task.spawn(function()
		while task.wait(0.3) do
			local idx = localPlayer:GetAttribute("PlotIndex")
			local plots = Workspace:FindFirstChild("Plots")
			local myPlot = (idx and plots) and plots:FindFirstChild("Plot_" .. tostring(idx))
			local basePart = myPlot and myPlot:FindFirstChild("PlotBase")
			if basePart then
				local prod = basePart:GetAttribute("EnergyProduced") or 20
				local cons = basePart:GetAttribute("EnergyConsumed") or 0
				energyLbl.Text = "⚡ Énergie : " .. tostring(cons) .. " / " .. tostring(prod)
				energyLbl.TextColor3 = (cons > prod) and Color3.fromRGB(255, 85, 85) or Color3.fromRGB(110, 220, 255)
			end
		end
	end)

	-- =========================================================================
	-- 2. BARRE DE MODE CONSTRUCTION / DÉPLACEMENT / BULLDOZER
	-- =========================================================================
	local modeBar = Instance.new("Frame")
	modeBar.Size = UDim2.new(0, 360, 0, 46)
	modeBar.Position = UDim2.new(0.5, -180, 1, -120)
	UITheme.StyleFrame(modeBar, Color3.fromRGB(22, 28, 42), 10)
	modeBar.Visible = false
	modeBar.Parent = screenGui

	local rotModeBtn = UITheme.CreateButton(modeBar, "Tourner 90° (R)", UDim2.new(0.46, 0, 0, 34), UDim2.new(0.03, 0, 0, 6), Color3.fromRGB(50, 130, 225), 14)
	local cancelModeBtn = UITheme.CreateButton(modeBar, "Quitter Mode (X)", UDim2.new(0.46, 0, 0, 34), UDim2.new(0.51, 0, 0, 6), Color3.fromRGB(215, 95, 45), 14)

	rotModeBtn.Activated:Connect(function()
		BuildController.RotatePreview()
	end)
	cancelModeBtn.Activated:Connect(function()
		BuildController.CancelMode()
	end)

	BuildController.OnModeChanged = function(isActive: boolean, modeName: string?)
		modeBar.Visible = isActive
		if modeName == "Demolish" then
			rotModeBtn.Visible = false
			cancelModeBtn.Size = UDim2.new(0.94, 0, 0, 34)
			cancelModeBtn.Position = UDim2.new(0.03, 0, 0, 6)
			cancelModeBtn.Text = "🗑️ Quitter Mode Bulldozer (X)"
		else
			rotModeBtn.Visible = true
			cancelModeBtn.Size = UDim2.new(0.46, 0, 0, 34)
			cancelModeBtn.Position = UDim2.new(0.51, 0, 0, 6)
			cancelModeBtn.Text = "Fermer Mode (X)"
		end
	end

	-- =========================================================================
	-- 3. MENU CONTEXTUEL
	-- =========================================================================
	local selFrame = Instance.new("Frame")
	selFrame.Size = UDim2.new(0, 480, 0, 84)
	selFrame.Position = UDim2.new(0.5, -240, 1, -155)
	UITheme.StyleFrame(selFrame, Color3.fromRGB(35, 42, 60), 10)
	selFrame.Visible = false
	selFrame.Parent = screenGui

	local selTitle = UITheme.CreateLabel(selFrame, "", UDim2.new(1, -48, 0, 26), UDim2.new(0, 12, 0, 6), Color3.fromRGB(255, 215, 70), 15, true)
	local closeSelBtn = UITheme.CreateButton(selFrame, "X", UDim2.new(0, 26, 0, 26), UDim2.new(1, -32, 0, 6), Color3.fromRGB(190, 55, 55), 13)
	closeSelBtn.Activated:Connect(function()
		selFrame.Visible = false
	end)

	local upBtn = UITheme.CreateButton(selFrame, "Améliorer", UDim2.new(0.23, 0, 0, 38), UDim2.new(0.02, 0, 0, 38), Color3.fromRGB(45, 175, 95), 13)
	local rotBtn = UITheme.CreateButton(selFrame, "Tourner 90°", UDim2.new(0.23, 0, 0, 38), UDim2.new(0.27, 0, 0, 38), Color3.fromRGB(55, 135, 225), 13)
	local moveBtn = UITheme.CreateButton(selFrame, "Déplacer", UDim2.new(0.23, 0, 0, 38), UDim2.new(0.52, 0, 0, 38), Color3.fromRGB(215, 145, 35), 13)
	local sellBtn = UITheme.CreateButton(selFrame, "Vendre (70%)", UDim2.new(0.23, 0, 0, 38), UDim2.new(0.77, 0, 0, 38), Color3.fromRGB(205, 60, 60), 13)

	local selId, selType, selRot = nil, nil, 0

	BuildController.OnMachineClicked = function(model: Model)
		selId = model:GetAttribute("MachineId")
		selType = model:GetAttribute("MachineType")
		selRot = model:GetAttribute("Rotation") or 0
		local lvl = model:GetAttribute("Level") or 1
		local cfg = MachineConfig.Get(selType)
		if not cfg then return end

		if cfg.IsBelt then
			selTitle.Text = cfg.Name .. "  —  Orientation : " .. tostring(selRot) .. "°"
			upBtn.Visible = false
			rotBtn.Size = UDim2.new(0.30, 0, 0, 38)
			rotBtn.Position = UDim2.new(0.02, 0, 0, 38)
			moveBtn.Size = UDim2.new(0.30, 0, 0, 38)
			moveBtn.Position = UDim2.new(0.35, 0, 0, 38)
			sellBtn.Size = UDim2.new(0.30, 0, 0, 38)
			sellBtn.Position = UDim2.new(0.68, 0, 0, 38)
		else
			upBtn.Visible = true
			upBtn.Size = UDim2.new(0.23, 0, 0, 38)
			upBtn.Position = UDim2.new(0.02, 0, 0, 38)
			rotBtn.Size = UDim2.new(0.23, 0, 0, 38)
			rotBtn.Position = UDim2.new(0.27, 0, 0, 38)
			moveBtn.Size = UDim2.new(0.23, 0, 0, 38)
			moveBtn.Position = UDim2.new(0.52, 0, 0, 38)
			sellBtn.Size = UDim2.new(0.23, 0, 0, 38)
			sellBtn.Position = UDim2.new(0.77, 0, 0, 38)

			local maxLvl = cfg.MaxLevel or PlotAndPrestigeConfig.MaxMachineLevel
			local upCost = MachineConfig.GetUpgradeCost(selType, lvl)
			selTitle.Text = cfg.Name .. " [Nv." .. tostring(lvl) .. "/" .. tostring(maxLvl) .. "]"

			if lvl >= maxLvl then
				upBtn.Text = "Niveau Max (" .. tostring(maxLvl) .. ")"
				upBtn.BackgroundColor3 = Color3.fromRGB(75, 80, 95)
				upBtn.Active = false
			else
				upBtn.Text = "Améliorer (" .. PlotAndPrestigeConfig.FormatMoney(upCost) .. "$)"
				upBtn.BackgroundColor3 = Color3.fromRGB(45, 175, 95)
				upBtn.Active = true
			end
		end

		selFrame.Visible = true
	end

	upBtn.Activated:Connect(function()
		if selId and upBtn.Active then
			remotes.UpgradeMachine:FireServer(selId)
			selFrame.Visible = false
		end
	end)

	rotBtn.Activated:Connect(function()
		if selId then
			local rEvent = remotes:FindFirstChild("RotateMachine") or remotes:FindFirstChild("RotateExistingMachine")
			if rEvent then rEvent:FireServer(selId) end
			selFrame.Visible = false
		end
	end)

	moveBtn.Activated:Connect(function()
		if selId and selType then
			selFrame.Visible = false
			BuildController.StartMoveMode(selId, selType, selRot)
		end
	end)

	sellBtn.Activated:Connect(function()
		if selId then
			remotes.SellMachine:FireServer(selId)
			selFrame.Visible = false
		end
	end)

	-- =========================================================================
	-- 4. BARRE DU BAS (Machines, Tapis, 📘 Wiki, Terrain, Chaos, 🗑️ Bulldozer)
	-- =========================================================================
	local bottomBar = Instance.new("Frame")
	bottomBar.Size = UDim2.new(0, 740, 0, 54)
	bottomBar.Position = UDim2.new(0.5, -370, 1, -64)
	UITheme.StyleFrame(bottomBar, Color3.fromRGB(16, 20, 30), 12)
	bottomBar.Parent = screenGui

	ModalController.Init(screenGui)

	local btnMachines = UITheme.CreateButton(bottomBar, "Machines", UDim2.new(0.16, 0, 0, 40), UDim2.new(0.01, 0, 0, 7), Color3.fromRGB(40, 170, 95), 13)
	local btnBelts = UITheme.CreateButton(bottomBar, "Tapis & 90°", UDim2.new(0.16, 0, 0, 40), UDim2.new(0.18, 0, 0, 7), Color3.fromRGB(50, 130, 225), 13)
	local btnWiki = UITheme.CreateButton(bottomBar, "📘 Wiki", UDim2.new(0.14, 0, 0, 40), UDim2.new(0.35, 0, 0, 7), Color3.fromRGB(130, 85, 235), 13)
	local btnPlot = UITheme.CreateButton(bottomBar, "Terrain & Prestige", UDim2.new(0.19, 0, 0, 40), UDim2.new(0.50, 0, 0, 7), Color3.fromRGB(215, 145, 35), 13)
	local btnChaos = UITheme.CreateButton(bottomBar, "Chaos", UDim2.new(0.13, 0, 0, 40), UDim2.new(0.70, 0, 0, 7), Color3.fromRGB(205, 50, 110), 13)
	local btnBulldozer = UITheme.CreateButton(bottomBar, "🗑️ Bulldozer", UDim2.new(0.15, 0, 0, 40), UDim2.new(0.84, 0, 0, 7), Color3.fromRGB(195, 55, 55), 13)

	btnMachines.Activated:Connect(function()
		selFrame.Visible = false
		ModalController.OpenShop("Machines")
	end)
	btnBelts.Activated:Connect(function()
		selFrame.Visible = false
		ModalController.OpenShop("Belts")
	end)
	btnWiki.Activated:Connect(function()
		selFrame.Visible = false
		ModalController.OpenWiki()
	end)
	btnPlot.Activated:Connect(function()
		selFrame.Visible = false
		ModalController.OpenPlotAndPrestige()
	end)
	btnChaos.Activated:Connect(function()
		selFrame.Visible = false
		ModalController.OpenChaos()
	end)
	btnBulldozer.Activated:Connect(function()
		selFrame.Visible = false
		BuildController.StartDemolishMode()
	end)

	-- =========================================================================
	-- 5. SYNCHRONISATION SERVEUR -> CLIENT
	-- =========================================================================
	local syncRemote = remotes:FindFirstChild("SyncData") or remotes:FindFirstChild("SyncPlayerData")
	if syncRemote then
		syncRemote.OnClientEvent:Connect(function(data: any)
			if not data then return end
			ModalController.PlayerData = data
			creditsLbl.Text = "Crédits : " .. PlotAndPrestigeConfig.FormatMoney(data.Credits or 0) .. " $"
			chaosLbl.Text = "Chaos : " .. tostring(data.ChaosTokens or 0)
			local mult = PlotAndPrestigeConfig.GetPrestigeMultiplier(data.Prestige or 0)
			prestigeLbl.Text = "Prestige " .. tostring(data.Prestige or 0) .. " (x" .. tostring(mult) .. ")"

			if data.ActiveContract then
				contractLbl.Text = data.ActiveContract.Description .. " (" .. tostring(data.ActiveContract.Progress) .. "/" .. tostring(data.ActiveContract.Target) .. ")"
			else
				contractLbl.Text = "Tous les contrats sont terminés !"
			end
		end)
	end

	local notifRemote = remotes:FindFirstChild("Notify") or remotes:FindFirstChild("NotifyClient")
	if notifRemote then
		notifRemote.OnClientEvent:Connect(function(msg: string, notifType: string?)
			notifLbl.Text = tostring(msg or "")
			notifLbl.TextColor3 = (notifType == "Warning") and Color3.fromRGB(255, 95, 80) or Color3.fromRGB(80, 245, 130)
			notifLbl.Visible = true
			task.delay(3.5, function()
				if notifLbl.Text == msg then
					notifLbl.Visible = false
				end
			end)
		end)
	end

	local eventRemote = remotes:FindFirstChild("WorldEvent") or remotes:FindFirstChild("WorldEventUpdate")
	if eventRemote then
		eventRemote.OnClientEvent:Connect(function(eventData: any)
			if eventData and eventData.Name then
				eventLbl.Text = "⚡ ÉVÉNEMENT MONDIAL : " .. tostring(eventData.Name) .. " — " .. tostring(eventData.Description or "")
				eventBanner.Visible = true
			else
				eventBanner.Visible = false
			end
		end)
	end
end

return HUDController