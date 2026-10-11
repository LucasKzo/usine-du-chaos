-- ReplicatedStorage/Shared/Config/PlotAndPrestigeConfig.lua
local PlotAndPrestigeConfig = {}

PlotAndPrestigeConfig.CellSize = 6 -- 6x6 studs par case
PlotAndPrestigeConfig.StartingCredits = 500
PlotAndPrestigeConfig.MaxMachineLevel = 3

-- Paliers d'agrandissement de la parcelle
PlotAndPrestigeConfig.PlotTiers = {
	[1] = { Name = "Terrain Initial (6x6)", Cells = 6, MaxMachines = 25, Cost = 0 },
	[2] = { Name = "Extension I (8x8)", Cells = 8, MaxMachines = 45, Cost = 2500 },
	[3] = { Name = "Extension II (10x10)", Cells = 10, MaxMachines = 75, Cost = 35000 },
	[4] = { Name = "Extension III (12x12)", Cells = 12, MaxMachines = 115, Cost = 500000 },
	[5] = { Name = "Mégacomplexe (16x16)", Cells = 16, MaxMachines = 180, Cost = 15000000 },
}

-- Prix exponentiel des Centres de Livraison selon le nombre déjà posé sur le terrain
PlotAndPrestigeConfig.DeliveryCenterCosts = {
	[0] = 0,         -- 1er gratuit
	[1] = 25000,     -- 2e plateforme
	[2] = 1000000,   -- 3e plateforme
	[3] = 100000000, -- 4e plateforme et +
}

function PlotAndPrestigeConfig.GetDeliveryCenterCost(currentCount: number): number
	if currentCount <= 0 then return 0 end
	if currentCount == 1 then return 25000 end
	if currentCount == 2 then return 1000000 end
	return 100000000 * (10 ^ (currentCount - 3))
end

-- Coût du prochain Prestige (Rebirth)
function PlotAndPrestigeConfig.GetPrestigeCost(currentPrestige: number): number
	return math.floor(250000 * (8 ^ currentPrestige))
end

-- Multiplicateur de vente apporté par le Prestige (+100% par Prestige)
function PlotAndPrestigeConfig.GetPrestigeMultiplier(currentPrestige: number): number
	return 1 + currentPrestige
end

return PlotAndPrestigeConfig