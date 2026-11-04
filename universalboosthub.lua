--[[
    Boost Hub  |  built with WindUI (Footagesus)
    Tabs: Main, Player, ESP, Settings (empty for now)
]]

local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

-- Services -------------------------------------------------------------
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TeleportService  = game:GetService("TeleportService")
local VirtualUser      = game:GetService("VirtualUser")

local lp = Players.LocalPlayer

-- Helpers --------------------------------------------------------------
local function getChar() return lp.Character end
local function getHum()
    local c = getChar()
    return c and c:FindFirstChildOfClass("Humanoid")
end
local function getRoot()
    local c = getChar()
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function notify(title, content)
    WindUI:Notify({ Title = title, Content = content, Duration = 3 })
end

-- Connection manager
local conns = {}
local function unbind(name)
    if conns[name] then
        conns[name]:Disconnect()
        conns[name] = nil
    end
end
local function bind(name, signal, fn)
    unbind(name)
    conns[name] = signal:Connect(fn)
end

local function loadRemote(name, url)
    task.spawn(function()
        local ok, err = pcall(function()
            loadstring(game:HttpGet(url))()
        end)
        if ok then
            notify("Loader", name .. " loaded")
        else
            notify("Loader", name .. " failed: " .. tostring(err))
        end
    end)
end

-- Window ---------------------------------------------------------------
local Window = WindUI:CreateWindow({
    Title = "Boost Hub",
    Icon = "rocket",
    Author = "Boost Hub",
    Folder = "BoostHub",
    Size = UDim2.fromOffset(580, 460),
    Theme = "Dark",
})

pcall(function() Window:SetToggleKey(Enum.KeyCode.RightShift) end)

local MainTab     = Window:Tab({ Title = "Main",     Icon = "house" })
local PlayerTab   = Window:Tab({ Title = "Player",   Icon = "user" })
local ESPTab      = Window:Tab({ Title = "ESP",      Icon = "eye" })
local SettingsTab = Window:Tab({ Title = "Settings", Icon = "settings" }) -- intentionally empty

-- =====================================================================
-- MAIN
-- =====================================================================
MainTab:Section({ Title = "Script Loaders" })

MainTab:Button({
    Title = "Infinite Yield",
    Desc = "Popular admin command script",
    Callback = function()
        loadRemote("Infinite Yield", "https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source")
    end,
})

MainTab:Button({
    Title = "Dex Explorer",
    Desc = "Game explorer / instance viewer",
    Callback = function()
        loadRemote("Dex Explorer", "https://raw.githubusercontent.com/infyiff/backup/main/dex.lua")
    end,
})

MainTab:Button({
    Title = "SimpleSpy",
    Desc = "Remote event / function spy",
    Callback = function()
        loadRemote("SimpleSpy", "https://raw.githubusercontent.com/exxtremestuffs/SimpleSpySource/master/SimpleSpy.lua")
    end,
})

MainTab:Section({ Title = "Utility" })

MainTab:Button({
    Title = "Rejoin Server",
    Desc = "Rejoin the current server",
    Callback = function()
        if #Players:GetPlayers() <= 1 then
            lp:Kick("\nRejoining...")
            task.wait()
            TeleportService:Teleport(game.PlaceId, lp)
        else
            TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, lp)
        end
    end,
})

-- =====================================================================
-- PLAYER
-- =====================================================================
local DEFAULT_SPEED, DEFAULT_JUMP, DEFAULT_GRAVITY = 16, 50, workspace.Gravity

local state = {
    speedOn = false, speed = 50,
    jumpOn = false,  jump = 100,
    flyOn = false,   flySpeed = 60,
}

PlayerTab:Section({ Title = "Movement" })

-- WalkSpeed
PlayerTab:Slider({
    Title = "WalkSpeed",
    Step = 1,
    Value = { Min = 16, Max = 300, Default = 50 },
    Callback = function(v) state.speed = v end,
})
PlayerTab:Toggle({
    Title = "Enable WalkSpeed",
    Desc = "Keeps your custom speed applied",
    Value = false, Default = false,
    Callback = function(on)
        state.speedOn = on
        if not on then
            local h = getHum()
            if h then h.WalkSpeed = DEFAULT_SPEED end
        end
    end,
})

-- JumpPower
PlayerTab:Slider({
    Title = "JumpPower",
    Step = 1,
    Value = { Min = 50, Max = 400, Default = 100 },
    Callback = function(v) state.jump = v end,
})
PlayerTab:Toggle({
    Title = "Enable JumpPower",
    Value = false, Default = false,
    Callback = function(on)
        state.jumpOn = on
        if not on then
            local h = getHum()
            if h then h.JumpPower = DEFAULT_JUMP end
        end
    end,
})

-- Apply speed / jump every frame while enabled
RunService.Heartbeat:Connect(function()
    local h = getHum()
    if not h then return end
    if state.speedOn then h.WalkSpeed = state.speed end
    if state.jumpOn then
        h.UseJumpPower = true
        h.JumpPower = state.jump
    end
end)

-- Gravity
PlayerTab:Slider({
    Title = "Gravity",
    Step = 1,
    Value = { Min = 0, Max = 400, Default = math.floor(DEFAULT_GRAVITY) },
    Callback = function(v) workspace.Gravity = v end,
})

-- Infinite Jump
PlayerTab:Toggle({
    Title = "Infinite Jump",
    Value = false, Default = false,
    Callback = function(on)
        if on then
            bind("infjump", UserInputService.JumpRequest, function()
                local h = getHum()
                if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
            end)
        else
            unbind("infjump")
        end
    end,
})

-- Noclip
PlayerTab:Toggle({
    Title = "Noclip",
    Desc = "Walk through walls",
    Value = false, Default = false,
    Callback = function(on)
        if on then
            bind("noclip", RunService.Stepped, function()
                local c = getChar()
                if not c then return end
                for _, p in ipairs(c:GetDescendants()) do
                    if p:IsA("BasePart") and p.CanCollide then
                        p.CanCollide = false
                    end
                end
            end)
        else
            unbind("noclip")
        end
    end,
})

-- Fly --------------------------------------------------------------
PlayerTab:Section({ Title = "Fly" })

local flyBV, flyBG

local function stopFly()
    unbind("fly")
    if flyBV then flyBV:Destroy() flyBV = nil end
    if flyBG then flyBG:Destroy() flyBG = nil end
    local h = getHum()
    if h then h.PlatformStand = false end
end

local function startFly()
    bind("fly", RunService.RenderStepped, function()
        local root, hum, cam = getRoot(), getHum(), workspace.CurrentCamera
        if not (root and hum and cam) then return end

        if not flyBV or flyBV.Parent ~= root then
            if flyBV then flyBV:Destroy() end
            flyBV = Instance.new("BodyVelocity")
            flyBV.MaxForce = Vector3.new(1e9, 1e9, 1e9)
            flyBV.Velocity = Vector3.zero
            flyBV.Parent = root
        end
        if not flyBG or flyBG.Parent ~= root then
            if flyBG then flyBG:Destroy() end
            flyBG = Instance.new("BodyGyro")
            flyBG.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
            flyBG.P = 1e4
            flyBG.D = 100
            flyBG.Parent = root
        end

        hum.PlatformStand = true

        local look, right = cam.CFrame.LookVector, cam.CFrame.RightVector
        local flatLook = Vector3.new(look.X, 0, look.Z)
        local flatRight = Vector3.new(right.X, 0, right.Z)
        flatLook = flatLook.Magnitude > 1e-3 and flatLook.Unit or Vector3.new(0, 0, -1)
        flatRight = flatRight.Magnitude > 1e-3 and flatRight.Unit or Vector3.new(1, 0, 0)

        -- Works with keyboard, gamepad and mobile thumbstick
        local md = hum.MoveDirection
        local dir = look * md:Dot(flatLook) + right * md:Dot(flatRight)

        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.yAxis end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir -= Vector3.yAxis end

        flyBV.Velocity = dir * state.flySpeed
        flyBG.CFrame = cam.CFrame
    end)
end

PlayerTab:Slider({
    Title = "Fly Speed",
    Step = 1,
    Value = { Min = 10, Max = 300, Default = 60 },
    Callback = function(v) state.flySpeed = v end,
})
PlayerTab:Toggle({
    Title = "Fly",
    Desc = "WASD / joystick to move, Space up, Ctrl down. You also fly toward where the camera looks.",
    Value = false, Default = false,
    Callback = function(on)
        state.flyOn = on
        if on then startFly() else stopFly() end
    end,
})

-- Protection -------------------------------------------------------
PlayerTab:Section({ Title = "Protection" })

PlayerTab:Toggle({
    Title = "Anti AFK",
    Desc = "Prevents the 20 minute idle kick",
    Value = false, Default = false,
    Callback = function(on)
        if on then
            bind("antiafk", lp.Idled, function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
            end)
        else
            unbind("antiafk")
        end
    end,
})

PlayerTab:Toggle({
    Title = "Anti Fling",
    Desc = "Disables collisions with other players and cancels extreme velocity",
    Value = false, Default = false,
    Callback = function(on)
        if on then
            bind("antifling", RunService.Stepped, function()
                for _, plr in ipairs(Players:GetPlayers()) do
                    if plr ~= lp and plr.Character then
                        for _, p in ipairs(plr.Character:GetDescendants()) do
                            if p:IsA("BasePart") and p.CanCollide then
                                p.CanCollide = false
                            end
                        end
                    end
                end
                local root = getRoot()
                if root and not state.flyOn then
                    if root.AssemblyLinearVelocity.Magnitude > 150
                        or root.AssemblyAngularVelocity.Magnitude > 50 then
                        root.AssemblyLinearVelocity = Vector3.zero
                        root.AssemblyAngularVelocity = Vector3.zero
                    end
                end
            end)
        else
            unbind("antifling")
        end
    end,
})

-- Misc -------------------------------------------------------------
PlayerTab:Section({ Title = "Misc" })

PlayerTab:Toggle({
    Title = "Click Teleport",
    Desc = "Hold Left Ctrl and click to teleport",
    Value = false, Default = false,
    Callback = function(on)
        if on then
            bind("clicktp", UserInputService.InputBegan, function(input, processed)
                if processed then return end
                if input.UserInputType == Enum.UserInputType.MouseButton1
                    and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
                    local root = getRoot()
                    local hit = lp:GetMouse().Hit
                    if root and hit then
                        root.CFrame = CFrame.new(hit.Position + Vector3.new(0, 3, 0))
                    end
                end
            end)
        else
            unbind("clicktp")
        end
    end,
})

PlayerTab:Button({
    Title = "Reset Character",
    Callback = function()
        local h = getHum()
        if h then h.Health = 0 end
    end,
})

PlayerTab:Button({
    Title = "Reset All Movement",
    Desc = "Restores default speed, jump and gravity",
    Callback = function()
        local h = getHum()
        if h then
            h.WalkSpeed = DEFAULT_SPEED
            h.JumpPower = DEFAULT_JUMP
        end
        workspace.Gravity = DEFAULT_GRAVITY
        notify("Player", "Movement reset to defaults")
    end,
})

-- =====================================================================
-- ESP
-- =====================================================================
local espFolder = Instance.new("Folder")
espFolder.Name = "BoostHubESP"
local okParent = pcall(function()
    espFolder.Parent = (gethui and gethui()) or game:GetService("CoreGui")
end)
if not okParent then
    espFolder.Parent = lp:WaitForChild("PlayerGui")
end

-- Generic ESP controller: collect() returns { [Model] = displayName }
local function newESP(color, interval, collect)
    local self = { entries = {}, conn = nil, last = 0 }

    local function remove(model)
        local e = self.entries[model]
        if e then
            e.hl:Destroy()
            e.gui:Destroy()
            self.entries[model] = nil
        end
    end

    local function add(model, name)
        local part = model:FindFirstChild("Head")
            or model.PrimaryPart
            or model:FindFirstChildWhichIsA("BasePart")
        if not part then return end

        local hl = Instance.new("Highlight")
        hl.Adornee = model
        hl.FillColor = color
        hl.OutlineColor = Color3.new(1, 1, 1)
        hl.FillTransparency = 0.6
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Parent = espFolder

        local gui = Instance.new("BillboardGui")
        gui.Adornee = part
        gui.Size = UDim2.fromOffset(200, 30)
        gui.StudsOffset = Vector3.new(0, 2.5, 0)
        gui.AlwaysOnTop = true
        gui.Parent = espFolder

        local label = Instance.new("TextLabel")
        label.BackgroundTransparency = 1
        label.Size = UDim2.fromScale(1, 1)
        label.TextColor3 = color
        label.TextStrokeTransparency = 0.3
        label.TextScaled = false
        label.TextSize = 14
        label.Font = Enum.Font.GothamBold
        label.Parent = gui

        self.entries[model] = { hl = hl, gui = gui, label = label, name = name, part = part }
    end

    function self.Start()
        if self.conn then return end
        self.conn = RunService.RenderStepped:Connect(function()
            local now = os.clock()
            if now - self.last >= interval then
                self.last = now
                local targets = collect()
                for model in pairs(self.entries) do
                    if not targets[model] or not model.Parent then remove(model) end
                end
                for model, name in pairs(targets) do
                    if not self.entries[model] then add(model, name) end
                end
            end

            local root = getRoot()
            for model, e in pairs(self.entries) do
                local hum = model:FindFirstChildOfClass("Humanoid")
                local dist = root and math.floor((e.part.Position - root.Position).Magnitude) or 0
                local hp = hum and string.format(" | %d HP", math.floor(hum.Health)) or ""
                e.label.Text = string.format("%s [%dm]%s", e.name, dist, hp)
            end
        end)
    end

    function self.Stop()
        if self.conn then
            self.conn:Disconnect()
            self.conn = nil
        end
        for model in pairs(self.entries) do remove(model) end
    end

    return self
end

local playerESP = newESP(Color3.fromRGB(255, 70, 70), 0.25, function()
    local t = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= lp and plr.Character then
            t[plr.Character] = plr.DisplayName
        end
    end
    return t
end)

local npcESP = newESP(Color3.fromRGB(255, 200, 60), 2, function()
    local t = {}
    for _, d in ipairs(workspace:GetDescendants()) do
        if d:IsA("Humanoid") and d.Health > 0 then
            local m = d.Parent
            if m and m:IsA("Model") and m ~= lp.Character
                and not Players:GetPlayerFromCharacter(m) then
                t[m] = m.Name
            end
        end
    end
    return t
end)

ESPTab:Toggle({
    Title = "ESP Player",
    Desc = "Highlight, name, distance and health of other players",
    Value = false, Default = false,
    Callback = function(on)
        if on then playerESP.Start() else playerESP.Stop() end
    end,
})

ESPTab:Toggle({
    Title = "ESP NPC",
    Desc = "Highlight every non-player humanoid (rescans every 2s)",
    Value = false, Default = false,
    Callback = function(on)
        if on then npcESP.Start() else npcESP.Stop() end
    end,
})

-- =====================================================================
-- SETTINGS: intentionally empty (SettingsTab), to be filled later
-- =====================================================================

Window:SelectTab(1)
notify("Boost Hub", "Loaded. Press RightShift to toggle the window.")
