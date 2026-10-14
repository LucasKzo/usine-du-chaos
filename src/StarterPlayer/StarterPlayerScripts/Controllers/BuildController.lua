-- StarterPlayer/StarterPlayerScripts/Controllers/BuildController.lua
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local UserInputService = game:GetService("UserInputService")
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
local camera = Workspace.CurrentCamera
local remotes = ReplicatedStorage:WaitForChild("Remotes")

local demolishHighlight: Highlight? = nil
local isMouseDown = false
local lastDemolishedId = ""

local function playSfx(soundId: string, volume: number, pitch: number)
	local s = Instance.new("Sound")
	s.SoundId = soundId
	s.Volume = volume
	s.PlaybackSpeed = pitch
	s.Parent = SoundService
	s:Play()
	task.delay(1.5, function()
		s:Destroy()
	end)
end

local function getMyPlotModel(): Model?
	local idx = localPlayer:GetAttribute("PlotIndex")
	local folder = Workspace:FindFirstChild("Plots")
	return (idx and folder) and folder:FindFirstChild("Plot_" .. tostring(idx)) or nil
end

local function getHoveredMachineModel(): Model?
	local plotModel = getMyPlotModel()
	if not plotModel then return nil end
	local machinesFolder = plotModel:FindFirstChild("Machines")
	if not machinesFolder then return nil end

	local mouseLoc = UserInputService:GetMouseLocation()
	local ray = camera:ViewportPointToRay(mouseLoc.X, mouseLoc.Y)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { machinesFolder }

	local hit = Workspace:Raycast(ray.Origin, ray.Direction * 300, params)
	if hit and hit.Instance then
		local current: Instance? = hit.Instance
		while current and current.Parent ~= machinesFolder and current ~= Workspace do
			current = current.Parent
		end
		if current and current:IsA("Model") and current:GetAttribute("MachineId") then
			return current
		end
	end
	return nil
end

function BuildController.StartPlaceMode(machineType: string)
	BuildController.CancelMode()
	BuildController.Mode = "Place"
	BuildController.SelectedMachineType = machineType
	BuildController.PreviewModel = ModelFactory.CreateMachineModel(machineType, true)
	BuildController.PreviewModel.Parent = Workspace
	if BuildController.OnModeChanged then
		BuildController.OnModeChanged(true, "Place")
	end
end

function BuildController.StartMoveMode(machineId: string, machineType: string, currentRot: number)
	BuildController.CancelMode()
	BuildController.Mode = "Move"
	BuildController.MovingMachineId = machineId
	BuildController.SelectedMachineType = machineType
	BuildController.Rotation = currentRot or 0
	BuildController.PreviewModel = ModelFactory.CreateMachineModel(machineType, true)
	BuildController.PreviewModel.Parent = Workspace
	if BuildController.OnModeChanged then
		BuildController.OnModeChanged(true, "Move")
	end
end

function BuildController.StartDemolishMode()
	BuildController.CancelMode()
	BuildController.Mode = "Demolish"
	local hl = Instance.new("Highlight")
	hl.FillColor = Color3.fromRGB(255, 55, 55)
	hl.OutlineColor = Color3.fromRGB(255, 220, 220)
	hl.FillTransparency = 0.35
	hl.Parent = Workspace
	demolishHighlight = hl
	if BuildController.OnModeChanged then
		BuildController.OnModeChanged(true, "Demolish")
	end
end

function BuildController.RotatePreview()
	BuildController.Rotation = (BuildController.Rotation + 90) % 360
	playSfx("rbxassetid://12221967", 0.35, 1.25)
	if BuildController.PreviewModel and BuildController.PreviewModel.PrimaryPart then
		local pos = BuildController.PreviewModel.PrimaryPart.Position
		local cf = CFrame.new(pos) * CFrame.Angles(0, math.rad(-BuildController.Rotation), 0)
		ModelFactory.PivotMachineModel(BuildController.PreviewModel, cf)
	end
end

function BuildController.CancelMode()
	BuildController.Mode = "None"
	BuildController.SelectedMachineType = nil
	BuildController.MovingMachineId = nil
	isMouseDown = false
	lastDemolishedId = ""
	if BuildController.PreviewModel then
		BuildController.PreviewModel:Destroy()
		BuildController.PreviewModel = nil
	end
	if demolishHighlight then
		demolishHighlight:Destroy()
		demolishHighlight = nil
	end
	if BuildController.OnModeChanged then
		BuildController.OnModeChanged(false, "None")
	end
end

function BuildController.ConfirmAction()
	if BuildController.Mode == "Demolish" then
		local target = getHoveredMachineModel()
		if target then
			local mId = target:GetAttribute("MachineId")
			if mId and mId ~= lastDemolishedId then
				lastDemolishedId = mId
				playSfx("rbxassetid://12221967", 0.45, 0.75)
				remotes.SellMachine:FireServer(mId)
			end
		end
		return
	end

	if not BuildController.IsValidPlacement then return end
	if BuildController.Mode == "Place" and BuildController.SelectedMachineType then
		playSfx("rbxassetid://12221967", 0.45, 1.05)
		remotes.PlaceMachine:FireServer(BuildController.SelectedMachineType, BuildController.CurrentGridX, BuildController.CurrentGridZ, BuildController.Rotation)
	elseif BuildController.Mode == "Move" and BuildController.MovingMachineId then
		playSfx("rbxassetid://12221967", 0.45, 1.1)
		remotes.MoveMachine:FireServer(BuildController.MovingMachineId, BuildController.CurrentGridX, BuildController.CurrentGridZ, BuildController.Rotation)
		BuildController.CancelMode()
	end
end

function BuildController.Init()
	RunService.RenderStepped:Connect(function()
		if BuildController.Mode == "Demolish" then
			local hovered = getHoveredMachineModel()
			if demolishHighlight then
				demolishHighlight.Adornee = hovered
			end
			if isMouseDown and hovered then
				BuildController.ConfirmAction()
			end
			return
		end

		if BuildController.Mode == "None" or not BuildController.PreviewModel then return end

		local plotModel = getMyPlotModel()
		if not plotModel then return end
		local basePart = plotModel:FindFirstChild("PlotBase")
		local machinesFolder = plotModel:FindFirstChild("Machines")
		if not basePart or not machinesFolder then return end

		local cellsCount = basePart:GetAttribute("Cells") or PlotAndPrestigeConfig.PlotTiers[1].Cells
		local mouseLoc = UserInputService:GetMouseLocation()
		local ray = camera:ViewportPointToRay(mouseLoc.X, mouseLoc.Y)
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

			local baseHeight = BuildController.PreviewModel.PrimaryPart and BuildController.PreviewModel.PrimaryPart.Size.Y or 0.3
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
		if input.KeyCode == Enum.KeyCode.R then
			if BuildController.Mode == "Place" or BuildController.Mode == "Move" then
				BuildController.RotatePreview()
			end
			return
		elseif input.KeyCode == Enum.KeyCode.X or input.KeyCode == Enum.KeyCode.Escape then
			if BuildController.Mode ~= "None" then
				BuildController.CancelMode()
			end
			return
		end

		if gp then return end

		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			isMouseDown = true
			if BuildController.Mode ~= "None" then
				BuildController.ConfirmAction()
			else
				local clickedModel = getHoveredMachineModel()
				if clickedModel and BuildController.OnMachineClicked then
					playSfx("rbxassetid://12221967", 0.3, 1.35)
					BuildController.OnMachineClicked(clickedModel)
				end
			end
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			isMouseDown = false
			lastDemolishedId = ""
		end
	end)
end

return BuildController