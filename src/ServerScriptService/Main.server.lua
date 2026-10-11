
-- L'USINE DU CHAOS - Version 0.2
-- Serveur : parcelles, production, argent et boutique.
-- Chemin : src/ServerScriptService/Main.server.lua

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local STARTING_CASH = 100
local BASE_CASH_PER_CRATE = 10
local BASE_PRODUCTION_INTERVAL = 3
local BASE_CONVEYOR_SPEED = 12

local MAX_PLOTS = 8
local PLOT_SPACING = 100
local MAX_UPGRADE_LEVEL = 5

-- Configuration des améliorations.
local UPGRADES = {
    Power = {
        displayName = "Machine améliorée",
        baseCost = 100,
        costStep = 100,
    },
    Speed = {
        displayName = "Convoyeur rapide",
        baseCost = 150,
        costStep = 125,
    },
}

-- Communications entre le client et le serveur.
-- Les objets sont créés ici pour que Rojo n'ait pas
-- besoin de fichiers supplémentaires pour les RemoteFunctions.

local oldRemotes = ReplicatedStorage:FindFirstChild("FactoryRemotes")
if oldRemotes then
    oldRemotes:Destroy()
end

local remotes = Instance.new("Folder")
remotes.Name = "FactoryRemotes"
remotes.Parent = ReplicatedStorage

local buyUpgradeRemote = Instance.new("RemoteFunction")
buyUpgradeRemote.Name = "BuyUpgrade"
buyUpgradeRemote.Parent = remotes

local getShopDataRemote = Instance.new("RemoteFunction")
getShopDataRemote.Name = "GetShopData"
getShopDataRemote.Parent = remotes

local plotsFolder = workspace:FindFirstChild("PlayerPlots")
if plotsFolder then
    plotsFolder:Destroy()
end

plotsFolder = Instance.new("Folder")
plotsFolder.Name = "PlayerPlots"
plotsFolder.Parent = workspace

local plotsByUserId = {}
local occupiedSlots = {}
local upgradesByUserId = {}
local lastPurchaseByUserId = {}

local function getUpgradeCost(upgradeName, currentLevel)
    local config = UPGRADES[upgradeName]
    if not config then
        return nil
    end

    return config.baseCost + currentLevel * config.costStep
end

local function getCashPerCrate(player)
    local levels = upgradesByUserId[player.UserId]
    local powerLevel = levels and levels.Power or 0

    return BASE_CASH_PER_CRATE * (powerLevel + 1)
end

local function getProductionInterval(player)
    local levels = upgradesByUserId[player.UserId]
    local speedLevel = levels and levels.Speed or 0

    -- Chaque niveau accélère la cadence de 25 %.
    return BASE_PRODUCTION_INTERVAL / (1 + 0.25 * speedLevel)
end

local function getConveyorSpeed(player)
    local levels = upgradesByUserId[player.UserId]
    local speedLevel = levels and levels.Speed or 0

    return BASE_CONVEYOR_SPEED * (1 + 0.25 * speedLevel)
end

local function getShopData(player)
    local levels = upgradesByUserId[player.UserId]
    if not levels then
        return nil
    end

    local stats = player:FindFirstChild("leaderstats")
    local cash = stats and stats:FindFirstChild("Cash")

    if not cash then
        return nil
    end

    return {
        cash = cash.Value,
        powerLevel = levels.Power,
        speedLevel = levels.Speed,
        maxLevel = MAX_UPGRADE_LEVEL,
        powerCost = getUpgradeCost("Power", levels.Power),
        speedCost = getUpgradeCost("Speed", levels.Speed),
        cashPerCrate = getCashPerCrate(player),
        productionInterval = getProductionInterval(player),
    }
end

local function createPart(parent, name, size, position, color, material)
    local part = Instance.new("Part")
    part.Name = name
    part.Size = size
    part.Position = position
    part.Anchored = true
    part.Color = color
    part.Material = material or Enum.Material.SmoothPlastic
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    part.Parent = parent
    return part
end

local function createPlot(player, slot)
    local model = Instance.new("Model")
    model.Name = "Plot_" .. player.UserId
    model:SetAttribute("OwnerUserId", player.UserId)
    model:SetAttribute("OwnerName", player.Name)
    model.Parent = plotsFolder

    local origin = Vector3.new((slot - 1) * PLOT_SPACING, 0, 0)

    createPart(
        model, "PlotGround",
        Vector3.new(80, 1, 80),
        origin,
        Color3.fromRGB(65, 105, 75),
        Enum.Material.Grass
    )

    createPart(
        model, "FactoryFloor",
        Vector3.new(38, 1, 30),
        origin + Vector3.new(0, 1, 5),
        Color3.fromRGB(75, 78, 85),
        Enum.Material.Concrete
    )

    local machine = Instance.new("Model")
    machine.Name = "BasicProducer"
    machine.Parent = model

    createPart(
        machine, "MachineBase",
        Vector3.new(12, 5, 10),
        origin + Vector3.new(-10, 4, 5),
        Color3.fromRGB(55, 105, 200),
        Enum.Material.Metal
    )

    createPart(
        machine, "MachineTop",
        Vector3.new(8, 2, 8),
        origin + Vector3.new(-10, 7.5, 5),
        Color3.fromRGB(35, 45, 65),
        Enum.Material.Metal
    )

    createPart(
        machine, "WarningLight",
        Vector3.new(2, 1, 2),
        origin + Vector3.new(-10, 9, 5),
        Color3.fromRGB(80, 255, 100),
        Enum.Material.Neon
    )

    createPart(
        model, "Conveyor",
        Vector3.new(28, 1, 8),
        origin + Vector3.new(10, 2.5, 5),
        Color3.fromRGB(35, 38, 43),
        Enum.Material.Metal
    )

    for i = 0, 6 do
        createPart(
            model, "Roller_" .. i,
            Vector3.new(1, 0.4, 8.5),
            origin + Vector3.new(-2 + i * 4, 3.2, 5),
            Color3.fromRGB(125, 130, 140),
            Enum.Material.Metal
        )
    end

    createPart(
        model, "DeliveryZone",
        Vector3.new(8, 0.4, 10),
        origin + Vector3.new(28, 3.2, 5),
        Color3.fromRGB(30, 220, 110),
        Enum.Material.Neon
    )

    local sign = createPart(
        model, "OwnerSign",
        Vector3.new(16, 6, 1),
        origin + Vector3.new(0, 5, -30),
        Color3.fromRGB(30, 35, 45),
        Enum.Material.Metal
    )

    local surface = Instance.new("SurfaceGui")
    surface.Face = Enum.NormalId.Front
    surface.Parent = sign

    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.Text = "USINE DE " .. string.upper(player.Name)
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextScaled = true
    label.Font = Enum.Font.GothamBold
    label.Parent = surface

    return model, origin
end

local function createCrate(player, plot, origin)
    if not plot or not plot.Parent or not player.Parent then
        return
    end

    local cashValue = getCashPerCrate(player)
    local conveyorSpeed = getConveyorSpeed(player)

    local crate = createPart(
        plot, "ProductionCrate",
        Vector3.new(2, 2, 2),
        origin + Vector3.new(-10, 5.5, 5),
        Color3.fromRGB(255, 170, 40),
        Enum.Material.Neon
    )

    crate.CanCollide = false
    crate:SetAttribute("CashValue", cashValue)

    local destination = origin + Vector3.new(28, 5.5, 5)
    local distance = (destination - crate.Position).Magnitude
    local duration = distance / conveyorSpeed

    local tween = TweenService:Create(
        crate,
        TweenInfo.new(duration, Enum.EasingStyle.Linear),
        { Position = destination }
    )

    tween:Play()

    tween.Completed:Connect(function(playbackState)
        if playbackState ~= Enum.PlaybackState.Completed then
            if crate.Parent then
                crate:Destroy()
            end
            return
        end

        -- L'argent est attribué uniquement par le serveur.
        local ownerId = plot:GetAttribute("OwnerUserId")
        local owner = ownerId and Players:GetPlayerByUserId(ownerId)

        if owner == player and owner.Parent then
            local stats = owner:FindFirstChild("leaderstats")
            local cash = stats and stats:FindFirstChild("Cash")

            if cash and cash:IsA("IntValue") then
                cash.Value += cashValue
            end
        end

        crate:Destroy()
    end)
end

local function assignPlayer(player)
    if plotsByUserId[player.UserId] then
        return
    end

    local slot

    for i = 1, MAX_PLOTS do
        if not occupiedSlots[i] then
            slot = i
            break
        end
    end

    if not slot then
        warn("[Usine] Aucune parcelle disponible pour " .. player.Name)
        return
    end

    occupiedSlots[slot] = player.UserId
    upgradesByUserId[player.UserId] = {
        Power = 0,
        Speed = 0,
    }

    local stats = Instance.new("Folder")
    stats.Name = "leaderstats"
    stats.Parent = player

    local cash = Instance.new("IntValue")
    cash.Name = "Cash"
    cash.Value = STARTING_CASH
    cash.Parent = stats

    local plot, origin = createPlot(player, slot)

    plotsByUserId[player.UserId] = {
        model = plot,
        origin = origin,
        slot = slot,
    }

    print("[Usine] Parcelle attribuée à " .. player.Name)

    local function moveCharacter(character)
        local root = character:WaitForChild("HumanoidRootPart", 10)

        if root and plotsByUserId[player.UserId] then
            character:PivotTo(
                CFrame.new(origin + Vector3.new(0, 5, -15))
            )
        end
    end

    player.CharacterAdded:Connect(moveCharacter)

    if player.Character then
        task.spawn(moveCharacter, player.Character)
    end

    task.spawn(function()
        while player.Parent and plot.Parent do
            task.wait(getProductionInterval(player))

            if player.Parent and plot.Parent then
                createCrate(player, plot, origin)
            end
        end
    end)
end

local function removePlayer(player)
    local data = plotsByUserId[player.UserId]

    if data then
        occupiedSlots[data.slot] = nil
        plotsByUserId[player.UserId] = nil

        if data.model and data.model.Parent then
            data.model:Destroy()
        end
    end

    upgradesByUserId[player.UserId] = nil
    lastPurchaseByUserId[player.UserId] = nil

    print("[Usine] Parcelle libérée pour " .. player.Name)
end

getShopDataRemote.OnServerInvoke = function(player)
    return getShopData(player)
end

buyUpgradeRemote.OnServerInvoke = function(player, upgradeName)
    -- Vérifier que le joueur est correctement initialisé.
    if not plotsByUserId[player.UserId] then
        return false, "Ta parcelle n'est pas prête."
    end

    -- N'accepter que les deux identifiants prévus.
    if typeof(upgradeName) ~= "string" or not UPGRADES[upgradeName] then
        return false, "Amélioration inconnue."
    end

    -- Petite limite anti-spam des achats.
    local now = os.clock()
    local lastPurchase = lastPurchaseByUserId[player.UserId] or 0

    if now - lastPurchase < 0.25 then
        return false, "Attends un instant avant un autre achat."
    end

    lastPurchaseByUserId[player.UserId] = now

    local levels = upgradesByUserId[player.UserId]
    if not levels then
        return false, "Données du joueur indisponibles."
    end

    local currentLevel = levels[upgradeName]

    if currentLevel >= MAX_UPGRADE_LEVEL then
        return false, "Cette amélioration est au niveau maximum."
    end

    local cost = getUpgradeCost(upgradeName, currentLevel)
    local stats = player:FindFirstChild("leaderstats")
    local cash = stats and stats:FindFirstChild("Cash")

    if not cash or not cash:IsA("IntValue") then
        return false, "Argent indisponible."
    end

    -- Le serveur choisit le prix et contrôle le solde.
    if cash.Value < cost then
        return false, "Pas assez d'argent ! Il te faut " .. cost .. " $."
    end

    -- Transaction serveur : payer puis appliquer le niveau.
    cash.Value -= cost
    levels[upgradeName] = currentLevel + 1

    local data = getShopData(player)

    print(
        "[Usine] " .. player.Name
        .. " a acheté " .. upgradeName
        .. " niveau " .. levels[upgradeName]
    )

    return true, "Amélioration achetée !", data
end

Players.PlayerAdded:Connect(assignPlayer)
Players.PlayerRemoving:Connect(removePlayer)

for _, player in Players:GetPlayers() do
    task.spawn(assignPlayer, player)
end

print("[Usine] Système de production et boutique chargé.")
