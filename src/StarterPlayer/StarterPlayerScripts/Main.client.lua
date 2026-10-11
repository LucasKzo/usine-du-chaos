
-- L'USINE DU CHAOS - Version 0.2
-- Client : interface d'argent et boutique.
-- Chemin : src/StarterPlayer/StarterPlayerScripts/Main.client.lua

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local remotes = ReplicatedStorage:WaitForChild("FactoryRemotes")
local buyUpgradeRemote = remotes:WaitForChild("BuyUpgrade")
local getShopDataRemote = remotes:WaitForChild("GetShopData")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "FactoryHUD"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local function addCorner(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius)
    corner.Parent = parent
    return corner
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

local function makeButton(parent, name, text, position)
    local button = Instance.new("TextButton")
    button.Name = name
    button.Size = UDim2.new(1, -24, 0, 54)
    button.Position = position
    button.BackgroundColor3 = Color3.fromRGB(45, 125, 85)
    button.BorderSizePixel = 0
    button.Text = text
    button.TextColor3 = Color3.new(1, 1, 1)
    button.TextSize = 15
    button.TextWrapped = true
    button.Font = Enum.Font.GothamBold
    button.AutoButtonColor = true
    button.Parent = parent

    addCorner(button, 8)
    return button
end

-- Compteur d'argent.
local cashPanel = Instance.new("Frame")
cashPanel.Name = "CashPanel"
cashPanel.Size = UDim2.fromOffset(260, 65)
cashPanel.Position = UDim2.fromOffset(20, 20)
cashPanel.BackgroundColor3 = Color3.fromRGB(28, 32, 42)
cashPanel.BackgroundTransparency = 0.08
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

-- Fenêtre de la boutique.
local shop = Instance.new("Frame")
shop.Name = "ShopPanel"
shop.Size = UDim2.fromOffset(300, 335)
shop.Position = UDim2.fromOffset(20, 98)
shop.BackgroundColor3 = Color3.fromRGB(28, 32, 42)
shop.BackgroundTransparency = 0.04
shop.BorderSizePixel = 0
shop.Parent = screenGui
addCorner(shop, 12)

local shopStroke = Instance.new("UIStroke")
shopStroke.Color = Color3.fromRGB(90, 110, 145)
shopStroke.Thickness = 1.5
shopStroke.Parent = shop

local title = makeLabel(
    shop,
    "Title",
    "🏭 BOUTIQUE DE L'USINE",
    UDim2.new(1, -20, 0, 42),
    UDim2.fromOffset(10, 8),
    18
)
title.Font = Enum.Font.GothamBold

local info = makeLabel(
    shop,
    "ProductionInfo",
    "Chargement des améliorations...",
    UDim2.new(1, -20, 0, 45),
    UDim2.fromOffset(10, 48),
    13
)
info.TextColor3 = Color3.fromRGB(195, 205, 220)

local powerButton = makeButton(
    shop,
    "PowerUpgradeButton",
    "Chargement...",
    UDim2.fromOffset(12, 105)
)

local speedButton = makeButton(
    shop,
    "SpeedUpgradeButton",
    "Chargement...",
    UDim2.fromOffset(12, 167)
)

local status = makeLabel(
    shop,
    "Status",
    "Les améliorations augmentent ta production.",
    UDim2.new(1, -20, 0, 55),
    UDim2.fromOffset(10, 231),
    13
)
status.TextColor3 = Color3.fromRGB(255, 220, 130)

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

local function refreshShop()
    local success, data = pcall(function()
        return getShopDataRemote:InvokeServer()
    end)

    if not success or not data then
        status.Text = "Impossible de charger la boutique. Réessaie."
        return
    end

    currentData = data

    info.Text = string.format(
        "Gain par caisse : %d $  |  Cadence : %.1f s",
        data.cashPerCrate,
        data.productionInterval
    )

    if data.powerLevel >= data.maxLevel then
        powerButton.Text = "Machine améliorée\nNIVEAU MAX"
        powerButton.BackgroundColor3 = Color3.fromRGB(75, 80, 90)
    else
        powerButton.Text = string.format(
            "⚙ Machine améliorée  |  Nv. %d → %d\nPrix : %d $",
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
            "⚡ Convoyeur rapide  |  Nv. %d → %d\nPrix : %d $",
            data.speedLevel,
            data.speedLevel + 1,
            data.speedCost
        )
        speedButton.BackgroundColor3 = Color3.fromRGB(45, 100, 165)
    end
end

local function purchaseUpgrade(upgradeName, button)
    if purchaseInProgress then
        return
    end

    if not currentData then
        refreshShop()
        return
    end

    purchaseInProgress = true
    button.Active = false
    status.Text = "Achat en cours..."

    local callSucceeded, bought, message, data = pcall(function()
        return buyUpgradeRemote:InvokeServer(upgradeName)
    end)

    if not callSucceeded then
        status.Text = "Erreur de connexion. Réessaie."
    else
        status.Text = message or "Réponse reçue."

        if bought and data then
            currentData = data
            status.Text = "Achat réussi ! " .. message
        end
    end

    refreshShop()

    purchaseInProgress = false
    button.Active = true
end

powerButton.Activated:Connect(function()
    purchaseUpgrade("Power", powerButton)
end)

speedButton.Activated:Connect(function()
    purchaseUpgrade("Speed", speedButton)
end)

refreshShop()

print("[Usine] Interface de boutique chargée.")
