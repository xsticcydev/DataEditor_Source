
--Script version: 2021.01.16.

--The code is made by Xsticcy.
--This is the code of the Roblox plugin: Data Editor

--Read docs: https://devforum.roblox.com/t/a-new-free-datastore-editor-plugin/894063
--Link to the plugin: https://www.roblox.com/library/6013845672/DataEditor

local RS = game:GetService('RunService')

if not RS:IsEdit() then
	return
end

local toolbar = plugin:CreateToolbar("Data Editor")
local showBtn = toolbar:CreateButton("Show Editor", "Shows the data store editor.", "rbxassetid://1542073887")

local DataStoreService = game:GetService("DataStoreService")
local ConnectedDataStore
local ConnectedDataStoreName
local PluginDS = DataStoreService:GetDataStore('DataEditor_DataStore')

local gui = script.Parent.DataEditorGui
local coreGui = game:GetService("CoreGui")

local blockedValues = {}

local themeColors = {
	dark = {
		bg = Color3.fromRGB(46,46,46),
		bg_darker = Color3.fromRGB(40,40,40),
		bg_lighter = Color3.fromRGB(56,56,56),
		simple_text_color = Color3.fromRGB(255,255,255),
		disabled_text_color = Color3.fromRGB(188, 188, 188),
		accent_color = Color3.fromRGB(0, 170, 127),
		tableIdx = Color3.fromRGB(255, 247, 0),
		db_color = Color3.fromRGB(255,255,255)
	},
	light = {
		bg = Color3.fromRGB(240,240,240),
		bg_darker = Color3.fromRGB(220,220,220),
		bg_lighter = Color3.fromRGB(255,255,255),
		simple_text_color = Color3.fromRGB(0,0,0),
		disabled_text_color = Color3.fromRGB(100, 100, 100),
		accent_color = Color3.fromRGB(17, 0, 255),
		tableIdx = Color3.fromRGB(23, 173, 0),
		db_color = Color3.fromRGB(0, 170, 127)
	}
}

if coreGui:FindFirstChild(gui.Name) then
	coreGui[gui.Name]:Destroy()
	local newGui = gui:Clone()
	newGui.Parent = coreGui
	gui = newGui
else
	local newGui = gui:Clone()
	newGui.Parent = coreGui
	gui = newGui
end

gui.Enabled = false


showBtn.Click:Connect(function()
	gui.Enabled = not gui.Enabled
end)

--gui elements--

local addFrame = gui.Main.Add
local addDSName = addFrame.DSName
local addDSBtn = addFrame.AddDS
local addValueName = addFrame.ValueName
local addValueBtn = addFrame.AddValue

local browserFrame = gui.Main.Browser
local defaultElement = browserFrame.Element
local defaultTableElement = browserFrame.TableElement

--//--//--//--//

local currentTable = {}
local t

function reloadTheme(theme)
	pcall(function()
		if theme == nil then
			theme = 'dark'
		end
		t = themeColors[theme]
		gui.Main.BackgroundColor3 = t.bg
		addFrame.Label1.TextColor3 = t.accent_color
		addFrame.Label2.TextColor3 = t.accent_color
		addFrame.Label1.BackgroundColor3 = t.bg_lighter
		addFrame.Label2.BackgroundColor3 = t.bg_lighter
		addDSName.BackgroundColor3 = t.bg_lighter
		addValueName.BackgroundColor3 = t.bg_lighter
		addDSName.TextColor3 = t.simple_text_color
		addValueName.TextColor3 = t.simple_text_color
		
		browserFrame.BackgroundColor3 = t.bg_darker
		
		for _, v in ipairs(browserFrame:GetChildren()) do
			pcall(function()
				v.BackgroundColor3 = t.bg
				v.Value.TextColor3 = t.accent_color
				v.Decor.BackgroundColor3 = t.bg
				v.Decor.TextColor3 = t.simple_text_color
				v.Dot.BackgroundColor3 = t.bg
				v.Dot.TextColor3 = t.simple_text_color
				v.HideBtn.BackgroundColor3 = t.bg_darker
				v.HideBtn.TextColor3 = t.accent_color
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
		end
	end)
end

reloadTheme(PluginDS:GetAsync('theme'))


t = themeColors[PluginDS:GetAsync('theme')]

local canSwitchTheme = true

gui.Main.SwitchTheme.MouseButton1Click:Connect(function()
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
		gui.Main.SwitchTheme.Text = '...'
		wait(6.01)
		gui.Main.SwitchTheme.Text = 'Switch Theme'
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
		if v ~= defaultElement and v ~= defaultTableElement and v:IsA('Frame') then
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

function queryValue(ValueName)
	if (not ConnectedDataStore and addDSName.Text ~= '') or (addDSName.Text ~= ConnectedDataStoreName) then
		ConnectedDataStore = DataStoreService:GetDataStore(addDSName.Text)
		ConnectedDataStoreName = addDSName.Text
		connDataStore(addDSName.Text)
	end
	
	if blockedValues[ValueName] == nil and not browserFrame:FindFirstChild(ValueName) then
		local element = defaultElement:Clone()
		local value = ConnectedDataStore:GetAsync(ValueName)
		if value == nil then
			value = ''
		end
		element.Value.Text = formatVal(value)
		element.ValName.Text = ValueName
		element.Name = ValueName
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
				e.Value.TextColor3 = t.accent_color
				if type(value) == 'table' then
					for _, v in ipairs(browserFrame:GetChildren()) do
						if v.Name == e.Name..':TableElement' then
							v.Value.TextEditable = true
							v.Value.TextColor3 = t.accent_color
						end
					end
				end
			end)
		end
		
		element.DeleteBtn.MouseButton1Up:Connect(function()
			spawn(function()
				blockBox(false)
			end)
			if type(value) == 'table' then
				for _, v in ipairs(browserFrame:GetChildren()) do
					if v.Name == element.Name..':TableElement' then
						v:Destroy()
					end
				end
			end
			element:Destroy()
			element = nil
			ConnectedDataStore:RemoveAsync(ValueName)
		end)
		
		element.HideBtn.MouseButton1Up:Connect(function()
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
		
		element.Value.FocusLost:Connect(function()
			wait(0.1)
			if element == nil then return end
			local newVal = element.Value.Text
			pcall(function()
				value = tostring(ConnectedDataStore:GetAsync(ValueName))
			end)
			if value == nil then
				value = ''
			end
			newVal = formatVal(newVal)
			if newVal ~= formatVal(value) and blockedValues[ValueName] == nil then
				ConnectedDataStore:SetAsync(ValueName, newVal)
				spawn(function()
					blockBox()
				end)
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
				wait()
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
						ConnectedDataStore:SetAsync(ValueName, currentTable)
						spawn(function()
							blockBox()
						end)
					end
				end)
				tableVal.DeleteBtn.MouseButton1Up:Connect(function()
					myTable[i] = nil
					currentTable = currentPath[1]
					ConnectedDataStore:SetAsync(ValueName, currentTable)
					spawn(function()
						blockBox()
					end)
					tableVal:Destroy()
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
						ConnectedDataStore:SetAsync(ValueName, currentTable)
						spawn(function()
							blockBox()
						end)
					end
				end)
				if cnt == tablelength(val) then
					tableVal.NewBtn.Visible = true
					tableVal.NewBtn.MouseButton1Up:Connect(function()
						myTable[tablelength(myTable)+1] = ''
						currentTable = currentPath[1]
						ConnectedDataStore:SetAsync(ValueName, currentTable)
						spawn(function()
							blockBox()
						end)
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
	dsElement.Decor.Visible = false
	dsElement.LayoutOrder = -10
	
	dsElement.Visible = true
	
	dsElement.DeleteBtn.Visible = false
	dsElement.HideBtn.Visible = false
	
	dsElement.DataStore.InputEnded:Connect(function(inp)
		if inp.UserInputType.Value == 0 then
			dsElement:Destroy()
			ConnectedDataStoreName = ''
			ConnectedDataStore = nil
			clearBrowser()
		end
	end)
end

addDSBtn.MouseButton1Up:Connect(function()
	local b = pcall(function()
		ConnectedDataStore = DataStoreService:GetDataStore(addDSName.Text)
	end)
	if b then
		ConnectedDataStoreName = addDSName.Text
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

