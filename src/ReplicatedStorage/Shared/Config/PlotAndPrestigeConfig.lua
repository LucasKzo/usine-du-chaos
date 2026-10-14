-- ReplicatedStorage/Shared/Config/PlotAndPrestigeConfig.lua
local PlotAndPrestigeConfig = {}

PlotAndPrestigeConfig.CellSize = 6
PlotAndPrestigeConfig.StartingCredits = 500
PlotAndPrestigeConfig.MaxMachineLevel = 3

-- Paliers d'agrandissement du terrain étendu jusqu'à 32x32
PlotAndPrestigeConfig.PlotTiers = {
	[1] = { Name = "Parcelle 6x6 (Départ)", Cells = 6, MaxMachines = 36, Cost = 0 },
	[2] = { Name = "Extension 8x8", Cells = 8, MaxMachines = 64, Cost = 4000 },
	[3] = { Name = "Extension 10x10", Cells = 10, MaxMachines = 100, Cost = 45000 },
	[4] = { Name = "Complexe 12x12", Cells = 12, MaxMachines = 144, Cost = 450000 },
	[5] = { Name = "Méga-Usine 16x16", Cells = 16, MaxMachines = 256, Cost = 3500000 },
	[6] = { Name = "Super-Complexe 20x20", Cells = 20, MaxMachines = 400, Cost = 25000000 },
	[7] = { Name = "Colosse Industriel 24x24", Cells = 24, MaxMachines = 576, Cost = 180000000 },
	[8] = { Name = "Empire de l'Usine 28x28", Cells = 28, MaxMachines = 784, Cost = 1200000000 },
	[9] = { Name = "Domaine Absolu 32x32", Cells = 32, MaxMachines = 1024, Cost = 8500000000 },
}

-- =========================================================================
-- FONCTIONS D'ÉCHELLE INFINIE (PRESTIGE INFINI)
-- =========================================================================

local BASE_PRESTIGE_COST = 10000000 -- 10 Millions $ pour le Prestige 1
local COST_GROWTH_BASE = 12         -- Facteur de multiplication de base par Prestige
local MULT_GROWTH_RATE = 2.5        -- Chaque Prestige multiplie les revenus par x2.5

-- 1. Fonction infinie du coût de Prestige : 10M * (12 + 2*P)^P
function PlotAndPrestigeConfig.GetPrestigeCost(currentPrestige: number): number
	local p = math.max(0, math.floor(tonumber(currentPrestige) or 0))
	local dynamicBase = COST_GROWTH_BASE + (p * 2)
	return math.floor(BASE_PRESTIGE_COST * (dynamicBase ^ p))
end

-- 2. Fonction infinie du multiplicateur de vente : 2.5^P (arrondi à 2 décimales)
function PlotAndPrestigeConfig.GetPrestigeMultiplier(prestigeLevel: number): number
	local p = math.max(0, math.floor(tonumber(prestigeLevel) or 0))
	if p == 0 then
		return 1
	end
	return math.floor((MULT_GROWTH_RATE ^ p) * 100) / 100
end

-- 3. Coût exponentiel pour poser des Centres de Livraison supplémentaires (le 1er est gratuit)
function PlotAndPrestigeConfig.GetDeliveryCenterCost(existingCount: number): number
	if existingCount <= 0 then
		return 0
	end
	return math.floor(15000 * (4.0 ^ (existingCount - 1)))
end

-- 4. Formatage lisible des grands nombres (K, M, B, T, Qa, Qi...)
local SUFFIXES = { "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc" }

function PlotAndPrestigeConfig.FormatMoney(amount: number): string
	local n = tonumber(amount) or 0
	if n < 10000 then
		return tostring(math.floor(n))
	end
	local tier = math.floor(math.log10(n) / 3)
	if tier <= 0 then
		return tostring(math.floor(n))
	end
	local suffix = SUFFIXES[tier] or ("e" .. tostring(tier * 3))
	local scaled = n / (10 ^ (tier * 3))
	return string.format("%.2f", scaled):gsub("%.?0+$", "") .. suffix
end

return PlotAndPrestigeConfig