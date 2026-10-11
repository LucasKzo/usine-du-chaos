-- StarterPlayer/StarterPlayerScripts/ClientMain.client.lua
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ModelFactory = require(ReplicatedStorage.Shared:WaitForChild("ModelFactory"))
local Controllers = script.Parent:WaitForChild("Controllers")
local BuildController = require(Controllers:WaitForChild("BuildController"))
local HUDController = require(Controllers:WaitForChild("HUDController"))

BuildController.Init()
HUDController.Init()

-- Dossier client dédié aux minerais 3D en mouvement sur les tapis
local visualsFolder = Workspace:FindFirstChild("ClientVisualResources") or Instance.new("Folder")
visualsFolder.Name = "ClientVisualResources"
visualsFolder.Parent = Workspace

local observedMachines = {}

local function hookMachineVisuals(machineModel: Model)
	if observedMachines[machineModel] then return end
	observedMachines[machineModel] = true

	-- Dès que le serveur transfère une ressource vers la case suivante, on fait glisser le modèle 3D !
	machineModel:GetAttributeChangedSignal("TransferSeq"):Connect(function()
		local resId = machineModel:GetAttribute("LastMovedItem")
		local targetId = machineModel:GetAttribute("TargetMachineId")
		if not resId or resId == "" or not targetId then return end

		local machinesFolder = machineModel.Parent
		local targetModel = machinesFolder and machinesFolder:FindFirstChild(targetId)
		if not machineModel.PrimaryPart or not targetModel or not targetModel.PrimaryPart then return end

		local itemVisual = ModelFactory.CreateResourceModel(resId)
		itemVisual.Parent = visualsFolder

		local startPos = machineModel.PrimaryPart.Position + Vector3.new(0, 1.35, 0)
		local endPos = targetModel.PrimaryPart.Position + Vector3.new(0, 1.35, 0)
		ModelFactory.PivotMachineModel(itemVisual, CFrame.new(startPos))

		-- Glissement fluide de la ressource entre les deux machines/tapis en 0.45s
		local proxy = Instance.new("CFrameValue")
		proxy.Value = CFrame.new(startPos)
		local conn = proxy.Changed:Connect(function(newCF)
			if itemVisual.Parent then
				ModelFactory.PivotMachineModel(itemVisual, newCF)
			end
		end)

		local tween = TweenService:Create(proxy, TweenInfo.new(0.45, Enum.EasingStyle.Linear), {
			Value = CFrame.new(endPos) * CFrame.Angles(0, math.rad(90), 0),
		})
		tween:Play()
		tween.Completed:Connect(function()
			conn:Disconnect()
			proxy:Destroy()
			itemVisual:Destroy()
		end)
	end)
end

-- Surveiller toutes les machines posées et faire tourner les têtes de foreuses en 60 FPS
RunService.RenderStepped:Connect(function(dt)
	local plots = Workspace:FindFirstChild("Plots")
	if not plots then return end

	for _, plotModel in ipairs(plots:GetChildren()) do
		local machinesFolder = plotModel:FindFirstChild("Machines")
		if machinesFolder then
			for _, m in ipairs(machinesFolder:GetChildren()) do
				if m:IsA("Model") then
					hookMachineVisuals(m)
					local drill = m:FindFirstChild("DrillHead")
					if drill and drill:IsA("BasePart") then
						drill.CFrame = drill.CFrame * CFrame.Angles(0, dt * 4.5, 0)
					end
				end
			end
		end
	end
end)