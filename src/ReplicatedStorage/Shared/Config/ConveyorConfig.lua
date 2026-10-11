-- ReplicatedStorage/Shared/Config/ConveyorConfig.lua
local ConveyorConfig = {}

-- Catalogue des tapis roulants (4 vitesses, virages 90°, jonctions et trieurs)
ConveyorConfig.Belts = {
	-- GAMME 1 : BASIQUE
	Belt1_Straight = {
		Id = "Belt1_Straight", Name = "Tapis Basique Droit", Category = "Belts",
		Description = "Transporte les ressources tout droit (Vitesse x1).",
		Price = 15, TransferRate = 1, Capacity = 3, TurnType = "Straight",
		Color = Color3.fromRGB(95, 100, 110),
	},
	Belt1_Left = {
		Id = "Belt1_Left", Name = "Tapis Basique 90° Gauche", Category = "Belts",
		Description = "Tourne les ressources à 90° vers la gauche.",
		Price = 20, TransferRate = 1, Capacity = 3, TurnType = "Left",
		Color = Color3.fromRGB(95, 100, 110),
	},
	Belt1_Right = {
		Id = "Belt1_Right", Name = "Tapis Basique 90° Droite", Category = "Belts",
		Description = "Tourne les ressources à 90° vers la droite.",
		Price = 20, TransferRate = 1, Capacity = 3, TurnType = "Right",
		Color = Color3.fromRGB(95, 100, 110),
	},

	-- GAMME 2 : RAPIDE
	Belt2_Straight = {
		Id = "Belt2_Straight", Name = "Tapis Rapide Droit", Category = "Belts",
		Description = "Transporte 2 ressources par cycle tout droit.",
		Price = 150, TransferRate = 2, Capacity = 6, TurnType = "Straight",
		Color = Color3.fromRGB(50, 130, 220),
	},
	Belt2_Left = {
		Id = "Belt2_Left", Name = "Tapis Rapide 90° Gauche", Category = "Belts",
		Description = "Virage rapide 90° vers la gauche (Débit x2).",
		Price = 180, TransferRate = 2, Capacity = 6, TurnType = "Left",
		Color = Color3.fromRGB(50, 130, 220),
	},
	Belt2_Right = {
		Id = "Belt2_Right", Name = "Tapis Rapide 90° Droite", Category = "Belts",
		Description = "Virage rapide 90° vers la droite (Débit x2).",
		Price = 180, TransferRate = 2, Capacity = 6, TurnType = "Right",
		Color = Color3.fromRGB(50, 130, 220),
	},

	-- GAMME 3 : EXPRESS
	Belt3_Straight = {
		Id = "Belt3_Straight", Name = "Tapis Express Droit", Category = "Belts",
		Description = "Transporte 4 ressources par cycle tout droit.",
		Price = 2500, TransferRate = 4, Capacity = 12, TurnType = "Straight",
		Color = Color3.fromRGB(240, 185, 45),
	},
	Belt3_Left = {
		Id = "Belt3_Left", Name = "Tapis Express 90° Gauche", Category = "Belts",
		Description = "Virage Express 90° vers la gauche (Débit x4).",
		Price = 2800, TransferRate = 4, Capacity = 12, TurnType = "Left",
		Color = Color3.fromRGB(240, 185, 45),
	},
	Belt3_Right = {
		Id = "Belt3_Right", Name = "Tapis Express 90° Droite", Category = "Belts",
		Description = "Virage Express 90° vers la droite (Débit x4).",
		Price = 2800, TransferRate = 4, Capacity = 12, TurnType = "Right",
		Color = Color3.fromRGB(240, 185, 45),
	},

	-- GAMME 4 : MAGNÉTIQUE
	Belt4_Straight = {
		Id = "Belt4_Straight", Name = "Tapis Magnétique Droit", Category = "Belts",
		Description = "Flux magnétique ultra-rapide (8 objets/cycle).",
		Price = 40000, TransferRate = 8, Capacity = 25, TurnType = "Straight",
		Color = Color3.fromRGB(165, 65, 245),
	},

	-- AIGUILLAGES LOGISTIQUES
	Merger = {
		Id = "Merger", Name = "Jonction 3-en-1", Category = "Belts",
		Description = "Reçoit de plusieurs côtés et fusionne tout vers l'avant.",
		Price = 350, TransferRate = 4, Capacity = 15, TurnType = "Straight",
		Color = Color3.fromRGB(60, 190, 150),
	},
	Sorter = {
		Id = "Sorter", Name = "Trieur Intelligent", Category = "Belts",
		Description = "Envoie les minerais bruts à droite (90°) et les produits raffinés tout droit.",
		Price = 900, TransferRate = 4, Capacity = 15, TurnType = "Sorter",
		Color = Color3.fromRGB(45, 195, 225),
	},
}

return ConveyorConfig