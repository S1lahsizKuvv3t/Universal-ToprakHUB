-- [[ ToprakHUB V44.9 - INFINITE YIELD & COLOR SEPARATION ]]
-- [ GÜNCELLEME: ADMIN KOMUTLARI EKLENDİ, UI RENGİ SABİTLENDİ ]

local name = "ToprakHUB_V44_IY"

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
    for _, con in pairs(_G.ToprakCons) do pcall(function() con:Disconnect() end) end
    _G.ToprakCons = {}
    
    for _, v in pairs(game:GetService("CoreGui"):GetChildren()) do 
        if v.Name:find("ToprakHUB") then v:Destroy() end 
    end
    
    if _G.FOVCircle then pcall(function() _G.FOVCircle:Remove() end) _G.FOVCircle = nil end
    if _G.Lines then for _, l in pairs(_G.Lines) do pcall(function() l:Remove() end) end _G.Lines = {} end
    if _G.Names then for _, n in pairs(_G.Names) do pcall(function() n:Remove() end) end _G.Names = {} end
    
    -- Kamera ayarlarını sıfırla
    pcall(function()
        camera.CameraType = Enum.CameraType.Custom
        if player.Character and player.Character:FindFirstChild("Humanoid") then
            camera.CameraSubject = player.Character.Humanoid
        end
        UIS.MouseBehavior = Enum.MouseBehavior.Default
    end)
end
totalShutdown()

-- [2] DEĞİŞKENLER & RENK AYIRIMI
local speedOn, jumpOn, espOn, aimbotOn, silentAimOn, tracerOn, rainbowOn, fullBrightOn = false, false, false, false, false, false, false, false
local spinOn, spinSpeed = false, 50
local freeCamOn, freeCamSpeed = false, 2
local camRotX, camRotY = 0, 0

-- RENK AYIRIMI YAPILDI
local themeColor = Color3.fromRGB(255, 0, 0) -- UI İÇİN SABİT RENGİMİZ
local rV, gV, bV = 255, 0, 0 -- ESP İÇİN BAŞLANGIÇ RENGİ (Fark edilsin diye Kırmızı)
local fovRadius, aiming = 120, false

_G.Lines = _G.Lines or {}
_G.Names = _G.Names or {}

-- Işık Yedekleri
local oldBrightness = Lighting.Brightness
local oldClockTime = Lighting.ClockTime
local oldGlobalShadows = Lighting.GlobalShadows

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
FOVCircle.Color = themeColor -- FOV sabit kalsın
_G.FOVCircle = FOVCircle

-- [5] UI OLUŞTURMA
local ScreenGui = Instance.new("ScreenGui", game:GetService("CoreGui"))
ScreenGui.Name = name

local Main = Instance.new("Frame", ScreenGui)
Main.Size = UDim2.new(0, 520, 0, 420)
Main.Position = UDim2.new(0.5, -260, 0.5, -210)
Main.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
Main.Active = true
Main.Draggable = true
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)

local Stroke = Instance.new("UIStroke", Main)
Stroke.Thickness = 2
Stroke.Color = themeColor -- UI Çerçevesi Sabit Renk

local SideBar = Instance.new("Frame", Main)
SideBar.Size = UDim2.new(0, 150, 1, 0)
SideBar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
Instance.new("UICorner", SideBar)

local Title = Instance.new("TextLabel", SideBar)
Title.Size = UDim2.new(1, 0, 0, 60)
Title.Text = "Toprak V44.9"
Title.Font = "GothamBold"
Title.TextSize = 22
Title.BackgroundTransparency = 1
Title.TextColor3 = themeColor -- Başlık Sabit Renk

local Container = Instance.new("Frame", Main)
Container.Size = UDim2.new(1, -170, 1, -20)
Container.Position = UDim2.new(0, 160, 0, 10)
Container.BackgroundTransparency = 1

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
    
    local p = Instance.new("Frame", Container)
    p.Size = UDim2.new(1,0,1,0)
    p.BackgroundTransparency = 1
    p.Visible = (pos == 0)
    
    btn.MouseButton1Click:Connect(function() 
        for _, v in pairs(Pages) do v.Visible = false end 
        p.Visible = true 
    end)
    Pages[tname] = p
    return p
end

local AimP = createTab("AIMBOT", 0)
local MoveP = createTab("MOVEMENT", 1)
local TeleP = createTab("TELEPORT", 2)
local VisP = createTab("VISUALS", 3)
local FunP = createTab("FUN", 4)

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
    b.BackgroundColor3 = themeColor -- Slider butonu da sabit tema rengi olsun
    Instance.new("UICorner", b).CornerRadius = UDim.new(1,0)
    
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

-- [ ARAYÜZ İÇERİKLERİ ]

-- AIMBOT SAYFASI
local AimStatus = label(AimP, "AIMBOT: KAPALI [E]", 10, 16)
local SilentStatus = label(AimP, "SILENT AIM: KAPALI [R]", 40, 16)
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

local TargetBox = Instance.new("TextBox", TeleP)
TargetBox.Size = UDim2.new(0.8,0,0,30); TargetBox.Position = UDim2.new(0.1,0,0,35)
TargetBox.PlaceholderText = "Oyuncu ismi girin..."; TargetBox.BackgroundColor3 = Color3.fromRGB(30,30,30); TargetBox.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", TargetBox)

local TpBtn = Instance.new("TextButton", TeleP)
TpBtn.Size = UDim2.new(0.38,0,0,30); TpBtn.Position = UDim2.new(0.1,0,0,70)
TpBtn.Text = "İSME GİT"; TpBtn.Font = "GothamBold"; TpBtn.BackgroundColor3 = Color3.fromRGB(45,45,45); TpBtn.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", TpBtn)

local SpecBtn = Instance.new("TextButton", TeleP)
SpecBtn.Size = UDim2.new(0.38,0,0,30); SpecBtn.Position = UDim2.new(0.52,0,0,70)
SpecBtn.Text = "İZLE"; SpecBtn.Font = "GothamBold"; SpecBtn.BackgroundColor3 = Color3.fromRGB(45,45,45); SpecBtn.TextColor3 = Color3.new(1,1,1)
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

-- VISUALS SAYFASI (SLIDERLAR SADECE ESP'Yİ ETKİLER)
makeSlider(VisP, "ESP RENGİ (KIRMIZI)", 5, rV, 255, function(v) rV = v end)
makeSlider(VisP, "ESP RENGİ (YEŞİL)", 45, gV, 255, function(v) gV = v end)
makeSlider(VisP, "ESP RENGİ (MAVİ)", 85, bV, 255, function(v) bV = v end)

local RainBtn = Instance.new("TextButton", VisP)
RainBtn.Size = UDim2.new(0.8,0,0,30); RainBtn.Position = UDim2.new(0.1,0,0,135)
RainBtn.Text = "RAINBOW ESP: KAPALI"; RainBtn.Font = "GothamBold"; RainBtn.BackgroundColor3 = Color3.fromRGB(35,35,35)
Instance.new("UICorner", RainBtn)

local TraceBtn = Instance.new("TextButton", VisP)
TraceBtn.Size = UDim2.new(0.8,0,0,30); TraceBtn.Position = UDim2.new(0.1,0,0,170)
TraceBtn.Text = "ÇİZGİLER: KAPALI"; TraceBtn.Font = "GothamBold"; TraceBtn.BackgroundColor3 = Color3.fromRGB(35,35,35)
Instance.new("UICorner", TraceBtn)

local FBBtn = Instance.new("TextButton", VisP)
FBBtn.Size = UDim2.new(0.8,0,0,30); FBBtn.Position = UDim2.new(0.1,0,0,205)
FBBtn.Text = "FULLBRIGHT: KAPALI"; FBBtn.Font = "GothamBold"; FBBtn.BackgroundColor3 = Color3.fromRGB(35,35,35)
Instance.new("UICorner", FBBtn)

local EspStatus = label(VisP, "ESP (V): KAPALI", 245, 14)
EspStatus.TextColor3 = Color3.new(1,0,0)

-- FUN SAYFASI
local SpinBtn = Instance.new("TextButton", FunP)
SpinBtn.Size = UDim2.new(0.8,0,0,40); SpinBtn.Position = UDim2.new(0.1,0,0,20)
SpinBtn.Text = "SPINBOT: KAPALI"; SpinBtn.Font = "GothamBold"; SpinBtn.BackgroundColor3 = Color3.fromRGB(35,35,35); SpinBtn.TextColor3 = Color3.new(1,0,0)
Instance.new("UICorner", SpinBtn)
makeSlider(FunP, "SPIN HIZI", 70, 50, 200, function(v) spinSpeed = v end)

-- YENİ: INFINITE YIELD BUTONU
local IYBtn = Instance.new("TextButton", FunP)
IYBtn.Size = UDim2.new(0.8,0,0,40); IYBtn.Position = UDim2.new(0.1,0,0,140)
IYBtn.Text = "INFINITE YIELD AÇ"; IYBtn.Font = "GothamBold"; IYBtn.BackgroundColor3 = Color3.fromRGB(130,30,130); IYBtn.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", IYBtn)


-- [6] RENDER & SPINBOT & FREECAM LOGIC
table.insert(_G.ToprakCons, RS.RenderStepped:Connect(function()
    
    -- SADECE ESP İÇİN RENK HESAPLAMASI
    local currentEspColor
    if rainbowOn then 
        currentEspColor = Color3.fromHSV(tick() * 0.2 % 1, 0.8, 1) 
    else 
        currentEspColor = Color3.fromRGB(rV, gV, bV) 
    end
    
    -- Fullbright
    if fullBrightOn then Lighting.Brightness = 2; Lighting.ClockTime = 14; Lighting.GlobalShadows = false end
    
    -- FOV Dairesi (Rengi UI ile sabit kaldı)
    FOVCircle.Position = Vector2.new(mouse.X, mouse.Y + 36)
    FOVCircle.Radius = fovRadius
    FOVCircle.Visible = true

    -- FREECAM HAREKET MANTIĞI
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

    -- SPINBOT CORE
    if spinOn and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        player.Character.HumanoidRootPart.CFrame = player.Character.HumanoidRootPart.CFrame * CFrame.Angles(0, math.rad(spinSpeed), 0)
    end

    -- ESP & ÇİZGİLER (Artık currentEspColor kullanıyor)
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
            if espOn then
                if not nl then nl = Drawing.new("Text") nl.Size = 12; nl.Center = true; nl.Outline = true; _G.Names[v.Name] = nl end
                local pos, on = camera:WorldToViewportPoint(hrp.Position + Vector3.new(0, 3.5, 0))
                if on then nl.Position = Vector2.new(pos.X, pos.Y); nl.Text = v.Name; nl.Color = currentEspColor; nl.Visible = true else nl.Visible = false end
            elseif nl then nl.Visible = false end
            
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

    -- AIMBOT
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
IYBtn.MouseButton1Click:Connect(function()
    loadstring(game:HttpGet('https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source'))()
end)

SpinBtn.MouseButton1Click:Connect(function()
    spinOn = not spinOn
    SpinBtn.Text = "SPINBOT: "..(spinOn and "AÇIK" or "KAPALI")
    SpinBtn.TextColor3 = spinOn and Color3.new(0,1,0) or Color3.new(1,0,0)
end)

RainBtn.MouseButton1Click:Connect(function() 
    rainbowOn = not rainbowOn
    RainBtn.Text = "RAINBOW ESP: "..(rainbowOn and "AÇIK" or "KAPALI") 
end)

TraceBtn.MouseButton1Click:Connect(function() 
    tracerOn = not tracerOn
    TraceBtn.Text = "ÇİZGİLER: "..(tracerOn and "AÇIK" or "KAPALI") 
end)

FBBtn.MouseButton1Click:Connect(function() 
    fullBrightOn = not fullBrightOn; FBBtn.Text = "FULLBRIGHT: "..(fullBrightOn and "AÇIK" or "KAPALI")
    if not fullBrightOn then Lighting.Brightness = oldBrightness; Lighting.ClockTime = oldClockTime; Lighting.GlobalShadows = oldGlobalShadows end
end)

TpBtn.MouseButton1Click:Connect(function()
    if TargetBox.Text == "" then return end
    for _, v in pairs(Players:GetPlayers()) do
        if v ~= player and v.Name:lower():find(TargetBox.Text:lower()) and v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
            if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                player.Character.HumanoidRootPart.CFrame = v.Character.HumanoidRootPart.CFrame * CFrame.new(0,0,-3)
            end
        end
    end
end)

SpecBtn.MouseButton1Click:Connect(function()
    if TargetBox.Text == "" then return end
    for _, v in pairs(Players:GetPlayers()) do
        if v ~= player and v.Name:lower():find(TargetBox.Text:lower()) and v.Character and v.Character:FindFirstChild("Humanoid") then
            camera.CameraSubject = v.Character.Humanoid
        end
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

-- FREECAM MOUSE DÖNDÜRME MANTIĞI
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

-- [8] KEYS
table.insert(_G.ToprakCons, UIS.InputBegan:Connect(function(i, g)
    if i.KeyCode == Enum.KeyCode.RightShift then totalShutdown() return end
    if i.KeyCode == Enum.KeyCode.RightControl then Main.Visible = not Main.Visible return end
    if g then return end 
    
    if i.KeyCode == Enum.KeyCode.E then 
        aimbotOn = not aimbotOn; AimStatus.Text = "AIMBOT: "..(aimbotOn and "AKTİF" or "KAPALI")
        AimStatus.TextColor3 = aimbotOn and Color3.new(0,1,0) or Color3.new(1,0,0)
    elseif i.KeyCode == Enum.KeyCode.R then 
        silentAimOn = not silentAimOn; SilentStatus.Text = "SILENT AIM: "..(silentAimOn and "AKTİF" or "KAPALI")
        SilentStatus.TextColor3 = silentAimOn and Color3.new(0,1,0) or Color3.new(1,0,0)
    elseif i.KeyCode == Enum.KeyCode.Q then 
        speedOn = not speedOn; SpeedStatus.Text = "HIZ: "..(speedOn and "AÇIK" or "KAPALI")
        SpeedStatus.TextColor3 = speedOn and Color3.new(0,1,0) or Color3.new(1,0,0)
    elseif i.KeyCode == Enum.KeyCode.X then 
        jumpOn = not jumpOn; JumpStatus.Text = "ZIPLAMA: "..(jumpOn and "AÇIK" or "KAPALI")
        JumpStatus.TextColor3 = jumpOn and Color3.new(0,1,0) or Color3.new(1,0,0)
        local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.UseJumpPower = true; hum.JumpPower = jumpOn and (tonumber(JumpIn.Text) or 50) or 50 end
    elseif i.KeyCode == Enum.KeyCode.V then 
        espOn = not espOn; EspStatus.Text = "ESP (V): "..(espOn and "AÇIK" or "KAPALI")
        EspStatus.TextColor3 = espOn and Color3.new(0,1,0) or Color3.new(1,0,0) 
    elseif i.KeyCode == Enum.KeyCode.Backquote then 
        freeCamOn = not freeCamOn
        FreeCamStatus.Text = "FREECAM: "..(freeCamOn and "AÇIK [é]" or "KAPALI [é]")
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

print("ToprakHUB V44.9 IY Yüklendi! Kapanış İçin: Sağ Shift")
