-- ================== PSF Remake 4.1 — Complete All-in-One UI + Script Executor + Script Hub + Fling System ==================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

-- Ensure data storage
if not player:FindFirstChild("PSFRemakeData") then
    local folder = Instance.new("Folder", player)
    folder.Name = "PSFRemakeData"
    local scriptsVal = Instance.new("StringValue", folder)
    scriptsVal.Name = "Scripts"
    scriptsVal.Value = "[]"
    local settingsVal = Instance.new("StringValue", folder)
    settingsVal.Name = "Settings"
    settingsVal.Value = "{}"
end

local dataFolder = player:FindFirstChild("PSFRemakeData")
local scriptsValue = dataFolder:FindFirstChild("Scripts")
local settingsValue = dataFolder:FindFirstChild("Settings")

-- JSON decode helper
local function decodeJSON(s,fallback)
    local ok,res = pcall(function() return HttpService:JSONDecode(s) end)
    if ok and type(res)=="table" then return res end
    return fallback
end

local savedScripts = decodeJSON(scriptsValue.Value,nil)
local demoScripts = savedScripts and #savedScripts>0 and savedScripts or {
    {name="Hello", code="print('Hello from PSF')"},
    {name="Timer", code="for i=1,5 do print('tick', i) wait(1) end"},
}

local savedSettings = decodeJSON(settingsValue.Value,{selected=1})

-- UI Root
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PSFRemakeUI"
screenGui.ResetOnSpawn=false
screenGui.Parent = PlayerGui

-- Auto scale
local uiScale = Instance.new("UIScale",screenGui)
uiScale.Name="AutoUIScale"
local function updateScale()
    local s = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize.X or 800
    local scale = math.clamp(s/900,0.8,1.2)
    uiScale.Scale=scale
end
RunService.RenderStepped:Connect(updateScale)
updateScale()

-- Main container
local main = Instance.new("Frame",screenGui)
main.Name="Main"
main.AnchorPoint=Vector2.new(0.5,0.5)
main.Position=UDim2.new(0.5,0,0.5,0)
main.Size=UDim2.new(0.92,0,0.78,0)
main.BackgroundColor3=Color3.fromRGB(18,18,18)
main.BorderSizePixel=0
main.ClipsDescendants=true
Instance.new("UICorner",main).CornerRadius=UDim.new(0,12)

-- Draggable
local dragging=false
local dragInput, dragStart, startPos
main.InputBegan:Connect(function(input)
    if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
        dragging=true
        dragStart=input.Position
        startPos=main.Position
        input.Changed:Connect(function()
            if input.UserInputState==Enum.UserInputState.End then
                dragging=false
            end
        end)
    end
end)
main.InputChanged:Connect(function(input)
    if input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch then
        dragInput=input
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and input==dragInput then
        local delta=input.Position-dragStart
        main.Position=startPos+UDim2.new(0,delta.X,0,delta.Y)
    end
end)

-- Header
local header = Instance.new("Frame",main)
header.Name="Header"
header.Size=UDim2.new(1,0,0,46)
header.BackgroundTransparency=1

local title=Instance.new("TextLabel",header)
title.Text="PSF Remake 4.1 - Script Hub"
title.Font=Enum.Font.GothamBold
title.TextSize=20
title.TextColor3=Color3.fromRGB(240,240,240)
title.BackgroundTransparency=1
title.Position=UDim2.new(0,16,0,6)
title.Size=UDim2.new(0.5,0,1,0)
title.TextXAlignment=Enum.TextXAlignment.Left

-- Toolbar
local toolbar=Instance.new("Frame",header)
toolbar.AnchorPoint=Vector2.new(1,0)
toolbar.Position=UDim2.new(1,-12,0,6)
toolbar.BackgroundTransparency=1
toolbar.Size=UDim2.new(0,460,1,0)
local function makeBtn(parent,text,sizeX,color)
    local b=Instance.new("TextButton",parent)
    b.Text=text
    b.Font=Enum.Font.Gotham
    b.TextSize=14
    b.TextColor3=Color3.fromRGB(255,255,255)
    b.AutoButtonColor=true
    b.BackgroundColor3=color or Color3.fromRGB(38,38,38)
    b.Size=UDim2.new(0,sizeX or 72,0,30)
    b.BorderSizePixel=0
    Instance.new("UICorner",b).CornerRadius=UDim.new(0,6)
    return b
end

local runBtn=makeBtn(toolbar,"Run",72,Color3.fromRGB(0, 150, 255))
local newBtn=makeBtn(toolbar,"New",72,Color3.fromRGB(0, 170, 255))
local delBtn=makeBtn(toolbar,"Delete",72,Color3.fromRGB(255,50,50))
local clearBtn=makeBtn(toolbar,"Clear",72,Color3.fromRGB(150, 100, 0))
local hubBtn=makeBtn(toolbar,"Script Hub",90,Color3.fromRGB(120, 0, 200))
local flingBtn=makeBtn(toolbar,"Fling",72,Color3.fromRGB(255,150,0))
local stopFlingBtn=makeBtn(toolbar,"Stop Fling",90,Color3.fromRGB(255,50,50))

local tbLayout=Instance.new("UIListLayout",toolbar)
tbLayout.FillDirection=Enum.FillDirection.Horizontal
tbLayout.HorizontalAlignment=Enum.HorizontalAlignment.Right
tbLayout.SortOrder=Enum.SortOrder.LayoutOrder
tbLayout.Padding=UDim.new(0,8)

-- Body
local body=Instance.new("Frame",main)
body.Position=UDim2.new(0,12,0,56)
body.Size=UDim2.new(1,-24,1,-68)
body.BackgroundTransparency=1

-- Left panel: scripts list
local left=Instance.new("Frame",body)
left.Size=UDim2.new(0.32,-8,1,0)
left.Position=UDim2.new(0,0,0,0)
left.BackgroundTransparency=1

local leftHeader=Instance.new("TextLabel",left)
leftHeader.Text="My Scripts"
leftHeader.Font=Enum.Font.GothamSemibold
leftHeader.TextSize=16
leftHeader.TextColor3=Color3.fromRGB(230,230,230)
leftHeader.BackgroundTransparency=1
leftHeader.Size=UDim2.new(1,0,0,0.06*body.AbsoluteSize.Y)
leftHeader.Position=UDim2.new(0,0,0,0)

local listFrame=Instance.new("ScrollingFrame",left)
listFrame.Position=UDim2.new(0,0,0.06,8)
listFrame.Size=UDim2.new(1,0,0.94,-8)
listFrame.BackgroundColor3=Color3.fromRGB(24,24,24)
listFrame.BorderSizePixel=0
listFrame.ScrollBarThickness=8
local listCorner=Instance.new("UICorner",listFrame)
listCorner.CornerRadius=UDim.new(0,8)
local listLayout=Instance.new("UIListLayout",listFrame)
listLayout.Padding=UDim.new(0,8)
listLayout.SortOrder=Enum.SortOrder.LayoutOrder
listLayout.HorizontalAlignment=Enum.HorizontalAlignment.Center

-- Right panel: editor + console
local right=Instance.new("Frame",body)
right.Size=UDim2.new(0.68,0,1,0)
right.Position=UDim2.new(0.32,8,0,0)
right.BackgroundTransparency=1

local editorBox=Instance.new("TextBox",right)
editorBox.MultiLine=true
editorBox.ClearTextOnFocus=false
editorBox.TextWrapped=false
editorBox.TextXAlignment=Enum.TextXAlignment.Left
editorBox.TextYAlignment=Enum.TextYAlignment.Top
editorBox.Font=Enum.Font.Code
editorBox.TextSize=16
editorBox.Text="-- Выберите или создайте скрипт\n-- Или используйте Script Hub\n"
editorBox.BackgroundColor3=Color3.fromRGB(14,14,14)
editorBox.TextColor3=Color3.fromRGB(240,240,240)
editorBox.Size=UDim2.new(1,0,0.64,0)
editorBox.Position=UDim2.new(0,0,0.06,8)
Instance.new("UICorner",editorBox).CornerRadius=UDim.new(0,8)

local consoleFrame=Instance.new("ScrollingFrame",right)
consoleFrame.Position=UDim2.new(0,0,0.73,8)
consoleFrame.Size=UDim2.new(1,0,0.27,-8)
consoleFrame.BackgroundColor3=Color3.fromRGB(12,12,12)
consoleFrame.BorderSizePixel=0
consoleFrame.ScrollBarThickness=8
local consoleCorner=Instance.new("UICorner",consoleFrame)
consoleCorner.CornerRadius=UDim.new(0,8)

local consoleText=Instance.new("TextLabel",consoleFrame)
consoleText.Size=UDim2.new(1,-16,0,0)
consoleText.Position=UDim2.new(0,8,0,8)
consoleText.BackgroundTransparency=1
consoleText.TextXAlignment=Enum.TextXAlignment.Left
consoleText.TextYAlignment=Enum.TextYAlignment.Top
consoleText.Font=Enum.Font.Code
consoleText.TextSize=14
consoleText.TextColor3=Color3.fromRGB(220,220,220)
consoleText.Text=""
consoleText.TextWrapped=true
consoleText.AutomaticSize=Enum.AutomaticSize.Y

-- ================== Helper Functions ==================
local function appendConsole(line)
    consoleText.Text=consoleText.Text..tostring(line).."\n"
    consoleText.Size=UDim2.new(1,-16,0,consoleText.TextBounds.Y+16)
    consoleFrame.CanvasSize=UDim2.new(0,0,0,consoleText.AbsoluteSize.Y+24)
    consoleFrame.CanvasPosition=Vector2.new(0,math.max(0,consoleText.AbsoluteSize.Y-consoleFrame.AbsoluteSize.Y))
end

local function saveScripts()
    scriptsValue.Value=HttpService:JSONEncode(demoScripts)
end

local function rebuildList()
    for _,child in pairs(listFrame:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    for i,s in ipairs(demoScripts) do
        local btn=Instance.new("TextButton",listFrame)
        btn.Size=UDim2.new(1,-16,0,40)
        btn.Position=UDim2.new(0,8,0,0)
        btn.BackgroundColor3=Color3.fromRGB(28,28,28)
        btn.TextColor3=Color3.fromRGB(235,235,235)
        btn.Font=Enum.Font.Gotham
        btn.TextSize=14
        btn.Text=s.name
        Instance.new("UICorner",btn).CornerRadius=UDim.new(0,8)
        btn.LayoutOrder=i
        btn.MouseButton1Click:Connect(function()
            savedSettings.selected=i
            editorBox.Text=s.code or ""
            appendConsole("Selected: "..s.name)
            saveScripts()
        end)
    end
    listFrame.CanvasSize=UDim2.new(0,0,0,listLayout.AbsoluteContentSize.Y+16)
end
rebuildList()

-- ================== Script Hub ==================
local hubFrame = Instance.new("Frame", main)
hubFrame.Size = UDim2.new(1, -24, 1, -68)
hubFrame.Position = UDim2.new(0, 12, 0, 56)
hubFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
hubFrame.Visible = false
Instance.new("UICorner", hubFrame).CornerRadius = UDim.new(0, 12)

local hubHeader = Instance.new("TextLabel", hubFrame)
hubHeader.Text = "📁 Script Hub"
hubHeader.Font = Enum.Font.GothamBold
hubHeader.TextSize = 18
hubHeader.TextColor3 = Color3.fromRGB(240, 240, 240)
hubHeader.BackgroundTransparency = 1
hubHeader.Size = UDim2.new(1, 0, 0, 40)
hubHeader.Position = UDim2.new(0, 16, 0, 8)
hubHeader.TextXAlignment = Enum.TextXAlignment.Left

local hubCloseBtn = Instance.new("TextButton", hubFrame)
hubCloseBtn.Text = "✕"
hubCloseBtn.Font = Enum.Font.GothamBold
hubCloseBtn.TextSize = 16
hubCloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
hubCloseBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
hubCloseBtn.Size = UDim2.new(0, 30, 0, 30)
hubCloseBtn.Position = UDim2.new(1, -38, 0, 8)
hubCloseBtn.AutoButtonColor = true
Instance.new("UICorner", hubCloseBtn).CornerRadius = UDim.new(0, 6)

local hubList = Instance.new("ScrollingFrame", hubFrame)
hubList.Size = UDim2.new(1, -16, 1, -60)
hubList.Position = UDim2.new(0, 8, 0, 48)
hubList.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
hubList.ScrollBarThickness = 8
Instance.new("UICorner", hubList).CornerRadius = UDim.new(0, 8)
local hubLayout = Instance.new("UIListLayout", hubList)
hubLayout.Padding = UDim.new(0, 8)
hubLayout.SortOrder = Enum.SortOrder.LayoutOrder

local popularScripts = {
    {name="🌟 Infinite Yield FE", description="Most popular admin script", code="loadstring(game:HttpGet('https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source'))()", color=Color3.fromRGB(255,215,0)},
    {name="🦅 Owl Hub", description="Universal script hub", code="loadstring(game:HttpGet('https://raw.githubusercontent.com/CriShoux/OwlHub/master/OwlHub.txt'))()", color=Color3.fromRGB(0,150,255)},
    {name="🌀 CMD-X", description="Powerful command executor", code="loadstring(game:HttpGet('https://raw.githubusercontent.com/CMD-X/CMD-X/master/Source',true))()", color=Color3.fromRGB(100,200,100)}
}

local function createHubButtons()
    for _,c in pairs(hubList:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
    for i,s in ipairs(popularScripts) do
        local btn = Instance.new("TextButton", hubList)
        btn.Size = UDim2.new(1,-16,0,80)
        btn.Position = UDim2.new(0,8,0,(i-1)*88)
        btn.BackgroundColor3 = s.color
        btn.Text = ""
        btn.AutoButtonColor = false
        Instance.new("UICorner",btn).CornerRadius = UDim.new(0,8)

        local nameLabel = Instance.new("TextLabel",btn)
        nameLabel.Size = UDim2.new(1,-16,0,30)
        nameLabel.Position = UDim2.new(0,8,0,8)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = s.name
        nameLabel.TextColor3 = Color3.fromRGB(255,255,255)
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextSize = 16
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left

        local descLabel = Instance.new("TextLabel",btn)
        descLabel.Size = UDim2.new(1,-16,0,20)
        descLabel.Position = UDim2.new(0,8,0,38)
        descLabel.BackgroundTransparency = 1
        descLabel.Text = s.description
        descLabel.TextColor3 = Color3.fromRGB(220,220,220)
        descLabel.Font = Enum.Font.Gotham
        descLabel.TextSize = 12
        descLabel.TextXAlignment = Enum.TextXAlignment.Left

        local loadBtn = Instance.new("TextButton",btn)
        loadBtn.Size = UDim2.new(0,80,0,25)
        loadBtn.Position = UDim2.new(1,-88,1,-30)
        loadBtn.Text="LOAD"
        loadBtn.BackgroundColor3=Color3.fromRGB(40,40,40)
        loadBtn.TextColor3=Color3.fromRGB(255,255,255)
        loadBtn.Font=Enum.Font.GothamBold
        loadBtn.TextSize=12
        loadBtn.AutoButtonColor=true
        Instance.new("UICorner",loadBtn).CornerRadius=UDim.new(0,4)
        loadBtn.MouseButton1Click:Connect(function()
            editorBox.Text=s.code
            hubFrame.Visible=false
            body.Visible=true
            appendConsole("📥 Loaded: "..s.name)
        end)

        local execBtn = Instance.new("TextButton",btn)
        execBtn.Size = UDim2.new(0,80,0,25)
        execBtn.Position = UDim2.new(1,-88,1,-60)
        execBtn.Text="EXECUTE"
        execBtn.BackgroundColor3=Color3.fromRGB(0,150,255)
        execBtn.TextColor3=Color3.fromRGB(255,255,255)
        execBtn.Font=Enum.Font.GothamBold
        execBtn.TextSize=12
execBtn.AutoButtonColor=true
        Instance.new("UICorner",execBtn).CornerRadius=UDim.new(0,4)
        execBtn.MouseButton1Click:Connect(function()
            local success, err = pcall(function() loadstring(s.code)() end)
            if success then appendConsole("✅ Executed: "..s.name) else appendConsole("❌ Error: "..tostring(err)) end
        end)
    end
    hubList.CanvasSize=UDim2.new(0,0,0,#popularScripts*88)
end
createHubButtons()

-- Hub buttons
hubBtn.MouseButton1Click:Connect(function()
    body.Visible=false
    hubFrame.Visible=true
    appendConsole("📁 Opened Script Hub")
end)
hubCloseBtn.MouseButton1Click:Connect(function()
    hubFrame.Visible=false
    body.Visible=true
    appendConsole("📁 Closed Script Hub")
end)

-- Run/New/Delete/Clear Buttons
runBtn.MouseButton1Click:Connect(function()
    local sel=savedSettings.selected or 1
    local s=demoScripts[sel]
    if s then
        s.code=editorBox.Text
        saveScripts()
        appendConsole("🚀 Running: "..s.name)
        local ok,f=pcall(loadstring,s.code)
        if ok and type(f)=="function" then
            local success,err=pcall(f)
            if success then
                appendConsole("✅ Script executed successfully!")
            else
                appendConsole("❌ Runtime error: "..tostring(err))
            end
        elseif not ok then
            appendConsole("❌ Compile error: "..tostring(f))
        end
    else
        appendConsole("❌ No script selected.")
    end
end)

newBtn.MouseButton1Click:Connect(function()
    table.insert(demoScripts,{name="New Script "..#demoScripts+1, code="-- new script\nprint('Hello from new script!')"})
    savedSettings.selected=#demoScripts
    rebuildList()
    editorBox.Text=demoScripts[#demoScripts].code
    saveScripts()
    appendConsole("📝 Created new script.")
end)

delBtn.MouseButton1Click:Connect(function()
    local sel=savedSettings.selected
    if sel and demoScripts[sel] then
        table.remove(demoScripts,sel)
        savedSettings.selected=math.clamp(sel-1,1,math.max(1,#demoScripts))
        rebuildList()
        editorBox.Text=demoScripts[savedSettings.selected] and demoScripts[savedSettings.selected].code or ""
        saveScripts()
        appendConsole("🗑️ Deleted script.")
    else 
        appendConsole("❌ No script selected to delete.") 
    end
end)

clearBtn.MouseButton1Click:Connect(function()
    consoleText.Text=""
    consoleFrame.CanvasSize=UDim2.new(0,0,0,0)
    appendConsole("🧹 Console cleared.")
end)

-- Auto-save editor
local autosaveTicker=0
editorBox:GetPropertyChangedSignal("Text"):Connect(function() autosaveTicker=0 end)
RunService.Heartbeat:Connect(function(dt)
    autosaveTicker=autosaveTicker+dt
    if autosaveTicker>1 then
        autosaveTicker=0
        local sel=savedSettings.selected
        if sel and demoScripts[sel] then
            demoScripts[sel].code=editorBox.Text
            saveScripts()
        end
    end
end)

-- Restore last selected
local sel=savedSettings.selected or 1
editorBox.Text=demoScripts[sel] and demoScripts[sel].code or ""
appendConsole("🎮 PSF Remake 4.1 - Script Hub ready!")
appendConsole("💡 Use Script Hub button to load popular scripts")
appendConsole("⚡ Select your script and press Run to execute")

-- ================== Collapse/Expand & Smooth UI Animation ==================
local collapsed=false
local rotateBtn=Instance.new("ImageButton",screenGui)
rotateBtn.Size=UDim2.new(0,40,0,40)
rotateBtn.Position=UDim2.new(0,10,1,-50)
rotateBtn.AnchorPoint=Vector2.new(0,0)
rotateBtn.Image="rbxassetid://93738238823550"
rotateBtn.BackgroundTransparency=1
rotateBtn.Rotation=0
rotateBtn.MouseButton1Click:Connect(function() collapsed = not collapsed end)

local animSpeed=5
local colorTime=0
RunService.RenderStepped:Connect(function(dt)
    rotateBtn.Rotation=(rotateBtn.Rotation+dt*90)%360
    local targetScale=collapsed and 0 or 1
    local currentX,currentY=main.Size.X.Scale,main.Size.Y.Scale
    local scaleX=currentX+(targetScale-currentX)*dt*animSpeed
    local scaleY=currentY+(targetScale-currentY)*dt*animSpeed
    main.Size=UDim2.new(scaleX,0,scaleY,0)
    main.ClipsDescendants=scaleY<0.01
    body.Visible=scaleY>0.01 and not hubFrame.Visible
    main.BackgroundTransparency=1-scaleY
    colorTime=colorTime+dt
    local cv=(math.sin(colorTime)+1)/2
    local r=18+(240-18)*cv
    local g=18+(240-18)*cv
    local b=18+(240-18)*cv
    main.BackgroundColor3=Color3.fromRGB(r,g,b)
end)

-- Save settings periodically
RunService.Heartbeat:Connect(function(dt)
    settingsValue.Value = HttpService:JSONEncode(savedSettings)
end)

-- ================== Fling System ==================
local flingTarget = nil
local flingActive = false

local flingFrame = Instance.new("Frame", main)
flingFrame.Size = UDim2.new(0.3,0,0.5,0)
flingFrame.Position = UDim2.new(0.35,0,0.25,0)
flingFrame.BackgroundColor3 = Color3.fromRGB(30,30,30)
flingFrame.Visible = false
Instance.new("UICorner", flingFrame).CornerRadius = UDim.new(0,10)

local flingLayout = Instance.new("UIListLayout", flingFrame)
flingLayout.Padding = UDim.new(0,4)
flingLayout.SortOrder = Enum.SortOrder.LayoutOrder

local function rebuildFlingList()
    for _,c in pairs(flingFrame:GetChildren()) do
        if c:IsA("TextButton") then c:Destroy() end
    end
    for _,p in pairs(Players:GetPlayers()) do
        if p ~= player then
            local btn = Instance.new("TextButton", flingFrame)
            btn.Size=UDim2.new(1,-8,0,30)
            btn.Text=p.Name
            btn.BackgroundColor3=Color3.fromRGB(50,50,50)
            btn.TextColor3=Color3.fromRGB(255,255,255)
            Instance.new("UICorner",btn).CornerRadius=UDim.new(0,6)
            btn.MouseButton1Click:Connect(function()
                flingTarget=p
                appendConsole("🎯 Selected "..p.Name.." for Fling")
            end)
        end
    end
end

flingBtn.MouseButton1Click:Connect(function()
    flingActive = true
    flingFrame.Visible=true
    rebuildFlingList()
end)

stopFlingBtn.MouseButton1Click:Connect(function()
    flingActive = false
    flingTarget=nil
    flingFrame.Visible=false
    appendConsole("🛑 Fling stopped")
end)

RunService.Heartbeat:Connect(function()
    if flingActive and flingTarget and flingTarget.Character and player.Character then
        local hrp = player.Character:FindFirstChild("HumanoidRootPart")
        local targetHRP = flingTarget.Character:FindFirstChild("HumanoidRootPart")
        if hrp and targetHRP then
            hrp.CFrame = targetHRP.CFrame
            hrp.Velocity = Vector3.new(0,500,0)
        end
    end
end)

appendConsole("✅ Fling System Ready - Select a player and press Fling")
