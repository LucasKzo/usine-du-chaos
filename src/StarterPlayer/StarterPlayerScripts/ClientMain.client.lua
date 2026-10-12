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
local waitingVisualOnTile = {} -- Garde le modèle 3D posé sur le tapis tant que le tapis contient la ressource

local function clearTileVisual(tileModel: Model)
	local existing = waitingVisualOnTile[tileModel]
	if existing then
		if existing.Model and existing.Model.Parent then
			existing.Model:Destroy()
		end
		waitingVisualOnTile[tileModel] = nil
	end
end

local function hookMachineVisuals(machineModel: Model)
	if observedMachines[machineModel] then return end
	observedMachines[machineModel] = true

	-- Si le tapis devient vide (ou est supprimé), on nettoie le visuel posé dessus
	machineModel:GetAttributeChangedSignal("HeldItem"):Connect(function()
		local held = machineModel:GetAttribute("HeldItem")
		if not held or held == "" then
			clearTileVisual(machineModel)
		end
	end)

	machineModel.AncestryChanged:Connect(function(_, parent)
		if not parent then
			clearTileVisual(machineModel)
		end
	end)

	machineModel:GetAttributeChangedSignal("TransferSeq"):Connect(function()
		local resId = machineModel:GetAttribute("LastMovedItem")
		local targetId = machineModel:GetAttribute("TargetMachineId")
		if not resId or resId == "" or not targetId then return end

		local machinesFolder = machineModel.Parent
		local targetModel = machinesFolder and machinesFolder:FindFirstChild(targetId)
		if not machineModel.PrimaryPart or not targetModel or not targetModel.PrimaryPart then return end

		-- Réutilise le modèle 3D qui attendait sur le tapis (zéro clignotement, même après un bouchon !)
		local itemVisual = nil
		local existing = waitingVisualOnTile[machineModel]
		if existing and existing.ResId == resId and existing.Model and existing.Model.Parent then
			itemVisual = existing.Model
			waitingVisualOnTile[machineModel] = nil
		else
			clearTileVisual(machineModel)
			itemVisual = ModelFactory.CreateResourceModel(resId)
			itemVisual.Parent = visualsFolder
		end

		local startPos = machineModel.PrimaryPart.Position + Vector3.new(0, 0.75, 0)
		local endPos = targetModel.PrimaryPart.Position + Vector3.new(0, 0.75, 0)
		local dir = (endPos - startPos)
		local rotCF = (dir.Magnitude > 0.01) and CFrame.lookAt(Vector3.zero, dir.Unit) or CFrame.identity

		local startCF = CFrame.new(startPos) * rotCF
		local endCF = CFrame.new(endPos) * rotCF
		ModelFactory.PivotMachineModel(itemVisual, startCF)

		local proxy = Instance.new("CFrameValue")
		proxy.Value = startCF
		local conn = proxy.Changed:Connect(function(newCF)
			if itemVisual.Parent then
				ModelFactory.PivotMachineModel(itemVisual, newCF)
			end
		end)

		local tween = TweenService:Create(proxy, TweenInfo.new(0.48, Enum.EasingStyle.Linear), {
			Value = endCF,
		})
		tween:Play()
		tween.Completed:Connect(function()
			conn:Disconnect()
			proxy:Destroy()

			local targetType = targetModel:GetAttribute("MachineType")
			local targetCfg = targetType and MachineConfig.Get(targetType)
			-- Si la cible est un tapis, le minerai RESTE visible dessus tant qu'il n'est pas entré dans le four !
			if targetCfg and targetCfg.IsBelt then
				clearTileVisual(targetModel)
				waitingVisualOnTile[targetModel] = { ResId = resId, Model = itemVisual }
			else
				if itemVisual.Parent then
					itemVisual:Destroy()
				end
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