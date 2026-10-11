
-- L'USINE DU CHAOS - Version 0.3
-- Client : compteur d'argent et boutique des machines.
-- Chemin : src/StarterPlayer/StarterPlayerScripts/Main.client.lua

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local remotes = ReplicatedStorage:WaitForChild("FactoryRemotes")
local buyRemote = remotes:WaitForChild("BuyUpgrade")
local shopDataRemote = remotes:WaitForChild("GetShopData")

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

-- Compteur d'argent.
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
    cashPanel, "CashLabel", "Chargement...",
    UDim2.new(1, -20, 1, 0),
    UDim2.fromOffset(10, 0), 23
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
shop.Size = UDim2.fromOffset(330, 440)
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
    shop, "Title", "🏭 BOUTIQUE DE L'USINE",
    UDim2.new(1, -55, 0, 40),
    UDim2.fromOffset(10, 5), 17
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
    shop, "ProductionInfo", "Chargement des données...",
    UDim2.new(1, -20, 0, 45),
    UDim2.fromOffset(10, 43), 13
)
info.TextColor3 = Color3.fromRGB(195, 205, 220)

local powerButton = makeButton(
    shop, "PowerUpgradeButton", "Chargement...", 92,
    Color3.fromRGB(45, 125, 85)
)

local speedButton = makeButton(
    shop, "SpeedUpgradeButton", "Chargement...", 151,
    Color3.fromRGB(45, 100, 165)
)

local transformerButton = makeButton(
    shop, "TransformerButton", "Chargement...", 210,
    Color3.fromRGB(35, 125, 80)
)

local multiplierButton = makeButton(
    shop, "MultiplierButton", "Chargement...", 269,
    Color3.fromRGB(155, 110, 30)
)

local status = makeLabel(
    shop, "Status",
    "Achète des machines pour augmenter la valeur de tes caisses.",
    UDim2.new(1, -20, 0, 65),
    UDim2.fromOffset(10, 332), 13
)
status.TextColor3 = Color3.fromRGB(255, 220, 130)

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
            data.powerLevel, data.powerLevel + 1, data.powerCost
        )
    end

    if data.speedLevel >= data.maxLevel then
        speedButton.Text = "Convoyeur rapide\nNIVEAU MAX"
        speedButton.BackgroundColor3 = Color3.fromRGB(75, 80, 90)
    else
        speedButton.Text = string.format(
            "⚡ Convoyeur rapide | Nv. %d → %d\nPrix : %d $",
            data.speedLevel, data.speedLevel + 1, data.speedCost
        )
    end

    if data.transformerOwned then
        transformerButton.Text = "✓ Transformateur\nACHETÉ"
        transformerButton.BackgroundColor3 = Color3.fromRGB(65, 80, 75)
    else
        transformerButton.Text = string.format(
            "🔧 Transformateur | Valeur ×2\nPrix : %d $",
            data.transformerCost
        )
        transformerButton.BackgroundColor3 = Color3.fromRGB(35, 125, 80)
    end

    if data.multiplierOwned then
        multiplierButton.Text = "✓ Multiplicateur\nACHETÉ"
        multiplierButton.BackgroundColor3 = Color3.fromRGB(85, 75, 55)
    else
        multiplierButton.Text = string.format(
            "⚡ Multiplicateur | Valeur ×2\nPrix : %d $",
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
    else
        status.Text = message or "Réponse reçue."
    end

    refreshShop()
    purchaseInProgress = false
end

powerButton.Activated:Connect(function()
    purchase("Power")
end)

speedButton.Activated:Connect(function()
    purchase("Speed")
end)

transformerButton.Activated:Connect(function()
    purchase("Transformer")
end)

multiplierButton.Activated:Connect(function()
    purchase("Multiplier")
end)

refreshShop()

print("[Usine] Boutique v0.3 chargée.")






-- Bouton développeur pour les tests dans Studio
local devCashRemote = remotes:WaitForChild("DevGiveCash")

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

local devCorner = Instance.new("UICorner")
devCorner.CornerRadius = UDim.new(0, 8)
devCorner.Parent = devButton

devButton.Activated:Connect(function()
    devButton.Text = "Chargement..."

    local success, allowed, message = pcall(function()
        return devCashRemote:InvokeServer()
    end)

    if success then
        devButton.Text = message or "Réponse reçue"
    else
        devButton.Text = "Erreur serveur"
        warn("[DEV] Appel impossible :", allowed)
    end

    task.wait(2)
    devButton.Text = "+100 000 $ [DEV]"
end)
