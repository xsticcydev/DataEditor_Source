
function test()
	return game:GetService("RunService"):IsEdit()
end

if pcall(test) then
	print("DataEditor is running!")
else
	print("DataEditor can't run during runtime!")
	return
end

local toolbar = plugin:CreateToolbar('Data Editor')
local btn = toolbar:CreateButton('Toggle Editor', 'Toggle the Data Editor window.', 'rbxassetid://8402442532')
local orderedDS = false
local reverseListing = plugin:GetSetting("revList")

local placeId = game.PlaceId

local recents = plugin:GetSetting(tostring(placeId).."Recents")
if not recents then
	recents = {
		DS = {},
		Keys = {},
	}
end

if reverseListing == nil then
	reverseListing = false
end

local wasClosed = {}

local widgetInfo = DockWidgetPluginGuiInfo.new(
	Enum.InitialDockState.Float, -- type
	false, -- enable widget at start
	true, -- just keep it like this
	500,    -- default width
	400,    -- default height
	500,    -- minimum width
	200     -- minimum height
)

local widget = plugin:CreateDockWidgetPluginGui("DataEditorWidget", widgetInfo)
widget.Title = "Data Editor (v2)"

local gui = script.Parent.Gui.Main:Clone()
gui.Parent = widget

local settingsFrame = script.Parent.Gui.Settings:Clone()
settingsFrame.Parent = widget

local loadingFrame = script.Parent.Gui.Loading:Clone()
loadingFrame.Parent = widget

btn.Click:Connect(function()
	widget.Enabled = not widget.Enabled
end)

local dss = game:GetService("DataStoreService")

local connDS = nil
local connDSName = ""
local keysTmp = {}
local canQuery = true
local canSave = true

local keyPerPage = 10

local tempK = gui.Data._Key

function convertString(s)
	if string.sub(s, #s, #s) == '"' then
		return string.sub(s, 2, #s-1)
	end
	if s == "nil" then
		return nil
	elseif tonumber(s) then
		return tonumber(s)
	elseif s == "true" then
		return true
	elseif s == "false" then
		return false
	elseif s == "{}" then
		return {""}
	else
		return s
	end
end

function status(txt,ok)
	gui.Status.Text = txt
	if not ok then
		gui.Status.TextColor3 = Color3.fromRGB(255, 61, 61)
	else
		gui.Status.TextColor3 = Color3.fromRGB(0, 255, 127)
	end
end

function getTxtBox()
	if string.sub(gui.TxtBox.Text, #gui.TxtBox.Text-2, #gui.TxtBox.Text) == ".id" then
		return game.Players:GetUserIdFromNameAsync(string.sub(gui.TxtBox.Text, 0, #gui.TxtBox.Text-3))
	end
	return gui.TxtBox.Text
end

function reloadGui()
	if connDS == nil then
		gui.Data.NextPage.Visible = false
		status("Not connected to datastore", false)
		gui.DisconnectBtn.Visible = false
		gui.ConnectBtn.Visible = true
		gui.QueryBtn.Visible = false
		gui.Ordered.Visible = true
	else
		status("Connected: "..connDSName, true)
		gui.Ordered.Visible = false
		gui.DisconnectBtn.Visible = true
		gui.ConnectBtn.Visible = false
		gui.QueryBtn.Visible = true
		delay(0,function()
			gui.QueryBtn.ImageLabel.Image = "rbxassetid://6035047391"
		end)
	end
end

gui.Ordered.MouseButton1Click:Connect(function()
	orderedDS = not orderedDS
	if orderedDS then
		gui.Ordered.BackgroundColor3 = Color3.fromRGB(41, 121, 255)
	else
		gui.Ordered.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	end
end)

reloadGui()

local dsPages

function listCurrentPage()
	local entries = dsPages:GetCurrentPage()
	-- Iterate through all key-value pairs on page
	for i, entry in pairs(entries) do
		keysTmp[entry.key] = entry.value
	end
end

function listOrderedDataStore()
	dsPages = connDS:GetSortedAsync(not reverseListing, keyPerPage)
	listCurrentPage()
	reloadKeys()
end

gui.Data.NextPage.MouseButton1Click:Connect(function()
	dsPages:AdvanceToNextPageAsync()
	listCurrentPage()
	reloadKeys()
	wait()
	gui.Data.CanvasPosition = Vector2.new(0,gui.Data.CanvasSize.Y.Offset)
end)

function connectToDS()
	if connDS ~= nil then
		return
	end
	if getTxtBox() == "" then
		status("Please enter a valid name.", false)
		delay(2,function()
			status("Not connected to datastore", false)
		end)
		return
	end
	
	if not orderedDS then
		connDS = dss:GetDataStore(getTxtBox())
	else
		connDS = dss:GetOrderedDataStore(getTxtBox())
		loadingFrame.Visible = true
		gui.Visible = false
		spawn(function()
			while wait() do
				loadingFrame.Icon.Rotation += 15
				if not loadingFrame.Visible then
					return
				end
			end
		end)
		listOrderedDataStore()
		reloadKeys()
		loadingFrame.Visible = false
		gui.Visible = true
	end
	connDSName = getTxtBox()
	print(table.find(recents.DS, connDSName))
	if not table.find(recents.DS, connDSName) then
		table.insert(recents.DS, connDSName)
		plugin:SetSetting(tostring(placeId).."Recents", recents)
	end
	gui.TxtBox.Text = ""
	gui.TxtBox.PlaceholderText = "Key"
	gui.DisconnectBtn.Visible = true
	gui.TxtBox:CaptureFocus()
	delay(0, function()
		gui.TxtBox.Text = ""
	end)
	reloadGui()
end

function save()
	local n = 0
	for k, v in pairs(keysTmp) do
		n += 1
	end
	if n == 0 then return end
	if connDS == nil then return end
	if not canSave then return end
	canSave = false
	
	gui.SaveBtn.BackgroundTransparency = 0.7
	gui.SaveBtn.AutoButtonColor = false
	
	gui.SaveBtn.ImageLabel.Image = "rbxassetid://6035067842"
	
	for k, v in pairs(keysTmp) do
		connDS:SetAsync(k, v)
	end
	
	gui.SaveBtn.ImageLabel.Image = "rbxassetid://6023426909"
	
	reloadKeys()
	
	task.wait(1)
	
	gui.SaveBtn.ImageLabel.Image = "rbxassetid://6031754564"
	
	task.wait(5.2)
	gui.SaveBtn.BackgroundTransparency = 0
	gui.SaveBtn.AutoButtonColor = true
	gui.SaveBtn.ImageLabel.Image = "rbxassetid://6035067857"
	canSave = true
end

local tableOptionIdx = 1
local tableOptionFrame
local selectedTableOption

local function Destroyed(x)
	if x.Parent then return false end
	local _, result = pcall(function() x.Parent = x end)
	return result:match("locked") and true or false
end

local function GetTableType(t)
	assert(type(t) == "table", "Supplied argument is not a table")
	for i,_ in pairs(t) do
		if type(i) ~= "number" then
			return "dictionary"
		end
	end
	return "array"
end

function reloadKeys()
	
	gui.Data.NextPage.Visible = orderedDS
	
	local function styleFrame(frame:Frame, simpleKey:bool)
		frame.MouseEnter:Connect(function()
			frame.BackgroundTransparency = 0.95
		end)
		frame.MouseLeave:Connect(function()
			frame.BackgroundTransparency = 1
		end)
		if simpleKey then
			frame.grabber.Visible = false
			frame.grabber.MouseEnter:Connect(function()
				frame.grabber.BackgroundTransparency = 0.8
			end)
			frame.grabber.MouseLeave:Connect(function()
				frame.grabber.BackgroundTransparency = 1
			end)
			local grab = false
			frame.grabber.InputBegan:Connect(function(i)
				if i.UserInputType == Enum.UserInputType.MouseButton1 then
					grab = true
					local conn
					local sPos
					local sLO
					local conn2
					conn2 = gui.Data.InputEnded:Connect(function(i)
						if i.UserInputType == Enum.UserInputType.MouseButton1 then
							grab = false
							conn2:Disconnect()
						end
					end)
					conn = gui.Data.InputChanged:Connect(function(i)
						if i.UserInputType == Enum.UserInputType.MouseMovement then
							if not sPos then
								sPos = i.Position
								sLO = frame.LayoutOrder
								return
							end
							
							local pos = i.Position
							
							local n = math.ceil((sPos - pos).Y/30)
							
							for _, f in pairs(gui.Data:GetChildren()) do
								if f ~= tempK and f:IsA("Frame") then
									if f.LayoutOrder == sLO + n*-1 then
										local lO = frame.LayoutOrder
										frame.LayoutOrder = f.LayoutOrder
										f.LayoutOrder = lO
									end
								end
							end
						end
						if not grab then
							local lo = {}
							for _, f in pairs(gui.Data:GetChildren()) do
								if f ~= tempK and f:IsA("Frame") and f.RemBtn.ImageLabel.Image == "rbxassetid://6022668962" then
									lo[f.KeyName.Text] = f.LayoutOrder
								end
							end
							reloadKeys(lo)
							conn:Disconnect()
						end
					end)
				end
			end)
		end
	end
	
	for _, k in pairs(gui.Data:GetChildren()) do
		if k:IsA("Frame") and k ~= tempK and k ~= gui.Data.NextPage then
			pcall(function() k:Destroy() end)
		end
	end
	if connDS == nil then return end
	
	gui.TxtBox.BackgroundTransparency = 0.5
	gui.QueryBtn.BackgroundTransparency = 0.5
	
	local i = 0
	
	local function getLen(t)
		local len = 0
		for key, value in pairs(t) do
			len += 1
		end
		return len
	end
	
	local len = getLen(keysTmp)
	
	for key, value in pairs(keysTmp) do
		i += 1
		if i % 100 == 0 then
			wait()
		end
		local frame = tempK:Clone()
		frame.KeyName.Text = key
		if value == "nil" then
			value = "nil"
		elseif typeof(value) == "string" and string.sub(value, 1,1) ~= '"' then
			value = '"'..value..'"'
		end
		frame.Value.Text = tostring(value)
		frame.Name = key
		frame.Visible = true
		frame.Parent = gui.Data
		frame.LayoutOrder = i
		frame.HideBtn.Visible = true
		
		
		if orderedDS then
			if reverseListing then
				frame.LayoutOrder = len - value
			else
				frame.LayoutOrder = value
			end
		end
		
		
		styleFrame(frame, true)
		
		frame.RemBtn.MouseButton1Click:Connect(function()
			--keysTmp[key] = "__DATAEDITOR_REMOVE"
			keysTmp[key] = nil
			connDS:RemoveAsync(key)
			reloadKeys()
		end)
		
		frame.HideBtn.MouseButton1Click:Connect(function()
			keysTmp[key] = nil
			reloadKeys()
		end)
		
		frame.Value.Focused:Connect(function() frame.ChangeVal.Visible = true; end)
		frame.Value.FocusLost:Connect(function() frame.ChangeVal.Visible = false end)
		
		local function colorTxt(frame)
			if frame.Value.Text == "nil" then
				frame.Value.TextColor3 = Color3.new(1, 0, 0.0156863)
			elseif tonumber(frame.Value.Text) then
				frame.Value.TextColor3 = Color3.new(0, 1, 0.498039)
			elseif frame.Value.Text == "true" or frame.Value.Text == "false" then
				frame.Value.TextColor3 = Color3.new(0, 0.666667, 1)
			else
				frame.Value.TextColor3 = Color3.new(1, 0.490196, 0.290196)
			end
		end
		
		local n = frame.AbsoluteSize.X/20
		frame.Size = UDim2.new( 1,-12,0,  math.max(math.ceil(#frame.Value.Text/n), 2)*15  )
		
		local function listTable(t, indent, tKey)
			
			local oKey = key
			
			local n = 0
			local tableI = 0
			for _,_ in pairs(t) do n += 1 end
			
			local frames = {}
			
			for key, value in pairs(t) do
				i += 1
				tableI += 1
				local frame = tempK:Clone()
				frame.KeyName.Text = key
				frame.KeyName.Position += UDim2.fromOffset(indent*8,0)
				frame.Expand.Position += UDim2.fromOffset(indent*8,0)
				if value == "nil" then
					value = "nil"
				elseif typeof(value) == "string" and string.sub(value, 1,1) ~= '"' then
					value = '"'..value..'"'
				end
				frame.Value.Text = tostring(value)
				frame.Name = "oKey"..key..indent
				frame.Visible = true
				frame.Parent = gui.Data
				frame.LayoutOrder = i
				frame.RemBtn.ImageLabel.Image = "rbxassetid://6031094678"
				frame.AddBtn.Visible = tableI == n
				frame.tableSplit.Visible = tableI == n
				
				frame.Value.Focused:Connect(function() frame.ChangeVal.Visible = true end)
				frame.Value.FocusLost:Connect(function() frame.ChangeVal.Visible = false end)
				
				styleFrame(frame)
				if not tonumber(key) then
					frame.KeyName.InputBegan:Connect(function(i)
						if i.UserInputType == Enum.UserInputType.MouseButton1 then
							frame.ChangeKey.TextBox.Text = key
							frame.ChangeKey.TextBox:CaptureFocus()
							frame.ChangeKey.Visible = true
						end
					end)
				end
				frame.ChangeKey.TextBox.FocusLost:Connect(function()
					if frame.ChangeKey.TextBox.Text == key then
						reloadKeys()
						return
					end
					t[frame.ChangeKey.TextBox.Text] = value
					t[key] = nil
					reloadKeys()
				end)
				if typeof(value) == "table" then
					frame.Value.TextEditable = false

				end
				frame.Value.FocusLost:Connect(function()
					if tostring(value) == frame.Value.Text then
						return
					end
					
					if typeof(value) == "table" then
						return
					end
					t[key] = convertString(frame.Value.Text)
					if frame.Value.Text == "{}" then
						if GetTableType(t) == "dictionary" then
							t[key] = {key = ""}
						else
							t[key] = {""}
						end
					end
					reloadKeys()
				end)
				frame.RemBtn.MouseButton1Click:Connect(function()
					if tonumber(key) then
						table.remove(t, key)
					else
						t[key] = nil
					end
					reloadKeys()
				end)
				frame.AddBtn.MouseButton1Click:Connect(function()
					if tonumber(key) then
						t[key+1] = ""
					else
						t["key"..n+1] = "value"
					end
					reloadKeys()
				end)
				frame.Value:GetPropertyChangedSignal("Text"):Connect(function()
					colorTxt(frame)
				end)
				frame.Value:GetPropertyChangedSignal("Text"):Connect(function()
					if not frame then return end
					colorTxt(frame)
					local n = frame.AbsoluteSize.X/40
					frame.Size = UDim2.new( 1,-12,0,  math.max(math.ceil(#frame.Value.Text/n), 2)*15  )
				end)
				widget:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
					if Destroyed(frame) then return end
					local n = frame.AbsoluteSize.X/40
					frame.Size = UDim2.new( 1,-12,0,  math.max(math.ceil(#frame.Value.Text/n), 2)*15  )
				end)
				local n = frame.AbsoluteSize.X/40
				frame.Size = UDim2.new( 1,-12,0,  math.max(math.ceil(#frame.Value.Text/n), 2)*15  )
				colorTxt(frame)
				if typeof(value) == "table" then
					wait()
					frame.Value.Text = "table: ..."
					frame.tableSplit.Visible = true
					local listedFrames = listTable(value, indent+1, key)
					
					frame.Expand.Visible = true
					frame.Expand.Rotation = 90
					
					if wasClosed[frame.Name] ~= nil then
						for _, f in pairs(listedFrames) do
							f.Visible = not wasClosed[frame.Name]
						end
						if wasClosed[frame.Name] == true then
							frame.Expand.Rotation = 0
						else
							frame.Expand.Rotation = 90
						end
					end
					
					frame.Expand.MouseButton1Click:Connect(function()
						for _, f in pairs(listedFrames) do
							f.Visible = not f.Visible
							if not f.Visible then
								wasClosed[frame.Name] = true
							else
								wasClosed[frame.Name] = false
							end
						end
						if frame.Expand.Rotation == 90 then
							frame.Expand.Rotation = 0
						else
							frame.Expand.Rotation = 90
						end
					end)
					
					frame:GetPropertyChangedSignal("Visible"):Connect(function()
						for _, f in pairs(listedFrames) do
							f.Visible = frame.Visible
						end
						if frame.Visible then
							frame.Expand.Rotation = 90
						else
							frame.Expand.Rotation = 0
						end
					end)
					
				end
				
				table.insert(frames, frame)
				
			end
			
			return frames
		end
		
		if typeof(value) == "table" then
			frame.Value.Text = "table: ..."
			frame.tableSplit.Visible = true
			local listedFrames = listTable(value, 1, key)
			
			frame.Expand.Visible = true
			frame.Expand.Rotation = 90
			
			if wasClosed[frame.Name] ~= nil then
				for _, f in pairs(listedFrames) do
					f.Visible = not wasClosed[frame.Name]
				end
				if wasClosed[frame.Name] == true then
					frame.Expand.Rotation = 0
				else
					frame.Expand.Rotation = 90
				end
			end
			
			frame.Expand.MouseButton1Click:Connect(function()
				for _, f in pairs(listedFrames) do
					f.Visible = not f.Visible
					if not f.Visible then
						wasClosed[frame.Name] = true
					else
						wasClosed[frame.Name] = false
					end
				end
				if frame.Expand.Rotation == 90 then
					frame.Expand.Rotation = 0
				else
					frame.Expand.Rotation = 90
				end
			end)
			
		end
		
		if typeof(value) == "table" then
			frame.Value.TextEditable = false
		end
		frame.Value.FocusLost:Connect(function()
			
			if typeof(value) == "table" then
				return
			end
			
			if tostring(value) == frame.Value.Text then
				return
			end
			
			if typeof(convertString(frame.Value.Text)) == "table" then
				frame.TableOption.Visible = true
				tableOptionFrame = frame.TableOption
				tableOptionIdx = 1
				selectedTableOption = nil
				repeat wait(0.1) until selectedTableOption ~= nil
				keysTmp[key] = selectedTableOption
				reloadKeys()
				return
			end
			--print(convertString(frame.Value.Text), typeof(convertString(frame.Value.Text)))
			keysTmp[key] = convertString(frame.Value.Text)
			reloadKeys()
		end)
		frame.TableOption.Table.MouseButton1Click:Connect(function()
			frame.TableOption.Visible = false
			selectedTableOption = {"value"}
			reloadKeys()
		end)
		frame.TableOption.Dict.MouseButton1Click:Connect(function()
			frame.TableOption.Visible = false
			selectedTableOption = {key="value"}
			reloadKeys()
		end)
		frame.Value:GetPropertyChangedSignal("Text"):Connect(function()
			if not frame then return end
			colorTxt(frame)
			frame.Size = UDim2.new( 1,-12,0,  math.max((frame.Value.TextBounds.Y+30), 30)+4  )
		end)
		widget:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
			if Destroyed(frame) then return end
			frame.Size = UDim2.new( 1,-12,0,  math.max((frame.Value.TextBounds.Y+30), 30)+4  )
		end)
		frame.Size = UDim2.new( 1,-12,0,  math.max((frame.Value.TextBounds.Y+30), 30)+4  )
		colorTxt(frame)
	end
	gui.TxtBox.BackgroundTransparency = 0
	gui.QueryBtn.BackgroundTransparency = 0
	
end

function keyPerPageButtons()
	settingsFrame["10Keys"].BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	settingsFrame["20Keys"].BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	settingsFrame["40Keys"].BackgroundColor3 = Color3.fromRGB(255, 255, 255)

	if keyPerPage == 10 then
		settingsFrame["10Keys"].BackgroundColor3 = Color3.fromRGB(0,0,0)
	elseif keyPerPage == 20 then
		settingsFrame["20Keys"].BackgroundColor3 = Color3.fromRGB(0,0,0)
	elseif keyPerPage == 40 then
		settingsFrame["40Keys"].BackgroundColor3 = Color3.fromRGB(0,0,0)
	end
end

gui.Sidebar.Settings.MouseButton1Click:Connect(function()
	
	keyPerPageButtons()
	
	settingsFrame.Visible = true
	settingsFrame.Size -= UDim2.fromOffset(1,0)
	settingsFrame.Size += UDim2.fromOffset(1,0)
	gui.Visible = false
end)

settingsFrame["10Keys"].MouseButton1Click:Connect(function()
	keyPerPage = 10
	keyPerPageButtons()
end)
settingsFrame["20Keys"].MouseButton1Click:Connect(function()
	keyPerPage = 20
	keyPerPageButtons()
end)
settingsFrame["40Keys"].MouseButton1Click:Connect(function()
	keyPerPage = 40
	keyPerPageButtons()
end)

gui.InputBegan:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.Keyboard then
		if tableOptionFrame and selectedTableOption == nil then -- TABLE OPTION
			if i.KeyCode == Enum.KeyCode.Up then
				tableOptionIdx -= 1
			end
			if i.KeyCode == Enum.KeyCode.Down then
				tableOptionIdx += 1
			end
			if tableOptionIdx == 3 then
				tableOptionIdx = 1
			end
			if tableOptionIdx == 0 then
				tableOptionIdx = 2
			end
			if tableOptionIdx == 1 then
				tableOptionFrame.Table.BackgroundTransparency = 0.5
				tableOptionFrame.Dict.BackgroundTransparency = 1
			else
				tableOptionFrame.Dict.BackgroundTransparency = 0.5
				tableOptionFrame.Table.BackgroundTransparency = 1
			end
			if i.KeyCode == Enum.KeyCode.Return then
				if tableOptionIdx == 1 then
					selectedTableOption = {"value"}
				else
					selectedTableOption = {key="value"}
				end
			end
		end
	end
end)

function queryKey(name)
	if not canQuery then return end
	canQuery = false
	gui.QueryBtn.ImageLabel.Image = "rbxassetid://6031302917"
	if not connDS then canQuery = true; gui.QueryBtn.ImageLabel.Image = "rbxassetid://6035047391"; return end
	if name then gui.TxtBox.Text = name end
	if getTxtBox() == "" then
		gui.QueryBtn.ImageLabel.Image = "rbxassetid://6035047391"
		canQuery = true
		return
	end
	if not table.find(recents.Keys, gui.TxtBox.Text) then
		table.insert(recents.Keys, gui.TxtBox.Text)
		plugin:SetSetting(tostring(placeId).."Recents", recents)
	end
	local s = getTxtBox()
	gui.TxtBox.Text = ""
	gui.TxtBox.BackgroundTransparency = 0.5
	local value = connDS:GetAsync(s)
	if value == nil then value = "nil" end
	keysTmp[s] = value
	reloadKeys()
	delay(2,function()
		reloadGui()
	end)
	gui.QueryBtn.ImageLabel.Image = "rbxassetid://6035047391"
	canQuery = true
end

function disconnectDS()
	if connDS == nil then
		return
	end
	connDS = nil
	connDSName = nil
	gui.TxtBox.Text = ""
	gui.TxtBox.PlaceholderText = "Datastore"
	keysTmp = {}
	reloadKeys()
	reloadGui()
end

local styled = {}

local function simpleBtnStyle(b:GuiButton)
	if b:FindFirstChildOfClass("ImageLabel") then
		local iClr = b:FindFirstChildOfClass("ImageLabel").ImageColor3
		local bClr = b.BackgroundColor3
		local oT = b.BackgroundTransparency
		b.MouseLeave:Connect(function()
			b.BackgroundTransparency = oT
			b:FindFirstChildOfClass("ImageLabel").ImageColor3 = iClr
		end)
		b.MouseEnter:Connect(function()
			b.BackgroundTransparency = oT+0.7
			b:FindFirstChildOfClass("ImageLabel").ImageColor3 = bClr
		end)
	end
	table.insert(styled, b)
end

gui.TxtBox.FocusLost:Connect(function(enterPressed)
	if enterPressed then
		connectToDS(); queryKey()
	end
end)
gui.SaveBtn.MouseButton1Click:Connect(function() save() end)
gui.QueryBtn.MouseButton1Click:Connect(function() queryKey() end)
gui.ConnectBtn.MouseButton1Click:Connect(function() connectToDS() end)
gui.DisconnectBtn.MouseButton1Click:Connect(function() disconnectDS() end)

gui.RefreshBtn.MouseButton1Click:Connect(function()
	if not orderedDS then
		local list = keysTmp
		
		for key, _ in pairs(keysTmp) do
			queryKey(key)
		end
		reloadKeys()
	end
end)

settingsFrame.Back.MouseButton1Click:Connect(function()
	settingsFrame.Visible = false
	gui.Visible = true
end)
local i = 0
game["Run Service"].Heartbeat:Connect(function()
	i += 1
	if i == 2 then
		i = 0
		for _, v in pairs(widget:GetDescendants()) do
			if v:IsA("GuiButton") then
				if not table.find(styled, v) then
					simpleBtnStyle(v)
				end
			end
			if v.Name == "Value" and v:IsA("TextBox") then
				v.Parent.Size = UDim2.new( 1,-12,0,  math.max((v.TextBounds.Y+30), 30)+4  )
			end
		end
		local c = UDim2.fromOffset(0,40)
		for _, v in pairs(gui.Data:GetChildren()) do
			if v:IsA("Frame") then
				c += UDim2.fromOffset(0,v.AbsoluteSize.Y+1)
			end
		end
		gui.Data.CanvasSize = c
	end
end)

settingsFrame.RevList.MouseButton1Click:Connect(function()
	reverseListing = not reverseListing
	plugin:SetSetting("revList", reverseListing)
	if reverseListing then
		settingsFrame.RevList.BackgroundColor3 = Color3.fromRGB(0,0,0)
	else
		settingsFrame.RevList.BackgroundColor3 = Color3.fromRGB(255,255,255)
	end
end)
if reverseListing then
	settingsFrame.RevList.BackgroundColor3 = Color3.fromRGB(0,0,0)
else
	settingsFrame.RevList.BackgroundColor3 = Color3.fromRGB(255,255,255)
end

gui.TxtBox.Focused:Connect(function() gui.TxtBox.FocusLine.Visible = true end)
gui.TxtBox.FocusLost:Connect(function() gui.TxtBox.FocusLine.Visible = false; wait(0.1); gui.Recents.Visible = false end)

gui.TxtBox:GetPropertyChangedSignal("Text"):Connect(function()
	gui.Recents.Visible = #gui.TxtBox.Text > 0
	if gui.Recents.Visible then
		
		for _, v in pairs(gui.Recents:GetChildren()) do
			if v:IsA("TextButton") and v.Name ~= "_recent" then
				v:Destroy()
			end
		end
		
		if not connDS then
			for i, r in pairs(recents.DS) do
				if tostring(r):lower():match(gui.TxtBox.Text:lower()) then
					local btn = gui.Recents._recent:Clone()
					btn.Parent = gui.Recents
					btn.Text = r
					btn.Visible = true
					btn.Name = "item"
					btn.MouseButton1Down:Connect(function()
						gui.TxtBox.Text = r
					end)
					btn.rem.MouseButton1Down:Connect(function()
						table.remove(recents.DS, table.find(recents.DS, r))
						plugin:SetSetting(tostring(placeId).."Recents", recents)
						btn:Destroy()
					end)
				end
			end
		else
			for i, r in pairs(recents.Keys) do
				if tostring(r):lower():match(gui.TxtBox.Text:lower()) then
					local btn = gui.Recents._recent:Clone()
					btn.Parent = gui.Recents
					btn.Text = r
					btn.Visible = true
					btn.Name = "item"
					btn.MouseButton1Down:Connect(function()
						gui.TxtBox.Text = r
					end)
					btn.rem.MouseButton1Down:Connect(function()
						table.remove(recents.Keys, table.find(recents.Keys, r))
						plugin:SetSetting(tostring(placeId).."Recents", recents)
						btn:Destroy()
					end)
				end
			end
		end
	end
end)
