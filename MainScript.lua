
--Script version: 2021.03.15.

--The code is made by Xsticcy.
--This is the code of the Roblox plugin: Data Editor

--Read docs: https://devforum.roblox.com/t/a-new-free-datastore-editor-plugin/894063
--Link to the plugin: https://www.roblox.com/library/6013845672/DataEditor



local RS = game:GetService('RunService')

if not RS:IsEdit() then
	return
end

local toolbar = plugin:CreateToolbar("Data Editor")
local showBtn = toolbar:CreateButton("Toggle Editor", "Shows the data store editor.", "rbxassetid://1542073887")

local DataStoreService = game:GetService("DataStoreService")
local ConnectedDataStore
local ConnectedDataStoreName
local isConnectedDataStoreOrdered = false
local isReverseListing = false
local PluginDS = DataStoreService:GetDataStore('DataEditor_DataStore')

local gui = script.Parent.DataEditorGui
local coreGui = game:GetService("CoreGui")

local lastRemovedKeyValue = nil
local lastRemovedKeyName = nil

local blockedValues = {}

local localData = {}

local themeColors = {
	dark = {
		bg = Color3.fromRGB(40, 44, 52),
		bg_darker = Color3.fromRGB(33, 37, 43),
		bg_lighter = Color3.fromRGB(51, 56, 66),
		button_bg = Color3.fromRGB(77, 120, 204),
		simple_text_color = Color3.fromRGB(255,255,255),
		keyname_text_color = Color3.fromRGB(76, 119, 202),
		hidebtn = {
			bg = Color3.fromRGB(83, 93, 108),
			text_color = Color3.fromRGB(153, 172, 199),
		},
		remove_bg_color = Color3.fromRGB(255, 93, 93),
		disabled_text_color = Color3.fromRGB(188, 188, 188),
		accent_color = Color3.fromRGB(255,255,255),
		tableIdx = Color3.fromRGB(96, 152, 255),
		db_color = Color3.fromRGB(255,255,255),
		def_blue = Color3.fromRGB(77, 120, 204)
	},
	light = {
		bg = Color3.fromRGB(255, 255, 255),
		bg_darker = Color3.fromRGB(230, 230, 230),
		bg_lighter = Color3.fromRGB(255, 255, 255),
		button_bg = Color3.fromRGB(77, 120, 204),
		simple_text_color = Color3.fromRGB(0,0,0),
		keyname_text_color = Color3.fromRGB(76, 119, 202),
		hidebtn = {
			bg = Color3.fromRGB(221, 221, 221),
			text_color = Color3.fromRGB(94, 94, 94),
		},
		remove_bg_color = Color3.fromRGB(255, 93, 93),
		disabled_text_color = Color3.fromRGB(188, 188, 188),
		accent_color = Color3.fromRGB(77, 120, 204),
		tableIdx = Color3.fromRGB(96, 152, 255),
		db_color = Color3.fromRGB(77, 120, 204),
		def_blue = Color3.fromRGB(77, 120, 204)
	}
}


local widgetInfo = DockWidgetPluginGuiInfo.new(
	Enum.InitialDockState.Float,  -- Widget will be initialized in floating panel
	true,   -- Widget will be initially enabled
	false,  -- Don't override the previous enabled state
	980,    -- Default width of the floating window
	630,    -- Default height of the floating window
	400,    -- Minimum width of the floating window
	570     -- Minimum height of the floating window
)

-- Create new widget GUI
local widget = plugin:CreateDockWidgetPluginGui(time(), widgetInfo)
widget.Title = "Data Editor"  -- Optional widget title

local newGui = gui.Main:Clone()
newGui.Parent = widget
gui = newGui

widget.Enabled = false

showBtn.Click:Connect(function()
	widget.Enabled = not widget.Enabled
end)

--gui elements--

local addFrame = gui.Add
local addDSName = addFrame.DSName
local addDSBtn = addFrame.AddDS
local addOrderedDSBtn = addFrame.AddOrderedDS
local addValueName = addFrame.ValueName
local addValueBtn = addFrame.AddValue

local browserFrame = gui.Browser
local defaultElement = browserFrame.Element
local defaultTableElement = browserFrame.TableElement
local gotoNextPageButton = browserFrame.GoToNextPageButton

--//--//--//--//

local currentTable = {}
local t

function reloadTheme(theme)
	pcall(function()
		if theme == nil then
			theme = 'dark'
		end
		t = themeColors[theme]
		gui.BackgroundColor3 = t.bg_darker
		addFrame.Label1.TextColor3 = t.accent_color
		addFrame.Label2.TextColor3 = t.accent_color
		addFrame.Label1.BackgroundColor3 = t.bg_lighter
		addFrame.Label2.BackgroundColor3 = t.bg_lighter
		addDSName.BackgroundColor3 = t.bg_lighter
		addValueName.BackgroundColor3 = t.bg_lighter
		addDSName.TextColor3 = t.simple_text_color
		addValueName.TextColor3 = t.simple_text_color
		
		gui.TextLabel1.TextColor3 = t.simple_text_color
		
		gui.Refresh.BackgroundColor3 = t.bg_darker
		gui.Refresh.ImageColor3 = t.simple_text_color
		
		gui.UndoLastRemoved.BackgroundColor3 = t.bg_darker
		gui.UndoLastRemoved.TextLabel.TextColor3 = t.simple_text_color
		
		gui.Reverse.BackgroundColor3 = t.bg
		
		browserFrame.BackgroundColor3 = t.bg_darker
		
		for _, v in ipairs(browserFrame:GetChildren()) do
			pcall(function()
				v.BackgroundColor3 = t.bg
				v.Value.BackgroundColor3 = t.bg_lighter
				v.Value.TextColor3 = t.keyname_text_color
				v.ValName.TextColor3 = t.keyname_text_color
				v.Dot.TextColor3 = t.simple_text_color
				v.HideBtn.BackgroundColor3 = t.hidebtn.bg
				v.HideBtn.TextColor3 = t.hidebtn.text_color
			end)
			pcall(function()
				v.ValIdx.TextColor3 = t.tableIdx
			end)
			pcall(function()
				v.DataStore.ImageColor3 = t.db_color
				v.DataStore.BackgroundColor3 = t.bg
				v.DataStore.TextLabel.BackgroundColor3 = t.bg
				v.DataStore.TextLabel.TextColor3 = t.simple_text_color
			end)
			pcall(function()
				v.TextLabel.TextColor3 = t.simple_text_color
			end)
		end
	end)
end

reloadTheme(PluginDS:GetAsync('theme'))

local canSwitchTheme = true

gui.SwitchTheme.MouseButton1Click:Connect(function()
	if canSwitchTheme then
		local theme
		local e = pcall(function()
			theme = PluginDS:GetAsync('theme')
		end)
		if theme == 'light' then
			PluginDS:SetAsync('theme', 'dark')
		else
			PluginDS:SetAsync('theme', 'light')
		end
		
		reloadTheme(PluginDS:GetAsync('theme'))
		canSwitchTheme = false
		gui.SwitchTheme.TextLabel.Text = '...'
		wait(6.01)
		gui.SwitchTheme.TextLabel.Text = 'Switch Theme'
		canSwitchTheme = true
	end
end)

addValueName.Changed:Connect(function()
	if blockedValues[addValueName.Text] ~= nil then
		addValueName.TextColor3 = t.disabled_text_color
	elseif blockedValues[addValueName.Text] == nil then
		addValueName.TextColor3 = t.simple_text_color
	end
end)

function clearBrowser()
	for _, v in ipairs(browserFrame:GetChildren()) do
		if v ~= defaultElement and v ~= defaultTableElement and v.Name ~= 'PageSplit' and (v:IsA('Frame') or v:IsA('TextButton')) and v.Name ~= 'GoToNextPageButton' then
			v:Destroy()
		end
	end
end

function toUserId(v)
	local b = pcall(function()
		local x = game.Players:GetUserIdFromNameAsync(v)
	end)
	if b then
		return tonumber(game.Players:GetUserIdFromNameAsync(v))
	end
	return v
end

function formatVal(v)
	if tonumber(v) ~= nil then
		return tonumber(v)
	end
	if type(v) == 'table' then
		return '{}'
	end
	if v == true or v == false then
		return tostring(v)
	end
	if v == 'true' then
		return true
	end
	if v == 'false' then
		return false
	end
	if v == nil then
		return ''
	end
	if v == '{}' then
		return {''}
	end
	if type(v) == 'string' and not string.match(v, '"') then
		return '"'..v..'"'
	end
	return v
end

function queryValue(ValueName, ...)
	
	if (not ConnectedDataStore and addDSName.Text ~= '') or (addDSName.Text ~= ConnectedDataStoreName) then
		ConnectedDataStore = DataStoreService:GetDataStore(addDSName.Text)
		ConnectedDataStoreName = addDSName.Text
		connDataStore(addDSName.Text)
	end
	
	if ... and isConnectedDataStoreOrdered then
		local data = ...
		ValueName = data[1]..data[3]
	end
	
	if blockedValues[ValueName] == nil then
		if browserFrame:FindFirstChild(ValueName) then
			browserFrame[ValueName]:Destroy()
			for _, v in ipairs(browserFrame:GetChildren()) do
				if v.Name == ValueName..':TableElement' then
					v:Destroy()
				end
			end
		end
		local element = defaultElement:Clone()
		local value
		if ... == nil then
			value = ConnectedDataStore:GetAsync(ValueName)
		end
		if value == nil then
			value = ''
		end
		if ... and not isConnectedDataStoreOrdered then
			value = ...
		end
		
		if ... and isConnectedDataStoreOrdered then
			local data = ...
			value = data[2]
		end
		
		if not isConnectedDataStoreOrdered then
			localData[ValueName] = value
		else
			local data = ...
			localData[data[3]] = value
		end
		
		element.Value.Text = formatVal(value)
		element.ValName.Text = ValueName
		if ... and isConnectedDataStoreOrdered then
			local data = ...
			element.ValName.Text = data[3]
		end
		element.Name = ValueName
		if ... and isConnectedDataStoreOrdered then
			local data = ...
			ValueName = data[3]
		end
		if isConnectedDataStoreOrdered then
			element.Name = ValueName
		end
		element.Parent = browserFrame
		
		element.Visible = true
		
		local blockBox = function(...)
			local p = {...}
			if addValueName.Text == ValueName then
				addValueName.TextColor3 = t.disabled_text_color
			end
			local e
			local newVal = ValueName
			if element ~= nil and element:FindFirstChild('Value') then
				if type(value) == 'table' then
					for _, v in ipairs(browserFrame:GetChildren()) do
						if v.Name == element.Name..':TableElement' then
							v:Destroy()
						end
					end
					newVal = formatVal(element.Value.Text)
				else
					newVal = formatVal(element.Value.Text)
				end
				element:Destroy()
				if not p[1] then
					queryValue(ValueName)
				end
				if type(newVal) == 'table' then 
					newVal = '{}'
				end
				e = browserFrame[ValueName]
				blockedValues[ValueName] = true
				e.Value.TextEditable = false
				e.Value.Text = e.Value.Text
				e.Value.TextColor3 = Color3.fromRGB(170, 150, 115)
				if type(value) == 'table' then
					for _, v in ipairs(browserFrame:GetChildren()) do
						if v.Name == e.Name..':TableElement' then
							v.Value.TextEditable = false
							v.Value.TextColor3 = Color3.fromRGB(170, 150, 115)
						end
					end
				end
			end
			wait(6)
			if e == nil then return end
			pcall(function()
				blockedValues[ValueName] = nil
				if addValueName.Text == ValueName then
					addValueName.TextColor3 = t.simple_text_color
				end
				e.Value.TextEditable = true
				e.Value.TextColor3 = t.keyname_text_color
				if type(value) == 'table' then
					for _, v in ipairs(browserFrame:GetChildren()) do
						if v.Name == e.Name..':TableElement' then
							v.Value.TextEditable = true
							v.Value.TextColor3 = t.keyname_text_color
						end
					end
				end
			end)
		end
		
		element.DeleteBtn.MouseButton1Up:Connect(function()
			localData[ValueName] = nil
			if type(value) == 'table' then
				for _, v in ipairs(browserFrame:GetChildren()) do
					if v.Name == element.Name..':TableElement' then
						v:Destroy()
					end
				end
			end
			element:Destroy()
			element = nil
			lastRemovedKeyValue = value
			lastRemovedKeyName = ValueName
			ConnectedDataStore:RemoveAsync(ValueName)
		end)
		
		element.HideBtn.MouseButton1Up:Connect(function()
			localData[ValueName] = nil
			if type(value) == 'table' then
				for _, v in ipairs(browserFrame:GetChildren()) do
					if v.Name == element.Name..':TableElement' then
						v:Destroy()
					end
				end
			end
			element:Destroy()
			element = nil
		end)
		
		element.Value.Focused:Connect(function()
			element.Value.BackgroundColor3 = t.bg_darker
		end)
		
		element.Value.FocusLost:Connect(function()
			wait(0.1)
			if element == nil then return end
			element.Value.BackgroundColor3 = t.bg
			local newVal = element.Value.Text
			pcall(function()
				value = tostring(ConnectedDataStore:GetAsync(ValueName))
			end)
			if value == nil then
				value = ''
			end
			
			newVal = formatVal(newVal)
			if newVal ~= formatVal(value) and blockedValues[ValueName] == nil then
				localData[ValueName] = newVal
				queryValue(ValueName, newVal)
			end
		end)
		
		element.MouseEnter:Connect(function()
			element.BackgroundColor3 = t.bg_lighter
		end)
		element.MouseLeave:Connect(function()
			element.BackgroundColor3 = t.bg
		end)
		
		local aD = 1
		local currentPath = {}
		local function listArray(val, d)
			aD = d
			currentPath[#currentPath+1] = val
			
			local function tablelength(T)
				local count = 0
				for _ in pairs(T) do count = count + 1 end
				return count
			end
			
			local cnt = 0
			
			for i, v in pairs(val) do
				cnt += 1
				local tableVal = defaultTableElement:Clone()
				tableVal.Visible = true
				tableVal.Parent = browserFrame
				local tabbing = ''
				for x = 1, aD do
					tabbing = tabbing..'  '
				end
				tableVal.ValIdx.Text = tabbing..i
				tableVal.Value.Text = formatVal(v)
				tableVal.Name = element.Name..':TableElement'
				if type(v)=='table' then
					listArray(v, aD+1)
					aD = d
					table.remove(currentPath, #currentPath)
				end
				local myTable = currentPath[#currentPath]
				myTable[i] = v
				tableVal.Value.FocusLost:Connect(function()
					local newVal = tableVal.Value.Text
					if formatVal(newVal) ~= formatVal(myTable[i]) then
						newVal = formatVal(newVal)
						myTable[i] = newVal
						currentTable = currentPath[1]
						localData[ValueName] = currentTable
					end
				end)
				tableVal.DeleteBtn.MouseButton1Up:Connect(function()
					myTable[i] = nil
					currentTable = currentPath[1]
					localData[ValueName] = currentTable
					queryValue(ValueName, currentTable)
				end)
				tableVal.ValIdx.FocusLost:Connect(function()
					local newVal = tableVal.Value.Text
					if tableVal.ValIdx.Text == '' then
						tableVal.ValIdx.Text = i
						return
					end
					if true then
						newVal = formatVal(newVal)
						myTable[i] = nil
						myTable[tableVal.ValIdx.Text] = newVal
						currentTable = currentPath[1]
						localData[ValueName] = currentTable
						queryValue(ValueName, currentTable)
					end
				end)
				if cnt == tablelength(val) then
					tableVal.NewBtn.Visible = true
					tableVal.NewBtn.MouseButton1Up:Connect(function()
						myTable[tablelength(myTable)+1] = ''
						currentTable = currentPath[1]
						localData[ValueName] = currentTable
						queryValue(ValueName, currentTable)
					end)
				end
				tableVal.MouseEnter:Connect(function()
					tableVal.BackgroundColor3 = t.bg_lighter
				end)
				tableVal.MouseLeave:Connect(function()
					tableVal.BackgroundColor3 = t.bg
				end)
			end
		end
		
		if type(value) == 'table' then
			listArray(value, 1)
			currentTable = value
		end
		
	end
end

function connDataStore(dsName)
	clearBrowser()
	
	local dsElement = defaultElement:Clone()
	dsElement.Value:Destroy()
	dsElement.ValName.Text = dsName
	dsElement.DataStore.Visible = true
	dsElement.Parent = browserFrame
	dsElement.Dot.Visible = false
	dsElement.LayoutOrder = -10
	
	dsElement.Visible = true
	
	dsElement.DeleteBtn.Visible = false
	dsElement.HideBtn.Visible = false
	
	dsElement.DataStore.InputEnded:Connect(function(inp)
		if inp.UserInputType.Value == 0 then
			dsElement:Destroy()
			ConnectedDataStoreName = ''
			ConnectedDataStore = nil
			isConnectedDataStoreOrdered = false
			clearBrowser()
		end
	end)
	
	if isConnectedDataStoreOrdered then
		local pages = ConnectedDataStore:GetSortedAsync(isReverseListing, 30)
		local pageNumber = 1
		local keys = pages:GetCurrentPage()
		
		local function addNewPage()
			local pageSplit = gui.Browser.PageSplit:Clone()
			pageSplit.Name = 'PSplit'..pageNumber
			pageSplit.Label.Text = '-PAGE ['..pageNumber..']-'
			pageSplit.Parent = gui.Browser
			pageSplit.Visible = true
			for key, value in pairs(keys) do
				queryValue(key, {pageNumber, value.value, value.key})
			end

			if pages.IsFinished then
				--nothing
			else
				local buttonClone = gotoNextPageButton:Clone()
				buttonClone.Visible = true
				buttonClone.Parent = gui.Browser
				buttonClone.Name = 'GTNPBTN'
				buttonClone.MouseButton1Click:Connect(function()
					buttonClone:Destroy()
					pages:AdvanceToNextPageAsync()
					pageNumber += 1
					keys = pages:GetCurrentPage()
					addNewPage()
				end)
			end
		end
		
		addNewPage()
		
	end
	
end

spawn(function()
	while wait() do
		if widget.Enabled then
			browserFrame.CanvasSize = UDim2.new(0, 0, 0, browserFrame.UIListLayout.AbsoluteContentSize.Y)
		end
	end
end)

addDSBtn.MouseButton1Up:Connect(function()
	localData = {}
	local b = pcall(function()
		ConnectedDataStore = DataStoreService:GetDataStore(addDSName.Text)
	end)
	if b then
		ConnectedDataStoreName = addDSName.Text
		isConnectedDataStoreOrdered = false
		connDataStore(addDSName.Text)
	end
end)

addOrderedDSBtn.MouseButton1Up:Connect(function()
	localData = {}
	local b = pcall(function()
		ConnectedDataStore = DataStoreService:GetOrderedDataStore(addDSName.Text)
	end)
	if b then
		ConnectedDataStoreName = addDSName.Text
		isConnectedDataStoreOrdered = true
		connDataStore(addDSName.Text)
	end
end)

addValueBtn.MouseButton1Up:Connect(function()
	local t = addValueName.Text
	if string.sub(t, -3,-1) == '.id' then
		t = toUserId(string.split(t, '.')[#string.split(t, '.')-1])
	end
	queryValue(t)
end)

local canRefresh = true

gui.Refresh.MouseButton1Up:Connect(function()
	if canRefresh then
		canRefresh = false
		
		gui.Refresh.BackgroundColor3 = Color3.new(0.486275, 0.486275, 0.486275)
		gui.Refresh.BorderColor3 = Color3.new(0.486275, 0.486275, 0.486275)
		gui.Refresh.AutoButtonColor = false
		
		for key, _ in pairs(localData) do
			queryValue(key)
		end
		wait(6)
		gui.Refresh.BackgroundColor3 = t.bg
		gui.Refresh.BorderColor3 = t.def_blue
		gui.Refresh.AutoButtonColor = true
		canRefresh = true
	end
end)

local canSave = true

gui.Save.MouseButton1Up:Connect(function()
	if canSave then
		
		gui.Save.BackgroundColor3 = Color3.new(0.486275, 0.486275, 0.486275)
		gui.Save.BorderColor3 = Color3.new(0.486275, 0.486275, 0.486275)
		gui.Save.AutoButtonColor = false
		
		canSave = false
		if not isConnectedDataStoreOrdered then
			for key, value in pairs(localData) do
				ConnectedDataStore:SetAsync(key, value)
			end
		else
			for key, value in pairs(localData) do
				ConnectedDataStore:SetAsync(key, value)
			end
		end
		
		wait(6)
		gui.Save.BackgroundColor3 = t.def_blue
		gui.Save.BorderColor3 = t.def_blue
		gui.Save.AutoButtonColor = true
		
		canSave = true
	end
end)

gui.UndoLastRemoved.MouseButton1Up:Connect(function()
	if lastRemovedKeyName ~= nil and lastRemovedKeyValue ~= nil then
		queryValue(lastRemovedKeyName, lastRemovedKeyValue)
	end
end)

gui.Reverse.MouseButton1Up:Connect(function()
	isReverseListing = not isReverseListing
	if isReverseListing then
		gui.Reverse.BackgroundColor3 = Color3.fromRGB(76, 119, 202)
	else
		gui.Reverse.BackgroundColor3 = t.bg
	end
	if ConnectedDataStore then
		connDataStore(ConnectedDataStoreName)
	end
end)
