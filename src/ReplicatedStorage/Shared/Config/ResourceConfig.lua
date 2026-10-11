-- ReplicatedStorage/Shared/Config/ResourceConfig.lua
local ResourceConfig = {}

-- Formes disponibles : "Ore" (roche brute), "Ingot" (lingot), "Block" (cube lourd), "Gem" (cristal), "Canister" (cellule), "Core" (orbe d'énergie)
ResourceConfig.Items = {
	-- PALIER I : FER
	IronOre = {
		Name = "Minerai de Fer", Value = 5, IsRaw = true,
		Shape = "Ore", Color = Color3.fromRGB(145, 95, 75), Material = Enum.Material.Slate,
	},
	IronIngot = {
		Name = "Lingot de Fer", Value = 15, IsRaw = false,
		Shape = "Ingot", Color = Color3.fromRGB(205, 210, 220), Material = Enum.Material.Metal,
	},
	IronBlock = {
		Name = "Bloc de Fer", Value = 45, IsRaw = false,
		Shape = "Block", Color = Color3.fromRGB(160, 170, 185), Material = Enum.Material.Metal,
	},

	-- PALIER II : OR & ÉLECTRUM
	GoldOre = {
		Name = "Pépite d'Or", Value = 35, IsRaw = true,
		Shape = "Ore", Color = Color3.fromRGB(245, 190, 35), Material = Enum.Material.Foil,
	},
	GoldIngot = {
		Name = "Lingot d'Or", Value = 95, IsRaw = false,
		Shape = "Ingot", Color = Color3.fromRGB(255, 205, 45), Material = Enum.Material.Metal,
	},
	GoldBlock = {
		Name = "Bloc d'Or", Value = 260, IsRaw = false,
		Shape = "Block", Color = Color3.fromRGB(255, 195, 30), Material = Enum.Material.Foil,
	},
	PureGold24K = {
		Name = "Or Pur 24K", Value = 650, IsRaw = false,
		Shape = "Ingot", Color = Color3.fromRGB(255, 235, 90), Material = Enum.Material.Neon, Glow = true,
	},
	ElectrumIngot = {
		Name = "Lingot d'Électrum", Value = 1800, IsRaw = false,
		Shape = "Ingot", Color = Color3.fromRGB(255, 150, 45), Material = Enum.Material.Neon, Glow = true,
	},

	-- PALIER III : DIAMANT & JOAILLERIE IMPÉRIALE
	RawDiamond = {
		Name = "Diamant Brut", Value = 300, IsRaw = true,
		Shape = "Gem", Color = Color3.fromRGB(110, 225, 255), Material = Enum.Material.Ice,
	},
	CleanDiamond = {
		Name = "Diamant Purifié", Value = 900, IsRaw = false,
		Shape = "Gem", Color = Color3.fromRGB(80, 235, 255), Material = Enum.Material.Glass,
	},
	CutDiamond = {
		Name = "Diamant Taillé", Value = 2800, IsRaw = false,
		Shape = "Gem", Color = Color3.fromRGB(130, 245, 255), Material = Enum.Material.Neon, Glow = true,
	},
	ImperialRelic = {
		Name = "Relique Impériale", Value = 9500, IsRaw = false,
		Shape = "Core", Color = Color3.fromRGB(215, 95, 255), Material = Enum.Material.Neon, Glow = true,
	},

	-- PALIER IV : TITANE & NANOCOMPOSITE
	RawTitanium = {
		Name = "Titane Brut", Value = 2000, IsRaw = true,
		Shape = "Ore", Color = Color3.fromRGB(185, 195, 215), Material = Enum.Material.Rock,
	},
	TitaniumSponge = {
		Name = "Éponge de Titane", Value = 6500, IsRaw = false,
		Shape = "Block", Color = Color3.fromRGB(150, 220, 175), Material = Enum.Material.CorrodedMetal,
	},
	TitaniumPlate = {
		Name = "Plaque de Titane", Value = 20000, IsRaw = false,
		Shape = "Ingot", Color = Color3.fromRGB(220, 235, 255), Material = Enum.Material.DiamondPlate,
	},
	Nanocomposite = {
		Name = "Nanocomposite", Value = 75000, IsRaw = false,
		Shape = "Block", Color = Color3.fromRGB(45, 245, 210), Material = Enum.Material.Neon, Glow = true,
	},

	-- PALIER V : URANIUM & QUANTIQUE
	RawUranium = {
		Name = "Uranium Brut", Value = 15000, IsRaw = true,
		Shape = "Ore", Color = Color3.fromRGB(85, 235, 65), Material = Enum.Material.Slate, Glow = true,
	},
	EnrichedUranium = {
		Name = "Uranium Enrichi", Value = 50000, IsRaw = false,
		Shape = "Canister", Color = Color3.fromRGB(120, 255, 60), Material = Enum.Material.Neon, Glow = true,
	},
	FusionCell = {
		Name = "Cellule à Fusion", Value = 160000, IsRaw = false,
		Shape = "Canister", Color = Color3.fromRGB(65, 205, 255), Material = Enum.Material.Neon, Glow = true,
	},
	AntimatterCore = {
		Name = "Cœur d'Antimatière", Value = 650000, IsRaw = false,
		Shape = "Core", Color = Color3.fromRGB(255, 55, 195), Material = Enum.Material.Neon, Glow = true,
	},
}

return ResourceConfig