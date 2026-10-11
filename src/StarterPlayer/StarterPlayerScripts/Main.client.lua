
-- L'USINE DU CHAOS - Version 0.5
-- Client : HUD, boutique, aperçu, placement et déplacement des machines.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local mouse = player:GetMouse()

local remotes = ReplicatedStorage:WaitForChild("FactoryRemotes")
local buyRemote = remotes:WaitForChild("BuyUpgrade")
local shopDataRemote = remotes:WaitForChild("GetShopData")
local placeMachineRemote = remotes:WaitForChild("PlaceMachine")
local removeMachineRemote = remotes:WaitForChild("RemoveMachine")
local devCashRemote = remotes:WaitForChild("DevGiveCash")

local GRID_SIZE = 4
local MACHINE_SIZE = Vector3.new(8, 5, 8)
local refreshShop

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "FactoryHUD"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local function addCorner(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius)
    corner.Parent = parent
end

local function makeLabel(parent, name, text, size, position, textSize)
    local label = Instance.new("TextLabel")
    label.Name = name
    label.Size = size
    label.Position = position
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(245, 245, 245)
    label.TextSize = textSize
    label.Font = Enum.Font.Gotham
    label.TextWrapped = true
    label.Parent = parent

    return label
end

local function makeButton(parent, name, text, y, color)
    local button = Instance.new("TextButton")
    button.Name = name
    button.Size = UDim2.new(1, -24, 0, 54)
    button.Position = UDim2.fromOffset(12, y)
    button.BackgroundColor3 = color
    button.BorderSizePixel = 0
    button.Text = text
    button.TextColor3 = Color3.new(1, 1, 1)
    button.TextSize = 14
    button.TextWrapped = true
    button.Font = Enum.Font.GothamBold
    button.AutoButtonColor = true
    button.Parent = parent

    addCorner(button, 8)

    return button
end

-- Affichage de l'argent.
local cashPanel = Instance.new("Frame")
cashPanel.Name = "CashPanel"
cashPanel.Size = UDim2.fromOffset(260, 65)
cashPanel.Position = UDim2.fromOffset(20, 20)
cashPanel.BackgroundColor3 = Color3.fromRGB(28, 32, 42)
cashPanel.BorderSizePixel = 0
cashPanel.Parent = screenGui
addCorner(cashPanel, 12)

local cashStroke = Instance.new("UIStroke")
cashStroke.Color = Color3.fromRGB(75, 210, 125)
cashStroke.Thickness = 2
cashStroke.Parent = cashPanel

local cashLabel = makeLabel(
    cashPanel,
    "CashLabel",
    "Chargement...",
    UDim2.new(1, -20, 1, 0),
    UDim2.fromOffset(10, 0),
    23
)

cashLabel.Font = Enum.Font.GothamBold
cashLabel.TextColor3 = Color3.fromRGB(110, 255, 150)
cashLabel.TextXAlignment = Enum.TextXAlignment.Left

local stats = player:WaitForChild("leaderstats")
local cash = stats:WaitForChild("Cash")

local function updateCash()
    cashLabel.Text = "💰  " .. tostring(cash.Value) .. " $"
end

updateCash()
cash:GetPropertyChangedSignal("Value"):Connect(updateCash)

-- Boutique.
local shop = Instance.new("Frame")
shop.Name = "ShopPanel"
shop.Size = UDim2.fromOffset(340, 465)
shop.Position = UDim2.fromOffset(20, 98)
shop.BackgroundColor3 = Color3.fromRGB(28, 32, 42)
shop.BackgroundTransparency = 0.04
shop.BorderSizePixel = 0
shop.Parent = screenGui
addCorner(shop, 12)

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(90, 110, 145)
stroke.Thickness = 1.5
stroke.Parent = shop

local title = makeLabel(
    shop,
    "Title",
    "🏭 BOUTIQUE DE L'USINE",
    UDim2.new(1, -55, 0, 40),
    UDim2.fromOffset(10, 5),
    17
)

title.Font = Enum.Font.GothamBold

local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
closeButton.Size = UDim2.fromOffset(32, 30)
closeButton.Position = UDim2.new(1, -40, 0, 5)
closeButton.BackgroundColor3 = Color3.fromRGB(70, 75, 90)
closeButton.BorderSizePixel = 0
closeButton.Text = "X"
closeButton.TextColor3 = Color3.new(1, 1, 1)
closeButton.TextSize = 15
closeButton.Font = Enum.Font.GothamBold
closeButton.Parent = shop
addCorner(closeButton, 6)

local info = makeLabel(
    shop,
    "ProductionInfo",
    "Chargement des données...",
    UDim2.new(1, -20, 0, 45),
    UDim2.fromOffset(10, 43),
    13
)

info.TextColor3 = Color3.fromRGB(195, 205, 220)

local powerButton = makeButton(
    shop,
    "PowerUpgradeButton",
    "Chargement...",
    92,
    Color3.fromRGB(45, 125, 85)
)

local speedButton = makeButton(
    shop,
    "SpeedUpgradeButton",
    "Chargement...",
    151,
    Color3.fromRGB(45, 100, 165)
)

local transformerButton = makeButton(
    shop,
    "TransformerButton",
    "Chargement...",
    210,
    Color3.fromRGB(35, 125, 80)
)

local multiplierButton = makeButton(
    shop,
    "MultiplierButton",
    "Chargement...",
    269,
    Color3.fromRGB(155, 110, 30)
)

local status = makeLabel(
    shop,
    "Status",
    "Achète une machine puis clique sur le sol de ton usine pour la placer.",
    UDim2.new(1, -20, 0, 65),
    UDim2.fromOffset(10, 332),
    13
)

status.TextColor3 = Color3.fromRGB(255, 220, 130)

local cancelPlacementButton = Instance.new("TextButton")
cancelPlacementButton.Name = "CancelPlacementButton"
cancelPlacementButton.Size = UDim2.new(1, -24, 0, 35)
cancelPlacementButton.Position = UDim2.fromOffset(12, 397)
cancelPlacementButton.BackgroundColor3 = Color3.fromRGB(120, 55, 55)
cancelPlacementButton.BorderSizePixel = 0
cancelPlacementButton.Text = "Annuler le placement (Échap)"
cancelPlacementButton.TextColor3 = Color3.new(1, 1, 1)
cancelPlacementButton.TextSize = 13
cancelPlacementButton.Font = Enum.Font.GothamBold
cancelPlacementButton.Visible = false
cancelPlacementButton.Parent = shop
addCorner(cancelPlacementButton, 8)

local openButton = Instance.new("TextButton")
openButton.Name = "OpenShopButton"
openButton.Size = UDim2.fromOffset(130, 42)
openButton.Position = UDim2.fromOffset(20, 98)
openButton.BackgroundColor3 = Color3.fromRGB(45, 125, 85)
openButton.BorderSizePixel = 0
openButton.Text = "🛒 Boutique"
openButton.TextColor3 = Color3.new(1, 1, 1)
openButton.TextSize = 16
openButton.Font = Enum.Font.GothamBold
openButton.Visible = false
openButton.Parent = screenGui
addCorner(openButton, 8)

closeButton.Activated:Connect(function()
    shop.Visible = false
    openButton.Visible = true
end)

openButton.Activated:Connect(function()
    shop.Visible = true
    openButton.Visible = false
end)

local currentData = nil
local purchaseInProgress = false
local placementMachine = nil
local placementPreview = nil
local placementValid = false
local placementPosition = nil

local function getOwnPlot()
    local plots = workspace:FindFirstChild("PlayerPlots")

    if not plots then
        return nil
    end

    return plots:FindFirstChild("Plot_" .. player.UserId)
end

local function getPlotOrigin(plot)
    local ground = plot and plot:FindFirstChild("PlotGround")
    return ground and ground.Position or nil
end

local function snapToGrid(position, origin)
    local relativeX = math.floor(
        (position.X - origin.X) / GRID_SIZE + 0.5
    ) * GRID_SIZE

    local relativeZ = math.floor(
        (position.Z - origin.Z) / GRID_SIZE + 0.5
    ) * GRID_SIZE

    return relativeX, relativeZ
end

local function stopPlacement()
    placementMachine = nil
    placementValid = false
    placementPosition = nil

    if placementPreview then
        placementPreview:Destroy()
        placementPreview = nil
    end

    cancelPlacementButton.Visible = false
end

local function startPlacement(machineName)
    local plot = getOwnPlot()

    if not plot then
        status.Text = "Ta parcelle n'est pas encore prête."
        return
    end

    stopPlacement()
    placementMachine = machineName

    local configColor = machineName == "Transformer"
        and Color3.fromRGB(50, 220, 125)
        or Color3.fromRGB(255, 195, 45)

    placementPreview = Instance.new("Part")
    placementPreview.Name = "LocalMachinePlacementPreview"
    placementPreview.Size = MACHINE_SIZE
    placementPreview.Anchored = true
    placementPreview.CanCollide = false
    placementPreview.CanTouch = false
    placementPreview.CanQuery = false
    placementPreview.Material = Enum.Material.Neon
    placementPreview.Color = configColor
    placementPreview.Transparency = 0.5
    placementPreview.Parent = workspace

    cancelPlacementButton.Visible = true
    shop.Visible = true
    openButton.Visible = false

    status.Text = "Mode placement : vise le sol de ton usine et clique. Échap pour annuler."
end

cancelPlacementButton.Activated:Connect(function()
    stopPlacement()
    status.Text = "Placement annulé."
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if input.KeyCode == Enum.KeyCode.Escape and placementMachine then
        stopPlacement()
        status.Text = "Placement annulé."
        return
    end

    if gameProcessed or not placementMachine then
        return
    end

    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        if not placementValid or not placementPosition then
            status.Text = "Emplacement invalide : vise le sol de ton usine."
            return
        end

        local machineName = placementMachine
        local position = placementPosition

        status.Text = "Placement en cours..."

        local success, placed, message = pcall(function()
            return placeMachineRemote:InvokeServer(machineName, position)
        end)

        if not success then
            status.Text = "Erreur de connexion pendant le placement."
            warn("[Usine] Erreur PlaceMachine :", placed)
            return
        end

        status.Text = message or "Réponse reçue."

        if placed then
            stopPlacement()
            refreshShop()
        end
    end
end)

-- Aperçu vert si le placement est autorisé, rouge sinon.
local function updatePlacementPreview()
    if not placementMachine or not placementPreview then
        return
    end

    local plot = getOwnPlot()
    local origin = getPlotOrigin(plot)
    local target = mouse.Target

    placementValid = false
    placementPosition = nil

    if not plot or not origin or not target or not target:IsDescendantOf(plot) then
        placementPreview.Transparency = 0.75
        placementPreview.Color = Color3.fromRGB(255, 70, 70)
        return
    end

    local relativeX, relativeZ = snapToGrid(mouse.Hit.Position, origin)

    local worldPosition = Vector3.new(
        origin.X + relativeX,
        4,
        origin.Z + relativeZ
    )

    placementPreview.Position = worldPosition

    local inBounds = relativeX >= 0
        and relativeX <= 14
        and relativeZ >= -6
        and relativeZ <= 16
        and math.abs(relativeZ - 5) <= 3.5

    placementValid = inBounds
    placementPosition = Vector3.new(
        worldPosition.X,
        0,
        worldPosition.Z
    )

    placementPreview.Transparency = 0.5

    placementPreview.Color = inBounds
        and Color3.fromRGB(80, 255, 120)
        or Color3.fromRGB(255, 70, 70)
end

RunService.RenderStepped:Connect(updatePlacementPreview)

refreshShop = function()
    local callSucceeded, data = pcall(function()
        return shopDataRemote:InvokeServer()
    end)

    if not callSucceeded or not data then
        status.Text = "Impossible de charger la boutique."
        return
    end

    currentData = data

    info.Text = string.format(
        "Caisse : %d $  |  Cadence : %.1f s",
        data.cashPerCrate,
        data.productionInterval
    )

    if data.powerLevel >= data.maxLevel then
        powerButton.Text = "Machine améliorée\nNIVEAU MAX"
        powerButton.BackgroundColor3 = Color3.fromRGB(75, 80, 90)
    else
        powerButton.Text = string.format(
            "⚙ Machine améliorée | Nv. %d → %d\nPrix : %d $",
            data.powerLevel,
            data.powerLevel + 1,
            data.powerCost
        )

        powerButton.BackgroundColor3 = Color3.fromRGB(45, 125, 85)
    end

    if data.speedLevel >= data.maxLevel then
        speedButton.Text = "Convoyeur rapide\nNIVEAU MAX"
        speedButton.BackgroundColor3 = Color3.fromRGB(75, 80, 90)
    else
        speedButton.Text = string.format(
            "⚡ Convoyeur rapide | Nv. %d → %d\nPrix : %d $",
            data.speedLevel,
            data.speedLevel + 1,
            data.speedCost
        )

        speedButton.BackgroundColor3 = Color3.fromRGB(45, 100, 165)
    end

    if data.transformerPlaced then
        transformerButton.Text = "↔ Déplacer le transformateur"
        transformerButton.BackgroundColor3 = Color3.fromRGB(65, 95, 115)
    elseif data.transformerOwned then
        transformerButton.Text = "📍 Placer le transformateur\nDéjà acheté"
        transformerButton.BackgroundColor3 = Color3.fromRGB(35, 125, 80)
    else
        transformerButton.Text = string.format(
            "🔧 Acheter transformateur | Valeur ×2\nPrix : %d $",
            data.transformerCost
        )

        transformerButton.BackgroundColor3 = Color3.fromRGB(35, 125, 80)
    end

    if data.multiplierPlaced then
        multiplierButton.Text = "↔ Déplacer le multiplicateur"
        multiplierButton.BackgroundColor3 = Color3.fromRGB(115, 90, 45)
    elseif data.multiplierOwned then
        multiplierButton.Text = "📍 Placer le multiplicateur\nDéjà acheté"
        multiplierButton.BackgroundColor3 = Color3.fromRGB(155, 110, 30)
    else
        multiplierButton.Text = string.format(
            "⚡ Acheter multiplicateur | Valeur ×2\nPrix : %d $",
            data.multiplierCost
        )

        multiplierButton.BackgroundColor3 = Color3.fromRGB(155, 110, 30)
    end
end

local function purchase(itemName)
    if purchaseInProgress then
        return
    end

    purchaseInProgress = true
    status.Text = "Achat en cours..."

    local callSucceeded, bought, message = pcall(function()
        return buyRemote:InvokeServer(itemName)
    end)

    if not callSucceeded then
        status.Text = "Erreur de connexion. Réessaie."
        warn("[Usine] Erreur achat :", bought)
        purchaseInProgress = false
        return
    end

    status.Text = message or "Réponse reçue."

    refreshShop()

    if bought and (itemName == "Transformer" or itemName == "Multiplier") then
        startPlacement(itemName)
    elseif not bought and message and message:find("choisis son emplacement") then
        startPlacement(itemName)
    end

    purchaseInProgress = false
end

powerButton.Activated:Connect(function()
    purchase("Power")
end)

speedButton.Activated:Connect(function()
    purchase("Speed")
end)

-- Pour déplacer une machine, le serveur la retire temporairement,
-- puis le client lance le mode placement sans demander un nouvel achat.
local function relocateMachine(machineName)
    status.Text = "Préparation du déplacement..."

    local callSucceeded, removed, message = pcall(function()
        return removeMachineRemote:InvokeServer(machineName)
    end)

    if not callSucceeded then
        status.Text = "Erreur de connexion pendant le déplacement."
        warn("[Usine] Erreur RemoveMachine :", removed)
        return
    end

    status.Text = message or "Machine prête à être déplacée."

    if removed then
        refreshShop()
        startPlacement(machineName)
    end
end

transformerButton.Activated:Connect(function()
    if currentData and currentData.transformerPlaced then
        relocateMachine("Transformer")
    elseif currentData and currentData.transformerOwned then
        startPlacement("Transformer")
    else
        purchase("Transformer")
    end
end)

multiplierButton.Activated:Connect(function()
    if currentData and currentData.multiplierPlaced then
        relocateMachine("Multiplier")
    elseif currentData and currentData.multiplierOwned then
        startPlacement("Multiplier")
    else
        purchase("Multiplier")
    end
end)

-- Bouton développeur : le serveur vérifie l'identité et le mode Studio.
local devButton = Instance.new("TextButton")
devButton.Name = "DevCashButton"
devButton.Size = UDim2.fromOffset(190, 45)
devButton.Position = UDim2.new(1, -210, 1, -65)
devButton.BackgroundColor3 = Color3.fromRGB(150, 90, 35)
devButton.TextColor3 = Color3.new(1, 1, 1)
devButton.TextSize = 15
devButton.Font = Enum.Font.GothamBold
devButton.Text = "+100 000 $ [DEV]"
devButton.Parent = screenGui
addCorner(devButton, 8)

devButton.Activated:Connect(function()
    devButton.Text = "Chargement..."

    local success, allowed, message = pcall(function()
        return devCashRemote:InvokeServer()
    end)

    if success then
        devButton.Text = message or "Réponse reçue"

        if not allowed then
            status.Text = message or "Accès refusé."
        end
    else
        devButton.Text = "Erreur serveur"
        warn("[DEV] Appel impossible :", allowed)
    end

    task.wait(2)
    devButton.Text = "+100 000 $ [DEV]"
end)

refreshShop()
print("[Usine] Interface v0.5 chargée.")
