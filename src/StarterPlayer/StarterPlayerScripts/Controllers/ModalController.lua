-- StarterPlayer/StarterPlayerScripts/Controllers/ModalController.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ConfigFolder = ReplicatedStorage.Shared.Config
local PlotAndPrestigeConfig = require(ConfigFolder.PlotAndPrestigeConfig)
local MachineConfig = require(ConfigFolder.MachineConfig)
local ResourceConfig = require(ConfigFolder.ResourceConfig)
local ChaosAndEventsConfig = require(ConfigFolder.ChaosAndEventsConfig)

local UITheme = require(script.Parent.UITheme)
local BuildController = require(script.Parent.BuildController)

local ModalController = {}
ModalController.PlayerData = nil

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local modalFrame: Frame
local modalTitle: TextLabel
local contentScroll: ScrollingFrame

local SHOP_ORDER = {
	-- Extracteurs
	"IronExtractor", "GoldExtractor", "DiamondDrill", "TitaniumExcavator", "NuclearDrill",
	-- Raffineries
	"IndustrialFurnace", "HydraulicPress", "PlasmaArcFurnace", "ChemicalBath",
	"UltrasonicRefinery", "LaserCutter", "AcidEtcher", "GasCentrifuge", "CryoStabilizer",
	-- Alliages
	"AlloySmelter", "RoyalJeweler", "SynthesisChamber", "QuantumAssembler",
	-- Énergie & Spéciaux
	"ThermalGenerator", "FusionReactor", "Storage", "DeliveryCenter",
	-- Tapis & Virages 90°
	"Belt1_Straight", "Belt1_Left", "Belt1_Right",
	"Belt2_Straight", "Belt2_Left", "Belt2_Right",
	"Belt3_Straight", "Belt3_Left", "Belt3_Right",
	"Belt4_Straight", "Belt4_Left", "Belt4_Right",
	"Merger", "Sorter",
}

local function getResValue(resId: string): string
	local item = ResourceConfig.Items[resId]
	return item and (PlotAndPrestigeConfig.FormatMoney(item.Value) .. " $") or "? $"
end

local WIKI_ENTRIES = {
	{
		Category = "Filière de Base #1 — Fer",
		RequiredExtractors = { "IronExtractor" },
		Title = "Chaîne du Fer (Mine de Fer ➔ Four ➔ Presse)",
		Color = Color3.fromRGB(225, 110, 40),
		FlowFn = function()
			return "1. Mine de Fer (50$)  ➔  Minerai de Fer (" .. getResValue("IronOre") .. ")\n"
				.. "2. Four Industriel (150$)  ➔  Lingot de Fer (" .. getResValue("IronIngot") .. ")\n"
				.. "3. Presse Hydraulique (500$) [2 Lingots]  ➔  Bloc de Fer (" .. getResValue("IronBlock") .. ")"
		end,
	},
	{
		Category = "Filière de Base #2 — Or",
		RequiredExtractors = { "GoldExtractor" },
		Title = "Chaîne de l'Or (Mine d'Or ➔ Four ➔ Presse ➔ Bain Chimique)",
		Color = Color3.fromRGB(245, 190, 40),
		FlowFn = function()
			return "1. Mine d'Or (1500$)  ➔  Minerai d'Or (" .. getResValue("GoldOre") .. ")\n"
				.. "2. Four Industriel / Plasma  ➔  Lingot d'Or (" .. getResValue("GoldIngot") .. ")\n"
				.. "3. Presse Hydraulique [2 Lingots]  ➔  Bloc d'Or (" .. getResValue("GoldBlock") .. ")\n"
				.. "4. Bain Chimique (12K$) [Lingot ou Bloc]  ➔  Or Pur 24K (" .. getResValue("PureGold24K") .. ")"
		end,
	},
	{
		Category = "Filière de Base #3 — Diamant",
		RequiredExtractors = { "DiamondDrill" },
		Title = "Chaîne du Diamant (Foreuse ➔ Ultrasons ➔ Tailleuse Laser)",
		Color = Color3.fromRGB(65, 215, 255),
		FlowFn = function()
			return "1. Foreuse à Diamant (25K$)  ➔  Diamant Brut (" .. getResValue("RawDiamond") .. ")\n"
				.. "2. Purificateur Ultrasons (85K$)  ➔  Diamant Pur (" .. getResValue("CleanDiamond") .. ")\n"
				.. "3. Tailleuse Laser (280K$)  ➔  Diamant Taillé (" .. getResValue("CutDiamond") .. ")"
		end,
	},
	{
		Category = "Filière de Base #4 — Titane",
		RequiredExtractors = { "TitaniumExcavator" },
		Title = "Chaîne du Titane (Excavatrice ➔ Décapeur Acide ➔ Four à Plasma)",
		Color = Color3.fromRGB(180, 195, 220),
		FlowFn = function()
			return "1. Excavatrice Titane (500K$)  ➔  Titane Brut (" .. getResValue("RawTitanium") .. ")\n"
				.. "2. Décapeur Acide (1.8M$) [2 Bruts]  ➔  Éponge de Titane (" .. getResValue("TitaniumSponge") .. ")\n"
				.. "3. Four à Plasma (4500$) [1 Éponge]  ➔  Plaque de Titane (" .. getResValue("TitaniumPlate") .. ")"
		end,
	},
	{
		Category = "Filière de Base #5 — Uranium",
		RequiredExtractors = { "NuclearDrill" },
		Title = "Chaîne de l'Uranium (Foreuse Nucléaire ➔ Centrifugeuse ➔ Cryo)",
		Color = Color3.fromRGB(85, 245, 65),
		FlowFn = function()
			return "1. Foreuse Nucléaire (8M$)  ➔  Uranium Brut (" .. getResValue("RawUranium") .. ")\n"
				.. "2. Centrifugeuse Gaz (25M$) [2 Bruts]  ➔  Uranium Enrichi (" .. getResValue("EnrichedUranium") .. ")\n"
				.. "3. Stabilisateur Cryo (85M$) [2 Enrichis]  ➔  Cellule de Fusion (" .. getResValue("FusionCell") .. ")"
		end,
	},
	{
		Category = "Alliage Rang 1 (Fer + Or)",
		RequiredExtractors = { "IronExtractor", "GoldExtractor" },
		Title = "Fonderie d'Alliage (65K $)  ➔  Lingot d'Électrum",
		Color = Color3.fromRGB(255, 140, 40),
		FlowFn = function()
			return "Ingrédients : 1x Bloc de Fer (ou Lingot)  +  1x Or Pur 24K (ou Bloc/Lingot d'Or)\n"
				.. "Machine : Fonderie d'Alliage (Utilise une Jonction 3-en-1 pour relier les 2 lignes)\n"
				.. "Produit final : Lingot d'Électrum  —  Prix de vente : " .. getResValue("ElectrumIngot")
		end,
	},
	{
		Category = "Alliage Rang 2 (Fer + Or + Diamant)",
		RequiredExtractors = { "IronExtractor", "GoldExtractor", "DiamondDrill" },
		Title = "Joaillerie Impériale (1.2M $)  ➔  Relique Impériale",
		Color = Color3.fromRGB(185, 75, 245),
		FlowFn = function()
			return "Ingrédients : 1x Lingot d'Électrum (ou Or 24K)  +  1x Diamant Taillé\n"
				.. "Machine : Joaillerie Impériale (1.2M $ | ⚡180)\n"
				.. "Produit final : Relique Impériale  —  Prix de vente : " .. getResValue("ImperialRelic")
		end,
	},
	{
		Category = "Alliage Rang 3 (Titane + Diamant)",
		RequiredExtractors = { "TitaniumExcavator", "DiamondDrill" },
		Title = "Chambre de Synthèse (9.5M $)  ➔  Nanocomposite",
		Color = Color3.fromRGB(50, 230, 200),
		FlowFn = function()
			return "Ingrédients : 1x Plaque/Éponge de Titane  +  1x Diamant Taillé\n"
				.. "Machine : Chambre de Synthèse (9.5M $ | ⚡450)\n"
				.. "Produit final : Nanocomposite  —  Prix de vente : " .. getResValue("Nanocomposite")
		end,
	},
	{
		Category = "Alliage Ultime (Titane + Diamant + Uranium)",
		RequiredExtractors = { "TitaniumExcavator", "DiamondDrill", "NuclearDrill" },
		Title = "Assembleur Quantique (350M $)  ➔  Cœur d'Antimatière",
		Color = Color3.fromRGB(255, 65, 200),
		FlowFn = function()
			return "Ingrédients : 1x Nanocomposite  +  1x Cellule de Fusion\n"
				.. "Machine : Assembleur Quantique (350M $ | ⚡2500)\n"
				.. "Produit final : Cœur d'Antimatière  —  Prix de vente : " .. getResValue("AntimatterCore")
		end,
	},
}

local function clearScroll()
	for _, child in ipairs(contentScroll:GetChildren()) do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
end

function ModalController.Init(screenGui: ScreenGui)
	modalFrame = Instance.new("Frame")
	modalFrame.Size = UDim2.new(0, 660, 0, 420)
	modalFrame.Position = UDim2.new(0.5, -330, 0.5, -200)
	UITheme.StyleFrame(modalFrame, Color3.fromRGB(18, 23, 34), 12)
	modalFrame.Visible = false
	modalFrame.Parent = screenGui

	modalTitle = UITheme.CreateLabel(modalFrame, "Menu", UDim2.new(1, -60, 0, 42), UDim2.new(0, 16, 0, 4), Color3.new(1, 1, 1), 18, true)

	local closeBtn = UITheme.CreateButton(modalFrame, "X", UDim2.new(0, 34, 0, 34), UDim2.new(1, -42, 0, 8), Color3.fromRGB(205, 60, 60), 16)
	closeBtn.Activated:Connect(function()
		modalFrame.Visible = false
	end)

	contentScroll = Instance.new("ScrollingFrame")
	contentScroll.Size = UDim2.new(1, -24, 1, -62)
	contentScroll.Position = UDim2.new(0, 12, 0, 50)
	contentScroll.BackgroundTransparency = 1
	contentScroll.BorderSizePixel = 0
	contentScroll.ScrollBarThickness = 6
	contentScroll.Parent = modalFrame

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = contentScroll
end

function ModalController.OpenShop(categoryFilter: string?)
	clearScroll()
	modalTitle.Text = (categoryFilter == "Belts") and "Catalogue des Tapis, Virages 90° & Répartiteurs" or "Catalogue des Machines (Consulte le 📘 Wiki pour les schémas)"

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
			local price = (id == "DeliveryCenter") and PlotAndPrestigeConfig.GetDeliveryCenterCost(existingCenters) or (cfg.Cost or 0)

			local card = Instance.new("Frame")
			card.Size = UDim2.new(1, -12, 0, 58)
			card.LayoutOrder = count
			UITheme.StyleFrame(card, Color3.fromRGB(30, 36, 52), 8)
			card.Parent = contentScroll

			local priceText = (price == 0) and "GRATUIT (1er)" or (PlotAndPrestigeConfig.FormatMoney(price) .. " $")
			UITheme.CreateLabel(card, cfg.Name .. "  —  " .. priceText, UDim2.new(0.72, 0, 0.5, 0), UDim2.new(0, 12, 0, 4), Color3.new(1, 1, 1), 15, true)
			UITheme.CreateLabel(card, cfg.Description or "", UDim2.new(0.72, 0, 0.45, 0), UDim2.new(0, 12, 0.5, 0), Color3.fromRGB(185, 195, 215), 12, true)

			local buyBtn = UITheme.CreateButton(card, "Poser", UDim2.new(0.22, 0, 0.72, 0), UDim2.new(0.76, 0, 0.14, 0), Color3.fromRGB(45, 175, 95), 14)
			buyBtn.Activated:Connect(function()
				modalFrame.Visible = false
				BuildController.StartPlaceMode(id)
			end)
		end
	end
	contentScroll.CanvasSize = UDim2.new(0, 0, 0, count * 66)
	modalFrame.Visible = true
end

function ModalController.OpenWiki()
	clearScroll()
	modalTitle.Text = "📘 Wiki de l'Usine — Schémas & Prix (Débloqués par tes Mines)"

	local data = ModalController.PlayerData
	local unlocked = {}

	if data then
		if data.UnlockedExtractors then
			for k, v in pairs(data.UnlockedExtractors) do
				if v then unlocked[k] = true end
			end
		end
		if data.Machines then
			for _, m in ipairs(data.Machines) do
				local cfg = MachineConfig.Get(m.Type)
				if cfg and cfg.Category == "Extractors" then
					unlocked[m.Type] = true
				end
			end
		end
	end

	for i, entry in ipairs(WIKI_ENTRIES) do
		local isUnlocked = true
		local missingNames = {}

		for _, reqId in ipairs(entry.RequiredExtractors) do
			if not unlocked[reqId] then
				isUnlocked = false
				local reqCfg = MachineConfig.Get(reqId)
				table.insert(missingNames, reqCfg and reqCfg.Name or reqId)
			end
		end

		local card = Instance.new("Frame")
		card.Size = UDim2.new(1, -12, 0, isUnlocked and 92 or 58)
		card.LayoutOrder = i
		UITheme.StyleFrame(card, isUnlocked and Color3.fromRGB(28, 35, 52) or Color3.fromRGB(22, 24, 32), 8)
		card.Parent = contentScroll

		if isUnlocked then
			UITheme.CreateLabel(
				card,
				"🔓 [" .. entry.Category .. "]  " .. entry.Title,
				UDim2.new(1, -24, 0, 24),
				UDim2.new(0, 12, 0, 4),
				entry.Color,
				15,
				true
			)
			local flowLbl = UITheme.CreateLabel(
				card,
				entry.FlowFn(),
				UDim2.new(1, -24, 0, 60),
				UDim2.new(0, 12, 0, 28),
				Color3.fromRGB(220, 230, 245),
				12,
				true
			)
			flowLbl.TextWrapped = true
		else
			UITheme.CreateLabel(
				card,
				"🔒 [" .. entry.Category .. "]  —  Schéma & Prix Verrouillés (???)",
				UDim2.new(1, -24, 0, 24),
				UDim2.new(0, 12, 0, 6),
				Color3.fromRGB(150, 155, 170),
				14,
				true
			)
			UITheme.CreateLabel(
				card,
				"Condition : Pose " .. table.concat(missingNames, " + ") .. " sur ta parcelle pour débloquer cette page.",
				UDim2.new(1, -24, 0, 22),
				UDim2.new(0, 12, 0, 30),
				Color3.fromRGB(235, 110, 95),
				12,
				true
			)
		end
	end

	contentScroll.CanvasSize = UDim2.new(0, 0, 0, #WIKI_ENTRIES * 100)
	modalFrame.Visible = true
end

function ModalController.OpenPlotAndPrestige()
	clearScroll()
	modalTitle.Text = "Agrandissement du Terrain & Prestige Infini"

	local data = ModalController.PlayerData
	local currentTier = (data and data.PlotTier) or 1
	local currentPrestige = (data and data.Prestige) or 0

	local nextTierCfg = PlotAndPrestigeConfig.PlotTiers[currentTier + 1]
	local plotCard = Instance.new("Frame")
	plotCard.Size = UDim2.new(1, -12, 0, 82)
	UITheme.StyleFrame(plotCard, Color3.fromRGB(30, 36, 52), 8)
	plotCard.Parent = contentScroll

	if nextTierCfg then
		local plotCostStr = PlotAndPrestigeConfig.FormatMoney(nextTierCfg.Cost)
		UITheme.CreateLabel(plotCard, "Prochaine Extension : " .. nextTierCfg.Name .. " (" .. plotCostStr .. " $)", UDim2.new(0.68, 0, 0.45, 0), UDim2.new(0, 12, 0, 8), Color3.fromRGB(255, 215, 70), 16, true)
		UITheme.CreateLabel(plotCard, "Débloque une grille de " .. tostring(nextTierCfg.Cells) .. "x" .. tostring(nextTierCfg.Cells) .. " cases (" .. tostring(nextTierCfg.MaxMachines) .. " machines max).", UDim2.new(0.68, 0, 0.4, 0), UDim2.new(0, 12, 0, 42), Color3.fromRGB(190, 200, 220), 13, true)

		local upPlotBtn = UITheme.CreateButton(plotCard, "Agrandir", UDim2.new(0.25, 0, 0, 44), UDim2.new(0.72, 0, 0, 19), Color3.fromRGB(45, 175, 95), 15)
		upPlotBtn.Activated:Connect(function()
			local r = remotes:FindFirstChild("UpgradePlot") or remotes:FindFirstChild("UpgradePlotTier")
			if r then r:FireServer() end
			modalFrame.Visible = false
		end)
	else
		UITheme.CreateLabel(plotCard, "Taille Maximale Atteinte (Méga-Usine 16x16)", UDim2.new(1, -24, 1, 0), UDim2.new(0, 12, 0, 0), Color3.fromRGB(95, 245, 130), 16, true)
	end

	local pCost = PlotAndPrestigeConfig.GetPrestigeCost(currentPrestige)
	local pCostFormatted = PlotAndPrestigeConfig.FormatMoney(pCost)
	local nextMult = PlotAndPrestigeConfig.GetPrestigeMultiplier(currentPrestige + 1)

	local pCard = Instance.new("Frame")
	pCard.Size = UDim2.new(1, -12, 0, 95)
	UITheme.StyleFrame(pCard, Color3.fromRGB(42, 28, 58), 8)
	pCard.Parent = contentScroll

	UITheme.CreateLabel(pCard, "Passer au Prestige " .. tostring(currentPrestige + 1) .. "  —  Coût : " .. pCostFormatted .. " $", UDim2.new(0.68, 0, 0.45, 0), UDim2.new(0, 12, 0, 8), Color3.fromRGB(255, 185, 65), 16, true)
	UITheme.CreateLabel(pCard, "Réinitialise ta parcelle mais multiplie tes ventes par x" .. tostring(nextMult) .. " à vie (le Wiki reste débloqué) !", UDim2.new(0.68, 0, 0.45, 0), UDim2.new(0, 12, 0, 44), Color3.fromRGB(220, 200, 240), 13, true)

	local pBtn = UITheme.CreateButton(pCard, "Prestige !", UDim2.new(0.25, 0, 0, 46), UDim2.new(0.72, 0, 0, 24), Color3.fromRGB(215, 135, 35), 15)
	pBtn.Activated:Connect(function()
		local r = remotes:FindFirstChild("TriggerPrestige") or remotes:FindFirstChild("Prestige")
		if r then r:FireServer() end
		modalFrame.Visible = false
	end)

	contentScroll.CanvasSize = UDim2.new(0, 0, 0, 200)
	modalFrame.Visible = true
end

function ModalController.OpenChaos()
	clearScroll()
	modalTitle.Text = "Actions de Sabotage & Chaos"

	local count = 0
	local actions = ChaosAndEventsConfig.ChaosActions or ChaosAndEventsConfig.Abilities or {}
	for id, act in pairs(actions) do
		count = count + 1
		local card = Instance.new("Frame")
		card.Size = UDim2.new(1, -12, 0, 64)
		UITheme.StyleFrame(card, Color3.fromRGB(48, 24, 42), 8)
		card.Parent = contentScroll

		local cost = act.Cost or act.TokenCost or 15
		UITheme.CreateLabel(card, (act.Name or id) .. "  —  " .. tostring(cost) .. " Chaos", UDim2.new(0.7, 0, 0.45, 0), UDim2.new(0, 12, 0, 6), Color3.fromRGB(255, 120, 195), 15, true)
		UITheme.CreateLabel(card, act.Description or "", UDim2.new(0.7, 0, 0.45, 0), UDim2.new(0, 12, 0, 32), Color3.fromRGB(225, 195, 215), 12, true)

		local cBtn = UITheme.CreateButton(card, "Activer", UDim2.new(0.24, 0, 0, 40), UDim2.new(0.74, 0, 0, 12), Color3.fromRGB(205, 50, 110), 14)
		cBtn.Activated:Connect(function()
			local r = remotes:FindFirstChild("TriggerChaos") or remotes:FindFirstChild("UseChaos") or remotes:FindFirstChild("ChaosAction")
			if r then r:FireServer(act.Id or id) end
			modalFrame.Visible = false
		end)
	end

	contentScroll.CanvasSize = UDim2.new(0, 0, 0, count * 72)
	modalFrame.Visible = true
end

return ModalController