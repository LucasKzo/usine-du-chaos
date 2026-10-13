-- StarterPlayer/StarterPlayerScripts/ClientMain.client.lua
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ModelFactory = require(ReplicatedStorage.Shared:WaitForChild("ModelFactory"))
local MachineConfig = require(ReplicatedStorage.Shared.Config:WaitForChild("MachineConfig"))
local Controllers = script.Parent:WaitForChild("Controllers")
local BuildController = require(Controllers:WaitForChild("BuildController"))
local HUDController = require(Controllers:WaitForChild("HUDController"))

BuildController.Init()
HUDController.Init()

local visualsFolder = Workspace:FindFirstChild("ClientVisualResources") or Instance.new("Folder")
visualsFolder.Name = "ClientVisualResources"
visualsFolder.Parent = Workspace

local observedMachines = {}
local waitingVisualOnTile = {}
local activeTweens = {}

local function clearTileVisual(tileModel: Model)
	local existing = waitingVisualOnTile[tileModel]
	if existing then
		if existing.Model and existing.Model.Parent then
			if activeTweens[existing.Model] then
				activeTweens[existing.Model].Tween:Cancel()
				activeTweens[existing.Model].Conn:Disconnect()
				activeTweens[existing.Model].Proxy:Destroy()
				activeTweens[existing.Model] = nil
			end
			existing.Model:Destroy()
		end
		waitingVisualOnTile[tileModel] = nil
	end
end

local function hookMachineVisuals(machineModel: Model)
	if observedMachines[machineModel] then return end
	observedMachines[machineModel] = true

	machineModel:GetAttributeChangedSignal("HeldItem"):Connect(function()
		local held = machineModel:GetAttribute("HeldItem")
		if not held or held == "" then
			clearTileVisual(machineModel)
		end
	end)

	machineModel.AncestryChanged:Connect(function(_, parent)
		if not parent then clearTileVisual(machineModel) end
	end)

	machineModel:GetAttributeChangedSignal("TransferSeq"):Connect(function()
		local resId = machineModel:GetAttribute("LastMovedItem")
		local targetId = machineModel:GetAttribute("TargetMachineId")
		if not resId or resId == "" or not targetId then return end

		local machinesFolder = machineModel.Parent
		local targetModel = machinesFolder and machinesFolder:FindFirstChild(targetId)
		if not machineModel.PrimaryPart or not targetModel or not targetModel.PrimaryPart then return end

		local itemVisual = nil
		local existing = waitingVisualOnTile[machineModel]
		
		-- Récupération instantanée du modèle sans clignotement
		if existing and existing.Model and existing.Model.Parent then
			itemVisual = existing.Model
			waitingVisualOnTile[machineModel] = nil
		else
			clearTileVisual(machineModel)
			itemVisual = ModelFactory.CreateResourceModel(resId)
			itemVisual.Parent = visualsFolder
		end

		local targetType = targetModel:GetAttribute("MachineType")
		local targetCfg = targetType and MachineConfig.Get(targetType)
		
		if targetCfg and targetCfg.IsBelt then
			clearTileVisual(targetModel)
			waitingVisualOnTile[targetModel] = { ResId = resId, Model = itemVisual }
		end

		if activeTweens[itemVisual] then
			activeTweens[itemVisual].Tween:Cancel()
			activeTweens[itemVisual].Conn:Disconnect()
			activeTweens[itemVisual].Proxy:Destroy()
			activeTweens[itemVisual] = nil
		end

		local startPos = machineModel.PrimaryPart.Position + Vector3.new(0, 0.75, 0)
		local endPos = targetModel.PrimaryPart.Position + Vector3.new(0, 0.75, 0)
		local dir = (endPos - startPos)
		local rotCF = (dir.Magnitude > 0.01) and CFrame.lookAt(Vector3.zero, dir.Unit) or CFrame.identity

		local startCF = CFrame.new(startPos) * rotCF
		local endCF = CFrame.new(endPos) * rotCF
		
		if not existing then
			ModelFactory.PivotMachineModel(itemVisual, startCF)
		end

		local proxy = Instance.new("CFrameValue")
		-- On part de la position ACTUELLE de l'objet pour un virage parfait sans à-coups
		proxy.Value = (itemVisual.PrimaryPart and itemVisual.PrimaryPart.CFrame) or startCF
		
		local conn = proxy.Changed:Connect(function(newCF)
			if itemVisual.Parent then
				ModelFactory.PivotMachineModel(itemVisual, newCF)
			end
		end)

		-- Vitesse visuelle ajustée : un tapis Express ira 3x plus vite qu'un tapis basique !
		-- Le +0.15 sert de "colle" anti-lag pour que l'objet ne s'arrête jamais en attendant le tick serveur suivant.
		local machineType = machineModel:GetAttribute("MachineType")
		local currentCfg = machineType and MachineConfig.Get(machineType)
		local tRate = (currentCfg and currentCfg.IsBelt and currentCfg.TransferRate) or 1
		local tweenTime = (0.25 / tRate) + 0.15

		local tween = TweenService:Create(proxy, TweenInfo.new(tweenTime, Enum.EasingStyle.Linear), { Value = endCF })
		
		activeTweens[itemVisual] = { Tween = tween, Conn = conn, Proxy = proxy }
		tween:Play()
		
		tween.Completed:Connect(function()
			if activeTweens[itemVisual] and activeTweens[itemVisual].Tween == tween then
				activeTweens[itemVisual] = nil
			end
			conn:Disconnect()
			proxy:Destroy()
			
			if not (targetCfg and targetCfg.IsBelt) then
				if itemVisual.Parent then itemVisual:Destroy() end
			end
		end)
	end)
end

local animClock = 0
RunService.RenderStepped:Connect(function(dt)
	animClock = animClock + dt
	local plots = Workspace:FindFirstChild("Plots")
	if not plots then return end

	for _, plotModel in ipairs(plots:GetChildren()) do
		local machinesFolder = plotModel:FindFirstChild("Machines")
		if machinesFolder then
			for _, m in ipairs(machinesFolder:GetChildren()) do
				if m:IsA("Model") and m.PrimaryPart then
					hookMachineVisuals(m)

					local drill = m:FindFirstChild("DrillHead")
					if drill and drill:IsA("BasePart") then
						drill.CFrame = drill.CFrame * CFrame.Angles(0, dt * 6.0, 0)
					end

					local rotor = m:FindFirstChild("RotorSpinner")
					if rotor and rotor:IsA("BasePart") then
						rotor.CFrame = rotor.CFrame * CFrame.Angles(0, dt * 4.0, 0)
					end

					local piston = m:FindFirstChild("Piston")
					if piston and piston:IsA("BasePart") then
						local offset = math.sin(animClock * 5.0) * 0.75
						local basePos = m.PrimaryPart.Position
						piston.CFrame = CFrame.new(basePos.X, basePos.Y + 2.4 + offset, basePos.Z) * m.PrimaryPart.CFrame.Rotation
					end
				end
			end
		end
	end
end)