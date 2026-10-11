-- ReplicatedStorage/Shared/Config/MachineConfig.lua
local ConveyorConfig = require(script.Parent.ConveyorConfig)

local MachineConfig = {}

-- Machines de production, de raffinage, d'alliage, d'énergie et de vente
MachineConfig.Definitions = {
	-- VENTE & ÉNERGIE
	DeliveryCenter = {
		Id = "DeliveryCenter", Name = "Centre de Livraison", Category = "Logistics",
		Description = "Vend tout ce qui entre. 1er GRATUIT, puis coût exponentiel !",
		Price = 0, ProcessTime = 0.5, InputCapacity = 40, OutputCapacity = 0,
		EnergyConsumption = 0, EnergyProduction = 0, Color = Color3.fromRGB(45, 200, 95),
	},
	Storage = {
		Id = "Storage", Name = "Silo de Stockage", Category = "Logistics",
		Description = "Stocke jusqu'à 60 ressources avant de les pousser devant.",
		Price = 400, ProcessTime = 0.5, InputCapacity = 60, OutputCapacity = 60,
		EnergyConsumption = 0, EnergyProduction = 0, Color = Color3.fromRGB(140, 110, 75),
	},
	ThermalGenerator = {
		Id = "ThermalGenerator", Name = "Générateur Thermique", Category = "Energy",
		Description = "Fournit +15 Énergie à ton usine.",
		Price = 300, ProcessTime = 1.0, InputCapacity = 0, OutputCapacity = 0,
		EnergyConsumption = 0, EnergyProduction = 15, Color = Color3.fromRGB(245, 210, 50),
	},
	FusionReactor = {
		Id = "FusionReactor", Name = "Réacteur à Fusion", Category = "Energy",
		Description = "Fournit +120 Énergie pour les machines de haute technologie.",
		Price = 150000, ProcessTime = 1.0, InputCapacity = 0, OutputCapacity = 0,
		EnergyConsumption = 0, EnergyProduction = 120, Color = Color3.fromRGB(60, 230, 255),
	},

	-- ==================== PALIER I : FER ====================
	IronExtractor = {
		Id = "IronExtractor", Name = "Mine de Fer", Category = "Extractors",
		Description = "Extrait 1 Minerai de Fer (5$) toutes les 1.5s.",
		Price = 100, ProcessTime = 1.5, InputCapacity = 0, OutputCapacity = 10,
		EnergyConsumption = 1, EnergyProduction = 0, Color = Color3.fromRGB(175, 115, 85),
		Recipes = { { Inputs = {}, Outputs = { IronOre = 1 } } },
	},
	IndustrialFurnace = {
		Id = "IndustrialFurnace", Name = "Four Industriel", Category = "Refiners",
		Description = "Fond le Minerai de Fer en Lingot (15$) ou la Pépite d'Or en Lingot d'Or (95$).",
		Price = 250, ProcessTime = 2.0, InputCapacity = 15, OutputCapacity = 15,
		EnergyConsumption = 2, EnergyProduction = 0, Color = Color3.fromRGB(225, 85, 50),
		Recipes = {
			{ Inputs = { IronOre = 1 }, Outputs = { IronIngot = 1 } },
			{ Inputs = { GoldOre = 1 }, Outputs = { GoldIngot = 1 } },
		},
	},
	HydraulicPress = {
		Id = "HydraulicPress", Name = "Presse Hydraulique", Category = "Refiners",
		Description = "Compacte 2 Lingots de Fer en Bloc de Fer (45$) ou 2 Lingots d'Or en Bloc d'Or (260$).",
		Price = 650, ProcessTime = 2.5, InputCapacity = 20, OutputCapacity = 15,
		EnergyConsumption = 3, EnergyProduction = 0, Color = Color3.fromRGB(110, 125, 165),
		Recipes = {
			{ Inputs = { IronIngot = 2 }, Outputs = { IronBlock = 1 } },
			{ Inputs = { GoldIngot = 2 }, Outputs = { GoldBlock = 1 } },
		},
	},

	-- ==================== PALIER II : OR & ÉLECTRUM ====================
	GoldExtractor = {
		Id = "GoldExtractor", Name = "Mine d'Or", Category = "Extractors",
		Description = "Extrait 1 Pépite d'Or (35$) toutes les 2.0s.",
		Price = 2000, ProcessTime = 2.0, InputCapacity = 0, OutputCapacity = 10,
		EnergyConsumption = 3, EnergyProduction = 0, Color = Color3.fromRGB(245, 195, 40),
		Recipes = { { Inputs = {}, Outputs = { GoldOre = 1 } } },
	},
	ChemicalBath = {
		Id = "ChemicalBath", Name = "Bain Chimique", Category = "Refiners",
		Description = "Purifie 1 Bloc d'Or en Or Pur 24K (650$).",
		Price = 4500, ProcessTime = 2.5, InputCapacity = 15, OutputCapacity = 15,
		EnergyConsumption = 5, EnergyProduction = 0, Color = Color3.fromRGB(120, 225, 130),
		Recipes = {
			{ Inputs = { GoldBlock = 1 }, Outputs = { PureGold24K = 1 } },
		},
	},
	AlloySmelter = {
		Id = "AlloySmelter", Name = "Fonderie d'Alliage", Category = "Alloys",
		Description = "ALLIAGE : 1 Bloc de Fer + 1 Or Pur 24K -> 1 Lingot d'Électrum (1 800$).",
		Price = 8500, ProcessTime = 3.0, InputCapacity = 20, OutputCapacity = 15,
		EnergyConsumption = 8, EnergyProduction = 0, Color = Color3.fromRGB(255, 140, 40),
		Recipes = {
			{ Inputs = { IronBlock = 1, PureGold24K = 1 }, Outputs = { ElectrumIngot = 1 } },
		},
	},

	-- ==================== PALIER III : DIAMANT ====================
	DiamondDrill = {
		Id = "DiamondDrill", Name = "Foreuse à Diamant", Category = "Extractors",
		Description = "Extrait 1 Diamant Brut (300$) toutes les 2.5s.",
		Price = 25000, ProcessTime = 2.5, InputCapacity = 0, OutputCapacity = 10,
		EnergyConsumption = 10, EnergyProduction = 0, Color = Color3.fromRGB(75, 225, 255),
		Recipes = { { Inputs = {}, Outputs = { RawDiamond = 1 } } },
	},
	UltrasonicRefinery = {
		Id = "UltrasonicRefinery", Name = "Raffinerie Ultrasons", Category = "Refiners",
		Description = "Nettoie 1 Diamant Brut en Diamant Purifié (900$).",
		Price = 55000, ProcessTime = 2.5, InputCapacity = 15, OutputCapacity = 15,
		EnergyConsumption = 14, EnergyProduction = 0, Color = Color3.fromRGB(70, 165, 235),
		Recipes = {
			{ Inputs = { RawDiamond = 1 }, Outputs = { CleanDiamond = 1 } },
		},
	},
	LaserCutter = {
		Id = "LaserCutter", Name = "Tailleuse Laser", Category = "Refiners",
		Description = "Taille 1 Diamant Purifié en Diamant Taillé (2 800$).",
		Price = 120000, ProcessTime = 3.0, InputCapacity = 15, OutputCapacity = 15,
		EnergyConsumption = 20, EnergyProduction = 0, Color = Color3.fromRGB(235, 60, 140),
		Recipes = {
			{ Inputs = { CleanDiamond = 1 }, Outputs = { CutDiamond = 1 } },
		},
	},
	RoyalJeweler = {
		Id = "RoyalJeweler", Name = "Sertisseuse Royale", Category = "Alloys",
		Description = "FUSION : 1 Lingot d'Électrum + 1 Diamant Taillé -> Relique Impériale (9 500$).",
		Price = 250000, ProcessTime = 3.5, InputCapacity = 20, OutputCapacity = 15,
		EnergyConsumption = 28, EnergyProduction = 0, Color = Color3.fromRGB(180, 80, 245),
		Recipes = {
			{ Inputs = { ElectrumIngot = 1, CutDiamond = 1 }, Outputs = { ImperialRelic = 1 } },
		},
	},

	-- ==================== PALIER IV : TITANE ====================
	TitaniumExcavator = {
		Id = "TitaniumExcavator", Name = "Excavateur de Titane", Category = "Extractors",
		Description = "Extrait 1 Titane Brut (2 000$) toutes les 2.5s.",
		Price = 600000, ProcessTime = 2.5, InputCapacity = 0, OutputCapacity = 10,
		EnergyConsumption = 30, EnergyProduction = 0, Color = Color3.fromRGB(190, 200, 215),
		Recipes = { { Inputs = {}, Outputs = { RawTitanium = 1 } } },
	},
	AcidEtcher = {
		Id = "AcidEtcher", Name = "Décapeur Acide", Category = "Refiners",
		Description = "Transforme 1 Titane Brut en Éponge de Titane (6 500$).",
		Price = 1400000, ProcessTime = 2.5, InputCapacity = 15, OutputCapacity = 15,
		EnergyConsumption = 40, EnergyProduction = 0, Color = Color3.fromRGB(140, 240, 90),
		Recipes = {
			{ Inputs = { RawTitanium = 1 }, Outputs = { TitaniumSponge = 1 } },
		},
	},
	PlasmaArcFurnace = {
		Id = "PlasmaArcFurnace", Name = "Four à Arc Plasma", Category = "Refiners",
		Description = "Forge 1 Éponge de Titane en Plaque de Titane (20 000$).",
		Price = 3200000, ProcessTime = 3.0, InputCapacity = 15, OutputCapacity = 15,
		EnergyConsumption = 55, EnergyProduction = 0, Color = Color3.fromRGB(90, 120, 255),
		Recipes = {
			{ Inputs = { TitaniumSponge = 1 }, Outputs = { TitaniumPlate = 1 } },
		},
	},
	SynthesisChamber = {
		Id = "SynthesisChamber", Name = "Chambre de Synthèse", Category = "Alloys",
		Description = "ALLIAGE : 1 Diamant Taillé + 1 Plaque de Titane -> Nanocomposite (75 000$).",
		Price = 7500000, ProcessTime = 3.5, InputCapacity = 20, OutputCapacity = 15,
		EnergyConsumption = 75, EnergyProduction = 0, Color = Color3.fromRGB(50, 225, 195),
		Recipes = {
			{ Inputs = { CutDiamond = 1, TitaniumPlate = 1 }, Outputs = { Nanocomposite = 1 } },
		},
	},

	-- ==================== PALIER V : URANIUM ====================
	NuclearDrill = {
		Id = "NuclearDrill", Name = "Foreuse Nucléaire", Category = "Extractors",
		Description = "Extrait 1 Uranium Brut (15 000$) toutes les 3.0s.",
		Price = 25000000, ProcessTime = 3.0, InputCapacity = 0, OutputCapacity = 10,
		EnergyConsumption = 90, EnergyProduction = 0, Color = Color3.fromRGB(90, 255, 70),
		Recipes = { { Inputs = {}, Outputs = { RawUranium = 1 } } },
	},
	GasCentrifuge = {
		Id = "GasCentrifuge", Name = "Centrifugeuse Gazeuse", Category = "Refiners",
		Description = "Enrichit 1 Uranium Brut en Uranium Enrichi (50 000$).",
		Price = 60000000, ProcessTime = 3.0, InputCapacity = 15, OutputCapacity = 15,
		EnergyConsumption = 120, EnergyProduction = 0, Color = Color3.fromRGB(165, 255, 70),
		Recipes = {
			{ Inputs = { RawUranium = 1 }, Outputs = { EnrichedUranium = 1 } },
		},
	},
	CryoStabilizer = {
		Id = "CryoStabilizer", Name = "Cryo-Stabilisateur", Category = "Refiners",
		Description = "Condense 1 Uranium Enrichi en Cellule à Fusion (160 000$).",
		Price = 140000000, ProcessTime = 3.5, InputCapacity = 15, OutputCapacity = 15,
		EnergyConsumption = 160, EnergyProduction = 0, Color = Color3.fromRGB(80, 200, 255),
		Recipes = {
			{ Inputs = { EnrichedUranium = 1 }, Outputs = { FusionCell = 1 } },
		},
	},
	QuantumAssembler = {
		Id = "QuantumAssembler", Name = "Assembleur Quantique", Category = "Alloys",
		Description = "FUSION ULTIME : 1 Nanocomposite + 1 Cellule à Fusion -> Cœur d'Antimatière (650 000$).",
		Price = 350000000, ProcessTime = 4.0, InputCapacity = 20, OutputCapacity = 15,
		EnergyConsumption = 220, EnergyProduction = 0, Color = Color3.fromRGB(255, 65, 200),
		Recipes = {
			{ Inputs = { Nanocomposite = 1, FusionCell = 1 }, Outputs = { AntimatterCore = 1 } },
		},
	},
}

-- Fusionner les tapis dans l'accès global pour simplifier la recherche par ID
for beltId, beltData in pairs(ConveyorConfig.Belts) do
	MachineConfig.Definitions[beltId] = {
		Id = beltId,
		Name = beltData.Name,
		Category = "Belts",
		Description = beltData.Description,
		Price = beltData.Price,
		ProcessTime = 0.5,
		InputCapacity = beltData.Capacity,
		OutputCapacity = beltData.Capacity,
		TransferRate = beltData.TransferRate,
		TurnType = beltData.TurnType,
		IsBelt = true,
		EnergyConsumption = 0,
		EnergyProduction = 0,
		Color = beltData.Color,
	}
end

function MachineConfig.Get(id: string)
	return MachineConfig.Definitions[id]
end

-- Coût d'amélioration (plafonné au niveau 3)
function MachineConfig.GetUpgradeCost(id: string, currentLevel: number): number
	local cfg = MachineConfig.Definitions[id]
	if not cfg then return 999999999 end
	local base = math.max(100, cfg.Price)
	return math.floor(base * (2.5 ^ currentLevel))
end

return MachineConfig