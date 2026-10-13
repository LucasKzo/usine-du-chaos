-- StarterPlayer/StarterPlayerScripts/Controllers/BuildController.lua
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlotAndPrestigeConfig = require(ReplicatedStorage.Shared.Config.PlotAndPrestigeConfig)
local ModelFactory = require(ReplicatedStorage.Shared.ModelFactory)

local BuildController = {}
BuildController.Mode = "None"
BuildController.SelectedMachineType = nil
BuildController.MovingMachineId = nil
BuildController.Rotation = 0
BuildController.CurrentGridX = 1
BuildController.CurrentGridZ = 1
BuildController.IsValidPlacement = false
BuildController.PreviewModel = nil
BuildController.OnMachineClicked = nil
BuildController.OnModeChanged = nil

local localPlayer = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")

local function getMyPlotModel(): Model?
	local idx = localPlayer:GetAttribute("PlotIndex")
	local folder = Workspace:FindFirstChild("Plots")
	return (idx and folder) and folder:FindFirstChild("Plot_" .. tostring(idx)) or nil
end

local function getScreenPosition(input: InputObject?): Vector2
	if input and input.UserInputType == Enum.UserInputType.Touch then
		return Vector2.new(input.Position.X, input.Position.Y)
	end
	return UserInputService:GetMouseLocation()
end

local function getViewportRay(screenPosition: Vector2): Ray?
	local camera = Workspace.CurrentCamera
	if not camera then return nil end

	local topLeftInset = GuiService:GetGuiInset()
	return camera:ViewportPointToRay(screenPosition.X - topLeftInset.X, screenPosition.Y - topLeftInset.Y)
end

function BuildController.StartPlaceMode(machineType: string)
	BuildController.CancelMode()
	BuildController.Mode = "Place"
	BuildController.SelectedMachineType = machineType
	BuildController.PreviewModel = ModelFactory.CreateMachineModel(machineType, true)
	BuildController.PreviewModel.Parent = Workspace
	if BuildController.OnModeChanged then BuildController.OnModeChanged(true) end
end

function BuildController.StartMoveMode(machineId: string, machineType: string, currentRot: number)
	BuildController.CancelMode()
	BuildController.Mode = "Move"
	BuildController.MovingMachineId = machineId
	BuildController.SelectedMachineType = machineType
	BuildController.Rotation = currentRot or 0
	BuildController.PreviewModel = ModelFactory.CreateMachineModel(machineType, true)
	BuildController.PreviewModel.Parent = Workspace
	if BuildController.OnModeChanged then BuildController.OnModeChanged(true) end
end

function BuildController.RotatePreview()
	BuildController.Rotation = (BuildController.Rotation + 90) % 360
end

function BuildController.CancelMode()
	BuildController.Mode = "None"
	BuildController.SelectedMachineType = nil
	BuildController.MovingMachineId = nil
	if BuildController.PreviewModel then
		BuildController.PreviewModel:Destroy()
		BuildController.PreviewModel = nil
	end
	if BuildController.OnModeChanged then BuildController.OnModeChanged(false) end
end

function BuildController.ConfirmAction()
	if not BuildController.IsValidPlacement then return end
	if BuildController.Mode == "Place" and BuildController.SelectedMachineType then
		remotes.PlaceMachine:FireServer(BuildController.SelectedMachineType, BuildController.CurrentGridX, BuildController.CurrentGridZ, BuildController.Rotation)
	elseif BuildController.Mode == "Move" and BuildController.MovingMachineId then
		remotes.MoveMachine:FireServer(BuildController.MovingMachineId, BuildController.CurrentGridX, BuildController.CurrentGridZ, BuildController.Rotation)
		BuildController.CancelMode()
	end
end

function BuildController.Init()
	RunService.RenderStepped:Connect(function()
		if BuildController.Mode == "None" or not BuildController.PreviewModel then return end

		local plotModel = getMyPlotModel()
		if not plotModel then return end
		local basePart = plotModel:FindFirstChild("PlotBase")
		local machinesFolder = plotModel:FindFirstChild("Machines")
		if not basePart or not machinesFolder then return end

		local cellsCount = basePart:GetAttribute("Cells") or 6
		local screenPosition = getScreenPosition(nil)
		local ray = getViewportRay(screenPosition)
		if not ray then return end
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Include
		params.FilterDescendantsInstances = { basePart }

		local hit = Workspace:Raycast(ray.Origin, ray.Direction * 350, params)
		if hit then
			local cellSize = PlotAndPrestigeConfig.CellSize
			local totalSize = cellsCount * cellSize
			local originX = basePart.Position.X - (totalSize / 2)
			local originZ = basePart.Position.Z - (totalSize / 2)

			local gx = math.clamp(math.ceil((hit.Position.X - originX) / cellSize), 1, cellsCount)
			local gz = math.clamp(math.ceil((hit.Position.Z - originZ) / cellSize), 1, cellsCount)
			BuildController.CurrentGridX = gx
			BuildController.CurrentGridZ = gz

			local occupied = false
			for _, m in ipairs(machinesFolder:GetChildren()) do
				if m:GetAttribute("GridX") == gx and m:GetAttribute("GridZ") == gz then
					if m:GetAttribute("MachineId") ~= BuildController.MovingMachineId then
						occupied = true
						break
					end
				end
			end
			BuildController.IsValidPlacement = not occupied

			local baseHeight = BuildController.PreviewModel.PrimaryPart and BuildController.PreviewModel.PrimaryPart.Size.Y or 0.6
			local floorTopY = basePart.Position.Y + (basePart.Size.Y / 2)
			local worldX = originX + (gx - 0.5) * cellSize
			local worldZ = originZ + (gz - 0.5) * cellSize
			local worldY = floorTopY + (baseHeight / 2)

			local cf = CFrame.new(worldX, worldY, worldZ) * CFrame.Angles(0, math.rad(-BuildController.Rotation), 0)
			ModelFactory.PivotMachineModel(BuildController.PreviewModel, cf)

			if BuildController.PreviewModel.PrimaryPart then
				BuildController.PreviewModel.PrimaryPart.Color = BuildController.IsValidPlacement
					and Color3.fromRGB(70, 245, 110) or Color3.fromRGB(255, 70, 70)
			end
		end
	end)

	UserInputService.InputBegan:Connect(function(input, gp)
		if gp then return end
		if input.KeyCode == Enum.KeyCode.R then
			BuildController.RotatePreview()
		elseif input.KeyCode == Enum.KeyCode.X or input.KeyCode == Enum.KeyCode.Escape then
			BuildController.CancelMode()
		elseif input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			if BuildController.Mode ~= "None" then
				BuildController.ConfirmAction()
			else
				local plotModel = getMyPlotModel()
				if not plotModel then return end
				local machinesFolder = plotModel:FindFirstChild("Machines")
				if not machinesFolder then return end

				local screenPosition = getScreenPosition(input)
				local ray = getViewportRay(screenPosition)
				if not ray then return end
				local params = RaycastParams.new()
				params.FilterType = Enum.RaycastFilterType.Include
				params.FilterDescendantsInstances = { machinesFolder }

				local hit = Workspace:Raycast(ray.Origin, ray.Direction * 250, params)
				if hit and hit.Instance then
					local model = hit.Instance:FindFirstAncestorOfClass("Model")
					if model and model:GetAttribute("MachineId") and BuildController.OnMachineClicked then
						BuildController.OnMachineClicked(model)
					end
				end
			end
		end
	end)
end

return BuildController