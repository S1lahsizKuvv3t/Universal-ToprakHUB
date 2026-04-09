-- [[ Zewitt - INFINITE YIELD & COLOR SEPARATION ]]
-- [ GÜNCELLEME: ESP DETAY TOGGLE & GHOST BAR FİX ]

local name = "Zewitt"

-- SERVİSLER
local Players = game:GetService("Players")
local RS = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local mouse = player:GetMouse()

-- [1] TAM TEMİZLİK (GÜVENLİ KAPANIŞ VE GHOST FİX)
_G.ZewittCons = _G.ZewittCons or {}
local function totalShutdown()
    for _, con in pairs(_G.ZewittCons or {}) do 
        pcall(function() con:Disconnect() end) 
    end
    _G.ZewittCons = {}

    for _, v in pairs(game:GetService("Players"):GetPlayers()) do
        if v.Character and v.Character:FindFirstChild("ZewittHighlight") then
            v.Character.ZewittHighlight:Destroy()
        end
    end

    if _G.FOVCircle then pcall(function() _G.FOVCircle:Remove() end) _G.FOVCircle = nil end

    if _G.Names then for i, v in pairs(_G.Names) do pcall(function() v:Remove() end) end _G.Names = {} end
    if _G.Lines then for i, v in pairs(_G.Lines) do pcall(function() v:Remove() end) end _G.Lines = {} end
    
    if _G.HpBgs then for i, v in pairs(_G.HpBgs) do pcall(function() v:Remove() end) end _G.HpBgs = {} end
    if _G.HpBars then for i, v in pairs(_G.HpBars) do pcall(function() v:Remove() end) end _G.HpBars = {} end

    -- KESİN ÇÖZÜM: GUI TEMİZLİĞİ (Metin Tarama Taktiği)
    for _, gui in pairs(game:GetService("CoreGui"):GetChildren()) do 
        -- 1. Zewitt'i isminden bulup sil
        if gui.Name:find("Zewitt") then 
            gui:Destroy() 
        -- 2. Eğer bu rastgele bir menüyse ve Roblox'un kendi menüsü değilse içini tara
        elseif gui:IsA("ScreenGui") and gui.Name ~= "RobloxGui" then
            local isIY = false
            -- Menünün içindeki BÜTÜN parçalara en derine kadar bak
            for _, obj in pairs(gui:GetDescendants()) do
                -- Eğer bu parça bir yazı veya kutuysa
                if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
                    local text = string.lower(obj.Text)
                    local placeholder = obj:IsA("TextBox") and string.lower(obj.PlaceholderText) or ""
                    
                    -- Ekranda yazan yazılarda "infinite yield" veya "command" kelimeleri geçiyor mu?
                    if text:find("infinite yield") or placeholder:find("command") then
                        isIY = true
                        break
                    end
                end
            end
            -- Eğer yazıyı bulduysak, bu Infinite Yield'dır. Acımadan yok et!
            if isIY then gui:Destroy() end
        end
    end

    pcall(function()
        camera.CameraType = Enum.CameraType.Custom
        if player.Character and player.Character:FindFirstChild("Humanoid") then
            camera.CameraSubject = player.Character.Humanoid
        end
        UIS.MouseBehavior = Enum.MouseBehavior.Default
    end)
    
    print("Zewitt ve Infinite Yield Tamamen Temizlendi.")
end

-- [2] DEĞİŞKENLER & RENK AYIRIMI
local speedOn, jumpOn, espOn, aimbotOn, tracerOn, rainbowOn, fullBrightOn = false, false, false, false, false, false, false
-- YENİ: Detaylı ESP Kontrolleri
local espNameOn, espDistOn, espBarOn = true, true, true

local spinOn, spinSpeed = false, 50
local freeCamOn, freeCamSpeed = false, 2
local camRotX, camRotY = 0, 0

local themeR, themeG, themeB = 255, 0, 0
local themeColor = Color3.fromRGB(themeR, themeG, themeB)
_G.ThemeElements = _G.ThemeElements or {} 
local rV, gV, bV = 255, 0, 0
local fovRadius, aiming = 120, false

_G.Lines = _G.Lines or {}
_G.Names = _G.Names or {}
_G.HpBgs = _G.HpBgs or {}
_G.HpBars = _G.HpBars or {}

local oldBrightness = Lighting.Brightness
local oldClockTime = Lighting.ClockTime
local oldGlobalShadows = Lighting.GlobalShadows
local oldAmbient = Lighting.Ambient
local oldOutdoorAmbient = Lighting.OutdoorAmbient

local HttpService = game:GetService("HttpService")
local folderName = "Zewitt_Configs"
local fileName = folderName .. "/settings.json"

local Keybinds = {
    Aimbot = Enum.KeyCode.E,
    Speed = Enum.KeyCode.Q,
    Jump = Enum.KeyCode.X,
    ESP = Enum.KeyCode.V,
    FreeCam = Enum.KeyCode.Backquote,
	Dash = Enum.KeyCode.C
}
local recordingAction = nil
local recordingButton = nil

local targetModes = {"Head", "Body", "Random"}
local currentTargetIndex = 1
local currentTargetPart = "Head"
local currentRandomTarget = "Body"
-- [[ BİLDİRİM SİSTEMİ (NOTIFICATIONS) ]]
local function notify(title, text)
    local NotifyFrame = Instance.new("Frame", ScreenGui)
    NotifyFrame.Size = UDim2.new(0, 220, 0, 60)
    NotifyFrame.Position = UDim2.new(1, 30, 1, -50) -- Ekranın dışından başlar (sağdan)
    NotifyFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    NotifyFrame.BorderSizePixel = 0
    NotifyFrame.ZIndex = 1000
    Instance.new("UICorner", NotifyFrame).CornerRadius = UDim.new(0, 8)
    
    local grad = Instance.new("UIGradient", NotifyFrame)
    grad.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, themeColor),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 15, 15))
    }
    grad.Rotation = 45

    local nTitle = Instance.new("TextLabel", NotifyFrame)
    nTitle.Size = UDim2.new(1, -10, 0, 25); nTitle.Position = UDim2.new(0, 10, 0, 5)
    nTitle.BackgroundTransparency = 1; nTitle.Text = title; nTitle.Font = "GothamBold"
    nTitle.TextSize = 14; nTitle.TextColor3 = Color3.new(1, 1, 1); nTitle.TextXAlignment = "Left"

    local nText = Instance.new("TextLabel", NotifyFrame)
    nText.Size = UDim2.new(1, -10, 0, 20); nText.Position = UDim2.new(0, 10, 0, 30)
    nText.BackgroundTransparency = 1; nText.Text = text; nText.Font = "Gotham"
    nText.TextSize = 12; nText.TextColor3 = Color3.fromRGB(200, 200, 200); nText.TextXAlignment = "Left"

    -- Animasyonlar (TweenService)
    local TS = game:GetService("TweenService")
    NotifyFrame:TweenPosition(UDim2.new(1, -230, 1, -50), "Out", "Quint", 0.5, true)
    
    task.wait(3) -- 3 saniye ekranda kalır
    
    local fadeOut = TS:Create(NotifyFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {Position = UDim2.new(1, 30, 1, -50), BackgroundTransparency = 1})
    TS:Create(nTitle, TweenInfo.new(0.5), {TextTransparency = 1}):Play()
    TS:Create(nText, TweenInfo.new(0.5), {TextTransparency = 1}):Play()
    fadeOut:Play()
    fadeOut.Completed:Connect(function() NotifyFrame:Destroy() end)
end

local function SaveConfig()
    if not isfolder(folderName) then makefolder(folderName) end
    local dataToSave = { 
        Keybinds = {},
        Theme = {R = themeR, G = themeG, B = themeB} 
    }
    for action, keycode in pairs(Keybinds) do
        dataToSave.Keybinds[action] = keycode.Name
    end
    writefile(fileName, HttpService:JSONEncode(dataToSave))
end

local function LoadConfig()
    if isfile(fileName) then
        local success, result = pcall(function() return HttpService:JSONDecode(readfile(fileName)) end)
        if success and result then
            if result.Keybinds then
                for action, keyName in pairs(result.Keybinds) do
                    if Keybinds[action] and Enum.KeyCode[keyName] then
                        Keybinds[action] = Enum.KeyCode[keyName]
                    end
                end
            end
            if result.Theme then
                themeR = result.Theme.R or 255
                themeG = result.Theme.G or 0
                themeB = result.Theme.B or 0
                themeColor = Color3.fromRGB(themeR, themeG, themeB)
            end
        end
    end
end

LoadConfig()

-- [3] ÇIKIŞ YAPAN OYUNCUYU TEMİZLEME (GHOST FİX BURADA DA VAR)
table.insert(_G.ZewittCons, Players.PlayerRemoving:Connect(function(p)
    if _G.Names[p.Name] then _G.Names[p.Name]:Remove() _G.Names[p.Name] = nil end
    if _G.Lines[p.Name] then _G.Lines[p.Name]:Remove() _G.Lines[p.Name] = nil end
    if _G.HpBgs[p.Name] then _G.HpBgs[p.Name]:Remove() _G.HpBgs[p.Name] = nil end
    if _G.HpBars[p.Name] then _G.HpBars[p.Name]:Remove() _G.HpBars[p.Name] = nil end
end))

-- [4] DRAWING FOV
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 2
FOVCircle.NumSides = 60
FOVCircle.Radius = fovRadius
FOVCircle.Visible = true
FOVCircle.Transparency = 1
FOVCircle.Color = themeColor
_G.FOVCircle = FOVCircle

-- [5] UI OLUŞTURMA
local ScreenGui = Instance.new("ScreenGui", game:GetService("CoreGui"))
ScreenGui.Name = name
-- [[ WATERMARK (EKRANIN SAĞ ALT KÖŞESİ) ]]
local WatermarkFrame = Instance.new("Frame", ScreenGui)
WatermarkFrame.Size = UDim2.new(0, 200, 0, 25)
WatermarkFrame.Position = UDim2.new(1, -10, 1, -10)
WatermarkFrame.AnchorPoint = Vector2.new(1, 1)
WatermarkFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
WatermarkFrame.BackgroundTransparency = 0.5
WatermarkFrame.BorderSizePixel = 0
Instance.new("UICorner", WatermarkFrame).CornerRadius = UDim.new(0, 5)

local WatermarkText = Instance.new("TextLabel", WatermarkFrame)
WatermarkText.Size = UDim2.new(1, 0, 1, 0)
WatermarkText.BackgroundTransparency = 1
WatermarkText.Font = "GothamBold"
WatermarkText.TextSize = 12
WatermarkText.TextColor3 = themeColor
table.insert(_G.ThemeElements, WatermarkText)

-- FPS ve Ping Güncelleme Döngüsü
local lastTick = tick()
local frames = 0
table.insert(_G.ZewittCons, RS.RenderStepped:Connect(function()
    frames = frames + 1
    if tick() - lastTick >= 1 then
        local fps = frames
        local ping = math.floor(player:GetNetworkPing() * 1000)
        WatermarkText.Text = "Zewitt | FPS: " .. fps .. " | Ping: " .. ping .. "ms"
        frames = 0
        lastTick = tick()
    end
end))


local Main = Instance.new("Frame", ScreenGui)
Main.Size = UDim2.new(0, 520, 0, 420)
Main.Position = UDim2.new(0.5, -260, 0.5, -210)
Main.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
Main.Active = true
Main.ClipsDescendants = true 

local dragging, dragInput, dragStart, startPos

local function updateDrag(input)
    local delta = input.Position - dragStart
    Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

Main.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = Main.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)

table.insert(_G.ZewittCons, UIS.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end))

table.insert(_G.ZewittCons, RS.RenderStepped:Connect(function()
    if dragging and dragInput then updateDrag(dragInput) end
end))

Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)
local Stroke = Instance.new("UIStroke", Main); Stroke.Thickness = 2; Stroke.Color = themeColor

local SideBar = Instance.new("Frame", Main)
SideBar.Size = UDim2.new(0, 150, 1, 0)
SideBar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
Instance.new("UICorner", SideBar)
-- ANA EKRAN İÇİN GRADIENT (Belirgin Mavili Geçiş)
local MainGradient = Instance.new("UIGradient", Main)
MainGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(35, 50, 100)),   -- Sol üst: Canlı, derin Discord mavisi
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(20, 25, 45)),  -- Orta: Yumuşak lacivert geçiş
    ColorSequenceKeypoint.new(1, Color3.fromRGB(12, 12, 16))     -- Sağ alt: Koyu siyah/gri zemin
}
MainGradient.Rotation = 45

-- YAN MENÜ (SIDEBAR) İÇİN GRADIENT
local SideGradient = Instance.new("UIGradient", SideBar)
SideGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(50, 65, 120)),   -- Yan menü için bir tık daha parlak mavi
    ColorSequenceKeypoint.new(1, Color3.fromRGB(18, 20, 30))
}
SideGradient.Rotation = 45

local Title = Instance.new("TextLabel", SideBar)
Title.Size = UDim2.new(1, 0, 0, 60); Title.Text = "Zewitt"; Title.Font = "GothamBold"
Title.TextSize = 22; Title.BackgroundTransparency = 1; Title.TextColor3 = themeColor

local ProfileFrame = Instance.new("Frame", SideBar)
ProfileFrame.Size = UDim2.new(1, 0, 0, 50); ProfileFrame.Position = UDim2.new(0, 0, 1, -50); ProfileFrame.BackgroundTransparency = 1

local AvatarImage = Instance.new("ImageLabel", ProfileFrame)
AvatarImage.Size = UDim2.new(0, 30, 0, 30); AvatarImage.Position = UDim2.new(0, 10, 0.5, 0); AvatarImage.AnchorPoint = Vector2.new(0, 0.5)
AvatarImage.BackgroundColor3 = Color3.fromRGB(40, 40, 40); Instance.new("UICorner", AvatarImage).CornerRadius = UDim.new(1, 0)

task.spawn(function()
    local content, isReady = Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
    if isReady then AvatarImage.Image = content end
end)

local UsernameLabel = Instance.new("TextLabel", ProfileFrame)
UsernameLabel.Size = UDim2.new(1, -50, 1, 0); UsernameLabel.Position = UDim2.new(0, 45, 0, 0)
UsernameLabel.BackgroundTransparency = 1; UsernameLabel.Text = player.DisplayName
UsernameLabel.Font = "GothamBold"; UsernameLabel.TextSize = 12; UsernameLabel.TextColor3 = themeColor; UsernameLabel.TextXAlignment = Enum.TextXAlignment.Left

table.insert(_G.ThemeElements, UsernameLabel)

local Container = Instance.new("Frame", Main)
Container.Size = UDim2.new(1, -170, 1, -20); Container.Position = UDim2.new(0, 160, 0, 10); Container.BackgroundTransparency = 1

local ResizeHandle = Instance.new("TextButton", Main)
ResizeHandle.Size = UDim2.new(0, 20, 0, 20); ResizeHandle.Position = UDim2.new(1, -20, 1, -20)
ResizeHandle.BackgroundTransparency = 1; ResizeHandle.Text = "◢"; ResizeHandle.TextSize = 16; ResizeHandle.TextColor3 = themeColor; ResizeHandle.ZIndex = 10

local resizing, minSize = false, Vector2.new(520, 420)
ResizeHandle.MouseButton1Down:Connect(function() resizing = true end)
table.insert(_G.ZewittCons, UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then resizing = false end
end))
table.insert(_G.ZewittCons, RS.RenderStepped:Connect(function()
    if resizing then
        local newWidth = math.max(minSize.X, mouse.X - Main.AbsolutePosition.X)
        local newHeight = math.max(minSize.Y, mouse.Y - Main.AbsolutePosition.Y)
        Main.Size = UDim2.new(0, newWidth, 0, newHeight)
    end
end))

local MinimizeBtn = Instance.new("TextButton", Main)
MinimizeBtn.Size = UDim2.new(0, 30, 0, 30); MinimizeBtn.Position = UDim2.new(1, -40, 0, 5)
MinimizeBtn.BackgroundTransparency = 1; MinimizeBtn.Text = "-"; MinimizeBtn.TextSize = 24
MinimizeBtn.Font = "GothamBold"; MinimizeBtn.TextColor3 = themeColor; MinimizeBtn.ZIndex = 10

local isMinimized, preMinimizeSize = false, Main.Size
MinimizeBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    if isMinimized then
        preMinimizeSize = Main.Size
        MinimizeBtn.Text = "+"
        Container.Visible = false; ResizeHandle.Visible = false
        for _, v in pairs(SideBar:GetChildren()) do if v:IsA("TextButton") then v.Visible = false end end
        Main.Size = UDim2.new(0, preMinimizeSize.X.Offset, 0, 60)
    else
        MinimizeBtn.Text = "-"
        Container.Visible = true; ResizeHandle.Visible = true
        for _, v in pairs(SideBar:GetChildren()) do if v:IsA("TextButton") then v.Visible = true end end
        Main.Size = preMinimizeSize
    end
end)

local Pages = {}
local function createTab(tname, pos)
    local btn = Instance.new("TextButton", SideBar)
    btn.Size = UDim2.new(0.9, 0, 0, 40); btn.Position = UDim2.new(0.05, 0, 0, 70 + (pos * 45))
    btn.Text = tname; btn.Font = "GothamBold"; btn.TextSize = 12
    btn.BackgroundColor3 = Color3.fromRGB(30,30,30); btn.TextColor3 = Color3.new(1,1,1)
    Instance.new("UICorner", btn)
    
    local p = Instance.new("ScrollingFrame", Container)
    p.Size = UDim2.new(1, 0, 1, 0); p.BackgroundTransparency = 1; p.BorderSizePixel = 0
    p.ScrollBarThickness = 4; p.CanvasSize = UDim2.new(0, 0, 0, 700); p.Visible = (pos == 0)
    p.ScrollBarImageColor3 = themeColor
    
    btn.MouseButton1Click:Connect(function() 
        for _, v in pairs(Pages) do v.Visible = false end 
        p.Visible = true 
    end)
    Pages[tname] = p
    table.insert(_G.ThemeElements, p)
    return p
end

local AimP = createTab("AIMBOT", 0)
local MoveP = createTab("MOVEMENT", 1)
local TeleP = createTab("TELEPORT", 2)
local VisP = createTab("VISUALS", 3)
local FunP = createTab("FUN", 4)
local SettingsP = createTab("SETTINGS", 5)
local ConfigP = createTab("CONFIGS", 6)

local function label(p, txt, y, sz)
    local l = Instance.new("TextLabel", p)
    l.Size = UDim2.new(1,0,0,30); l.Position = UDim2.new(0,0,0,y)
    l.Text = txt; l.TextColor3 = Color3.new(1,1,1)
    l.Font = "GothamBold"; l.TextSize = sz or 14; l.BackgroundTransparency = 1
    return l
end

local function makeSlider(p, title, y, def, max, callback)
    local l = label(p, title, y, 11)
    local bar = Instance.new("Frame", p)
    bar.Size = UDim2.new(0.8,0,0,8); bar.Position = UDim2.new(0.1,0,0,y+25); bar.BackgroundColor3 = Color3.fromRGB(40,40,40)
    Instance.new("UICorner", bar)
    
    local b = Instance.new("TextButton", bar)
    b.Size = UDim2.new(0,16,0,16); b.Position = UDim2.new(def/max,0,0.5,0)
    b.AnchorPoint = Vector2.new(0.5,0.5); b.Text = ""; b.BackgroundColor3 = themeColor
    Instance.new("UICorner", b).CornerRadius = UDim.new(1,0)
    table.insert(_G.ThemeElements, b) 

    local d = false
    b.MouseButton1Down:Connect(function() d = true end)
    table.insert(_G.ZewittCons, UIS.InputEnded:Connect(function(i) 
        if i.UserInputType == Enum.UserInputType.MouseButton1 then d = false end 
    end))
    table.insert(_G.ZewittCons, RS.RenderStepped:Connect(function()
        if d then 
            local m = math.clamp((mouse.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
            b.Position = UDim2.new(m,0,0.5,0)
            callback(m*max) 
        end
    end))
end

-- [[ YENİ NESİL İNTRO (YÜKLEME EKRANI) ]]
local function playIntroAnimation()
    if ScreenGui:FindFirstChild("ZewittIntro") then ScreenGui.ZewittIntro:Destroy() end
    
    local IntroFrame = Instance.new("Frame", ScreenGui)
    IntroFrame.Name = "ZewittIntro"
    IntroFrame.Size = UDim2.new(0, 400, 0, 150)
    IntroFrame.Position = UDim2.new(0.5, -200, 0.5, -75)
    IntroFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    IntroFrame.BorderSizePixel = 0
    IntroFrame.ZIndex = 999
    Instance.new("UICorner", IntroFrame).CornerRadius = UDim.new(0, 10)
    
    -- İntro Arkaplan Geçişi
    local introGrad = Instance.new("UIGradient", IntroFrame)
    introGrad.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 20, 45)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 15, 20))
    }
    introGrad.Rotation = 45

    local TitleLabel = Instance.new("TextLabel", IntroFrame)
    TitleLabel.Size = UDim2.new(1, 0, 0, 50); TitleLabel.Position = UDim2.new(0, 0, 0, 15)
    TitleLabel.BackgroundTransparency = 1; TitleLabel.Text = "ZEWITT"
    TitleLabel.Font = Enum.Font.GothamBlack; TitleLabel.TextSize = 36
    TitleLabel.TextColor3 = Color3.new(1, 1, 1); TitleLabel.ZIndex = 1000

    local StatusLabel = Instance.new("TextLabel", IntroFrame)
    StatusLabel.Size = UDim2.new(1, 0, 0, 20); StatusLabel.Position = UDim2.new(0, 0, 0, 75)
    StatusLabel.BackgroundTransparency = 1; StatusLabel.Text = "Initializing..."
    StatusLabel.Font = Enum.Font.Gotham; StatusLabel.TextSize = 12
    StatusLabel.TextColor3 = Color3.fromRGB(180, 180, 180); StatusLabel.ZIndex = 1000

    local BarBg = Instance.new("Frame", IntroFrame)
    BarBg.Size = UDim2.new(0.8, 0, 0, 6); BarBg.Position = UDim2.new(0.1, 0, 0, 105)
    BarBg.BackgroundColor3 = Color3.fromRGB(40, 40, 40); BarBg.BorderSizePixel = 0; BarBg.ZIndex = 1000
    Instance.new("UICorner", BarBg).CornerRadius = UDim.new(1, 0)

    local BarFill = Instance.new("Frame", BarBg)
    BarFill.Size = UDim2.new(0, 0, 1, 0); BarFill.BackgroundColor3 = themeColor
    BarFill.BorderSizePixel = 0; BarFill.ZIndex = 1001
    Instance.new("UICorner", BarFill).CornerRadius = UDim.new(1, 0)
    table.insert(_G.ThemeElements, BarFill)

    Main.Visible = false
    local TS = game:GetService("TweenService")
    
    -- Yükleme Senaryosu
    task.wait(0.5)
    TS:Create(BarFill, TweenInfo.new(1, Enum.EasingStyle.Sine), {Size = UDim2.new(0.4, 0, 1, 0)}):Play()
    StatusLabel.Text = "Loading assets..."
    task.wait(1.2)
    
    TS:Create(BarFill, TweenInfo.new(1.2, Enum.EasingStyle.Sine), {Size = UDim2.new(0.8, 0, 1, 0)}):Play()
    StatusLabel.Text = "Getting prepared..."
    task.wait(1.5)
    
    TS:Create(BarFill, TweenInfo.new(0.5, Enum.EasingStyle.Sine), {Size = UDim2.new(1, 0, 1, 0)}):Play()
    StatusLabel.Text = "Ready!"
    task.wait(0.6)

    -- Ekrandan Yavaşça Kaybolma (Fade Out)
    local fadeInfo = TweenInfo.new(0.8, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    TS:Create(IntroFrame, fadeInfo, {BackgroundTransparency = 1}):Play()
    TS:Create(TitleLabel, fadeInfo, {TextTransparency = 1}):Play()
    TS:Create(StatusLabel, fadeInfo, {TextTransparency = 1}):Play()
    TS:Create(BarBg, fadeInfo, {BackgroundTransparency = 1}):Play()
    TS:Create(BarFill, fadeInfo, {BackgroundTransparency = 1}):Play()
    
    task.wait(0.8)
    IntroFrame:Destroy()
    Main.Visible = true
end
task.spawn(playIntroAnimation)

-- AIMBOT SAYFASI
local AimStatus = label(AimP, "AIMBOT: KAPALI [E]", 10, 16)
local TargetBtn = Instance.new("TextButton", AimP)
TargetBtn.Size = UDim2.new(0.8, 0, 0, 30); TargetBtn.Position = UDim2.new(0.1, 0, 0, 45)
TargetBtn.Text = "HEDEF: Head"; TargetBtn.Font = "GothamBold"; TargetBtn.TextSize = 14
TargetBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35); TargetBtn.TextColor3 = Color3.new(1, 1, 1)
Instance.new("UICorner", TargetBtn); table.insert(_G.ThemeElements, TargetBtn)

TargetBtn.MouseButton1Click:Connect(function()
    currentTargetIndex = currentTargetIndex + 1
    if currentTargetIndex > #targetModes then currentTargetIndex = 1 end
    currentTargetPart = targetModes[currentTargetIndex]
    TargetBtn.Text = "HEDEF: " .. currentTargetPart
end)
makeSlider(AimP, "FOV BOYUTU", 85, 120, 600, function(v) fovRadius = v end)

-- MOVEMENT SAYFASI
local SpeedStatus = label(MoveP, "HIZ: KAPALI [Q]", 10, 16)
local SpeedIn = Instance.new("TextBox", MoveP)
SpeedIn.Size = UDim2.new(0.8,0,0,35); SpeedIn.Position = UDim2.new(0.1,0,0,45)
SpeedIn.Text = "5"; SpeedIn.BackgroundColor3 = Color3.fromRGB(35,35,35); SpeedIn.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", SpeedIn)

local JumpStatus = label(MoveP, "ZIPLAMA: KAPALI [X]", 100, 16)
local JumpIn = Instance.new("TextBox", MoveP)
JumpIn.Size = UDim2.new(0.8,0,0,35); JumpIn.Position = UDim2.new(0.1,0,0,135)
JumpIn.Text = "80"; JumpIn.BackgroundColor3 = Color3.fromRGB(35,35,35); JumpIn.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", JumpIn)

-- YENİ: DASH UI (ARAYÜZÜ)
local DashStatus = label(MoveP, "DASH MESAFESİ [C]", 190, 16)
local DashIn = Instance.new("TextBox", MoveP)
DashIn.Size = UDim2.new(0.8,0,0,35); DashIn.Position = UDim2.new(0.1,0,0,225)
DashIn.Text = "15"; DashIn.BackgroundColor3 = Color3.fromRGB(35,35,35); DashIn.TextColor3 = Color3.new(1,1,1)
DashIn.PlaceholderText = "İleri atılma mesafesi..."
Instance.new("UICorner", DashIn)

-- TELEPORT SAYFASI
label(TeleP, "IŞINLANMA & İZLEME", 5, 16)

local selectedPlayerName = ""
local DropdownBtn = Instance.new("TextButton", TeleP)
DropdownBtn.Size = UDim2.new(0.8, 0, 0, 30); DropdownBtn.Position = UDim2.new(0.1, 0, 0, 35)
DropdownBtn.Text = "Oyuncu Seç..."; DropdownBtn.Font = "GothamBold"; DropdownBtn.TextSize = 14
DropdownBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30); DropdownBtn.TextColor3 = Color3.new(1, 1, 1); DropdownBtn.ZIndex = 2
Instance.new("UICorner", DropdownBtn)

local PlayerListFrame = Instance.new("ScrollingFrame", TeleP)
PlayerListFrame.Size = UDim2.new(0.8, 0, 0, 110); PlayerListFrame.Position = UDim2.new(0.1, 0, 0, 68)
PlayerListFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25); PlayerListFrame.BorderSizePixel = 0
PlayerListFrame.ScrollBarThickness = 4; PlayerListFrame.Visible = false; PlayerListFrame.ZIndex = 5 
Instance.new("UICorner", PlayerListFrame)
Instance.new("UIListLayout", PlayerListFrame).SortOrder = Enum.SortOrder.LayoutOrder

local function refreshPlayerList()
    for _, v in pairs(PlayerListFrame:GetChildren()) do if v:IsA("TextButton") then v:Destroy() end end
    local ySize = 0
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= player then
            local plrBtn = Instance.new("TextButton", PlayerListFrame)
            plrBtn.Size = UDim2.new(1, 0, 0, 25); plrBtn.Text = p.Name; plrBtn.Font = "Gotham"; plrBtn.TextSize = 12
            plrBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35); plrBtn.TextColor3 = Color3.new(1, 1, 1); plrBtn.ZIndex = 6
            plrBtn.MouseButton1Click:Connect(function()
                selectedPlayerName = p.Name; DropdownBtn.Text = p.Name; PlayerListFrame.Visible = false
            end)
            ySize = ySize + 25
        end
    end
    PlayerListFrame.CanvasSize = UDim2.new(0, 0, 0, ySize)
end
DropdownBtn.MouseButton1Click:Connect(function()
    PlayerListFrame.Visible = not PlayerListFrame.Visible
    if PlayerListFrame.Visible then refreshPlayerList() end
end)

local TpBtn = Instance.new("TextButton", TeleP)
TpBtn.Size = UDim2.new(0.38,0,0,30); TpBtn.Position = UDim2.new(0.1,0,0,70); TpBtn.Text = "İSME GİT"
TpBtn.Font = "GothamBold"; TpBtn.BackgroundColor3 = Color3.fromRGB(45,45,45); TpBtn.TextColor3 = Color3.new(1,1,1); TpBtn.ZIndex = 1
Instance.new("UICorner", TpBtn)

local SpecBtn = Instance.new("TextButton", TeleP)
SpecBtn.Size = UDim2.new(0.38,0,0,30); SpecBtn.Position = UDim2.new(0.52,0,0,70); SpecBtn.Text = "İZLE"
SpecBtn.Font = "GothamBold"; SpecBtn.BackgroundColor3 = Color3.fromRGB(45,45,45); SpecBtn.TextColor3 = Color3.new(1,1,1); SpecBtn.ZIndex = 1
Instance.new("UICorner", SpecBtn)

local UnSpecBtn = Instance.new("TextButton", TeleP)
UnSpecBtn.Size = UDim2.new(0.8,0,0,30); UnSpecBtn.Position = UDim2.new(0.1,0,0,105); UnSpecBtn.Text = "İZLEMEYİ BIRAK"
UnSpecBtn.Font = "GothamBold"; UnSpecBtn.BackgroundColor3 = Color3.fromRGB(30,30,30); UnSpecBtn.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", UnSpecBtn)

local NearestTpBtn = Instance.new("TextButton", TeleP)
NearestTpBtn.Size = UDim2.new(0.8,0,0,30); NearestTpBtn.Position = UDim2.new(0.1,0,0,140); NearestTpBtn.Text = "EN YAKIN OYUNCUYA TP"
NearestTpBtn.Font = "GothamBold"; NearestTpBtn.BackgroundColor3 = Color3.fromRGB(150,30,30); NearestTpBtn.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", NearestTpBtn)

-- [[ GELİŞMİŞ ÇOKLU WAYPOINT SİSTEMİ ]]
label(TeleP, "ÖZEL KONUMLAR (WAYPOINTS)", 180, 16)
local WpNameIn = Instance.new("TextBox", TeleP)
WpNameIn.Size = UDim2.new(0.5, 0, 0, 30); WpNameIn.Position = UDim2.new(0.1, 0, 0, 215)
WpNameIn.PlaceholderText = "Konum Adı (Örn: Base)"; WpNameIn.Text = ""; WpNameIn.Font = "GothamBold"; WpNameIn.TextSize = 12
WpNameIn.BackgroundColor3 = Color3.fromRGB(35, 35, 35); WpNameIn.TextColor3 = Color3.new(1, 1, 1)
Instance.new("UICorner", WpNameIn)

local SaveWpBtn = Instance.new("TextButton", TeleP)
SaveWpBtn.Size = UDim2.new(0.28, 0, 0, 30); SaveWpBtn.Position = UDim2.new(0.62, 0, 0, 215)
SaveWpBtn.Text = "KAYDET"; SaveWpBtn.Font = "GothamBold"; SaveWpBtn.TextSize = 12
SaveWpBtn.BackgroundColor3 = Color3.fromRGB(45, 150, 45); SaveWpBtn.TextColor3 = Color3.new(1, 1, 1)
Instance.new("UICorner", SaveWpBtn)

local WpListFrame = Instance.new("ScrollingFrame", TeleP)
WpListFrame.Size = UDim2.new(0.8, 0, 0, 130); WpListFrame.Position = UDim2.new(0.1, 0, 0, 255)
WpListFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25); WpListFrame.BorderSizePixel = 0; WpListFrame.ScrollBarThickness = 4
Instance.new("UICorner", WpListFrame)
local WpLayout = Instance.new("UIListLayout", WpListFrame)
WpLayout.SortOrder = Enum.SortOrder.LayoutOrder; WpLayout.Padding = UDim.new(0, 5)

local SavedWaypoints = {}
local function refreshWaypoints()
    for _, v in pairs(WpListFrame:GetChildren()) do if v:IsA("Frame") then v:Destroy() end end
    local ySize = 0
    for i, wp in ipairs(SavedWaypoints) do
        local ItemFrame = Instance.new("Frame", WpListFrame)
        ItemFrame.Size = UDim2.new(1, -10, 0, 30); ItemFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
        Instance.new("UICorner", ItemFrame)

        local NameLabel = Instance.new("TextLabel", ItemFrame)
        NameLabel.Size = UDim2.new(0.55, 0, 1, 0); NameLabel.Position = UDim2.new(0.05, 0, 0, 0)
        NameLabel.BackgroundTransparency = 1; NameLabel.Text = wp.Name; NameLabel.Font = "GothamBold"
        NameLabel.TextSize = 12; NameLabel.TextColor3 = Color3.new(1, 1, 1); NameLabel.TextXAlignment = Enum.TextXAlignment.Left

        local GoBtn = Instance.new("TextButton", ItemFrame)
        GoBtn.Size = UDim2.new(0.2, 0, 0.8, 0); GoBtn.Position = UDim2.new(0.65, 0, 0.1, 0)
        GoBtn.Text = "GİT"; GoBtn.Font = "GothamBold"; GoBtn.TextSize = 10
        GoBtn.BackgroundColor3 = Color3.fromRGB(30, 100, 150); GoBtn.TextColor3 = Color3.new(1, 1, 1)
        Instance.new("UICorner", GoBtn)

        local DelBtn = Instance.new("TextButton", ItemFrame)
        DelBtn.Size = UDim2.new(0.1, 0, 0.8, 0); DelBtn.Position = UDim2.new(0.88, 0, 0.1, 0)
        DelBtn.Text = "X"; DelBtn.Font = "GothamBold"; DelBtn.TextSize = 12
        DelBtn.BackgroundColor3 = Color3.fromRGB(150, 40, 40); DelBtn.TextColor3 = Color3.new(1, 1, 1)
        Instance.new("UICorner", DelBtn)

        GoBtn.MouseButton1Click:Connect(function()
            if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then player.Character.HumanoidRootPart.CFrame = wp.CFrame end
        end)
        DelBtn.MouseButton1Click:Connect(function() table.remove(SavedWaypoints, i) refreshWaypoints() end)
        ySize = ySize + 35
    end
    WpListFrame.CanvasSize = UDim2.new(0, 0, 0, ySize)
end

SaveWpBtn.MouseButton1Click:Connect(function()
    if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        local wpName = WpNameIn.Text ~= "" and WpNameIn.Text or "Konum " .. (#SavedWaypoints + 1)
        table.insert(SavedWaypoints, { Name = wpName, CFrame = player.Character.HumanoidRootPart.CFrame })
        WpNameIn.Text = ""; refreshWaypoints() 
    end
end)

local FreeCamStatus = label(TeleP, "FREECAM: KAPALI [é]", 395, 16)
makeSlider(TeleP, "FREECAM HIZI", 425, 2, 10, function(v) freeCamSpeed = v end)

-- VISUALS SAYFASI
makeSlider(VisP, "ESP RENGİ (KIRMIZI)", 5, rV, 255, function(v) rV = v end)
makeSlider(VisP, "ESP RENGİ (YEŞİL)", 45, gV, 255, function(v) gV = v end)
makeSlider(VisP, "ESP RENGİ (MAVİ)", 85, bV, 255, function(v) bV = v end)

local RainBtn = Instance.new("TextButton", VisP)
RainBtn.Size = UDim2.new(0.8, 0, 0, 30); RainBtn.Position = UDim2.new(0.1, 0, 0, 135)
RainBtn.Text = "RAINBOW ESP: KAPALI"; RainBtn.Font = "GothamBold"; RainBtn.TextSize = 14
RainBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35); RainBtn.TextColor3 = Color3.new(1, 1, 1)
Instance.new("UICorner", RainBtn)

local TraceBtn = Instance.new("TextButton", VisP)
TraceBtn.Size = UDim2.new(0.8,0,0,30); TraceBtn.Position = UDim2.new(0.1,0,0,170)
TraceBtn.Text = "ÇİZGİLER: KAPALI"; TraceBtn.Font = "GothamBold"; TraceBtn.TextSize = 14
TraceBtn.BackgroundColor3 = Color3.fromRGB(35,35,35); TraceBtn.TextColor3 = Color3.new(1, 1, 1)
Instance.new("UICorner", TraceBtn)

local FBBtn = Instance.new("TextButton", VisP)
FBBtn.Size = UDim2.new(0.8,0,0,30); FBBtn.Position = UDim2.new(0.1,0,0,205)
FBBtn.Text = "FULLBRIGHT: KAPALI"; FBBtn.Font = "GothamBold"; FBBtn.TextSize = 14
FBBtn.BackgroundColor3 = Color3.fromRGB(35,35,35); FBBtn.TextColor3 = Color3.new(1, 1, 1) 
Instance.new("UICorner", FBBtn)

-- YENİ: ESP ALT DETAY KONTROLLERİ
label(VisP, "ESP DETAYLARI", 245, 14)

local EspNameBtn = Instance.new("TextButton", VisP)
EspNameBtn.Size = UDim2.new(0.8, 0, 0, 30); EspNameBtn.Position = UDim2.new(0.1, 0, 0, 275)
EspNameBtn.Text = "İSİM GÖSTER: AÇIK"; EspNameBtn.Font = "GothamBold"; EspNameBtn.TextSize = 14
EspNameBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35); EspNameBtn.TextColor3 = Color3.new(0, 1, 0)
Instance.new("UICorner", EspNameBtn)

local EspDistBtn = Instance.new("TextButton", VisP)
EspDistBtn.Size = UDim2.new(0.8, 0, 0, 30); EspDistBtn.Position = UDim2.new(0.1, 0, 0, 310)
EspDistBtn.Text = "MESAFE GÖSTER: AÇIK"; EspDistBtn.Font = "GothamBold"; EspDistBtn.TextSize = 14
EspDistBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35); EspDistBtn.TextColor3 = Color3.new(0, 1, 0)
Instance.new("UICorner", EspDistBtn)

local EspBarBtn = Instance.new("TextButton", VisP)
EspBarBtn.Size = UDim2.new(0.8, 0, 0, 30); EspBarBtn.Position = UDim2.new(0.1, 0, 0, 345)
EspBarBtn.Text = "CAN BARI GÖSTER: AÇIK"; EspBarBtn.Font = "GothamBold"; EspBarBtn.TextSize = 14
EspBarBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35); EspBarBtn.TextColor3 = Color3.new(0, 1, 0)
Instance.new("UICorner", EspBarBtn)

-- FUN SAYFASI
local SpinBtn = Instance.new("TextButton", FunP)
SpinBtn.Size = UDim2.new(0.8,0,0,40); SpinBtn.Position = UDim2.new(0.1,0,0,20)
SpinBtn.Text = "SPINBOT: KAPALI"; SpinBtn.Font = "GothamBold"; SpinBtn.TextSize = 14
SpinBtn.BackgroundColor3 = Color3.fromRGB(35,35,35); SpinBtn.TextColor3 = Color3.new(1,0,0)
Instance.new("UICorner", SpinBtn)
makeSlider(FunP, "SPIN HIZI", 70, 50, 200, function(v) spinSpeed = v end)

local IYBtn = Instance.new("TextButton", FunP)
IYBtn.Size = UDim2.new(0.8,0,0,40); IYBtn.Position = UDim2.new(0.1,0,0,140)
IYBtn.Text = "INFINITE YIELD AÇ"; IYBtn.Font = "GothamBold"; IYBtn.TextSize = 14
IYBtn.BackgroundColor3 = Color3.fromRGB(130,30,130); IYBtn.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", IYBtn)

-- [[ SETTINGS SAYFASI ]]
label(SettingsP, "SİSTEM AYARLARI", 10, 16)

local KillBtn = Instance.new("TextButton", SettingsP)
KillBtn.Size = UDim2.new(0.8, 0, 0, 45); KillBtn.Position = UDim2.new(0.1, 0, 0, 50)
KillBtn.Text = "STOP & KILL UI"; KillBtn.Font = "GothamBold"; KillBtn.TextSize = 16
KillBtn.BackgroundColor3 = Color3.fromRGB(180, 0, 0); KillBtn.TextColor3 = Color3.new(1, 1, 1)
Instance.new("UICorner", KillBtn)
KillBtn.MouseButton1Click:Connect(function() KillBtn.Text = "SHUTTING DOWN..." task.wait(0.5) totalShutdown() end)

label(SettingsP, "Kapatmak için Sağ Shift'i de kullanabilirsin.", 110, 11)

local function createKeybindUI(parent, text, yPos, actionName)
    local btn = Instance.new("TextButton", parent)
    btn.Size = UDim2.new(0.8, 0, 0, 30); btn.Position = UDim2.new(0.1, 0, 0, yPos)
    btn.Text = text .. ": " .. Keybinds[actionName].Name; btn.Font = "GothamBold"; btn.TextSize = 14
    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40); btn.TextColor3 = Color3.new(1, 1, 1)
    Instance.new("UICorner", btn)

    btn.MouseButton1Click:Connect(function()
        recordingAction = actionName; recordingButton = btn
        btn.Text = text .. ": TUŞ BEKLENİYOR..."; btn.TextColor3 = Color3.fromRGB(255, 255, 0) 
    end)
    return btn
end

label(SettingsP, "TUŞ ATAMALARI", 140, 16)
createKeybindUI(SettingsP, "Aimbot Tuşu", 170, "Aimbot")
createKeybindUI(SettingsP, "Hız Tuşu", 205, "Speed")
createKeybindUI(SettingsP, "Zıplama Tuşu", 240, "Jump")
createKeybindUI(SettingsP, "ESP Tuşu", 275, "ESP")
createKeybindUI(SettingsP, "Freecam Tuşu", 310, "FreeCam")
createKeybindUI(SettingsP, "Dash Tuşu", 345, "Dash") -- YENİ EKLENDİ

local function UpdateThemeColor()
    themeColor = Color3.fromRGB(themeR, themeG, themeB)
    for _, element in pairs(_G.ThemeElements) do
        if element:IsA("UIStroke") then element.Color = themeColor
        elseif element:IsA("TextLabel") or element:IsA("TextButton") then element.TextColor3 = themeColor
        elseif element:IsA("Frame") or element:IsA("ImageLabel") then element.BackgroundColor3 = themeColor
        elseif element:IsA("ScrollingFrame") then element.ScrollBarImageColor3 = themeColor end
    end
    if _G.FOVCircle then _G.FOVCircle.Color = themeColor end
end

table.insert(_G.ThemeElements, Stroke)
table.insert(_G.ThemeElements, Title)
table.insert(_G.ThemeElements, ResizeHandle)
table.insert(_G.ThemeElements, MinimizeBtn)

label(SettingsP, "TEMA RENGİ AYARI", 390, 16) -- Y koordinatları güncellendi
makeSlider(SettingsP, "TEMA (KIRMIZI)", 420, themeR, 255, function(v) themeR = v UpdateThemeColor() SaveConfig() end)
makeSlider(SettingsP, "TEMA (YEŞİL)", 460, themeG, 255, function(v) themeG = v UpdateThemeColor() SaveConfig() end)
makeSlider(SettingsP, "TEMA (MAVİ)", 500, themeB, 255, function(v) themeB = v UpdateThemeColor() SaveConfig() end)

makeSlider(SettingsP, "MENÜ SAYDAMLIĞI", 540, 0, 100, function(v)
    local transparency = v / 100
    Main.BackgroundTransparency = transparency
    SideBar.BackgroundTransparency = transparency
    PlayerListFrame.BackgroundTransparency = transparency == 0 and 0.1 or transparency
end)

local CreditLabel = Instance.new("TextLabel", SettingsP)
CreditLabel.Size = UDim2.new(1, 0, 0, 20); CreditLabel.Position = UDim2.new(0, 0, 0, 585) 
CreditLabel.BackgroundTransparency = 1; CreditLabel.Text = "by Yiwit"; CreditLabel.Font = "GothamBold"
CreditLabel.TextSize = 14; CreditLabel.TextColor3 = themeColor

local DiscordLabel = Instance.new("TextLabel", SettingsP)
DiscordLabel.Size = UDim2.new(1, 0, 0, 20); DiscordLabel.Position = UDim2.new(0, 0, 0, 605)
DiscordLabel.BackgroundTransparency = 1; DiscordLabel.Text = "discord for help: yasliplanet._."; DiscordLabel.Font = "Gotham"
DiscordLabel.TextSize = 12; DiscordLabel.TextColor3 = themeColor

table.insert(_G.ThemeElements, CreditLabel); table.insert(_G.ThemeElements, DiscordLabel)

-- [[ CONFIG (PROFIL) SAYFASI ]]
label(ConfigP, "YENİ CONFIG OLUŞTUR", 10, 16)

local ConfigNameIn = Instance.new("TextBox", ConfigP)
ConfigNameIn.Size = UDim2.new(0.5, 0, 0, 30)
ConfigNameIn.Position = UDim2.new(0.1, 0, 0, 45)
ConfigNameIn.PlaceholderText = "Örn: Legit, Rage, Chill"
ConfigNameIn.Text = ""
ConfigNameIn.Font = "GothamBold"
ConfigNameIn.TextSize = 12
ConfigNameIn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
ConfigNameIn.TextColor3 = Color3.new(1, 1, 1)
Instance.new("UICorner", ConfigNameIn)

local SaveConfigBtn = Instance.new("TextButton", ConfigP)
SaveConfigBtn.Size = UDim2.new(0.28, 0, 0, 30)
SaveConfigBtn.Position = UDim2.new(0.62, 0, 0, 45)
SaveConfigBtn.Text = "KAYDET"
SaveConfigBtn.Font = "GothamBold"
SaveConfigBtn.TextSize = 12
SaveConfigBtn.BackgroundColor3 = Color3.fromRGB(45, 150, 45)
SaveConfigBtn.TextColor3 = Color3.new(1, 1, 1)
Instance.new("UICorner", SaveConfigBtn)

label(ConfigP, "KAYITLI CONFIGLER", 90, 16)

local ConfigListFrame = Instance.new("ScrollingFrame", ConfigP)
ConfigListFrame.Size = UDim2.new(0.8, 0, 0, 200)
ConfigListFrame.Position = UDim2.new(0.1, 0, 0, 125)
ConfigListFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
ConfigListFrame.BorderSizePixel = 0
ConfigListFrame.ScrollBarThickness = 4
Instance.new("UICorner", ConfigListFrame)

local CfgLayout = Instance.new("UIListLayout", ConfigListFrame)
CfgLayout.SortOrder = Enum.SortOrder.LayoutOrder
CfgLayout.Padding = UDim.new(0, 5)

local function refreshConfigs()
    for _, v in pairs(ConfigListFrame:GetChildren()) do
        if v:IsA("Frame") then v:Destroy() end
    end
    
    if not isfolder(folderName) then makefolder(folderName) end
    
    local ySize = 0
    -- Executor'ın dosya okuma sistemini güvenli şekilde (pcall) kullanarak klasörü tarıyoruz
    local success, files = pcall(function() return listfiles(folderName) end)
    
    if success and files then
        for _, file in pairs(files) do
            -- Sadece .json dosyalarını al ve isimdeki klasör yollarını temizle
            if file:sub(-5) == ".json" and file ~= folderName .. "/settings.json" then
                local shortName = file:match("([^/\\]+)%.json$") or "Bilinmeyen"
                
                local ItemFrame = Instance.new("Frame", ConfigListFrame)
                ItemFrame.Size = UDim2.new(1, -10, 0, 30)
                ItemFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
                Instance.new("UICorner", ItemFrame)

                local NameLabel = Instance.new("TextLabel", ItemFrame)
                NameLabel.Size = UDim2.new(0.55, 0, 1, 0)
                NameLabel.Position = UDim2.new(0.05, 0, 0, 0)
                NameLabel.BackgroundTransparency = 1
                NameLabel.Text = shortName
                NameLabel.Font = "GothamBold"
                NameLabel.TextSize = 12
                NameLabel.TextColor3 = Color3.new(1, 1, 1)
                NameLabel.TextXAlignment = Enum.TextXAlignment.Left

                local LoadBtn = Instance.new("TextButton", ItemFrame)
                LoadBtn.Size = UDim2.new(0.25, 0, 0.8, 0)
                LoadBtn.Position = UDim2.new(0.6, 0, 0.1, 0)
                LoadBtn.Text = "YÜKLE"
                LoadBtn.Font = "GothamBold"
                LoadBtn.TextSize = 10
                LoadBtn.BackgroundColor3 = Color3.fromRGB(30, 100, 150)
                LoadBtn.TextColor3 = Color3.new(1, 1, 1)
                Instance.new("UICorner", LoadBtn)

                local DelBtn = Instance.new("TextButton", ItemFrame)
                DelBtn.Size = UDim2.new(0.1, 0, 0.8, 0)
                DelBtn.Position = UDim2.new(0.88, 0, 0.1, 0)
                DelBtn.Text = "X"
                DelBtn.Font = "GothamBold"
                DelBtn.TextSize = 12
                DelBtn.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
                DelBtn.TextColor3 = Color3.new(1, 1, 1)
                Instance.new("UICorner", DelBtn)

                LoadBtn.MouseButton1Click:Connect(function()
                    local readSuccess, result = pcall(function() return HttpService:JSONDecode(readfile(file)) end)
                    if readSuccess and result then
                        -- 1. Tema Yükleme
                        if result.Theme then
                            themeR = result.Theme.R or 255; themeG = result.Theme.G or 0; themeB = result.Theme.B or 0
                            UpdateThemeColor()
                        end
                        
                        -- 2. Sayısal Değerleri Yükleme
                        if result.Fov then fovRadius = result.Fov end
                        if result.Speed then SpeedIn.Text = tostring(result.Speed) end
                        if result.Jump then JumpIn.Text = tostring(result.Jump) end
                        if result.Dash then DashIn.Text = tostring(result.Dash) end
                        if result.SpinSpeed then spinSpeed = result.SpinSpeed end
                        if result.FreeCamSpeed then freeCamSpeed = result.FreeCamSpeed end
                        
                        -- 3. ESP ve Görsel Ayarları Yükleme
                        if result.EspDetails then
                            espNameOn = result.EspDetails.Name; espDistOn = result.EspDetails.Dist; espBarOn = result.EspDetails.Bar
                            EspNameBtn.Text = "İSİM GÖSTER: " .. (espNameOn and "AÇIK" or "KAPALI")
                            EspNameBtn.TextColor3 = espNameOn and Color3.new(0, 1, 0) or Color3.new(1, 1, 1)
                            EspDistBtn.Text = "MESAFE GÖSTER: " .. (espDistOn and "AÇIK" or "KAPALI")
                            EspDistBtn.TextColor3 = espDistOn and Color3.new(0, 1, 0) or Color3.new(1, 1, 1)
                            EspBarBtn.Text = "CAN BARI GÖSTER: " .. (espBarOn and "AÇIK" or "KAPALI")
                            EspBarBtn.TextColor3 = espBarOn and Color3.new(0, 1, 0) or Color3.new(1, 1, 1)
                        end
                        
                        if result.Visuals then
                            rainbowOn = result.Visuals.Rainbow; tracerOn = result.Visuals.Tracer; fullBrightOn = result.Visuals.FullBright
                            RainBtn.Text = "RAINBOW ESP: " .. (rainbowOn and "AÇIK" or "KAPALI")
                            RainBtn.TextColor3 = rainbowOn and Color3.new(0, 1, 0) or Color3.new(1, 1, 1)
                            TraceBtn.Text = "ÇİZGİLER: " .. (tracerOn and "AÇIK" or "KAPALI")
                            TraceBtn.TextColor3 = tracerOn and Color3.new(0, 1, 0) or Color3.new(1, 1, 1)
                            FBBtn.Text = "FULLBRIGHT: " .. (fullBrightOn and "AÇIK" or "KAPALI")
                            FBBtn.TextColor3 = fullBrightOn and Color3.new(0, 1, 0) or Color3.new(1, 1, 1)
                        end
                        
                        -- 4. Tuş Atamalarını Yükleme
                        if result.Keys then
                            for action, keyName in pairs(result.Keys) do
                                if Keybinds[action] and Enum.KeyCode[keyName] then
                                    Keybinds[action] = Enum.KeyCode[keyName]
                                end
                            end
                        end
                        
 -- Bildirim ver
                        if notify then notify("CONFIG YÜKLENDİ", shortName .. " başarıyla uygulandı!") end
                    end
                end) -- İŞTE KODU BOZAN EKSİK KISIM BURASIYDI!

                DelBtn.MouseButton1Click:Connect(function()
                    pcall(function() delfile(file) end)
                    refreshConfigs()
                    if notify then notify("CONFIG", shortName .. " silindi!") end
                end)

                ySize = ySize + 35
            end
        end
    end
    ConfigListFrame.CanvasSize = UDim2.new(0, 0, 0, ySize)
end

SaveConfigBtn.MouseButton1Click:Connect(function()
    local cName = ConfigNameIn.Text
    if cName == "" then cName = "Yeni_Config" end
    
    local path = folderName .. "/" .. cName .. ".json"
    local data = {
        Theme = {R = themeR, G = themeG, B = themeB},
        Fov = fovRadius,
        Speed = tonumber(SpeedIn.Text) or 5,
        Jump = tonumber(JumpIn.Text) or 80,
        Dash = tonumber(DashIn.Text) or 15,
        SpinSpeed = spinSpeed,
        FreeCamSpeed = freeCamSpeed,
        EspDetails = {Name = espNameOn, Dist = espDistOn, Bar = espBarOn},
        Visuals = {Rainbow = rainbowOn, Tracer = tracerOn, FullBright = fullBrightOn},
        Keys = {}
    }
    for action, key in pairs(Keybinds) do
        data.Keys[action] = key.Name
    end
    
    pcall(function() writefile(path, HttpService:JSONEncode(data)) end)
    ConfigNameIn.Text = ""
    refreshConfigs()
    if notify then notify("CONFIG", cName .. " başarıyla kaydedildi!") end
end)

-- Menü açıldığında configleri listele
refreshConfigs()

-- [6] RENDER & SPINBOT & FREECAM LOGIC
table.insert(_G.ZewittCons, RS.RenderStepped:Connect(function()
    
    local currentEspColor
    if rainbowOn then currentEspColor = Color3.fromHSV(tick() * 0.2 % 1, 0.8, 1) 
    else currentEspColor = Color3.fromRGB(rV, gV, bV) end
    
    if fullBrightOn then 
        Lighting.Ambient = Color3.new(1, 1, 1); Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
        Lighting.Brightness = 2; Lighting.ClockTime = 14; Lighting.GlobalShadows = false 
    end
    
    if aimbotOn then
        FOVCircle.Visible = true; FOVCircle.Position = Vector2.new(mouse.X, mouse.Y + 36)
        FOVCircle.Radius = fovRadius; FOVCircle.Color = themeColor 
    else FOVCircle.Visible = false end

    if freeCamOn then
        camera.CameraType = Enum.CameraType.Scriptable
        local rotCFrame = CFrame.Angles(0, camRotY, 0) * CFrame.Angles(camRotX, 0, 0)
        local moveVec = Vector3.new()
        if UIS:IsKeyDown(Enum.KeyCode.W) then moveVec += rotCFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then moveVec -= rotCFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then moveVec += rotCFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then moveVec -= rotCFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then moveVec += Vector3.new(0,1,0) end
        if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then moveVec -= Vector3.new(0,1,0) end
        camera.CFrame = CFrame.new(camera.CFrame.Position + (moveVec * freeCamSpeed)) * rotCFrame
    end

    if spinOn and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        player.Character.HumanoidRootPart.CFrame = player.Character.HumanoidRootPart.CFrame * CFrame.Angles(0, math.rad(spinSpeed), 0)
    end

    for _, v in pairs(Players:GetPlayers()) do
        local char = v.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        
        local nl = _G.Names[v.Name]
        local hpBg = _G.HpBgs[v.Name]
        local hpBar = _G.HpBars[v.Name]
        
        if v ~= player and char and hrp then
            local h = char:FindFirstChild("ZewittHighlight")
            if espOn then
                if not h then h = Instance.new("Highlight", char); h.Name = "ZewittHighlight" end
                h.FillColor = currentEspColor; h.OutlineColor = Color3.new(1,1,1); h.Enabled = true
                
                -- Yazı, Arkaplan ve Can Barı Çizimlerini Oluştur
                if not nl then 
                    nl = Drawing.new("Text"); nl.Size = 13; nl.Center = true; nl.Outline = true
                    _G.Names[v.Name] = nl 
                end
                if not hpBg then
                    hpBg = Drawing.new("Square"); hpBg.Filled = true; hpBg.Color = Color3.new(0, 0, 0)
                    _G.HpBgs[v.Name] = hpBg
                end
                if not hpBar then
                    hpBar = Drawing.new("Square"); hpBar.Filled = true
                    _G.HpBars[v.Name] = hpBar
                end
                
                -- Verileri Hesapla
                local myHrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                local dist = myHrp and math.floor((myHrp.Position - hrp.Position).Magnitude) or 0
                
                local targetHum = char:FindFirstChild("Humanoid")
                local hp = targetHum and math.floor(targetHum.Health) or 0
                local maxHp = targetHum and math.floor(targetHum.MaxHealth) or 100
                if maxHp <= 0 then maxHp = 100 end 
                local hpPercent = math.clamp(hp / maxHp, 0, 1)

                local pos, on = camera:WorldToViewportPoint(hrp.Position + Vector3.new(0, 4.0, 0))
                
                if on then 
                    -- Toggle Sistemine Göre Yazı Formatı
                    local textStr = ""
                    if espNameOn then textStr = v.Name end
                    if espDistOn then
                        if textStr ~= "" then textStr = textStr .. "\n" end
                        textStr = textStr .. "[" .. dist .. "m]"
                    end
                    
                    nl.Position = Vector2.new(pos.X, pos.Y)
                    nl.Text = textStr
                    nl.Color = currentEspColor
                    nl.Visible = (textStr ~= "") 
                    
                    -- Toggle Sistemine Göre Can Barı
                    if espBarOn then
                        local barWidth = 40
                        local barHeight = 4
                        local barYOffset = (textStr ~= "") and 30 or 10
                        
                        hpBg.Size = Vector2.new(barWidth + 2, barHeight + 2)
                        hpBg.Position = Vector2.new(pos.X - (barWidth / 2) - 1, pos.Y + barYOffset - 1)
                        hpBg.Visible = true
                        
                        hpBar.Size = Vector2.new(barWidth * hpPercent, barHeight)
                        hpBar.Position = Vector2.new(pos.X - (barWidth / 2), pos.Y + barYOffset)
                        
                        local r = math.clamp(255 - (hpPercent * 255), 0, 255)
                        local g = math.clamp(hpPercent * 255, 0, 255)
                        hpBar.Color = Color3.fromRGB(r, g, 0)
                        hpBar.Visible = true
                    else
                        hpBg.Visible = false
                        hpBar.Visible = false
                    end
                else 
                    nl.Visible = false; hpBg.Visible = false; hpBar.Visible = false
                end
            else
                if h then h:Destroy() end
                if nl then nl.Visible = false end
                if hpBg then hpBg.Visible = false end
                if hpBar then hpBar.Visible = false end
            end
            
            -- ÇİZGİLER (TRACERS)
            local line = _G.Lines[v.Name]
            if tracerOn and espOn then
                if not line then line = Drawing.new("Line"); line.Thickness = 1.5; _G.Lines[v.Name] = line end
                if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    local sP, on1 = camera:WorldToViewportPoint(player.Character.HumanoidRootPart.Position)
                    local eP, on2 = camera:WorldToViewportPoint(hrp.Position)
                    if on1 and on2 then 
                        line.From = Vector2.new(sP.X, sP.Y); line.To = Vector2.new(eP.X, eP.Y)
                        line.Color = currentEspColor; line.Visible = true 
                    else line.Visible = false end
                end
            elseif line then line.Visible = false end
        else
            -- Adam öldü veya çıktı, çizimleri gizle
            if _G.Lines[v.Name] then _G.Lines[v.Name].Visible = false end
            if _G.Names[v.Name] then _G.Names[v.Name].Visible = false end
            if _G.HpBgs[v.Name] then _G.HpBgs[v.Name].Visible = false end
            if _G.HpBars[v.Name] then _G.HpBars[v.Name].Visible = false end
        end
    end

    if aimbotOn and aiming and not freeCamOn then
        local t, d = nil, fovRadius
        for _, v in pairs(Players:GetPlayers()) do
            if v ~= player and v.Character and v.Character:FindFirstChild("Humanoid") and v.Character.Humanoid.Health > 0 then
                local partToAim = nil
                local head = v.Character:FindFirstChild("Head")
                local hrp2 = v.Character:FindFirstChild("HumanoidRootPart")
                
                if currentTargetPart == "Head" and head then partToAim = head
                elseif currentTargetPart == "Body" and hrp2 then partToAim = hrp2
                elseif currentTargetPart == "Random" then
                    if currentRandomTarget == "Head" and head then partToAim = head
                    elseif hrp2 then partToAim = hrp2 end
                end

                if partToAim then
                    local pos, on = camera:WorldToViewportPoint(partToAim.Position)
                    if on then
                        local dist = (Vector2.new(pos.X, pos.Y) - Vector2.new(mouse.X, mouse.Y)).Magnitude
                        if dist < d then d = dist; t = partToAim end
                    end
                end
            end
        end
        if t then camera.CFrame = CFrame.new(camera.CFrame.Position, t.Position) end
    end
end))

-- [7] ACTIONS (BUTON TIKLAMALARI)

RainBtn.MouseButton1Click:Connect(function()
    rainbowOn = not rainbowOn
    RainBtn.Text = "RAINBOW ESP: " .. (rainbowOn and "AÇIK" or "KAPALI")
    RainBtn.TextColor3 = rainbowOn and Color3.new(0, 1, 0) or Color3.new(1, 1, 1)
end)

TraceBtn.MouseButton1Click:Connect(function() 
    tracerOn = not tracerOn
    TraceBtn.Text = "ÇİZGİLER: "..(tracerOn and "AÇIK" or "KAPALI") 
    TraceBtn.TextColor3 = tracerOn and Color3.new(0, 1, 0) or Color3.new(1, 1, 1)
end)

FBBtn.MouseButton1Click:Connect(function() 
    fullBrightOn = not fullBrightOn
    FBBtn.Text = "FULLBRIGHT: " .. (fullBrightOn and "AÇIK" or "KAPALI")
    FBBtn.TextColor3 = fullBrightOn and Color3.new(0, 1, 0) or Color3.new(1, 1, 1)
    if not fullBrightOn then 
        Lighting.Ambient = oldAmbient; Lighting.OutdoorAmbient = oldOutdoorAmbient
        Lighting.Brightness = oldBrightness; Lighting.ClockTime = oldClockTime; Lighting.GlobalShadows = oldGlobalShadows 
    end
end)

EspNameBtn.MouseButton1Click:Connect(function()
    espNameOn = not espNameOn
    EspNameBtn.Text = "İSİM GÖSTER: " .. (espNameOn and "AÇIK" or "KAPALI")
    EspNameBtn.TextColor3 = espNameOn and Color3.new(0, 1, 0) or Color3.new(1, 1, 1)
end)

EspDistBtn.MouseButton1Click:Connect(function()
    espDistOn = not espDistOn
    EspDistBtn.Text = "MESAFE GÖSTER: " .. (espDistOn and "AÇIK" or "KAPALI")
    EspDistBtn.TextColor3 = espDistOn and Color3.new(0, 1, 0) or Color3.new(1, 1, 1)
end)

EspBarBtn.MouseButton1Click:Connect(function()
    espBarOn = not espBarOn
    EspBarBtn.Text = "CAN BARI GÖSTER: " .. (espBarOn and "AÇIK" or "KAPALI")
    EspBarBtn.TextColor3 = espBarOn and Color3.new(0, 1, 0) or Color3.new(1, 1, 1)
end)

IYBtn.MouseButton1Click:Connect(function() loadstring(game:HttpGet('https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source'))() end)

SpinBtn.MouseButton1Click:Connect(function()
    spinOn = not spinOn
    SpinBtn.Text = "SPINBOT: "..(spinOn and "AÇIK" or "KAPALI")
    SpinBtn.TextColor3 = spinOn and Color3.new(0,1,0) or Color3.new(1,0,0)
end)

TpBtn.MouseButton1Click:Connect(function()
    if selectedPlayerName == "" then return end
    local v = Players:FindFirstChild(selectedPlayerName)
    if v and v ~= player and v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            player.Character.HumanoidRootPart.CFrame = v.Character.HumanoidRootPart.CFrame * CFrame.new(0,0,-3)
        end
    end
end)

SpecBtn.MouseButton1Click:Connect(function()
    if selectedPlayerName == "" then return end
    local v = Players:FindFirstChild(selectedPlayerName)
    if v and v ~= player and v.Character and v.Character:FindFirstChild("Humanoid") then
        camera.CameraSubject = v.Character.Humanoid
    end
end)

UnSpecBtn.MouseButton1Click:Connect(function() 
    if player.Character and player.Character:FindFirstChild("Humanoid") then
        camera.CameraSubject = player.Character.Humanoid 
    end
end)

NearestTpBtn.MouseButton1Click:Connect(function()
    local nearest, minDist = nil, math.huge
    local myPos = player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character.HumanoidRootPart.Position
    if not myPos then return end
    for _, v in pairs(Players:GetPlayers()) do
        if v ~= player and v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
            local dist = (v.Character.HumanoidRootPart.Position - myPos).Magnitude
            if dist < minDist then minDist = dist; nearest = v end
        end
    end
    if nearest then player.Character.HumanoidRootPart.CFrame = nearest.Character.HumanoidRootPart.CFrame * CFrame.new(0,0,-3) end
end)

table.insert(_G.ZewittCons, RS.Heartbeat:Connect(function()
    if speedOn and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        local hum = player.Character:FindFirstChildOfClass("Humanoid")
        local sVal = tonumber(SpeedIn.Text) or 5 
        if hum and hum.MoveDirection.Magnitude > 0 then
            player.Character.HumanoidRootPart.CFrame += hum.MoveDirection * (sVal/10)
        end
    end
end))

table.insert(_G.ZewittCons, UIS.InputChanged:Connect(function(input)
    if freeCamOn and input.UserInputType == Enum.UserInputType.MouseMovement then
        if UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
            UIS.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
            camRotX = math.clamp(camRotX - input.Delta.Y * 0.005, -math.rad(89), math.rad(89))
            camRotY = camRotY - input.Delta.X * 0.005
        else UIS.MouseBehavior = Enum.MouseBehavior.Default end
    end
end))

table.insert(_G.ZewittCons, UIS.InputBegan:Connect(function(i, g)
    if recordingAction and i.UserInputType == Enum.UserInputType.Keyboard then
        if i.KeyCode ~= Enum.KeyCode.Unknown and i.KeyCode ~= Enum.KeyCode.Escape then
            Keybinds[recordingAction] = i.KeyCode; SaveConfig()
            local baseText = string.split(recordingButton.Text, ":")[1]
            recordingButton.Text = baseText .. ": " .. i.KeyCode.Name; recordingButton.TextColor3 = Color3.new(1, 1, 1)
        else
            local baseText = string.split(recordingButton.Text, ":")[1]
            recordingButton.Text = baseText .. ": " .. Keybinds[recordingAction].Name; recordingButton.TextColor3 = Color3.new(1, 1, 1)
        end
        recordingAction = nil; recordingButton = nil
        return 
    end

    if i.KeyCode == Enum.KeyCode.RightShift then totalShutdown() return end
	if i.KeyCode == Enum.KeyCode.RightControl then Main.Visible = not Main.Visible return end
    if g then return end 
    
    if i.KeyCode == Keybinds.Aimbot then 
        aimbotOn = not aimbotOn; AimStatus.Text = "AIMBOT: "..(aimbotOn and "AKTİF" or "KAPALI")
        AimStatus.TextColor3 = aimbotOn and Color3.new(0,1,0) or Color3.new(1,0,0)
    elseif i.KeyCode == Keybinds.Speed then 
        speedOn = not speedOn; SpeedStatus.Text = "HIZ: "..(speedOn and "AÇIK" or "KAPALI")
        SpeedStatus.TextColor3 = speedOn and Color3.new(0,1,0) or Color3.new(1,0,0)
    elseif i.KeyCode == Keybinds.Jump then 
        jumpOn = not jumpOn; JumpStatus.Text = "ZIPLAMA: "..(jumpOn and "AÇIK" or "KAPALI")
        JumpStatus.TextColor3 = jumpOn and Color3.new(0,1,0) or Color3.new(1,0,0)
        local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.UseJumpPower = true; hum.JumpPower = jumpOn and (tonumber(JumpIn.Text) or 50) or 50 end
    elseif i.KeyCode == Keybinds.ESP then 
        espOn = not espOn -- Ana ESP açma kapama tuşu (V)
    elseif i.KeyCode == Keybinds.FreeCam then 
        freeCamOn = not freeCamOn
        if freeCamOn then
            local x, y, z = camera.CFrame:ToEulerAnglesYXZ()
            camRotX, camRotY = x, y
        else
            camera.CameraType = Enum.CameraType.Custom
            if player.Character and player.Character:FindFirstChild("Humanoid") then
                camera.CameraSubject = player.Character.Humanoid
            end
        end
    elseif i.KeyCode == Keybinds.Dash then 
        -- YENİ: DASH İŞLEMİ (Anında ileri atılma)
        local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            local dashDist = tonumber(DashIn.Text) or 15
            hrp.CFrame = hrp.CFrame + (hrp.CFrame.LookVector * dashDist)
        end
    end
    
    if i.UserInputType == Enum.UserInputType.MouseButton2 then 
        aiming = true 
        if currentTargetPart == "Random" then
            if math.random(1, 3) == 1 then currentRandomTarget = "Head" else currentRandomTarget = "Body" end
        end
    end
end))

table.insert(_G.ZewittCons, UIS.InputEnded:Connect(function(i) 
    if i.UserInputType == Enum.UserInputType.MouseButton2 then aiming = false end 
end))

print("Zewitt Yüklendi! Kapanış İçin: Sağ Shift")
