-- ReplicatedStorage/Shared/Config/ChaosAndEventsConfig.lua
local ChaosAndEventsConfig = {}

ChaosAndEventsConfig.Gadgets = {
	Jammer = {
		Id = "Jammer", Name = "Brouilleur",
		Description = "Réduit de 60% la vitesse d'une machine adverse pendant 15s.",
		Cost = 15, Duration = 15, Cooldown = 20,
	},
	Inverter = {
		Id = "Inverter", Name = "Inverseur de Tapis",
		Description = "Retourne le sens d'une machine ou d'un tapis adverse pendant 12s.",
		Cost = 20, Duration = 12, Cooldown = 25,
	},
	Overload = {
		Id = "Overload", Name = "Surcharge Critique",
		Description = "Double la vitesse pendant 6s puis bloque la machine pendant 10s.",
		Cost = 25, Duration = 16, Cooldown = 30,
	},
	CargoThief = {
		Id = "CargoThief", Name = "Pirate de Livraison",
		Description = "Détourne la prochaine vente d'une usine adverse vers ton compte !",
		Cost = 40, Duration = 20, Cooldown = 45,
	},
	Blackout = {
		Id = "Blackout", Name = "Panne Générale",
		Description = "Augmente de +50% la consommation d'énergie de tout le serveur (20s).",
		Cost = 60, Duration = 20, Cooldown = 90,
	},
}

ChaosAndEventsConfig.WorldEvents = {
	{
		Id = "BullMarket", Name = "Boom Boursier",
		Description = "Toutes les ventes rapportent +100% de Crédits (x2) !",
		Duration = 45,
	},
	{
		Id = "Overclock", Name = "Surcadence Globale",
		Description = "Toutes les machines et mines du serveur tournent 2x plus vite !",
		Duration = 40,
	},
	{
		Id = "GridStrain", Name = "Tension Électrique",
		Description = "L'énergie de base baisse de moitié. Vérifiez vos Générateurs !",
		Duration = 40,
	},
	{
		Id = "ChaosBounty", Name = "Prime du Chaos",
		Description = "Chaque vente rapporte +3 Jetons de Chaos supplémentaires !",
		Duration = 45,
	},
}

return ChaosAndEventsConfig