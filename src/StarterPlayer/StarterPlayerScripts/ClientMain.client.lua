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
local waitingVisualOnTile = {} -- Garde le modèle 3D sur un tapis pour éviter qu'il clignote entre 2 cases

local function hookMachineVisuals(machineModel: Model)
	if observedMachines[machineModel] then return end
	observedMachines[machineModel] = true

	machineModel:GetAttributeChangedSignal("TransferSeq"):Connect(function()
		local resId = machineModel:GetAttribute("LastMovedItem")
		local targetId = machineModel:GetAttribute("TargetMachineId")
		if not resId or resId == "" or not targetId then return end

		local machinesFolder = machineModel.Parent
		local targetModel = machinesFolder and machinesFolder:FindFirstChild(targetId)
		if not machineModel.PrimaryPart or not targetModel or not targetModel.PrimaryPart then return end

		-- Réutilise le modèle 3D déjà présent sur ce tapis s'il vient d'arriver (zéro clignotement !)
		local itemVisual = nil
		local existing = waitingVisualOnTile[machineModel]
		if existing and existing.ResId == resId and existing.Model and existing.Model.Parent then
			itemVisual = existing.Model
			waitingVisualOnTile[machineModel] = nil
		else
			if existing and existing.Model then
				existing.Model:Destroy()
				waitingVisualOnTile[machineModel] = nil
			end
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
			-- Si la case cible est un tapis, on garde l'objet 3D prêt pour le tapis suivant sans le détruire !
			if targetCfg and targetCfg.IsBelt then
				local oldTarget = waitingVisualOnTile[targetModel]
				if oldTarget and oldTarget.Model then
					oldTarget.Model:Destroy()
				end
				waitingVisualOnTile[targetModel] = { ResId = resId, Model = itemVisual }
				task.delay(0.25, function()
					if waitingVisualOnTile[targetModel] and waitingVisualOnTile[targetModel].Model == itemVisual then
						waitingVisualOnTile[targetModel] = nil
						if itemVisual.Parent then itemVisual:Destroy() end
					end
				end)
			else
				-- Si c'est un Four ou un Centre de Livraison, le minerai/lingot entre dans la machine et disparaît
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