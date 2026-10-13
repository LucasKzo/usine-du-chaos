-- ReplicatedStorage/Shared/Config/MachineConfig.lua
local MachineConfig = {}

MachineConfig.Definitions = {
	-- ==========================================
	-- PALIERS D'EXTRACTION (MaxLevel = 3)
	-- ==========================================
	IronExtractor = {
		Name = "Mine de Fer", Category = "Extractors",
		InputCapacity = 0, OutputCapacity = 5,
		ProcessTime = 1.5, EnergyConsumption = 0, EnergyProduction = 0,
		Recipes = { { Inputs = {}, Outputs = { IronOre = 1 } } },
		Cost = 50, MaxLevel = 3, UpgradeCost = { 150, 600 },
		Color = Color3.fromRGB(225, 110, 40)
	},
	GoldExtractor = {
		Name = "Mine d'Or", Category = "Extractors",
		InputCapacity = 0, OutputCapacity = 5,
		ProcessTime = 2.0, EnergyConsumption = 5, EnergyProduction = 0,
		Recipes = { { Inputs = {}, Outputs = { GoldOre = 1 } } },
		Cost = 1500, MaxLevel = 3, UpgradeCost = { 4500, 15000 },
		Color = Color3.fromRGB(245, 190, 40)
	},
	DiamondDrill = {
		Name = "Foreuse à Diamant", Category = "Extractors",
		InputCapacity = 0, OutputCapacity = 5,
		ProcessTime = 3.0, EnergyConsumption = 25, EnergyProduction = 0,
		Recipes = { { Inputs = {}, Outputs = { RawDiamond = 1 } } },
		Cost = 25000, MaxLevel = 3, UpgradeCost = { 75000, 250000 },
		Color = Color3.fromRGB(65, 215, 255)
	},
	TitaniumExcavator = {
		Name = "Excavatrice Titane", Category = "Extractors",
		InputCapacity = 0, OutputCapacity = 5,
		ProcessTime = 4.0, EnergyConsumption = 120, EnergyProduction = 0,
		Recipes = { { Inputs = {}, Outputs = { RawTitanium = 1 } } },
		Cost = 500000, MaxLevel = 3, UpgradeCost = { 1500000, 5000000 },
		Color = Color3.fromRGB(180, 195, 220)
	},
	NuclearDrill = {
		Name = "Foreuse Nucléaire", Category = "Extractors",
		InputCapacity = 0, OutputCapacity = 5,
		ProcessTime = 6.0, EnergyConsumption = 500, EnergyProduction = 0,
		Recipes = { { Inputs = {}, Outputs = { RawUranium = 1 } } },
		Cost = 8000000, MaxLevel = 3, UpgradeCost = { 24000000, 75000000 },
		Color = Color3.fromRGB(85, 245, 65)
	},

	-- ==========================================
	-- MACHINES DE RAFFINAGE (MaxLevel = 3)
	-- ==========================================
	IndustrialFurnace = {
		Name = "Four Industriel", Category = "Refiners",
		InputCapacity = 6, OutputCapacity = 5,
		ProcessTime = 1.5, EnergyConsumption = 0, EnergyProduction = 0,
		Recipes = {
			{ Inputs = { IronOre = 1 }, Outputs = { IronIngot = 1 } },
			{ Inputs = { GoldOre = 1 }, Outputs = { GoldIngot = 1 } },
		},
		Cost = 150, MaxLevel = 3, UpgradeCost = { 450, 1200 },
		Color = Color3.fromRGB(200, 55, 40),
		Description = "Fond le Minerai de Fer ou d'Or en Lingots."
	},
	HydraulicPress = {
		Name = "Presse Hydraulique", Category = "Refiners",
		InputCapacity = 6, OutputCapacity = 5,
		ProcessTime = 2.0, EnergyConsumption = 0, EnergyProduction = 0,
		Recipes = {
			{ Inputs = { IronIngot = 2 }, Outputs = { IronBlock = 1 } },
			{ Inputs = { GoldIngot = 2 }, Outputs = { GoldBlock = 1 } },
		},
		Cost = 500, MaxLevel = 3, UpgradeCost = { 1500, 4500 },
		Color = Color3.fromRGB(45, 115, 210),
		Description = "Compresse 2 Lingots (Fer ou Or) en 1 Bloc."
	},
	ChemicalBath = {
		Name = "Bain Chimique", Category = "Refiners",
		InputCapacity = 6, OutputCapacity = 5,
		ProcessTime = 2.5, EnergyConsumption = 15, EnergyProduction = 0,
		Recipes = {
			{ Inputs = { GoldIngot = 1 }, Outputs = { PureGold24K = 1 } },
			{ Inputs = { GoldBlock = 1 }, Outputs = { PureGold24K = 2 } },
			{ Inputs = { GoldOre = 1 }, Outputs = { GoldIngot = 1 } },
		},
		Cost = 12000, MaxLevel = 3, UpgradeCost = { 35000, 95000 },
		Color = Color3.fromRGB(115, 230, 115),
		Description = "Raffine les Lingots/Blocs d'Or en Or Pur 24K."
	},
	UltrasonicRefinery = {
		Name = "Purificateur Ultrasons", Category = "Refiners",
		InputCapacity = 5, OutputCapacity = 5,
		ProcessTime = 3.0, EnergyConsumption = 40, EnergyProduction = 0,
		Recipes = { { Inputs = { RawDiamond = 1 }, Outputs = { CleanDiamond = 1 } } },
		Cost = 85000, MaxLevel = 3, UpgradeCost = { 250000, 800000 },
		Color = Color3.fromRGB(70, 165, 240),
		Description = "Nettoie le Diamant Brut en Diamant Pur."
	},
	LaserCutter = {
		Name = "Tailleuse Laser", Category = "Refiners",
		InputCapacity = 5, OutputCapacity = 5,
		ProcessTime = 3.5, EnergyConsumption = 65, EnergyProduction = 0,
		Recipes = { { Inputs = { CleanDiamond = 1 }, Outputs = { CutDiamond = 1 } } },
		Cost = 280000, MaxLevel = 3, UpgradeCost = { 850000, 2500000 },
		Color = Color3.fromRGB(230, 45, 130),
		Description = "Taille un Diamant Pur en Diamant Taillé."
	},
	AcidEtcher = {
		Name = "Décapeur Acide", Category = "Refiners",
		InputCapacity = 6, OutputCapacity = 5,
		ProcessTime = 4.0, EnergyConsumption = 150, EnergyProduction = 0,
		Recipes = { { Inputs = { RawTitanium = 2 }, Outputs = { TitaniumSponge = 1 } } },
		Cost = 1800000, MaxLevel = 3, UpgradeCost = { 5500000, 16000000 },
		Color = Color3.fromRGB(140, 245, 75),
		Description = "Transforme 2 Titanes Bruts en Éponge de Titane."
	},
	PlasmaArcFurnace = {
		Name = "Four à Plasma", Category = "Refiners",
		InputCapacity = 6, OutputCapacity = 5,
		ProcessTime = 2.0, EnergyConsumption = 10, EnergyProduction = 0,
		Recipes = {
			{ Inputs = { TitaniumSponge = 1 }, Outputs = { TitaniumPlate = 1 } },
			{ Inputs = { GoldOre = 1 }, Outputs = { GoldIngot = 1 } },
			{ Inputs = { IronOre = 1 }, Outputs = { IronIngot = 1 } },
		},
		Cost = 4500, MaxLevel = 3, UpgradeCost = { 12000, 35000 },
		Color = Color3.fromRGB(70, 95, 245),
		Description = "Fond l'Éponge de Titane en Plaque (ou le Minerai d'Or/Fer)."
	},
	GasCentrifuge = {
		Name = "Centrifugeuse Gaz", Category = "Refiners",
		InputCapacity = 6, OutputCapacity = 5,
		ProcessTime = 5.0, EnergyConsumption = 650, EnergyProduction = 0,
		Recipes = { { Inputs = { RawUranium = 2 }, Outputs = { EnrichedUranium = 1 } } },
		Cost = 25000000, MaxLevel = 3, UpgradeCost = { 75000000, 225000000 },
		Color = Color3.fromRGB(165, 255, 65),
		Description = "Enrichit 2 Uraniums Bruts en Uranium Enrichi."
	},
	CryoStabilizer = {
		Name = "Stabilisateur Cryo", Category = "Refiners",
		InputCapacity = 6, OutputCapacity = 5,
		ProcessTime = 6.0, EnergyConsumption = 1200, EnergyProduction = 0,
		Recipes = { { Inputs = { EnrichedUranium = 2 }, Outputs = { FusionCell = 1 } } },
		Cost = 85000000, MaxLevel = 3, UpgradeCost = { 250000000, 800000000 },
		Color = Color3.fromRGB(75, 205, 255),
		Description = "Condense 2 Uraniums Enrichis en Cellule de Fusion."
	},

	-- ==========================================
	-- MACHINES D'ALLIAGE (MaxLevel = 3)
	-- ==========================================
	AlloySmelter = {
		Name = "Fonderie d'Alliage", Category = "Alloys",
		InputCapacity = 10, OutputCapacity = 5,
		ProcessTime = 3.0, EnergyConsumption = 35, EnergyProduction = 0,
		Recipes = {
			{ Inputs = { IronBlock = 1, PureGold24K = 1 }, Outputs = { ElectrumIngot = 1 } },
			{ Inputs = { IronBlock = 1, GoldBlock = 1 }, Outputs = { ElectrumIngot = 1 } },
			{ Inputs = { IronIngot = 1, PureGold24K = 1 }, Outputs = { ElectrumIngot = 1 } },
			{ Inputs = { IronIngot = 1, GoldIngot = 1 }, Outputs = { ElectrumIngot = 1 } },
		},
		Cost = 65000, MaxLevel = 3, UpgradeCost = { 180000, 500000 },
		Color = Color3.fromRGB(255, 140, 40),
		Description = "Fusionne le Fer (Bloc/Lingot) et l'Or (24K/Bloc/Lingot) en Électrum."
	},
	RoyalJeweler = {
		Name = "Joaillerie Impériale", Category = "Alloys",
		InputCapacity = 10, OutputCapacity = 5,
		ProcessTime = 4.5, EnergyConsumption = 180, EnergyProduction = 0,
		Recipes = {
			{ Inputs = { ElectrumIngot = 1, CutDiamond = 1 }, Outputs = { ImperialRelic = 1 } },
			{ Inputs = { PureGold24K = 1, CutDiamond = 1 }, Outputs = { ImperialRelic = 1 } },
		},
		Cost = 1200000, MaxLevel = 3, UpgradeCost = { 3500000, 10000000 },
		Color = Color3.fromRGB(185, 75, 245),
		Description = "Assemble l'Électrum et le Diamant Taillé en Relique Impériale."
	},
	SynthesisChamber = {
		Name = "Chambre de Synthèse", Category = "Alloys",
		InputCapacity = 10, OutputCapacity = 5,
		ProcessTime = 5.5, EnergyConsumption = 450, EnergyProduction = 0,
		Recipes = {
			{ Inputs = { TitaniumPlate = 1, CutDiamond = 1 }, Outputs = { Nanocomposite = 1 } },
			{ Inputs = { TitaniumSponge = 1, CutDiamond = 1 }, Outputs = { Nanocomposite = 1 } },
		},
		Cost = 9500000, MaxLevel = 3, UpgradeCost = { 28000000, 85000000 },
		Color = Color3.fromRGB(50, 230, 200),
		Description = "Combine Titane (Plaque/Éponge) et Diamant Taillé en Nanocomposite."
	},
	QuantumAssembler = {
		Name = "Assembleur Quantique", Category = "Alloys",
		InputCapacity = 10, OutputCapacity = 5,
		ProcessTime = 8.0, EnergyConsumption = 2500, EnergyProduction = 0,
		Recipes = { { Inputs = { Nanocomposite = 1, FusionCell = 1 }, Outputs = { AntimatterCore = 1 } } },
		Cost = 350000000, MaxLevel = 3, UpgradeCost = { 950000000, 2800000000 },
		Color = Color3.fromRGB(255, 65, 200),
		Description = "Fusionne Nanocomposite et Cellule de Fusion en Cœur d'Antimatière."
	},

	-- ==========================================
	-- ÉNERGIE & VENTE (MaxLevel = 3)
	-- ==========================================
	ThermalGenerator = {
		Name = "Générateur Thermique", Category = "Energy",
		InputCapacity = 0, OutputCapacity = 0,
		ProcessTime = 1.0, EnergyConsumption = 0, EnergyProduction = 25,
		Cost = 2500, MaxLevel = 3, UpgradeCost = { 7500, 22000 },
		Color = Color3.fromRGB(250, 210, 45)
	},
	FusionReactor = {
		Name = "Réacteur à Fusion", Category = "Energy",
		InputCapacity = 0, OutputCapacity = 0,
		ProcessTime = 1.0, EnergyConsumption = 0, EnergyProduction = 1500,
		Cost = 4500000, MaxLevel = 3, UpgradeCost = { 15000000, 45000000 },
		Color = Color3.fromRGB(55, 230, 255)
	},
	DeliveryCenter = {
		Name = "Centre de Livraison", Category = "Specials",
		InputCapacity = 50, OutputCapacity = 0,
		ProcessTime = 1.0, EnergyConsumption = 0, EnergyProduction = 0,
		Cost = 0, MaxLevel = 3, UpgradeCost = { 15000, 75000 },
		Color = Color3.fromRGB(45, 240, 115)
	},
	Storage = {
		Name = "Silo de Stockage", Category = "Specials",
		InputCapacity = 100, OutputCapacity = 100,
		ProcessTime = 1.0, EnergyConsumption = 0, EnergyProduction = 0,
		Cost = 1500, MaxLevel = 3, UpgradeCost = { 4500, 12000 },
		Color = Color3.fromRGB(140, 105, 70)
	},

	-- ==========================================
	-- TAPIS ROULANTS (MaxLevel = 1)
	-- ==========================================
	Belt1_Straight = {
		Name = "Tapis Basique Droit", Category = "Belts", IsBelt = true,
		InputCapacity = 3, OutputCapacity = 3, TransferRate = 1,
		EnergyConsumption = 0, EnergyProduction = 0,
		Cost = 50, MaxLevel = 1, UpgradeCost = {}, Color = Color3.fromRGB(80, 85, 95), TurnType = "Straight"
	},
	Belt1_Left = {
		Name = "Tapis Basique Gauche", Category = "Belts", IsBelt = true,
		InputCapacity = 3, OutputCapacity = 3, TransferRate = 1,
		EnergyConsumption = 0, EnergyProduction = 0,
		Cost = 50, MaxLevel = 1, UpgradeCost = {}, Color = Color3.fromRGB(80, 85, 95), TurnType = "Left"
	},
	Belt1_Right = {
		Name = "Tapis Basique Droite", Category = "Belts", IsBelt = true,
		InputCapacity = 3, OutputCapacity = 3, TransferRate = 1,
		EnergyConsumption = 0, EnergyProduction = 0,
		Cost = 50, MaxLevel = 1, UpgradeCost = {}, Color = Color3.fromRGB(80, 85, 95), TurnType = "Right"
	},

	Belt2_Straight = {
		Name = "Tapis Rapide Droit", Category = "Belts", IsBelt = true,
		InputCapacity = 3, OutputCapacity = 3, TransferRate = 2,
		EnergyConsumption = 0, EnergyProduction = 0,
		Cost = 250, MaxLevel = 1, UpgradeCost = {}, Color = Color3.fromRGB(50, 130, 225), TurnType = "Straight"
	},
	Belt2_Left = {
		Name = "Tapis Rapide Gauche", Category = "Belts", IsBelt = true,
		InputCapacity = 3, OutputCapacity = 3, TransferRate = 2,
		EnergyConsumption = 0, EnergyProduction = 0,
		Cost = 250, MaxLevel = 1, UpgradeCost = {}, Color = Color3.fromRGB(50, 130, 225), TurnType = "Left"
	},
	Belt2_Right = {
		Name = "Tapis Rapide Droite", Category = "Belts", IsBelt = true,
		InputCapacity = 3, OutputCapacity = 3, TransferRate = 2,
		EnergyConsumption = 0, EnergyProduction = 0,
		Cost = 250, MaxLevel = 1, UpgradeCost = {}, Color = Color3.fromRGB(50, 130, 225), TurnType = "Right"
	},

	Belt3_Straight = {
		Name = "Tapis Express Droit", Category = "Belts", IsBelt = true,
		InputCapacity = 3, OutputCapacity = 3, TransferRate = 3,
		EnergyConsumption = 0, EnergyProduction = 0,
		Cost = 1500, MaxLevel = 1, UpgradeCost = {}, Color = Color3.fromRGB(240, 185, 45), TurnType = "Straight"
	},
	Belt3_Left = {
		Name = "Tapis Express Gauche", Category = "Belts", IsBelt = true,
		InputCapacity = 3, OutputCapacity = 3, TransferRate = 3,
		EnergyConsumption = 0, EnergyProduction = 0,
		Cost = 1500, MaxLevel = 1, UpgradeCost = {}, Color = Color3.fromRGB(240, 185, 45), TurnType = "Left"
	},
	Belt3_Right = {
		Name = "Tapis Express Droite", Category = "Belts", IsBelt = true,
		InputCapacity = 3, OutputCapacity = 3, TransferRate = 3,
		EnergyConsumption = 0, EnergyProduction = 0,
		Cost = 1500, MaxLevel = 1, UpgradeCost = {}, Color = Color3.fromRGB(240, 185, 45), TurnType = "Right"
	},

	Belt4_Straight = {
		Name = "Tapis Quantique Droit", Category = "Belts", IsBelt = true,
		InputCapacity = 3, OutputCapacity = 3, TransferRate = 5,
		EnergyConsumption = 0, EnergyProduction = 0,
		Cost = 12000, MaxLevel = 1, UpgradeCost = {}, Color = Color3.fromRGB(165, 65, 245), TurnType = "Straight"
	},

	Merger = {
		Name = "Jonction 3-en-1", Category = "Belts", IsBelt = true,
		InputCapacity = 3, OutputCapacity = 3, TransferRate = 2,
		EnergyConsumption = 0, EnergyProduction = 0,
		Cost = 350, MaxLevel = 1, UpgradeCost = {}, Color = Color3.fromRGB(55, 190, 145), TurnType = "Straight"
	},
	Sorter = {
		Name = "Trieur Gauche/Droite", Category = "Belts", IsBelt = true,
		InputCapacity = 3, OutputCapacity = 3, TransferRate = 2,
		EnergyConsumption = 0, EnergyProduction = 0,
		Cost = 850, MaxLevel = 1, UpgradeCost = {}, Color = Color3.fromRGB(45, 200, 230), TurnType = "Sorter"
	},
}

for id, def in pairs(MachineConfig.Definitions) do
	def.Price = def.Cost or 0
	if not def.Description then
		if def.IsBelt then
			def.Description = "Débit : " .. tostring(def.TransferRate or 1) .. " objet(s)/tick (Sans niveau)"
		elseif def.Category == "Extractors" then
			def.Description = "Extrait 1 minerai toutes les " .. tostring(def.ProcessTime) .. "s"
		elseif def.Category == "Refiners" or def.Category == "Alloys" then
			def.Description = "Transformation en " .. tostring(def.ProcessTime) .. "s"
		elseif (def.EnergyProduction or 0) > 0 then
			def.Description = "Produit +" .. tostring(def.EnergyProduction) .. " Énergie / niveau"
		elseif id == "DeliveryCenter" then
			def.Description = "Vend les ressources (+50% de profit par niveau)"
		else
			def.Description = "Capacité : " .. tostring(def.InputCapacity or 100) .. " ressources"
		end
	end
end

function MachineConfig.Get(typeId: string)
	return MachineConfig.Definitions[typeId]
end

function MachineConfig.GetUpgradeCost(typeId: string, currentLevel: number): number
	local cfg = MachineConfig.Definitions[typeId]
	if not cfg or cfg.IsBelt then
		return 0
	end
	local lvl = currentLevel or 1
	if cfg.UpgradeCost and cfg.UpgradeCost[lvl] then
		return cfg.UpgradeCost[lvl]
	end
	local base = cfg.Cost or cfg.Price or 100
	return math.floor(base * (2.5 ^ lvl))
end

return MachineConfig