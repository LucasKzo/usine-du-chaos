-- StarterPlayer/StarterPlayerScripts/Controllers/ModalController.lua
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ConfigFolder = ReplicatedStorage.Shared.Config
local PlotAndPrestigeConfig = require(ConfigFolder.PlotAndPrestigeConfig)
local MachineConfig = require(ConfigFolder.MachineConfig)
local ChaosAndEventsConfig = require(ConfigFolder.ChaosAndEventsConfig)

local UITheme = require(script.Parent.UITheme)
local BuildController = require(script.Parent.BuildController)

local ModalController = {}
ModalController.PlayerData = nil

local localPlayer = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local modalFrame, modalTitle, contentScroll

local SHOP_ORDER = {
	-- Logistique & Énergie
	"DeliveryCenter", "Storage", "ThermalGenerator", "FusionReactor",
	-- Tapis & Aiguillages
	"Belt1_Straight", "Belt1_Left", "Belt1_Right",
	"Belt2_Straight", "Belt2_Left", "Belt2_Right",
	"Belt3_Straight", "Belt3_Left", "Belt3_Right",
	"Belt4_Straight", "Merger", "Sorter",
	-- Palier I : Fer
	"IronExtractor", "IndustrialFurnace", "HydraulicPress",
	-- Palier II : Or & Électrum
	"GoldExtractor", "ChemicalBath", "AlloySmelter",
	-- Palier III : Diamant
	"DiamondDrill", "UltrasonicRefinery", "LaserCutter", "RoyalJeweler",
	-- Palier IV : Titane
	"TitaniumExcavator", "AcidEtcher", "PlasmaArcFurnace", "SynthesisChamber",
	-- Palier V : Uranium
	"NuclearDrill", "GasCentrifuge", "CryoStabilizer", "QuantumAssembler",
}

local function clearScroll()
	for _, child in ipairs(contentScroll:GetChildren()) do
		if not child:IsA("UIListLayout") then child:Destroy() end
	end
end

function ModalController.Init(screenGui: ScreenGui)
	modalFrame = Instance.new("Frame")
	modalFrame.Size = UDim2.new(0, 650, 0, 410)
	modalFrame.Position = UDim2.new(0.5, -325, 0.5, -195)
	UITheme.StyleFrame(modalFrame, Color3.fromRGB(18, 23, 34), 12)
	modalFrame.Visible = false
	modalFrame.Parent = screenGui

	modalTitle = UITheme.CreateLabel(modalFrame, "Menu", UDim2.new(1, -60, 0, 42), UDim2.new(0, 16, 0, 4), Color3.new(1, 1, 1), 18, true)

	local closeBtn = UITheme.CreateButton(modalFrame, "X", UDim2.new(0, 34, 0, 34), UDim2.new(1, -42, 0, 8), Color3.fromRGB(205, 60, 60), 16)
	closeBtn.Activated:Connect(function()
		modalFrame.Visible = false
	end)

	contentScroll = Instance.new("ScrollingFrame")
	contentScroll.Size = UDim2.new(1, -24, 1, -58)
	contentScroll.Position = UDim2.new(0, 12, 0, 48)
	contentScroll.BackgroundTransparency = 1
	contentScroll.ScrollBarThickness = 6
	contentScroll.Parent = modalFrame

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 8)
	layout.Parent = contentScroll
end

function ModalController.OpenShop(categoryFilter: string?)
    clearScroll()
    modalTitle.Text = (categoryFilter == "Belts") and "Catalogue des Tapis & Virages 90°" or "Catalogue des Machines (5 Minerais & Alliages)"

    local data = ModalController.PlayerData
    local existingCenters = 0
    if data and data.Machines then
        for _, m in ipairs(data.Machines) do
            if m.Type == "DeliveryCenter" then existingCenters = existingCenters + 1 end
        end
    end

    local count = 0
    for _, id in ipairs(SHOP_ORDER) do
        local cfg = MachineConfig.Get(id)
        if cfg and ((categoryFilter == "Belts" and cfg.IsBelt) or (categoryFilter ~= "Belts" and not cfg.IsBelt)) then
            count = count + 1
            -- Utilisation de cfg.Cost au lieu de cfg.Price
            local price = (id == "DeliveryCenter") and PlotAndPrestigeConfig.GetDeliveryCenterCost(existingCenters) or (cfg.Cost or 0)

            local card = Instance.new("Frame")
            card.Size = UDim2.new(1, -12, 0, 58)
            UITheme.StyleFrame(card, Color3.fromRGB(30, 36, 52), 8)
            card.Parent = contentScroll

            local priceText = (price == 0) and "GRATUIT (1er)" or (tostring(price) .. " $")
            UITheme.CreateLabel(card, cfg.Name .. "  —  " .. priceText, UDim2.new(0.7, 0, 0.5, 0), UDim2.new(0, 12, 0, 4), Color3.new(1, 1, 1), 15, true)
            
            -- Création d'une description dynamique pour éviter le crash (nil)
            local descText = ""
            if cfg.IsBelt then
                descText = "Vitesse : " .. tostring(cfg.TransferRate or 1) .. " case(s) / tick"
            elseif cfg.Category == "Extractors" then
                descText = "Extrait toutes les " .. tostring(cfg.ProcessTime) .. "s"
            elseif cfg.Category == "Refiners" or cfg.Category == "Alloys" then
                descText = "Temps de traitement : " .. tostring(cfg.ProcessTime) .. "s"
            elseif cfg.EnergyProduction and cfg.EnergyProduction > 0 then
                descText = "Produit +" .. tostring(cfg.EnergyProduction) .. " Énergie"
            elseif id == "DeliveryCenter" then
                descText = "Vend les ressources. Gain +50% par niveau."
            elseif id == "Storage" then
                descText = "Stocke jusqu'à " .. tostring(cfg.InputCapacity) .. " ressources."
            end

            UITheme.CreateLabel(card, descText, UDim2.new(0.7, 0, 0.45, 0), UDim2.new(0, 12, 0.5, 0), Color3.fromRGB(185, 195, 215), 12, true)

            local buyBtn = UITheme.CreateButton(card, "Poser", UDim2.new(0.24, 0, 0.72, 0), UDim2.new(0.74, 0, 0.14, 0), Color3.fromRGB(45, 175, 95), 14)
            buyBtn.Activated:Connect(function()
                modalFrame.Visible = false
                BuildController.StartPlaceMode(id)
            end)
        end
    end
    contentScroll.CanvasSize = UDim2.new(0, 0, 0, count * 66)
    modalFrame.Visible = true
end

function ModalController.OpenPlotAndPrestige()
	clearScroll()
	modalTitle.Text = "Agrandissement du Terrain & Prestige Infini"
	local data = ModalController.PlayerData
	if not data then return end

	-- Carte 1 : Agrandissement de la parcelle
	local currentTier = data.PlotTier or 1
	local nextTierCfg = PlotAndPrestigeConfig.PlotTiers[currentTier + 1]

	local plotCard = Instance.new("Frame")
	plotCard.Size = UDim2.new(1, -12, 0, 90)
	UITheme.StyleFrame(plotCard, Color3.fromRGB(28, 48, 72), 10)
	plotCard.Parent = contentScroll

	local curCfg = PlotAndPrestigeConfig.PlotTiers[currentTier]
	UITheme.CreateLabel(plotCard, "Taille actuelle : " .. curCfg.Name .. " (Max " .. curCfg.MaxMachines .. " machines)", UDim2.new(0.65, 0, 0.45, 0), UDim2.new(0, 14, 0, 8), Color3.new(1, 1, 1), 15, true)

	if nextTierCfg then
		UITheme.CreateLabel(plotCard, "Prochain palier : " .. nextTierCfg.Name .. " — Coût : " .. tostring(nextTierCfg.Cost) .. " $", UDim2.new(0.65, 0, 0.45, 0), UDim2.new(0, 14, 0.5, 0), Color3.fromRGB(140, 225, 255), 13, true)
		local upPlotBtn = UITheme.CreateButton(plotCard, "Agrandir Terrain", UDim2.new(0.28, 0, 0.65, 0), UDim2.new(0.69, 0, 0.18, 0), Color3.fromRGB(50, 150, 235), 14)
		upPlotBtn.Activated:Connect(function()
			remotes.UpgradePlotTier:FireServer()
			modalFrame.Visible = false
		end)
	else
		UITheme.CreateLabel(plotCard, "Taille maximale atteinte (16x16) !", UDim2.new(0.65, 0, 0.45, 0), UDim2.new(0, 14, 0.5, 0), Color3.fromRGB(110, 255, 150), 14, true)
	end

	-- Carte 2 : Prestige (Rebirth)
	local presCost = PlotAndPrestigeConfig.GetPrestigeCost(data.Prestige or 0)
	local curMult = PlotAndPrestigeConfig.GetPrestigeMultiplier(data.Prestige or 0)
	local nextMult = PlotAndPrestigeConfig.GetPrestigeMultiplier((data.Prestige or 0) + 1)

	local presCard = Instance.new("Frame")
	presCard.Size = UDim2.new(1, -12, 0, 105)
	UITheme.StyleFrame(presCard, Color3.fromRGB(58, 28, 68), 10)
	presCard.Parent = contentScroll

	UITheme.CreateLabel(presCard, "Prestige Actuel : " .. tostring(data.Prestige) .. " (Multiplicateur de vente : x" .. tostring(curMult) .. ")", UDim2.new(0.65, 0, 0.4, 0), UDim2.new(0, 14, 0, 8), Color3.fromRGB(255, 215, 75), 15, true)
	UITheme.CreateLabel(presCard, "Passer Prestige " .. tostring(data.Prestige + 1) .. " (Revenus x" .. tostring(nextMult) .. " permanent) — Requis : " .. tostring(presCost) .. " $", UDim2.new(0.65, 0, 0.5, 0), UDim2.new(0, 14, 0.45, 0), Color3.fromRGB(235, 190, 255), 12, true)

	local presBtn = UITheme.CreateButton(presCard, "Passer Prestige", UDim2.new(0.28, 0, 0.6, 0), UDim2.new(0.69, 0, 0.2, 0), Color3.fromRGB(215, 65, 160), 14)
	presBtn.Activated:Connect(function()
		remotes.TriggerPrestige:FireServer()
		modalFrame.Visible = false
	end)

	-- Carte 3 : Contrat Infini en cours
	if data.ActiveContract then
		local c = data.ActiveContract
		local cCard = Instance.new("Frame")
		cCard.Size = UDim2.new(1, -12, 0, 85)
		UITheme.StyleFrame(cCard, Color3.fromRGB(28, 60, 45), 10)
		cCard.Parent = contentScroll

		UITheme.CreateLabel(cCard, c.Title .. " : " .. c.Description, UDim2.new(0.95, 0, 0.45, 0), UDim2.new(0, 14, 0, 8), Color3.new(1, 1, 1), 14, true)
		UITheme.CreateLabel(cCard, "Progression : " .. tostring(c.Progress) .. " / " .. tostring(c.Target) .. "  |  Récompense : +" .. tostring(c.RewardCredits) .. "$ & +" .. tostring(c.RewardChaos) .. " Chaos", UDim2.new(0.95, 0, 0.45, 0), UDim2.new(0, 14, 0.5, 0), Color3.fromRGB(130, 255, 165), 13, true)
	end

	contentScroll.CanvasSize = UDim2.new(0, 0, 0, 320)
	modalFrame.Visible = true
end

function ModalController.OpenChaos()
	clearScroll()
	modalTitle.Text = "Gadgets de Chaos & Bouclier"

	local shieldCard = Instance.new("Frame")
	shieldCard.Size = UDim2.new(1, -12, 0, 54)
	UITheme.StyleFrame(shieldCard, Color3.fromRGB(28, 65, 95), 8)
	shieldCard.Parent = contentScroll

	UITheme.CreateLabel(shieldCard, "Bouclier Défensif (15 Chaos) : Purge et protège ton usine (45s)", UDim2.new(0.68, 0, 1, 0), UDim2.new(0, 12, 0, 0), Color3.fromRGB(140, 225, 255), 14, true)
	local sBtn = UITheme.CreateButton(shieldCard, "Activer", UDim2.new(0.24, 0, 0.72, 0), UDim2.new(0.74, 0, 0.14, 0), Color3.fromRGB(50, 160, 235), 13)
	sBtn.Activated:Connect(function()
		remotes.ActivateShield:FireServer()
	end)

	for gId, gCfg in pairs(ChaosAndEventsConfig.Gadgets) do
		local card = Instance.new("Frame")
		card.Size = UDim2.new(1, -12, 0, 56)
		UITheme.StyleFrame(card, Color3.fromRGB(45, 28, 52), 8)
		card.Parent = contentScroll

		UITheme.CreateLabel(card, gCfg.Name .. " — " .. tostring(gCfg.Cost) .. " Chaos", UDim2.new(0.68, 0, 0.5, 0), UDim2.new(0, 12, 0, 4), Color3.fromRGB(255, 165, 225), 14, true)
		UITheme.CreateLabel(card, gCfg.Description, UDim2.new(0.68, 0, 0.45, 0), UDim2.new(0, 12, 0.5, 0), Color3.fromRGB(220, 200, 230), 12, true)

		local useBtn = UITheme.CreateButton(card, "Lancer", UDim2.new(0.24, 0, 0.72, 0), UDim2.new(0.74, 0, 0.14, 0), Color3.fromRGB(205, 55, 135), 13)
		useBtn.Activated:Connect(function()
			local targetId = 0
			for _, p in ipairs(Players:GetPlayers()) do
				if p ~= localPlayer then targetId = p.UserId break end
			end
			remotes.UseChaosGadget:FireServer(gId, targetId)
		end)
	end
	contentScroll.CanvasSize = UDim2.new(0, 0, 0, 420)
	modalFrame.Visible = true
end

return ModalController