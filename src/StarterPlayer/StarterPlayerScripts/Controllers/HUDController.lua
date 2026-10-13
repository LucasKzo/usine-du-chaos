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
	screenGui.Name = "UsineChaosHUD"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = false
	screenGui.Parent = localPlayer:WaitForChild("PlayerGui")

	-- =========================================================================
	-- 1. BARRE DU HAUT (Crédits, Chaos, Prestige & Contrats)
	-- =========================================================================
	local topBar = Instance.new("Frame")
	topBar.Size = UDim2.new(0, 540, 0, 44)
	topBar.Position = UDim2.new(0.5, -270, 0, 8)
	UITheme.StyleFrame(topBar, Color3.fromRGB(16, 20, 30), 10)
	topBar.Parent = screenGui

	local creditsLbl = UITheme.CreateLabel(topBar, "Crédits : 500 $", UDim2.new(0.34, 0, 1, 0), UDim2.new(0, 14, 0, 0), Color3.fromRGB(95, 245, 130), 16, true)
	local chaosLbl = UITheme.CreateLabel(topBar, "Chaos : 25", UDim2.new(0.30, 0, 1, 0), UDim2.new(0.35, 0, 0, 0), Color3.fromRGB(255, 105, 180), 16, true)
	local prestigeLbl = UITheme.CreateLabel(topBar, "Prestige 0 (x1)", UDim2.new(0.34, -14, 1, 0), UDim2.new(0.66, 0, 0, 0), Color3.fromRGB(255, 210, 60), 16, true)

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

	-- =========================================================================
	-- 2. BARRE DE MODE CONSTRUCTION / DÉPLACEMENT (Tourner R / Fermer X)
	-- =========================================================================
	local modeBar = Instance.new("Frame")
	modeBar.Size = UDim2.new(0, 340, 0, 46)
	modeBar.Position = UDim2.new(0.5, -170, 1, -120)
	UITheme.StyleFrame(modeBar, Color3.fromRGB(22, 28, 42), 10)
	modeBar.Visible = false
	modeBar.Parent = screenGui

	local rotModeBtn = UITheme.CreateButton(modeBar, "Tourner 90° (R)", UDim2.new(0.46, 0, 0, 34), UDim2.new(0.03, 0, 0, 6), Color3.fromRGB(50, 130, 225), 14)
	local cancelModeBtn = UITheme.CreateButton(modeBar, "Fermer Mode (X)", UDim2.new(0.46, 0, 0, 34), UDim2.new(0.51, 0, 0, 6), Color3.fromRGB(215, 95, 45), 14)

	rotModeBtn.Activated:Connect(function()
		BuildController.RotatePreview()
	end)
	cancelModeBtn.Activated:Connect(function()
		BuildController.CancelMode()
	end)

	BuildController.OnModeChanged = function(isActive: boolean)
		modeBar.Visible = isActive
	end

	-- =========================================================================
	-- 3. MENU CONTEXTUEL QUAND ON CLIQUE SUR UNE MACHINE OU UN TAPIS POSÉ
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

		local maxLvl = cfg.MaxLevel or (cfg.IsBelt and 1 or PlotAndPrestigeConfig.MaxMachineLevel)
		local upCost = MachineConfig.GetUpgradeCost and MachineConfig.GetUpgradeCost(selType, lvl) or 0

		if cfg.IsBelt then
			selTitle.Text = cfg.Name .. "  —  Orientation : " .. tostring(selRot) .. "°"
			upBtn.Text = "Tapis (Sans Nv.)"
			upBtn.BackgroundColor3 = Color3.fromRGB(75, 80, 95)
			upBtn.Active = false
		else
			selTitle.Text = cfg.Name .. " [Nv." .. tostring(lvl) .. "/" .. tostring(maxLvl) .. "]"
			if lvl >= maxLvl then
				upBtn.Text = "Niveau Max (" .. tostring(maxLvl) .. ")"
				upBtn.BackgroundColor3 = Color3.fromRGB(75, 80, 95)
				upBtn.Active = false
			else
				upBtn.Text = "Améliorer (" .. tostring(upCost) .. "$)"
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
	-- 4. BARRE DU BAS (4 Boutons Principaux)
	-- =========================================================================
	local bottomBar = Instance.new("Frame")
	bottomBar.Size = UDim2.new(0, 560, 0, 54)
	bottomBar.Position = UDim2.new(0.5, -280, 1, -64)
	UITheme.StyleFrame(bottomBar, Color3.fromRGB(16, 20, 30), 12)
	bottomBar.Parent = screenGui

	ModalController.Init(screenGui)

	local btnMachines = UITheme.CreateButton(bottomBar, "Machines", UDim2.new(0.23, 0, 0, 40), UDim2.new(0.015, 0, 0, 7), Color3.fromRGB(40, 170, 95), 14)
	local btnBelts = UITheme.CreateButton(bottomBar, "Tapis & 90°", UDim2.new(0.23, 0, 0, 40), UDim2.new(0.26, 0, 0, 7), Color3.fromRGB(50, 130, 225), 14)
	local btnPlot = UITheme.CreateButton(bottomBar, "Terrain & Prestige", UDim2.new(0.25, 0, 0, 40), UDim2.new(0.505, 0, 0, 7), Color3.fromRGB(215, 145, 35), 14)
	local btnChaos = UITheme.CreateButton(bottomBar, "Chaos", UDim2.new(0.21, 0, 0, 40), UDim2.new(0.77, 0, 0, 7), Color3.fromRGB(205, 50, 110), 14)

	btnMachines.Activated:Connect(function()
		selFrame.Visible = false
		ModalController.OpenShop("Machines")
	end)
	btnBelts.Activated:Connect(function()
		selFrame.Visible = false
		ModalController.OpenShop("Belts")
	end)
	btnPlot.Activated:Connect(function()
		selFrame.Visible = false
		ModalController.OpenPlotAndPrestige()
	end)
	btnChaos.Activated:Connect(function()
		selFrame.Visible = false
		ModalController.OpenChaos()
	end)

	-- =========================================================================
	-- 5. SYNCHRONISATION SERVEUR -> CLIENT
	-- =========================================================================
	local syncRemote = remotes:FindFirstChild("SyncData") or remotes:FindFirstChild("SyncPlayerData")
	if syncRemote then
		syncRemote.OnClientEvent:Connect(function(data: any)
			if not data then return end
			ModalController.PlayerData = data
			creditsLbl.Text = "Crédits : " .. tostring(data.Credits or 0) .. " $"
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