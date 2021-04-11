
--Script version: 2021.04.11.

--The code is made by Xsticcy.
--This is the code of the Roblox plugin: Data Editor

--Read docs: https://devforum.roblox.com/t/a-new-free-datastore-editor-plugin/894063
--Link to the plugin: https://www.roblox.com/library/6013845672/DataEditor


local RS = game:GetService('RunService')

if not RS:IsEdit() then
	return
end

local recent = {
	DSNames = {};
	DSScopes = {};
	KeyNames = {};
}

local toolbar = plugin:CreateToolbar("Data Editor")
local showBtn = toolbar:CreateButton("Toggle Editor", "Shows the data store editor.", "rbxassetid://1542073887")


local recentsF
local DSNames
local DSScopes
local KeyNames

if not game.ServerStorage:FindFirstChild('~DataEditorRecents') then
	recentsF = Instance.new('Folder', game.ServerStorage)
	recentsF.Name = '~DataEditorRecents'
	DSNames = Instance.new('Folder', recentsF)
	DSNames.Name = 'DSNames'
	DSScopes = Instance.new('Folder', recentsF)
	DSScopes.Name = 'DSScopes'
	KeyNames = Instance.new('Folder', recentsF)
	KeyNames.Name = 'KeyNames'
else
	recentsF = game.ServerStorage["~DataEditorRecents"]
	DSNames = recentsF.DSNames
	DSScopes = recentsF.DSScopes
	KeyNames = recentsF.KeyNames
end

for _, c in ipairs(DSNames:GetChildren()) do
	recent.DSNames[#recent.DSNames+1] = c.Value
end
for _, c in ipairs(DSScopes:GetChildren()) do
	recent.DSScopes[#recent.DSScopes+1] = c.Value
end
for _, c in ipairs(KeyNames:GetChildren()) do
	recent.KeyNames[#recent.KeyNames+1] = c.Value
end




local DataStoreService = game:GetService("DataStoreService")
local ConnectedDataStore
local ConnectedDataStoreName
local isConnectedDataStoreOrdered = false
local isReverseListing = false
local PluginDS = DataStoreService:GetDataStore('DataEditor_DataStore')
local currentRightTab = 'Add'
local ConnectedDataStoresTable = {}

local gui = script.Parent.DataEditorGui
local coreGui = game:GetService("CoreGui")

local lastRemovedKeyValue = nil
local lastRemovedKeyName = nil

local blockedValues = {}

local localData = {}

local themeColors = {
	dark = {
		bg = Color3.fromRGB(30, 30, 30),
		bg_darker = Color3.fromRGB(20, 20, 20),
		bg_lighter = Color3.fromRGB(40, 40, 40),
		button_bg = Color3.fromRGB(77, 141, 193),
		simple_text_color = Color3.fromRGB(212,212,212),
		keyname_text_color = Color3.fromRGB(212,212,212),
		hidebtn = {
			bg = Color3.fromRGB(45,45,45),
			text_color = Color3.fromRGB(80,80,80),
		},
		remove_bg_color = Color3.fromRGB(255, 93, 93),
		disabled_text_color = Color3.fromRGB(180, 180, 180),
		accent_color = Color3.fromRGB(212,212,212),
		tableIdx = Color3.fromRGB(212,212,212),
		db_color = Color3.fromRGB(212,212,212),
		main_primary_color = Color3.fromRGB(77, 141, 193),
		key_values = {
			string = Color3.new(0.807843, 0.568627, 0.470588),
			number = Color3.new(0.709804, 0.807843, 0.658824),
			boolean = Color3.fromRGB(77, 141, 193)
		}
	},
	light = {
		bg = Color3.fromRGB(255, 255, 255),
		bg_darker = Color3.fromRGB(230, 230, 230),
		bg_lighter = Color3.fromRGB(255, 255, 255),
		button_bg = Color3.fromRGB(77, 141, 193),
		simple_text_color = Color3.fromRGB(30,30,30),
		keyname_text_color = Color3.fromRGB(60,60,60),
		hidebtn = {
			bg = Color3.fromRGB(221, 221, 221),
			text_color = Color3.fromRGB(94, 94, 94),
		},
		remove_bg_color = Color3.fromRGB(255, 93, 93),
		disabled_text_color = Color3.fromRGB(180, 180, 180),
		accent_color = Color3.fromRGB(30,30,30),
		tableIdx = Color3.fromRGB(70, 70, 70),
		db_color = Color3.fromRGB(77, 141, 193),
		main_primary_color = Color3.fromRGB(77, 141, 193),
		key_values = {
			string = Color3.new(0.568627, 0.4, 0.290196),
			number = Color3.new(0.376471, 0.576471, 0.372549),
			boolean = Color3.fromRGB(77, 141, 193)
		}
	}
}


local widgetInfo = DockWidgetPluginGuiInfo.new(
	Enum.InitialDockState.Float,  -- Widget will be initialized in floating panel
	true,   -- Widget will be initially enabled
	false,  -- Don't override the previous enabled state
	980,    -- Default width of the floating window
	630,    -- Default height of the floating window
	300,    -- Minimum width of the floating window
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

local inMenu = false

gui.Menu.menu.MouseButton1Click:Connect(function()
	inMenu = not inMenu
	gui.Add.Visible = inMenu
	if not inMenu then gui.Add.Visible = widget.AbsoluteSize.X >= 490 end
end)

widget:GetPropertyChangedSignal('AbsoluteSize'):Connect(function()
	if not inMenu then gui.Add.Visible = widget.AbsoluteSize.X >= 490 end
	gui.Menu.Visible = widget.AbsoluteSize.X >= 490 == false
	if widget.AbsoluteSize.X <= 490 then
		gui.Browser.Size = UDim2.new(1, 0  ,  0.928, -32)
		gui.Add.Size =  UDim2.fromScale(0.9,1)
		gui.Add.Position = UDim2.fromScale(0.1,0)
	else
		gui.Browser.Size = UDim2.new(0.736, 0  ,  0.928, -32)
		gui.Add.Size =  UDim2.fromScale(0.264,0.5)
		gui.Add.Position = UDim2.fromScale(0.736,0.036)
	end
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
	
	gui.Add.DSScope.BackgroundColor3 = t.bg_lighter
	gui.Add.DSScope.TextColor3 = t.simple_text_color
	gui.Refresh.BackgroundColor3 = t.bg_darker
	gui.Refresh.ImageColor3 = t.simple_text_color
	gui.Menu.BackgroundColor3 = t.bg_darker
	gui.Menu.menu.ImageColor3 = t.simple_text_color
	
	gui.UndoLastRemoved.BackgroundColor3 = t.bg_darker
	gui.UndoLastRemoved.TextLabel.TextColor3 = t.simple_text_color
	
	gui.Reverse.BackgroundColor3 = t.bg
	
	browserFrame.BackgroundColor3 = t.bg_darker
	gui.Add.BackgroundColor3 = t.bg_darker
	
	gui.Editor.BackgroundColor3 = t.bg
	gui.Editor.BorderColor3 = t.bg_darker
	
	for _, v in ipairs(browserFrame:GetChildren()) do
		pcall(function()
			v.BackgroundColor3 = t.bg
			v.Value.BackgroundColor3 = t.bg
			v.Value.TextColor3 = t.keyname_text_color
			v.Value.Expand.TextStrokeColor3 = t.bg
			v.Value.Expand.TextColor3 = t.simple_text_color
			if v ~= defaultElement and v ~= defaultTableElement and not isConnectedDataStoreOrdered then queryValue(v.ValName.Text) end
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
	if isConnectedDataStoreOrdered then connDataStore(ConnectedDataStoreName) end
end

reloadTheme(PluginDS:GetAsync('theme'))

local canSwitchTheme = true


function removeQuotationMarks(s)
	return s:gsub('"', '')
end


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

function clearBrowser(...)
	local b = ...
	if b == nil then b = browserFrame end
	for _, v in ipairs(b:GetChildren()) do
		if v.Name ~= 'Element' and v.Name ~= 'TableElement' and v.Name ~= 'PageSplit' and (v:IsA('Frame') or v:IsA('TextButton')) and v.Name ~= 'GoToNextPageButton' then
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

local currentListTo = browserFrame

function queryValue(ValueName, ...)
	local data = ...
	if (type(data) ~= 'table' and isConnectedDataStoreOrdered  and not ConnectedDataStore) then
		data = {1, ..., ValueName}
	end
	
	if (addDSName.Text ~= '' and not isConnectedDataStoreOrdered and not ConnectedDataStore) then
		local scope = 'global'
		if gui.Add.DSScope.Text ~= '' then
			scope = gui.Add.DSScope.Text
			recent.DSScopes[#recent.DSScopes+1] = gui.Add.DSScope.Text
		end
		ConnectedDataStore = DataStoreService:GetDataStore(addDSName.Text, scope)
		ConnectedDataStoreName = addDSName.Text
		connDataStore(addDSName.Text)
	end
	
	if ... and isConnectedDataStoreOrdered then
		
		ValueName = data[1]..data[3]
	end
	
	pcall(function()
		local keysLen = #ConnectedDataStoresTable[ConnectedDataStoreName].keys
		ConnectedDataStoresTable[ConnectedDataStoreName].keys[keysLen+1] = ValueName
	end)
		
	if blockedValues[ValueName] == nil then
		if currentListTo:FindFirstChild(ValueName) then
			currentListTo[ValueName]:Destroy()
			for _, v in ipairs(currentListTo:GetChildren()) do
				if v.Name == ValueName..':TableElement' then
					v:Destroy()
				end
			end
		end
		if isConnectedDataStoreOrdered then
			if currentListTo:FindFirstChild(data[3]) then
				currentListTo[data[3]]:Destroy()
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
			value = data[2]
		end
		
		if not isConnectedDataStoreOrdered then
			localData[ValueName] = value
		else
			
			if data[3] == nil then
				data[3] = 0
			end
			localData[data[3]] = value
		end
		
		if typeof(value) == 'number' then
			element.Value.TextColor3 = t.key_values.number
		end
		if typeof(value) == 'string' then
			element.Value.TextColor3 = t.key_values.string
		end
		if typeof(value) == 'boolean' then
			element.Value.TextColor3 = t.key_values.boolean
		end
		
		element.Value.Text = formatVal(value)
		element.ValName.Text = ValueName
		if ... and isConnectedDataStoreOrdered then
			
			element.ValName.Text = data[3]
		end
		element.Name = ValueName
		if ... and isConnectedDataStoreOrdered then
			
			ValueName = data[3]
		end
		if isConnectedDataStoreOrdered then
			element.Name = ValueName
		end
		element.Parent = currentListTo
		
		element.Visible = true
		if typeof(value) ~= 'table' then
			element.Value.Expand.MouseButton1Click:Connect(function()
				gui.Editor.Visible = true
				pcall(function() gui.Editor.ValueBox.Text = formatVal(value) end)
				while gui.Editor.Visible do
					local eValue = formatVal(gui.Editor.ValueBox.Text)
					pcall(function() element.Value.Text = eValue end)
					if typeof(eValue) == 'number' then
						gui.Editor.ValueBox.TextColor3 = t.key_values.number
					end
					if typeof(eValue) == 'string' then
						gui.Editor.ValueBox.TextColor3 = t.key_values.string
					end
					if typeof(eValue) == 'boolean' then
						gui.Editor.ValueBox.TextColor3 = t.key_values.boolean
					end
					wait(0.2)
				end
				queryValue(ValueName, formatVal(gui.Editor.ValueBox.Text))
			end)
		end
		
		element.DeleteBtn.MouseButton1Up:Connect(function()
			localData[ValueName] = nil
			if type(value) == 'table' then
				for _, v in ipairs(currentListTo:GetChildren()) do
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
				for _, v in ipairs(currentListTo:GetChildren()) do
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
			if element == nil and element:FindFirstChild('Value') then return end
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
		
		local function listArray(val, d,...)
			aD = d
			
			local parent = ...
			if parent == nil then
				parent = browserFrame
			end
			
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
				tableVal.Parent = parent
				local tabbing = ''
				for x = 1, aD do
					tabbing = tabbing..'  '
				end
				
				if typeof(v) == 'number' then
					tableVal.Value.TextColor3 = t.key_values.number
				end
				if typeof(v) == 'string' then
					tableVal.Value.TextColor3 = t.key_values.string
				end
				if typeof(v) == 'boolean' then
					tableVal.Value.TextColor3 = t.key_values.boolean
				end
				
				tableVal.ValIdx.Text = tabbing..i
				tableVal.Value.Text = formatVal(v)
				tableVal.Name = element.Name..':TableElement'
				if type(v)=='table' then
					listArray(v, aD+1, parent)
					aD = d
					table.remove(currentPath, #currentPath)
				end
				local myTable = currentPath[#currentPath]
				myTable[i] = v
				
				if typeof(v) ~= 'table' then
					tableVal.Value.Expand.MouseButton1Click:Connect(function()
						gui.Editor.Visible = true
						pcall(function() gui.Editor.ValueBox.Text = formatVal(v) end)
						while gui.Editor.Visible do
							local eValue = formatVal(gui.Editor.ValueBox.Text)
							pcall(function() tableVal.Value.Text = eValue end)
							if typeof(eValue) == 'number' then
								gui.Editor.ValueBox.TextColor3 = t.key_values.number
							end
							if typeof(eValue) == 'string' then
								gui.Editor.ValueBox.TextColor3 = t.key_values.string
							end
							if typeof(eValue) == 'boolean' then
								gui.Editor.ValueBox.TextColor3 = t.key_values.boolean
							end
							wait(0.2)
						end
						myTable[i] = formatVal(gui.Editor.ValueBox.Text)
						currentTable = currentPath[1]
						localData[ValueName] = currentTable
						queryValue(ValueName, currentTable, parent)
					end)
				else
					tableVal.Value.Expand.MouseButton1Click:Connect(function()
						toSeperateWidget(i, v)
					end)
				end
				tableVal.Value.FocusLost:Connect(function()
					local newVal = tableVal.Value.Text
					if formatVal(newVal) ~= formatVal(myTable[i]) then
						if newVal == '{}' then
							newVal = {""}
						else
							newVal = formatVal(newVal)
						end
						myTable[i] = newVal
						currentTable = currentPath[1]
						localData[ValueName] = currentTable
						currentListTo = parent
						queryValue(ValueName, currentTable)
						currentListTo = browserFrame
					end
				end)
				tableVal.DeleteBtn.MouseButton1Up:Connect(function()
					myTable[i] = nil
					currentTable = currentPath[1]
					localData[ValueName] = currentTable
					currentListTo = parent
					queryValue(ValueName, currentTable)
					currentListTo = browserFrame
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
						currentListTo = parent
						queryValue(ValueName, currentTable)
						currentListTo = browserFrame
					end
				end)
				if cnt == tablelength(val) then
					tableVal.NewBtn.Visible = true
					tableVal.NewBtn.MouseButton1Up:Connect(function()
						myTable[tablelength(myTable)+1] = ''
						currentTable = currentPath[1]
						localData[ValueName] = currentTable
						currentListTo = parent
						queryValue(ValueName, currentTable)
						currentListTo = browserFrame
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
		
		function toSeperateWidget(valN, valV)
			local tablewidgetInfo = DockWidgetPluginGuiInfo.new(
				Enum.InitialDockState.Float,  -- Widget will be initialized in floating panel
				true,   -- Widget will be initially enabled
				false,  -- Don't override the previous enabled state
				350,    -- Default width of the floating window
				570,    -- Default height of the floating window
				300,    -- Minimum width of the floating window
				570     -- Minimum height of the floating window
			)

			pcall(function()
				game.PluginGuiService['DE_TABLE_'..valN]:Destroy()
			end)

			-- Create new widget GUI
			local tablewidget = plugin:CreateDockWidgetPluginGui(os.time(), tablewidgetInfo)
			tablewidget.Title = "Data Editor - Table("..valN..")"
			tablewidget.Name = 'DE_TABLE_'..valN

			local bF = browserFrame:Clone()
			bF.Parent = tablewidget
			bF.Size = UDim2.new(1,0,1,-22)
			bF.Position = UDim2.new(0,0,0,22)
			
			spawn(function()
				while tablewidget.Enabled do
					wait(1)
					bF.CanvasSize = UDim2.new(0,0,0,bF.UIListLayout.AbsoluteContentSize.Y)
				end
			end)
			
			currentListTo = bF
			queryValue(ValueName, value)
			currentTable = valV
			currentListTo = browserFrame
			
			for _, o in ipairs(bF:GetDescendants()) do
				pcall(function()
					if o.Name == 'Expand' then
						o.Visible = false
					end
				end)
			end

			local saveBtn = gui.Save:Clone()
			saveBtn.Parent = tablewidget
			saveBtn.Size = UDim2.new(1,0,0, 22)
			saveBtn.Position = UDim2.new(0.5,0,0,0)

			saveBtn.MouseButton1Click:Connect(function()
				saveKeys(saveBtn)
			end)
		end
		
		if type(value) == 'table' then
			
			listArray(value, 1, currentListTo)
			currentTable = value
			
			element.Value.Expand.MouseButton1Click:Connect(function(i)
				toSeperateWidget(ValueName, value)
			end)
			
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
	
	ConnectedDataStoresTable[dsName] = {keys={}}
	
end

spawn(function()
	while wait() do
		if widget.Enabled then
			browserFrame.CanvasSize = UDim2.new(0, 0, 0, browserFrame.UIListLayout.AbsoluteContentSize.Y)
		end
	end
end)

addDSBtn.MouseButton1Click:Connect(function()
	localData = {}
	local scope = 'global'
	if gui.Add.DSScope.Text ~= '' then
		scope = gui.Add.DSScope.Text
		if #scope > 3 then
			recent.DSScopes[#recent.DSScopes+1] = scope
		end
	end
	ConnectedDataStore = DataStoreService:GetDataStore(addDSName.Text, scope)
	ConnectedDataStoreName = addDSName.Text
	isConnectedDataStoreOrdered = false
	connDataStore(addDSName.Text)
	if #addDSName.Text > 3 then
		recent.DSNames[#recent.DSNames+1] = addDSName.Text
	end
end)

addOrderedDSBtn.MouseButton1Click:Connect(function()
	localData = {}
	local scope = 'global'
	if gui.Add.DSScope.Text ~= '' then
		scope = gui.Add.DSScope.Text
		if #scope > 3 then
			recent.DSScopes[#recent.DSScopes+1] = scope
		end
	end
	ConnectedDataStore = DataStoreService:GetOrderedDataStore(addDSName.Text, scope)
	ConnectedDataStoreName = addDSName.Text
	isConnectedDataStoreOrdered = true
	connDataStore(addDSName.Text)
	if #addDSName.Text > 3 then
		recent.DSNames[#recent.DSNames+1] = addDSName.Text
	end
end)

addValueBtn.MouseButton1Click:Connect(function()
	local t = addValueName.Text
	if string.sub(t, -3,-1) == '.id' then
		t = toUserId(string.split(t, '.')[#string.split(t, '.')-1])
	end
	if not isConnectedDataStoreOrdered then
		queryValue(t)
	else
		queryValue(t, {1, 0, t})
	end
	if #addValueName.Text > 3 then
		recent.KeyNames[#recent.KeyNames+1] = addValueName.Text 
	end
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
		gui.Refresh.BorderColor3 = t.main_primary_color
		gui.Refresh.AutoButtonColor = true
		canRefresh = true
	end
end)

local canSave = true

function saveKeys(btn)
	if canSave then

		btn.BackgroundColor3 = Color3.new(0.486275, 0.486275, 0.486275)
		btn.BorderColor3 = Color3.new(0.486275, 0.486275, 0.486275)
		btn.AutoButtonColor = false

		canSave = false
		if not isConnectedDataStoreOrdered then
			for key, v in pairs(localData) do
				local value = v
				if type(v) == 'string' then
					value = removeQuotationMarks(v)
				end
				ConnectedDataStore:SetAsync(key, value)
			end
		else
			for key, v in pairs(localData) do
				local value = v
				if type(v) == 'string' then
					value = removeQuotationMarks(v)
				end
				ConnectedDataStore:SetAsync(key, value)
			end
		end

		wait(6)
		btn.BackgroundColor3 = t.main_primary_color
		btn.BorderColor3 = t.main_primary_color
		btn.AutoButtonColor = true

		canSave = true
	end
end

gui.Save.MouseButton1Up:Connect(function()
	saveKeys(gui.Save)
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

function clearDuplicates(t)
	for i1, str in ipairs(t) do
		for i2, str2 in ipairs(t) do
			if str2 == str and i1 ~= i2 then
				table.remove(t, i2)
			end
		end
	end
end

gui.RightTabs.Add.MouseButton1Click:Connect(function() gui.Add.Visible = true; gui.Connections.Visible = false end)
gui.RightTabs.Connections.MouseButton1Click:Connect(function() gui.Connections.Visible = true; gui.Add.Visible = false end)

--Connections tab part
gui.Connections:GetPropertyChangedSignal('Visible'):Connect(function() 
	
	-- clear connection frames
	for _, child in ipairs(gui.Connections.Connections:GetChildren()) do
		if child:IsA('Frame') and child.Name ~= '~Connection' then
			child:Destroy()
		end
	end
	-----
	
	for datastoreName, data in pairs(ConnectedDataStoresTable) do
		local connectionFrame = gui.Connections.Connections['~Connection']:Clone()
		connectionFrame.Name = datastoreName
		connectionFrame.Title.Text = datastoreName
		connectionFrame.Parent = gui.Connections.Connections
		connectionFrame.Connect.MouseButton1Click:Connect(function()
			connDataStore(datastoreName)
			ConnectedDataStore = DataStoreService:GetDataStore(datastoreName)
			ConnectedDataStoreName = datastoreName
			for _, keyName in ipairs(data.keys) do
				queryValue(keyName)
			end
		end)
		connectionFrame.RemoveBtn.MouseButton1Click:Connect(function()
			ConnectedDataStoresTable[datastoreName] = nil
			connectionFrame:Destroy()
		end)
		connectionFrame.Visible = true
	end
end)

addDSName:GetPropertyChangedSignal('Text'):Connect(function()
	local me = addDSName
	local recentFrame = addDSName.Recent
	local searchIn = recent.DSNames
	if #searchIn > 0 then
		for _, b in ipairs(recentFrame:GetChildren()) do
			if b:IsA('TextButton') and b.Name ~= '~Btn' then
				b:Destroy()
			end
		end
		local results = 0
		for _, str in ipairs(searchIn) do
			if str:lower():match(me.Text:lower()) then
				results += 1
				local b = recentFrame['~Btn']:Clone()
				b.Name = str
				b.Text = str
				b.Visible = true
				b.Parent = recentFrame
				b.RemoveBtn.MouseButton1Down:Connect(function()
					DSNames[str]:Destroy()
					b:Destroy()
					table.remove(searchIn, table.find(searchIn, str))
				end)
				b.MouseButton1Down:Connect(function()
					me.Text = str
				end)
			end
		end
		recentFrame.Visible = results ~= 0
	end
end)
addDSName.FocusLost:Connect(function()
	wait(0.05)
	addDSName.Recent.Visible = false
end)

gui.Add.DSScope:GetPropertyChangedSignal('Text'):Connect(function()
	local me = gui.Add.DSScope
	local recentFrame = gui.Add.DSScope.Recent
	local searchIn = recent.DSScopes
	if #searchIn > 0 then
		for _, b in ipairs(recentFrame:GetChildren()) do
			if b:IsA('TextButton') and b.Name ~= '~Btn' then
				b:Destroy()
			end
		end
		local results = 0
		for _, str in ipairs(searchIn) do
			if str:lower():match(me.Text:lower()) then
				results += 1
				local b = recentFrame['~Btn']:Clone()
				b.Name = str
				b.Text = str
				b.Visible = true
				b.Parent = recentFrame
				b.RemoveBtn.MouseButton1Down:Connect(function()
					DSScopes[str]:Destroy()
					b:Destroy()
					table.remove(searchIn, table.find(searchIn, str))
				end)
				b.MouseButton1Down:Connect(function()
					me.Text = str
				end)
			end
		end
		recentFrame.Visible = results ~= 0
	end
end)
gui.Add.DSScope.FocusLost:Connect(function()
	wait(0.05)
	gui.Add.DSScope.Recent.Visible = false
end)

addValueName:GetPropertyChangedSignal('Text'):Connect(function()
	local me = addValueName
	local recentFrame = addValueName.Recent
	local searchIn = recent.KeyNames
	if #searchIn > 0 then
		for _, b in ipairs(recentFrame:GetChildren()) do
			if b:IsA('TextButton') and b.Name ~= '~Btn' then
				b:Destroy()
			end
		end
		local results = 0
		for _, str in ipairs(searchIn) do
			if str:lower():match(me.Text:lower()) then
				results += 1
				local b = recentFrame['~Btn']:Clone()
				b.Name = str
				b.Text = str
				b.Visible = true
				b.Parent = recentFrame
				b.RemoveBtn.MouseButton1Down:Connect(function()
					KeyNames[str]:Destroy()
					b:Destroy()
					table.remove(searchIn, table.find(searchIn, str))
				end)
				b.MouseButton1Down:Connect(function()
					me.Text = str
				end)
			end
		end
		recentFrame.Visible = results ~= 0
	end
end)
addValueName.FocusLost:Connect(function()
	wait(0.05)
	addValueName.Recent.Visible = false
end)

gui.Support.MouseButton1Click:Connect(function()
	gui.Support.link.Visible = not gui.Support.link.Visible
end)
gui.Support.link.close.MouseButton1Click:Connect(function()
	gui.Support.link.Visible = false
end)

gui.Editor.Close.MouseButton1Click:Connect(function()
	gui.Editor.Visible = false
end)

function giveOutlinesAtFocus()
	for _, o in ipairs(gui:GetDescendants()) do
		if o:IsA('TextBox') then
			o.Focused:Connect(function()
				o.BorderColor3 = t.main_primary_color
				o.BorderSizePixel = 1
			end)
			o.FocusLost:Connect(function()
				o.BorderColor3 = t.main_primary_color
				o.BorderSizePixel = 0
			end)
		end
	end
end

giveOutlinesAtFocus()

while wait(1) do
	clearDuplicates(recent.DSNames)
	clearDuplicates(recent.DSScopes)
	clearDuplicates(recent.KeyNames)
	
	giveOutlinesAtFocus()
	
	if #recent.DSNames > 6 then
		table.remove(recent.DSNames, 1)
	end
	if #recent.DSScopes > 6 then
		table.remove(recent.DSScopes, 1)
	end
	if #recent.KeyNames > 6 then
		table.remove(recent.KeyNames, 1)
	end
	
	if #DSNames:GetChildren() > 6 then
		KeyNames:GetChildren()[1]:Destroy()
	end
	if #DSScopes:GetChildren() > 6 then
		KeyNames:GetChildren()[1]:Destroy()
	end
	if #KeyNames:GetChildren() > 6 then
		KeyNames:GetChildren()[1]:Destroy()
	end
	
	for _, str in ipairs(recent.DSNames) do
		if not DSNames:FindFirstChild(str) and #str > 3 then
			local v = Instance.new('StringValue', DSNames)
			v.Value = str
			v.Name = str
		end
	end
	for _, str in ipairs(recent.DSScopes) do
		if not DSScopes:FindFirstChild(str) and #str > 3 then
			local v = Instance.new('StringValue', DSScopes)
			v.Value = str
			v.Name = str
		end
	end
	for _, str in ipairs(recent.KeyNames) do
		if not KeyNames:FindFirstChild(str) and #str > 3 then
			local v = Instance.new('StringValue', KeyNames)
			v.Value = str
			v.Name = str
		end
	end
end

