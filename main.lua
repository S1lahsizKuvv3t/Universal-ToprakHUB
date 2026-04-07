-- [[ ToprakHUB - INFINITE YIELD & COLOR SEPARATION ]]
-- [ GÜNCELLEME: OYUNCU SEÇME LİSTESİ (DROPDOWN) EKLENDİ ]

local name = "ToprakHUB"

-- SERVİSLER
local Players = game:GetService("Players")
local RS = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local mouse = player:GetMouse()

-- [1] TAM TEMİZLİK (GÜVENLİ KAPANIŞ)
_G.ToprakCons = _G.ToprakCons or {}
local function totalShutdown()
    for _, con in pairs(_G.ToprakCons or {}) do 
        pcall(function() con:Disconnect() end) 
    end
    _G.ToprakCons = {}

    for _, v in pairs(game:GetService("Players"):GetPlayers()) do
        if v.Character and v.Character:FindFirstChild("ToprakHighlight") then
            v.Character.ToprakHighlight:Destroy()
        end
    end

    if _G.FOVCircle then 
        pcall(function() _G.FOVCircle:Remove() end) 
        _G.FOVCircle = nil 
    end

    if _G.Names then 
        for i, v in pairs(_G.Names) do pcall(function() v:Remove() end) end 
        _G.Names = {} 
    end

    if _G.Lines then 
        for i, v in pairs(_G.Lines) do pcall(function() v:Remove() end) end 
        _G.Lines = {} 
    end

    for _, v in pairs(game:GetService("CoreGui"):GetChildren()) do 
        if v.Name:find("ToprakHUB") then v:Destroy() end 
    end

    pcall(function()
        camera.CameraType = Enum.CameraType.Custom
        if player.Character and player.Character:FindFirstChild("Humanoid") then
            camera.CameraSubject = player.Character.Humanoid
        end
        UIS.MouseBehavior = Enum.MouseBehavior.Default
    end)
    
    print("ToprakHUB Tamamen Temizlendi.")
end
totalShutdown()

-- [2] DEĞİŞKENLER & RENK AYIRIMI
local speedOn, jumpOn, espOn, aimbotOn, tracerOn, rainbowOn, fullBrightOn, namesOn = false, false, false, false, false, false, false, false
local spinOn, spinSpeed = false, 50
local freeCamOn, freeCamSpeed = false, 2
local camRotX, camRotY = 0, 0

local themeR, themeG, themeB = 255, 0, 0
local themeColor = Color3.fromRGB(themeR, themeG, themeB)
_G.ThemeElements = _G.ThemeElements or {} -- Rengi değişecek UI elementlerini tutacağımız tablo
local rV, gV, bV = 255, 0, 0
local fovRadius, aiming = 120, false

_G.Lines = _G.Lines or {}
_G.Names = _G.Names or {}

local oldBrightness = Lighting.Brightness
local oldClockTime = Lighting.ClockTime
local oldGlobalShadows = Lighting.GlobalShadows
local oldAmbient = Lighting.Ambient
local oldOutdoorAmbient = Lighting.OutdoorAmbient

-- Tuş Atamalarını Tutan Tablo ve Kayıt Durumu Değişkenleri
local HttpService = game:GetService("HttpService")
local folderName = "ToprakHUB_Configs"
local fileName = folderName .. "/settings.json"

-- Tuş Atamalarını Tutan Tablo (Varsayılanlar)
local Keybinds = {
    Aimbot = Enum.KeyCode.E,
    Speed = Enum.KeyCode.Q,
    Jump = Enum.KeyCode.X,
    ESP = Enum.KeyCode.V,
    FreeCam = Enum.KeyCode.Backquote
}
local recordingAction = nil
local recordingButton = nil

-- Ayarları Kaydetme Fonksiyonu
local function SaveConfig()
    if not isfolder(folderName) then makefolder(folderName) end
    
    local dataToSave = { 
        Keybinds = {},
        Theme = {R = themeR, G = themeG, B = themeB} -- TEMA RENGİNİ KAYDET
    }
    
    for action, keycode in pairs(Keybinds) do
        dataToSave.Keybinds[action] = keycode.Name
    end
    
    writefile(fileName, HttpService:JSONEncode(dataToSave))
end

-- Ayarları Yükleme Fonksiyonu
local function LoadConfig()
    if isfile(fileName) then
        local success, result = pcall(function()
            return HttpService:JSONDecode(readfile(fileName))
        end)
        
        if success and result then
            if result.Keybinds then
                for action, keyName in pairs(result.Keybinds) do
                    if Keybinds[action] and Enum.KeyCode[keyName] then
                        Keybinds[action] = Enum.KeyCode[keyName]
                    end
                end
            end
            -- TEMA RENGİNİ YÜKLE
            if result.Theme then
                themeR = result.Theme.R or 255
                themeG = result.Theme.G or 0
                themeB = result.Theme.B or 0
                themeColor = Color3.fromRGB(themeR, themeG, themeB)
            end
        end
    end
end

-- UI oluşturulmadan ÖNCE ayarları yükle ki butonlar güncel tuşları göstersin
LoadConfig()

-- [3] ÇIKIŞ YAPAN OYUNCUYU TEMİZLEME
table.insert(_G.ToprakCons, Players.PlayerRemoving:Connect(function(p)
    if _G.Names[p.Name] then _G.Names[p.Name]:Remove() _G.Names[p.Name] = nil end
    if _G.Lines[p.Name] then _G.Lines[p.Name]:Remove() _G.Lines[p.Name] = nil end
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

local Main = Instance.new("Frame", ScreenGui)
Main.Size = UDim2.new(0, 520, 0, 420)
Main.Position = UDim2.new(0.5, -260, 0.5, -210)
Main.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
Main.Active = true
Main.ClipsDescendants = true 
-- [[ ÖZEL SÜRÜKLEME (DRAG) SİSTEMİ ]]
local dragging
local dragInput
local dragStart
local startPos

-- Sadece SideBar (sol menü) veya Main (ana arka plan) üzerinden tutunca çalışsın
local function updateDrag(input)
    local delta = input.Position - dragStart
    Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

Main.InputBegan:Connect(function(input)
    -- Farenin sol tuşuna basıldığında
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = Main.Position
        
        -- Sürükleme başladığında diğer hareketleri dinle
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

table.insert(_G.ToprakCons, UIS.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end))

table.insert(_G.ToprakCons, RS.RenderStepped:Connect(function()
    if dragging and dragInput then
        updateDrag(dragInput)
    end
end))
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)

local Stroke = Instance.new("UIStroke", Main)
Stroke.Thickness = 2
Stroke.Color = themeColor

local SideBar = Instance.new("Frame", Main)
SideBar.Size = UDim2.new(0, 150, 1, 0)
SideBar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
Instance.new("UICorner", SideBar)

local Title = Instance.new("TextLabel", SideBar)
Title.Size = UDim2.new(1, 0, 0, 60)
Title.Text = "ToprakHUB"
Title.Font = "GothamBold"
Title.TextSize = 22
Title.BackgroundTransparency = 1
Title.TextColor3 = themeColor
-- [[ OYUNCU PROFİLİ (SOL ALT) ]]
local ProfileFrame = Instance.new("Frame", SideBar)
ProfileFrame.Size = UDim2.new(1, 0, 0, 50)
ProfileFrame.Position = UDim2.new(0, 0, 1, -50) -- En alta hizalar
ProfileFrame.BackgroundTransparency = 1

-- Profil Resmi (Avatar)
local AvatarImage = Instance.new("ImageLabel", ProfileFrame)
AvatarImage.Size = UDim2.new(0, 30, 0, 30)
AvatarImage.Position = UDim2.new(0, 10, 0.5, 0)
AvatarImage.AnchorPoint = Vector2.new(0, 0.5)
AvatarImage.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
Instance.new("UICorner", AvatarImage).CornerRadius = UDim.new(1, 0) -- Tam yuvarlak yapar

-- Resmi Roblox'tan Çekme
task.spawn(function()
    local userId = player.UserId
    local thumbType = Enum.ThumbnailType.HeadShot
    local thumbSize = Enum.ThumbnailSize.Size420x420
    local content, isReady = Players:GetUserThumbnailAsync(userId, thumbType, thumbSize)
    if isReady then
        AvatarImage.Image = content
    end
end)

-- Oyuncu İsmi
local UsernameLabel = Instance.new("TextLabel", ProfileFrame)
UsernameLabel.Size = UDim2.new(1, -50, 1, 0)
UsernameLabel.Position = UDim2.new(0, 45, 0, 0)
UsernameLabel.BackgroundTransparency = 1
UsernameLabel.Text = player.DisplayName -- Sadece kullanıcı adını istersen player.Name yapabilirsin
UsernameLabel.Font = "GothamBold"
UsernameLabel.TextSize = 12
UsernameLabel.TextColor3 = themeColor
UsernameLabel.TextXAlignment = Enum.TextXAlignment.Left

-- Tema değiştiğinde ismin rengi de değişsin diye listeye ekliyoruz
table.insert(_G.ThemeElements, UsernameLabel)


local Container = Instance.new("Frame", Main)
Container.Size = UDim2.new(1, -170, 1, -20)
Container.Position = UDim2.new(0, 160, 0, 10)
Container.BackgroundTransparency = 1

-- [[ YENİDEN BOYUTLANDIRMA (RESIZE) SİSTEMİ ]]
local ResizeHandle = Instance.new("TextButton", Main)
ResizeHandle.Size = UDim2.new(0, 20, 0, 20)
ResizeHandle.Position = UDim2.new(1, -20, 1, -20)
ResizeHandle.BackgroundTransparency = 1
ResizeHandle.Text = "◢"
ResizeHandle.TextSize = 16
ResizeHandle.TextColor3 = themeColor
ResizeHandle.ZIndex = 10

local resizing = false
local minSize = Vector2.new(520, 420)

ResizeHandle.MouseButton1Down:Connect(function() resizing = true end)
table.insert(_G.ToprakCons, UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then resizing = false end
end))

table.insert(_G.ToprakCons, RS.RenderStepped:Connect(function()
    if resizing then
        local newWidth = math.max(minSize.X, mouse.X - Main.AbsolutePosition.X)
        local newHeight = math.max(minSize.Y, mouse.Y - Main.AbsolutePosition.Y)
        Main.Size = UDim2.new(0, newWidth, 0, newHeight)
    end
end))

-- [[ KÜÇÜLTME (MINIMIZE) SİSTEMİ ]]
local MinimizeBtn = Instance.new("TextButton", Main)
MinimizeBtn.Size = UDim2.new(0, 30, 0, 30)
MinimizeBtn.Position = UDim2.new(1, -40, 0, 5)
MinimizeBtn.BackgroundTransparency = 1
MinimizeBtn.Text = "-"
MinimizeBtn.TextSize = 24
MinimizeBtn.Font = "GothamBold"
MinimizeBtn.TextColor3 = themeColor
MinimizeBtn.ZIndex = 10

local isMinimized = false
local preMinimizeSize = Main.Size

MinimizeBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    if isMinimized then
        preMinimizeSize = Main.Size
        MinimizeBtn.Text = "+"
        Container.Visible = false
        ResizeHandle.Visible = false
        for _, v in pairs(SideBar:GetChildren()) do
            if v:IsA("TextButton") then v.Visible = false end
        end
        Main.Size = UDim2.new(0, preMinimizeSize.X.Offset, 0, 60)
    else
        MinimizeBtn.Text = "-"
        Container.Visible = true
        ResizeHandle.Visible = true
        for _, v in pairs(SideBar:GetChildren()) do
            if v:IsA("TextButton") then v.Visible = true end
        end
        Main.Size = preMinimizeSize
    end
end)

local Pages = {}
local function createTab(tname, pos)
    local btn = Instance.new("TextButton", SideBar)
    btn.Size = UDim2.new(0.9, 0, 0, 40)
    btn.Position = UDim2.new(0.05, 0, 0, 70 + (pos * 45))
    btn.Text = tname
    btn.Font = "GothamBold"
    btn.TextSize = 12
    btn.BackgroundColor3 = Color3.fromRGB(30,30,30)
    btn.TextColor3 = Color3.new(1,1,1)
    Instance.new("UICorner", btn)
    
    -- YENİ: Normal Frame yerine ScrollingFrame kullanıyoruz
    local p = Instance.new("ScrollingFrame", Container)
    p.Size = UDim2.new(1, 0, 1, 0)
    p.BackgroundTransparency = 1
    p.BorderSizePixel = 0
    p.ScrollBarThickness = 4
    p.CanvasSize = UDim2.new(0, 0, 0, 700)
    p.Visible = (pos == 0)
    -- p.Active = true YOK, eğer varsa sil.
    
    btn.MouseButton1Click:Connect(function() 
        for _, v in pairs(Pages) do v.Visible = false end 
        p.Visible = true 
    end)
    Pages[tname] = p
    
    -- Kaydırma çubuğunun renginin de temaya uyması için listeye ekliyoruz
    table.insert(_G.ThemeElements, p)
    
    return p
end

local AimP = createTab("AIMBOT", 0)
local MoveP = createTab("MOVEMENT", 1)
local TeleP = createTab("TELEPORT", 2)
local VisP = createTab("VISUALS", 3)
local FunP = createTab("FUN", 4)
local SettingsP = createTab("SETTINGS", 5)

local function label(p, txt, y, sz)
    local l = Instance.new("TextLabel", p)
    l.Size = UDim2.new(1,0,0,30)
    l.Position = UDim2.new(0,0,0,y)
    l.Text = txt
    l.TextColor3 = Color3.new(1,1,1)
    l.Font = "GothamBold"
    l.TextSize = sz or 14
    l.BackgroundTransparency = 1
    return l
end

local function makeSlider(p, title, y, def, max, callback)
    local l = label(p, title, y, 11)
    local bar = Instance.new("Frame", p)
    bar.Size = UDim2.new(0.8,0,0,8)
    bar.Position = UDim2.new(0.1,0,0,y+25)
    bar.BackgroundColor3 = Color3.fromRGB(40,40,40)
    Instance.new("UICorner", bar)
    
    local b = Instance.new("TextButton", bar)
    b.Size = UDim2.new(0,16,0,16)
    b.Position = UDim2.new(def/max,0,0.5,0)
    b.AnchorPoint = Vector2.new(0.5,0.5)
    b.Text = ""
    b.BackgroundColor3 = themeColor
    Instance.new("UICorner", b).CornerRadius = UDim.new(1,0)
    table.insert(_G.ThemeElements, b) -- Slider'ın renkli topunu/çubuğunu listeye ekle

    local d = false
    b.MouseButton1Down:Connect(function() d = true end)
    table.insert(_G.ToprakCons, UIS.InputEnded:Connect(function(i) 
        if i.UserInputType == Enum.UserInputType.MouseButton1 then d = false end 
    end))
    
    table.insert(_G.ToprakCons, RS.RenderStepped:Connect(function()
        if d then 
            local m = math.clamp((mouse.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
            b.Position = UDim2.new(m,0,0.5,0)
            callback(m*max) 
        end
    end))
end

-- [[ KESİN ÇÖZÜM: WELCOME SCREEN ANIMATION ]]
local function playWelcomeAnimation()
    if ScreenGui:FindFirstChild("ToprakWelcome") then ScreenGui.ToprakWelcome:Destroy() end

    local WelcomeFrame = Instance.new("Frame", ScreenGui)
    WelcomeFrame.Name = "ToprakWelcome"
    WelcomeFrame.Size = UDim2.new(0, 520, 0, 420) 
    WelcomeFrame.Position = UDim2.new(0.5, -260, 0.5, -210) 
    WelcomeFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15) 
    WelcomeFrame.BorderSizePixel = 0
    WelcomeFrame.ZIndex = 999 
    
    local Corner = Instance.new("UICorner", WelcomeFrame)
    Corner.CornerRadius = UDim.new(0, 10)

    local WelcomeText = Instance.new("TextLabel", WelcomeFrame)
    WelcomeText.Size = UDim2.new(1, 0, 1, 0) 
    WelcomeText.BackgroundTransparency = 1
    WelcomeText.Text = "Welcome to ToprakHUB!"
    WelcomeText.Font = Enum.Font.GothamBold 
    WelcomeText.TextSize = 32
    WelcomeText.TextColor3 = Color3.fromRGB(255, 0, 0) 
    WelcomeText.TextTransparency = 1 
    WelcomeText.ZIndex = 1000 

    local TS = game:GetService("TweenService")
    local info = TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

    Main.Visible = false

    task.wait(0.2) 
    
    TS:Create(WelcomeText, info, {TextTransparency = 0}):Play()
    
    task.wait(2.5) 

    TS:Create(WelcomeText, info, {TextTransparency = 1}):Play()
    local fadeOut = TS:Create(WelcomeFrame, info, {BackgroundTransparency = 1})
    fadeOut:Play()

    fadeOut.Completed:Connect(function()
        WelcomeFrame:Destroy() 
        Main.Visible = true 
    end)
end

task.spawn(playWelcomeAnimation)

-- AIMBOT SAYFASI
local AimStatus = label(AimP, "AIMBOT: KAPALI [E]", 10, 16)
makeSlider(AimP, "FOV BOYUTU", 80, 120, 600, function(v) fovRadius = v end)

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

-- TELEPORT SAYFASI
label(TeleP, "IŞINLANMA & İZLEME", 5, 16)

-- [[ YENİ DROPDOWN SİSTEMİ (TEXTBOX YERİNE) ]]
local selectedPlayerName = ""

local DropdownBtn = Instance.new("TextButton", TeleP)
DropdownBtn.Size = UDim2.new(0.8, 0, 0, 30)
DropdownBtn.Position = UDim2.new(0.1, 0, 0, 35)
DropdownBtn.Text = "Oyuncu Seç..."
DropdownBtn.Font = "GothamBold"
DropdownBtn.TextSize = 14
DropdownBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
DropdownBtn.TextColor3 = Color3.new(1, 1, 1)
DropdownBtn.ZIndex = 2
Instance.new("UICorner", DropdownBtn)

local PlayerListFrame = Instance.new("ScrollingFrame", TeleP)
PlayerListFrame.Size = UDim2.new(0.8, 0, 0, 110)
PlayerListFrame.Position = UDim2.new(0.1, 0, 0, 68) -- Butonun hemen altı
PlayerListFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
PlayerListFrame.BorderSizePixel = 0
PlayerListFrame.ScrollBarThickness = 4
PlayerListFrame.Visible = false
PlayerListFrame.ZIndex = 5 -- Diğer butonların üstüne gelmesi için yüksek ZIndex
Instance.new("UICorner", PlayerListFrame)

local UIListLayout = Instance.new("UIListLayout", PlayerListFrame)
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder

local function refreshPlayerList()
    for _, v in pairs(PlayerListFrame:GetChildren()) do
        if v:IsA("TextButton") then v:Destroy() end
    end
    
    local ySize = 0
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= player then
            local plrBtn = Instance.new("TextButton", PlayerListFrame)
            plrBtn.Size = UDim2.new(1, 0, 0, 25)
            plrBtn.Text = p.Name
            plrBtn.Font = "Gotham"
            plrBtn.TextSize = 12
            plrBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
            plrBtn.TextColor3 = Color3.new(1, 1, 1)
            plrBtn.ZIndex = 6
            
            plrBtn.MouseButton1Click:Connect(function()
                selectedPlayerName = p.Name
                DropdownBtn.Text = p.Name
                PlayerListFrame.Visible = false
            end)
            ySize = ySize + 25
        end
    end
    PlayerListFrame.CanvasSize = UDim2.new(0, 0, 0, ySize)
end

DropdownBtn.MouseButton1Click:Connect(function()
    PlayerListFrame.Visible = not PlayerListFrame.Visible
    if PlayerListFrame.Visible then
        refreshPlayerList()
    end
end)
-- [[ DROPDOWN SİSTEMİ BİTİŞİ ]]

local TpBtn = Instance.new("TextButton", TeleP)
TpBtn.Size = UDim2.new(0.38,0,0,30); TpBtn.Position = UDim2.new(0.1,0,0,70)
TpBtn.Text = "İSME GİT"; TpBtn.Font = "GothamBold"; TpBtn.BackgroundColor3 = Color3.fromRGB(45,45,45); TpBtn.TextColor3 = Color3.new(1,1,1)
TpBtn.ZIndex = 1
Instance.new("UICorner", TpBtn)

local SpecBtn = Instance.new("TextButton", TeleP)
SpecBtn.Size = UDim2.new(0.38,0,0,30); SpecBtn.Position = UDim2.new(0.52,0,0,70)
SpecBtn.Text = "İZLE"; SpecBtn.Font = "GothamBold"; SpecBtn.BackgroundColor3 = Color3.fromRGB(45,45,45); SpecBtn.TextColor3 = Color3.new(1,1,1)
SpecBtn.ZIndex = 1
Instance.new("UICorner", SpecBtn)

local UnSpecBtn = Instance.new("TextButton", TeleP)
UnSpecBtn.Size = UDim2.new(0.8,0,0,30); UnSpecBtn.Position = UDim2.new(0.1,0,0,105)
UnSpecBtn.Text = "İZLEMEYİ BIRAK"; UnSpecBtn.Font = "GothamBold"; UnSpecBtn.BackgroundColor3 = Color3.fromRGB(30,30,30); UnSpecBtn.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", UnSpecBtn)

local NearestTpBtn = Instance.new("TextButton", TeleP)
NearestTpBtn.Size = UDim2.new(0.8,0,0,30); NearestTpBtn.Position = UDim2.new(0.1,0,0,140)
NearestTpBtn.Text = "EN YAKIN OYUNCUYA TP"; NearestTpBtn.Font = "GothamBold"; NearestTpBtn.BackgroundColor3 = Color3.fromRGB(150,30,30); NearestTpBtn.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", NearestTpBtn)

local FreeCamStatus = label(TeleP, "FREECAM: KAPALI [é]", 180, 16)
makeSlider(TeleP, "FREECAM HIZI", 210, 2, 10, function(v) freeCamSpeed = v end)

-- VISUALS SAYFASI
makeSlider(VisP, "ESP RENGİ (KIRMIZI)", 5, rV, 255, function(v) rV = v end)
makeSlider(VisP, "ESP RENGİ (YEŞİL)", 45, gV, 255, function(v) gV = v end)
makeSlider(VisP, "ESP RENGİ (MAVİ)", 85, bV, 255, function(v) bV = v end)

local RainBtn = Instance.new("TextButton", VisP)
RainBtn.Size = UDim2.new(0.8, 0, 0, 30)
RainBtn.Position = UDim2.new(0.1, 0, 0, 135)
RainBtn.Text = "RAINBOW ESP: KAPALI"
RainBtn.Font = "GothamBold"
RainBtn.TextSize = 14
RainBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
RainBtn.TextColor3 = Color3.new(1, 1, 1)
Instance.new("UICorner", RainBtn)

local TraceBtn = Instance.new("TextButton", VisP)
TraceBtn.Size = UDim2.new(0.8,0,0,30); TraceBtn.Position = UDim2.new(0.1,0,0,170)
TraceBtn.Text = "ÇİZGİLER: KAPALI"; TraceBtn.Font = "GothamBold"; TraceBtn.TextSize = 14; TraceBtn.BackgroundColor3 = Color3.fromRGB(35,35,35)
TraceBtn.TextColor3 = Color3.new(1, 1, 1)
Instance.new("UICorner", TraceBtn)

local FBBtn = Instance.new("TextButton", VisP)
FBBtn.Size = UDim2.new(0.8,0,0,30)
FBBtn.Position = UDim2.new(0.1,0,0,205)
FBBtn.Text = "FULLBRIGHT: KAPALI"
FBBtn.TextColor3 = Color3.new(1, 1, 1) 
FBBtn.Font = "GothamBold"
FBBtn.TextSize = 14
FBBtn.BackgroundColor3 = Color3.fromRGB(35,35,35)
Instance.new("UICorner", FBBtn)

local EspStatus = label(VisP, "ESP (V): KAPALI", 245, 14)
EspStatus.TextColor3 = Color3.new(1,0,0)

local NameBtn = Instance.new("TextButton", VisP)
NameBtn.Size = UDim2.new(0.8, 0, 0, 30)
NameBtn.Position = UDim2.new(0.1, 0, 0, 280) 
NameBtn.Text = "NAMETAGS: KAPALI"
NameBtn.Font = "GothamBold"
NameBtn.TextSize = 14
NameBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
NameBtn.TextColor3 = Color3.new(1, 1, 1)
Instance.new("UICorner", NameBtn)

-- FUN SAYFASI
local SpinBtn = Instance.new("TextButton", FunP)
SpinBtn.Size = UDim2.new(0.8,0,0,40); SpinBtn.Position = UDim2.new(0.1,0,0,20)
SpinBtn.Text = "SPINBOT: KAPALI"; SpinBtn.Font = "GothamBold"; SpinBtn.TextSize = 14; SpinBtn.BackgroundColor3 = Color3.fromRGB(35,35,35); SpinBtn.TextColor3 = Color3.new(1,0,0)
Instance.new("UICorner", SpinBtn)
makeSlider(FunP, "SPIN HIZI", 70, 50, 200, function(v) spinSpeed = v end)

local IYBtn = Instance.new("TextButton", FunP)
IYBtn.Size = UDim2.new(0.8,0,0,40); IYBtn.Position = UDim2.new(0.1,0,0,140)
IYBtn.Text = "INFINITE YIELD AÇ"; IYBtn.Font = "GothamBold"; IYBtn.TextSize = 14; IYBtn.BackgroundColor3 = Color3.fromRGB(130,30,130); IYBtn.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", IYBtn)

-- [[ SETTINGS SAYFASI ]]
label(SettingsP, "SİSTEM AYARLARI", 10, 16)

local KillBtn = Instance.new("TextButton", SettingsP)
KillBtn.Size = UDim2.new(0.8, 0, 0, 45)
KillBtn.Position = UDim2.new(0.1, 0, 0, 50)
KillBtn.Text = "STOP & KILL UI"
KillBtn.Font = "GothamBold"
KillBtn.TextSize = 16
KillBtn.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
KillBtn.TextColor3 = Color3.new(1, 1, 1)
Instance.new("UICorner", KillBtn)

KillBtn.MouseButton1Click:Connect(function()
    KillBtn.Text = "SHUTTING DOWN..."
    task.wait(0.5)
    totalShutdown() 
end)

label(SettingsP, "Kapatmak için Sağ Shift'i de kullanabilirsin.", 110, 11)
label(SettingsP, "Kapatmak için Sağ Shift'i de kullanabilirsin.", 110, 11)

-- [[ YENİ: TUŞ ATAMA (KEYBIND) SİSTEMİ ]]
local function createKeybindUI(parent, text, yPos, actionName)
    local btn = Instance.new("TextButton", parent)
    btn.Size = UDim2.new(0.8, 0, 0, 30)
    btn.Position = UDim2.new(0.1, 0, 0, yPos)
    btn.Text = text .. ": " .. Keybinds[actionName].Name
    btn.Font = "GothamBold"
    btn.TextSize = 14
    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    btn.TextColor3 = Color3.new(1, 1, 1)
    Instance.new("UICorner", btn)

    btn.MouseButton1Click:Connect(function()
        recordingAction = actionName
        recordingButton = btn
        btn.Text = text .. ": TUŞ BEKLENİYOR..."
        btn.TextColor3 = Color3.fromRGB(255, 255, 0) -- Bekleme anında sarı renk
    end)
    return btn
end

label(SettingsP, "TUŞ ATAMALARI", 140, 16)
createKeybindUI(SettingsP, "Aimbot Tuşu", 170, "Aimbot")
createKeybindUI(SettingsP, "Hız Tuşu", 205, "Speed")
createKeybindUI(SettingsP, "Zıplama Tuşu", 240, "Jump")
createKeybindUI(SettingsP, "ESP Tuşu", 275, "ESP")
createKeybindUI(SettingsP, "Freecam Tuşu", 310, "FreeCam")
-- [[ TEMA GÜNCELLEME FONKSİYONU ]]
local function UpdateThemeColor()
    themeColor = Color3.fromRGB(themeR, themeG, themeB)
    
    -- Kaydettiğimiz tüm arayüz parçalarının rengini değiştir
    for _, element in pairs(_G.ThemeElements) do
        if element:IsA("UIStroke") then
            element.Color = themeColor
        elseif element:IsA("TextLabel") or element:IsA("TextButton") then
            element.TextColor3 = themeColor
        elseif element:IsA("Frame") or element:IsA("ImageLabel") then
            element.BackgroundColor3 = themeColor
        end
    end
    
    -- FOV Dairesini de güncelle
    if _G.FOVCircle then _G.FOVCircle.Color = themeColor end
end

-- Settings UI oluşturulurken Listeyi Doldurma
table.insert(_G.ThemeElements, Stroke)
table.insert(_G.ThemeElements, Title)
table.insert(_G.ThemeElements, ResizeHandle)
table.insert(_G.ThemeElements, MinimizeBtn)

label(SettingsP, "TEMA RENGİ AYARI", 355, 16)

makeSlider(SettingsP, "TEMA (KIRMIZI)", 385, themeR, 255, function(v)
    themeR = v
    UpdateThemeColor()
    SaveConfig()
end)

makeSlider(SettingsP, "TEMA (YEŞİL)", 425, themeG, 255, function(v)
    themeG = v
    UpdateThemeColor()
    SaveConfig()
end)

makeSlider(SettingsP, "TEMA (MAVİ)", 465, themeB, 255, function(v)
    themeB = v
    UpdateThemeColor()
    SaveConfig()
end)

-- [[ YAPIMCI BİLGİSİ & DISCORD ]]
local CreditLabel = Instance.new("TextLabel", SettingsP)
CreditLabel.Size = UDim2.new(1, 0, 0, 20)
-- Y eksenini 520 yaparak slider'lardan sonraya hizalıyoruz
CreditLabel.Position = UDim2.new(0, 0, 0, 520) 
CreditLabel.BackgroundTransparency = 1
CreditLabel.Text = "by Yiwit"
CreditLabel.Font = "GothamBold"
CreditLabel.TextSize = 14
CreditLabel.TextColor3 = themeColor

local DiscordLabel = Instance.new("TextLabel", SettingsP)
DiscordLabel.Size = UDim2.new(1, 0, 0, 20)
DiscordLabel.Position = UDim2.new(0, 0, 0, 540)
DiscordLabel.BackgroundTransparency = 1
DiscordLabel.Text = "discord for help: yasliplanet._."
DiscordLabel.Font = "Gotham"
DiscordLabel.TextSize = 12
DiscordLabel.TextColor3 = themeColor

-- Temayı değiştirdiğinde bu yazıların da rengi otomatik değişsin
table.insert(_G.ThemeElements, CreditLabel)
table.insert(_G.ThemeElements, DiscordLabel)

-- [6] RENDER & SPINBOT & FREECAM LOGIC
table.insert(_G.ToprakCons, RS.RenderStepped:Connect(function()
    
    local currentEspColor
    if rainbowOn then 
        currentEspColor = Color3.fromHSV(tick() * 0.2 % 1, 0.8, 1) 
    else 
        currentEspColor = Color3.fromRGB(rV, gV, bV) 
    end
    
    if fullBrightOn then 
        Lighting.Ambient = Color3.new(1, 1, 1)
        Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.GlobalShadows = false 
    end
    
    if aimbotOn then
        FOVCircle.Visible = true
        FOVCircle.Position = Vector2.new(mouse.X, mouse.Y + 36)
        FOVCircle.Radius = fovRadius 
        FOVCircle.Color = themeColor 
    else
        FOVCircle.Visible = false
    end

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
        if v ~= player and char and hrp then
            local h = char:FindFirstChild("ToprakHighlight")
            if espOn then
                if not h then h = Instance.new("Highlight", char); h.Name = "ToprakHighlight" end
                h.FillColor = currentEspColor; h.OutlineColor = Color3.new(1,1,1); h.Enabled = true
            elseif h then h:Destroy() end
            
            local nl = _G.Names[v.Name]
            if espOn and namesOn then
                if not nl then 
                    nl = Drawing.new("Text") 
                    nl.Size = 10
                    nl.Center = true
                    nl.Outline = true
                    _G.Names[v.Name] = nl 
                end
                local pos, on = camera:WorldToViewportPoint(hrp.Position + Vector3.new(0, 3.5, 0))
                if on then 
                    nl.Position = Vector2.new(pos.X, pos.Y)
                    nl.Text = v.Name
                    nl.Color = currentEspColor
                    nl.Visible = true 
                else 
                    nl.Visible = false 
                end
            elseif nl then 
                nl.Visible = false 
            end
            
            local line = _G.Lines[v.Name]
            if tracerOn then
                if not line then line = Drawing.new("Line"); line.Thickness = 1.5; _G.Lines[v.Name] = line end
                if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    local sP, on1 = camera:WorldToViewportPoint(player.Character.HumanoidRootPart.Position)
                    local eP, on2 = camera:WorldToViewportPoint(hrp.Position)
                    if on1 and on2 then line.From = Vector2.new(sP.X, sP.Y); line.To = Vector2.new(eP.X, eP.Y); line.Color = currentEspColor; line.Visible = true else line.Visible = false end
                end
            elseif line then line.Visible = false end
        else
            if _G.Lines[v.Name] then _G.Lines[v.Name].Visible = false end
            if _G.Names[v.Name] then _G.Names[v.Name].Visible = false end
        end
    end

    if aimbotOn and aiming and not freeCamOn then
        local t, d = nil, fovRadius
        for _, v in pairs(Players:GetPlayers()) do
            if v ~= player and v.Character and v.Character:FindFirstChild("Head") and v.Character:FindFirstChild("Humanoid") and v.Character.Humanoid.Health > 0 then
                local pos, on = camera:WorldToViewportPoint(v.Character.Head.Position)
                if on then
                    local dist = (Vector2.new(pos.X, pos.Y) - Vector2.new(mouse.X, mouse.Y)).Magnitude
                    if dist < d then d = dist; t = v.Character.Head end
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
        Lighting.Ambient = oldAmbient
        Lighting.OutdoorAmbient = oldOutdoorAmbient
        Lighting.Brightness = oldBrightness
        Lighting.ClockTime = oldClockTime
        Lighting.GlobalShadows = oldGlobalShadows 
    end
end)

NameBtn.MouseButton1Click:Connect(function()
    namesOn = not namesOn
    NameBtn.Text = "NAMETAGS: " .. (namesOn and "AÇIK" or "KAPALI")
    NameBtn.TextColor3 = namesOn and Color3.new(0, 1, 0) or Color3.new(1, 1, 1)
end)

IYBtn.MouseButton1Click:Connect(function()
    loadstring(game:HttpGet('https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source'))()
end)

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
    
    if nearest then
        player.Character.HumanoidRootPart.CFrame = nearest.Character.HumanoidRootPart.CFrame * CFrame.new(0,0,-3)
    end
end)

table.insert(_G.ToprakCons, RS.Heartbeat:Connect(function()
    if speedOn and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        local hum = player.Character:FindFirstChildOfClass("Humanoid")
        local sVal = tonumber(SpeedIn.Text) or 5 
        if hum and hum.MoveDirection.Magnitude > 0 then
            player.Character.HumanoidRootPart.CFrame += hum.MoveDirection * (sVal/10)
        end
    end
end))

table.insert(_G.ToprakCons, UIS.InputChanged:Connect(function(input)
    if freeCamOn and input.UserInputType == Enum.UserInputType.MouseMovement then
        if UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
            UIS.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
            camRotX = math.clamp(camRotX - input.Delta.Y * 0.005, -math.rad(89), math.rad(89))
            camRotY = camRotY - input.Delta.X * 0.005
        else
            UIS.MouseBehavior = Enum.MouseBehavior.Default
        end
    end
end))

table.insert(_G.ToprakCons, UIS.InputBegan:Connect(function(i, g)
-- EĞER SİSTEM TUŞ KAYDEDİYORSA:
    if recordingAction and i.UserInputType == Enum.UserInputType.Keyboard then
        if i.KeyCode ~= Enum.KeyCode.Unknown and i.KeyCode ~= Enum.KeyCode.Escape then
            Keybinds[recordingAction] = i.KeyCode -- Yeni tuşu tabloya kaydet
            SaveConfig() -- YENİ: Değişikliği anında settings.json dosyasına kaydet
            
            -- Butonun metnini temizle ve yeni tuşu yaz
            local baseText = string.split(recordingButton.Text, ":")[1]
            recordingButton.Text = baseText .. ": " .. i.KeyCode.Name
            recordingButton.TextColor3 = Color3.new(1, 1, 1)
        else
            -- Escape basılırsa işlemi iptal et
            local baseText = string.split(recordingButton.Text, ":")[1]
            recordingButton.Text = baseText .. ": " .. Keybinds[recordingAction].Name
            recordingButton.TextColor3 = Color3.new(1, 1, 1)
        end
        recordingAction = nil
        recordingButton = nil
        return -- Kayıt yaparken aşağıdaki hilelerin çalışmasını engelle
    end

    -- KLASİK TUŞ KONTROLLERİ:
    if i.KeyCode == Enum.KeyCode.RightShift then totalShutdown() return end
    if i.KeyCode == Enum.KeyCode.RightControl then Main.Visible = not Main.Visible return end
    if g then return end 
    
    -- Sabit "Enum.KeyCode.Q" vb. yerine Keybinds tablosundan okuyoruz:
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
        espOn = not espOn; EspStatus.Text = "ESP: "..(espOn and "AÇIK" or "KAPALI")
        EspStatus.TextColor3 = espOn and Color3.new(0,1,0) or Color3.new(1,0,0) 
    elseif i.KeyCode == Keybinds.FreeCam then 
        freeCamOn = not freeCamOn
        FreeCamStatus.Text = "FREECAM: "..(freeCamOn and "AÇIK" or "KAPALI")
        FreeCamStatus.TextColor3 = freeCamOn and Color3.new(0,1,0) or Color3.new(1,1,1)
        if freeCamOn then
            local x, y, z = camera.CFrame:ToEulerAnglesYXZ()
            camRotX, camRotY = x, y
        else
            camera.CameraType = Enum.CameraType.Custom
            if player.Character and player.Character:FindFirstChild("Humanoid") then
                camera.CameraSubject = player.Character.Humanoid
            end
        end
    end
    
    if i.UserInputType == Enum.UserInputType.MouseButton2 then aiming = true end
end))

table.insert(_G.ToprakCons, UIS.InputEnded:Connect(function(i) 
    if i.UserInputType == Enum.UserInputType.MouseButton2 then aiming = false end 
end))

print("ToprakHUB Yüklendi! Kapanış İçin: Sağ Shift")
