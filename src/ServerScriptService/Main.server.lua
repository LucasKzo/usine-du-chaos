
-- L'USINE DU CHAOS - Version 0.5
-- Serveur : parcelles, production, boutique, placement,
-- déplacement des machines et commandes développeur.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local STARTING_CASH = 100
local BASE_CASH_PER_CRATE = 10
local BASE_PRODUCTION_INTERVAL = 3
local BASE_CONVEYOR_SPEED = 12

local MAX_PLOTS = 8
local PLOT_SPACING = 100
local MAX_UPGRADE_LEVEL = 5
local GRID_SIZE = 4

-- Vérifie que cet identifiant correspond bien à ton compte Roblox.
local DEV_USER_ID = 2418300030

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

local MACHINES = {
    Transformer = {
        displayName = "Transformateur",
        cost = 250,
        multiplier = 2,
        color = Color3.fromRGB(50, 220, 125),
    },
    Multiplier = {
        displayName = "Multiplicateur",
        cost = 500,
        multiplier = 2,
        color = Color3.fromRGB(255, 195, 45),
    },
}

-- Création des communications client/serveur.
local oldRemotes = ReplicatedStorage:FindFirstChild("FactoryRemotes")
if oldRemotes then
    oldRemotes:Destroy()
end

local remotes = Instance.new("Folder")
remotes.Name = "FactoryRemotes"
remotes.Parent = ReplicatedStorage

local function createRemoteFunction(name)
    local remote = Instance.new("RemoteFunction")
    remote.Name = name
    remote.Parent = remotes
    return remote
end

local buyRemote = createRemoteFunction("BuyUpgrade")
local shopDataRemote = createRemoteFunction("GetShopData")
local placeMachineRemote = createRemoteFunction("PlaceMachine")
local removeMachineRemote = createRemoteFunction("RemoveMachine")
local devCashRemote = createRemoteFunction("DevGiveCash")

-- Création des parcelles.
local oldPlots = workspace:FindFirstChild("PlayerPlots")
if oldPlots then
    oldPlots:Destroy()
end

local plotsFolder = Instance.new("Folder")
plotsFolder.Name = "PlayerPlots"
plotsFolder.Parent = workspace

local plotsByUserId = {}
local occupiedSlots = {}
local upgradesByUserId = {}
local placedMachinesByUserId = {}
local lastPurchaseByUserId = {}

local function getUpgradeCost(name, level)
    local config = UPGRADES[name]
    if not config then
        return nil
    end

    return config.baseCost + level * config.costStep
end

local function getCashPerCrate(player)
    local levels = upgradesByUserId[player.UserId]
    return BASE_CASH_PER_CRATE * (1 + (levels and levels.Power or 0))
end

local function getProductionInterval(player)
    local levels = upgradesByUserId[player.UserId]
    local speedLevel = levels and levels.Speed or 0

    return BASE_PRODUCTION_INTERVAL / (1 + 0.25 * speedLevel)
end

local function getConveyorSpeed(player)
    local levels = upgradesByUserId[player.UserId]
    local speedLevel = levels and levels.Speed or 0

    return BASE_CONVEYOR_SPEED * (1 + 0.25 * speedLevel)
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

-- Modèle visuel des machines achetables.
local function createProcessingMachine(plot, worldPosition, machineName, ownerUserId)
    local config = MACHINES[machineName]
    if not config then
        return nil
    end

    local model = Instance.new("Model")
    model.Name = machineName
    model:SetAttribute("MachineType", machineName)
    model:SetAttribute("OwnerUserId", ownerUserId)
    model.Parent = plot

    local x = worldPosition.X
    local z = worldPosition.Z
    local color = config.color

    createPart(
        model,
        "LeftSupport",
        Vector3.new(2, 5, 2),
        Vector3.new(x, 4, z - 3),
        color,
        Enum.Material.Metal
    )

    createPart(
        model,
        "RightSupport",
        Vector3.new(2, 5, 2),
        Vector3.new(x, 4, z + 3),
        color,
        Enum.Material.Metal
    )

    createPart(
        model,
        "MachineTop",
        Vector3.new(8, 1.5, 2),
        Vector3.new(x, 7, z),
        color,
        Enum.Material.Metal
    )

    local light = createPart(
        model,
        "ProcessingLight",
        Vector3.new(3, 0.4, 3),
        Vector3.new(x, 8, z),
        color,
        Enum.Material.Neon
    )

    light.CanCollide = false

    return model
end

-- Construction d'une parcelle de joueur.
local function createPlot(player, slot)
    local model = Instance.new("Model")
    model.Name = "Plot_" .. player.UserId
    model:SetAttribute("OwnerUserId", player.UserId)
    model:SetAttribute("OwnerName", player.Name)
    model.Parent = plotsFolder

    local origin = Vector3.new((slot - 1) * PLOT_SPACING, 0, 0)

    createPart(
        model,
        "PlotGround",
        Vector3.new(80, 1, 80),
        origin,
        Color3.fromRGB(65, 105, 75),
        Enum.Material.Grass
    )

    createPart(
        model,
        "FactoryFloor",
        Vector3.new(38, 1, 30),
        origin + Vector3.new(0, 1, 5),
        Color3.fromRGB(75, 78, 85),
        Enum.Material.Concrete
    )

    local producer = Instance.new("Model")
    producer.Name = "BasicProducer"
    producer.Parent = model

    createPart(
        producer,
        "MachineBase",
        Vector3.new(12, 5, 10),
        origin + Vector3.new(-10, 4, 5),
        Color3.fromRGB(55, 105, 200),
        Enum.Material.Metal
    )

    createPart(
        producer,
        "MachineTop",
        Vector3.new(8, 2, 8),
        origin + Vector3.new(-10, 7.5, 5),
        Color3.fromRGB(35, 45, 65),
        Enum.Material.Metal
    )

    createPart(
        producer,
        "WarningLight",
        Vector3.new(2, 1, 2),
        origin + Vector3.new(-10, 9, 5),
        Color3.fromRGB(80, 255, 100),
        Enum.Material.Neon
    )

    createPart(
        model,
        "Conveyor",
        Vector3.new(28, 1, 8),
        origin + Vector3.new(10, 2.5, 5),
        Color3.fromRGB(35, 38, 43),
        Enum.Material.Metal
    )

    for i = 0, 6 do
        createPart(
            model,
            "Roller_" .. i,
            Vector3.new(1, 0.4, 8.5),
            origin + Vector3.new(-2 + i * 4, 3.2, 5),
            Color3.fromRGB(125, 130, 140),
            Enum.Material.Metal
        )
    end

    createPart(
        model,
        "DeliveryZone",
        Vector3.new(8, 0.4, 10),
        origin + Vector3.new(28, 3.2, 5),
        Color3.fromRGB(30, 220, 110),
        Enum.Material.Neon
    )

    local sign = createPart(
        model,
        "OwnerSign",
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

-- Déplacement des caisses sur le convoyeur.
local function tweenCrate(crate, destination, speed)
    if not crate.Parent then
        return false
    end

    local distance = (destination - crate.Position).Magnitude
    local duration = math.max(distance / speed, 0.05)

    local tween = TweenService:Create(
        crate,
        TweenInfo.new(duration, Enum.EasingStyle.Linear),
        { Position = destination }
    )

    tween:Play()
    local playbackState = tween.Completed:Wait()

    return playbackState == Enum.PlaybackState.Completed
        and crate.Parent ~= nil
end

local function createCrate(player, plot, origin)
    if not plot.Parent or not player.Parent then
        return
    end

    local cashValue = getCashPerCrate(player)
    local conveyorSpeed = getConveyorSpeed(player)
    local placed = placedMachinesByUserId[player.UserId] or {}
    local routeMachines = {}

    -- Les machines proches de la ligne traitent les caisses.
    for machineName, machineData in pairs(placed) do
        local relativeZ = machineData.z

        if relativeZ
            and math.abs(relativeZ - 5) <= 3.5
            and machineData.x > -10
            and machineData.x < 28 then

            table.insert(routeMachines, {
                name = machineName,
                x = machineData.x,
                z = machineData.z,
                multiplier = MACHINES[machineName].multiplier,
                color = MACHINES[machineName].color,
            })
        end
    end

    table.sort(routeMachines, function(a, b)
        return a.x < b.x
    end)

    local crate = createPart(
        plot,
        "ProductionCrate",
        Vector3.new(2, 2, 2),
        origin + Vector3.new(-10, 5.5, 5),
        Color3.fromRGB(255, 170, 40),
        Enum.Material.Neon
    )

    crate.CanCollide = false
    crate:SetAttribute("CashValue", cashValue)

    task.spawn(function()
        local value = cashValue

        for _, machine in ipairs(routeMachines) do
            local reached = tweenCrate(
                crate,
                origin + Vector3.new(machine.x, 5.5, 5),
                conveyorSpeed
            )

            if not reached then
                if crate.Parent then
                    crate:Destroy()
                end
                return
            end

            value *= machine.multiplier
            crate.Color = machine.color
            crate:SetAttribute("CashValue", value)
        end

        local reached = tweenCrate(
            crate,
            origin + Vector3.new(28, 5.5, 5),
            conveyorSpeed
        )

        if not reached then
            if crate.Parent then
                crate:Destroy()
            end
            return
        end

        local ownerId = plot:GetAttribute("OwnerUserId")
        local owner = ownerId and Players:GetPlayerByUserId(ownerId)

        if owner == player and owner.Parent then
            local stats = owner:FindFirstChild("leaderstats")
            local cash = stats and stats:FindFirstChild("Cash")

            if cash and cash:IsA("IntValue") then
                cash.Value += value
            end
        end

        crate:Destroy()
    end)
end

-- Données affichées dans la boutique.
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

    local placed = placedMachinesByUserId[player.UserId] or {}

    return {
        cash = cash.Value,

        powerLevel = levels.Power,
        speedLevel = levels.Speed,
        maxLevel = MAX_UPGRADE_LEVEL,

        powerCost = getUpgradeCost("Power", levels.Power),
        speedCost = getUpgradeCost("Speed", levels.Speed),

        cashPerCrate = getCashPerCrate(player),
        productionInterval = getProductionInterval(player),

        transformerOwned = levels.Transformer,
        multiplierOwned = levels.Multiplier,

        transformerPlaced = placed.Transformer ~= nil,
        multiplierPlaced = placed.Multiplier ~= nil,

        transformerCost = MACHINES.Transformer.cost,
        multiplierCost = MACHINES.Multiplier.cost,
    }
end

-- Attribution d'une parcelle et initialisation du joueur.
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
        Transformer = false,
        Multiplier = false,
    }

    placedMachinesByUserId[player.UserId] = {}

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
            character:PivotTo(CFrame.new(origin + Vector3.new(0, 5, -15)))
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
    placedMachinesByUserId[player.UserId] = nil
    lastPurchaseByUserId[player.UserId] = nil

    print("[Usine] Parcelle libérée pour " .. player.Name)
end

shopDataRemote.OnServerInvoke = function(player)
    return getShopData(player)
end

-- Achats validés côté serveur.
buyRemote.OnServerInvoke = function(player, itemName)
    if not plotsByUserId[player.UserId] then
        return false, "Ta parcelle n'est pas prête."
    end

    if typeof(itemName) ~= "string"
        or (not UPGRADES[itemName] and not MACHINES[itemName]) then
        return false, "Article invalide."
    end

    local now = os.clock()
    local lastPurchase = lastPurchaseByUserId[player.UserId] or 0

    if now - lastPurchase < 0.25 then
        return false, "Attends un instant avant un autre achat."
    end

    lastPurchaseByUserId[player.UserId] = now

    local levels = upgradesByUserId[player.UserId]
    local stats = player:FindFirstChild("leaderstats")
    local cash = stats and stats:FindFirstChild("Cash")

    if not levels or not cash or not cash:IsA("IntValue") then
        return false, "Données indisponibles."
    end

    local cost

    if UPGRADES[itemName] then
        local currentLevel = levels[itemName]

        if currentLevel >= MAX_UPGRADE_LEVEL then
            return false, "Niveau maximum atteint."
        end

        cost = getUpgradeCost(itemName, currentLevel)
    else
        if levels[itemName] then
            local placed = placedMachinesByUserId[player.UserId] or {}

            if not placed[itemName] then
                return false, "Machine déjà achetée : choisis son emplacement."
            end

            return false, "Tu as déjà placé cette machine."
        end

        cost = MACHINES[itemName].cost
    end

    if cash.Value < cost then
        return false, "Pas assez d'argent ! Il te faut " .. cost .. " $."
    end

    cash.Value -= cost

    if UPGRADES[itemName] then
        levels[itemName] += 1

        print("[Usine] " .. player.Name .. " a acheté l'amélioration " .. itemName)

        return true, "Amélioration achetée !", getShopData(player)
    end

    -- La machine est achetée mais attend son placement.
    levels[itemName] = true

    print("[Usine] " .. player.Name .. " a acheté " .. itemName)

    return true, "Machine achetée ! Clique sur ta parcelle pour la placer.", getShopData(player)
end

-- Placement des machines avec vérifications côté serveur.
placeMachineRemote.OnServerInvoke = function(player, machineName, requestedPosition)
    if typeof(machineName) ~= "string" or not MACHINES[machineName] then
        return false, "Type de machine invalide."
    end

    if typeof(requestedPosition) ~= "Vector3" then
        return false, "Position invalide."
    end

    local plotData = plotsByUserId[player.UserId]
    local levels = upgradesByUserId[player.UserId]

    if not plotData or not levels then
        return false, "Ta parcelle n'est pas prête."
    end

    if not levels[machineName] then
        return false, "Tu dois d'abord acheter cette machine."
    end

    local placed = placedMachinesByUserId[player.UserId]

    if placed[machineName] then
        return false, "Cette machine est déjà placée."
    end

    local origin = plotData.origin

    local relativeX = math.floor(
        (requestedPosition.X - origin.X) / GRID_SIZE + 0.5
    ) * GRID_SIZE

    local relativeZ = math.floor(
        (requestedPosition.Z - origin.Z) / GRID_SIZE + 0.5
    ) * GRID_SIZE

    if relativeX < 0 or relativeX > 14
        or relativeZ < -6 or relativeZ > 16 then
        return false, "Place la machine sur le sol de ton usine."
    end

    -- Pour l'instant, les machines doivent être près du convoyeur.
    if math.abs(relativeZ - 5) > 3.5 then
        return false, "Place la machine près du convoyeur pour traiter les caisses."
    end

    -- Empêche les chevauchements.
    for _, existing in pairs(placed) do
        if math.abs(existing.x - relativeX) < 8
            and math.abs(existing.z - relativeZ) < 8 then
            return false, "Cet emplacement est déjà occupé."
        end
    end

    local worldPosition = Vector3.new(
        origin.X + relativeX,
        0,
        origin.Z + relativeZ
    )

    local model = createProcessingMachine(
        plotData.model,
        worldPosition,
        machineName,
        player.UserId
    )

    if not model then
        return false, "Impossible de créer cette machine."
    end

    placed[machineName] = {
        x = relativeX,
        z = relativeZ,
        model = model,
    }

    print(string.format(
        "[Usine] %s a placé %s en X=%d, Z=%d",
        player.Name,
        machineName,
        relativeX,
        relativeZ
    ))

    return true, "Machine placée ! Les prochaines caisses pourront être traitées.", getShopData(player)
end

-- Retrait temporaire d'une machine pour la déplacer.
-- Elle reste achetée et ne coûte rien de plus.
removeMachineRemote.OnServerInvoke = function(player, machineName)
    if typeof(machineName) ~= "string" or not MACHINES[machineName] then
        return false, "Type de machine invalide."
    end

    local plotData = plotsByUserId[player.UserId]
    local levels = upgradesByUserId[player.UserId]
    local placed = placedMachinesByUserId[player.UserId]

    if not plotData or not levels or not placed then
        return false, "Ta parcelle n'est pas prête."
    end

    if not levels[machineName] then
        return false, "Tu ne possèdes pas cette machine."
    end

    local machineData = placed[machineName]

    if not machineData then
        return true, "Machine déjà disponible pour être placée."
    end

    if machineData.model and machineData.model.Parent then
        machineData.model:Destroy()
    end

    placed[machineName] = nil

    print("[Usine] " .. player.Name .. " déplace " .. machineName)

    return true, "Machine retirée : choisis son nouvel emplacement.", getShopData(player)
end

-- Argent de test : uniquement dans Studio et pour le compte autorisé.
devCashRemote.OnServerInvoke = function(player)
    if not RunService:IsStudio() then
        return false, "Disponible uniquement dans Studio."
    end

    if DEV_USER_ID == 0 or player.UserId ~= DEV_USER_ID then
        warn("[DEV] Tentative non autorisée :", player.Name, player.UserId)
        return false, "Accès refusé."
    end

    local stats = player:FindFirstChild("leaderstats")
    local cash = stats and stats:FindFirstChild("Cash")

    if not cash or not cash:IsA("IntValue") then
        return false, "Statistique Cash introuvable."
    end

    cash.Value += 100000

    print("[DEV] +100000 $ pour " .. player.Name)

    return true, "100 000 $ ajoutés !"
end

Players.PlayerAdded:Connect(assignPlayer)
Players.PlayerRemoving:Connect(removePlayer)

for _, player in Players:GetPlayers() do
    task.spawn(assignPlayer, player)
end

print("[Usine] Système de production v0.5 chargé.")
