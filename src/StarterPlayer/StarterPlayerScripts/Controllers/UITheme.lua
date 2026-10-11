-- StarterPlayer/StarterPlayerScripts/Controllers/UITheme.lua
local UITheme = {}

function UITheme.StyleFrame(frame: GuiObject, bgColor: Color3, radius: number)
	frame.BackgroundColor3 = bgColor
	frame.BorderSizePixel = 0
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = frame
end

function UITheme.CreateButton(parent: Instance, text: string, size: UDim2, pos: UDim2, color: Color3, textSize: number?): TextButton
	local btn = Instance.new("TextButton")
	btn.Size = size
	btn.Position = pos
	UITheme.StyleFrame(btn, color, 6)
	btn.Text = text
	btn.TextColor3 = Color3.new(1, 1, 1)
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = textSize or 14
	btn.Parent = parent
	return btn
end

function UITheme.CreateLabel(parent: Instance, text: string, size: UDim2, pos: UDim2, color: Color3, textSize: number?, alignLeft: boolean?): TextLabel
	local lbl = Instance.new("TextLabel")
	lbl.Size = size
	lbl.Position = pos
	lbl.BackgroundTransparency = 1
	lbl.Text = text
	lbl.TextColor3 = color
	lbl.Font = Enum.Font.GothamBold
	lbl.TextSize = textSize or 14
	if alignLeft then
		lbl.TextXAlignment = Enum.TextXAlignment.Left
	end
	lbl.Parent = parent
	return lbl
end

return UITheme