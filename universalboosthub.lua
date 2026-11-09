--[[
Boost Hub  |  built with WindUI (Footagesus)
Tabs: Main, Player, Aim, ESP, Settings
]]
​-- Load WindUI safely with fallback endpoints
local WINDUI_URLS = {
"https://github.com/Footagesus/WindUI/releases/latest/download/main.lua",
"https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua",
"https://cdn.jsdelivr.net/gh/Footagesus/WindUI@main/dist/main.lua",
}
​local WindUI
for attempt = 1, 3 do
for _, url in ipairs(WINDUI_URLS) do
local ok, lib = pcall(function()
return loadstring(game:HttpGet(url))()
end)
if ok and type(lib) == "table" then
WindUI = lib
break
end
end
if WindUI then break end
task.wait(1)
end
​if not WindUI then
warn("[Boost Hub] Could not load WindUI.")
return
end
​-- Services -------------------------------------------------------------
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TeleportService  = game:GetService("TeleportService")
local VirtualUser      = game:GetService("VirtualUser")
local Lighting         = game:GetService("Lighting")
​local lp = Players.LocalPlayer
​-- Helpers --------------------------------------------------------------
local function getChar() return lp and lp.Character end
local function getHum()
local c = getChar()
return c and c:FindFirstChildOfClass("Humanoid")
end
local function getRoot()
local c = getChar()
return c and c:FindFirstChild("HumanoidRootPart")
end
​local function notify(title, content)
pcall(function()
WindUI:Notify({ Title = title, Content = content, Duration = 3 })
end)
end
​local conns = {}
local function unbind(name)
if conns[name] then
pcall(function() conns[name]:Disconnect() end)
conns[name] = nil
end
end
local function bind(name, signal, fn)
unbind(name)
if signal then conns[name] = signal:Connect(fn) end
end
​local function loadRemote(name, url)
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
​-- Window ---------------------------------------------------------------
local Window = WindUI:CreateWindow({
Title = "Boost Hub",
Icon = "rocket",
Author = "Boost Hub",
Folder = "BoostHub",
Size = UDim2.fromOffset(580, 460),
Theme = "Dark",
})
​pcall(function() Window:SetToggleKey(Enum.KeyCode.RightShift) end)
​local MainTab     = Window:Tab({ Title = "Main",     Icon = "house" })
local PlayerTab   = Window:Tab({ Title = "Player",   Icon = "user" })
local AimTab      = Window:Tab({ Title = "Aim",      Icon = "crosshair" })
local ESPTab      = Window:Tab({ Title = "ESP",      Icon = "eye" })
local SettingsTab = Window:Tab({ Title = "Settings", Icon = "settings" })
​-- =====================================================================
-- MAIN
-- =====================================================================
MainTab:Section({ Title = "Script Loaders" })
​MainTab:Button({
Title = "Infinite Yield",
Callback = function() loadRemote("Infinite Yield", "https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source") end,
})
MainTab:Button({
Title = "Dex Explorer",
Callback = function() loadRemote("Dex Explorer", "https://raw.githubusercontent.com/infyiff/backup/main/dex.lua") end,
})
MainTab:Button({
Title = "SimpleSpy",
Callback = function() loadRemote("SimpleSpy", "https://raw.githubusercontent.com/exxtremestuffs/SimpleSpySource/master/SimpleSpy.lua") end,
})
MainTab:Button({
Title = "CMD-X",
Callback = function() loadRemote("CMD-X", "https://raw.githubusercontent.com/CMD-X/CMD-X/master/Source") end,
})
​MainTab:Section({ Title = "Utility" })
MainTab:Button({
Title = "Rejoin Server",
Callback = function()
if #Players:GetPlayers() <= 1 then
pcall(function() lp:Kick("\nRejoining...") end)
task.wait()
TeleportService:Teleport(game.PlaceId, lp)
else
TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, lp)
end
end,
})
​-- =====================================================================
-- PLAYER
-- =====================================================================
local DEFAULT_SPEED, DEFAULT_JUMP, DEFAULT_GRAVITY = 16, 50, workspace.Gravity
local state = { speedOn = false, speed = 50, jumpOn = false, jump = 100, flyOn = false, flySpeed = 60 }
​PlayerTab:Section({ Title = "Movement" })
​PlayerTab:Slider({
Title = "WalkSpeed",
Step = 1,
Value = { Min = 16, Max = 300, Default = 50 },
Callback = function(v) state.speed = v end,
})
PlayerTab:Toggle({
Title = "Enable WalkSpeed",
Value = false,
Callback = function(on)
state.speedOn = on
if not on then
local h = getHum()
if h then h.WalkSpeed = DEFAULT_SPEED end
end
end,
})
​PlayerTab:Slider({
Title = "JumpPower",
Step = 1,
Value = { Min = 50, Max = 400, Default = 100 },
Callback = function(v) state.jump = v end,
})
PlayerTab:Toggle({
Title = "Enable JumpPower",
Value = false,
Callback = function(on)
state.jumpOn = on
if not on then
local h = getHum()
if h then h.JumpPower = DEFAULT_JUMP end
end
end,
})
​RunService.Heartbeat:Connect(function()
local h = getHum()
if not h then return end
if state.speedOn then h.WalkSpeed = state.speed end
if state.jumpOn then
h.UseJumpPower = true
h.JumpPower = state.jump
end
end)
​PlayerTab:Toggle({
Title = "Infinite Jump",
Value = false,
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
​PlayerTab:Toggle({
Title = "Noclip",
Value = false,
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
​PlayerTab:Section({ Title = "Fly" })
local flyBV, flyBG
​local function stopFly()
unbind("fly")
if flyBV then flyBV:Destroy() flyBV = nil end
if flyBG then flyBG:Destroy() flyBG = nil end
local h = getHum()
if h then h.PlatformStand = false end
end
​local function startFly()
bind("fly", RunService.RenderStepped, function()
local root, hum, cam = getRoot(), getHum(), workspace.CurrentCamera
if not (root and hum and cam) then return end
​if not flyBV or flyBV.Parent ~= root then
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
​hum.PlatformStand = true
​local look, right = cam.CFrame.LookVector, cam.CFrame.RightVector
local flatLook = Vector3.new(look.X, 0, look.Z)
local flatRight = Vector3.new(right.X, 0, right.Z)
flatLook = flatLook.Magnitude > 1e-3 and flatLook.Unit or Vector3.new(0, 0, -1)
flatRight = flatRight.Magnitude > 1e-3 and flatRight.Unit or Vector3.new(1, 0, 0)
​local md = hum.MoveDirection
local dir = look * md:Dot(flatLook) + right * md:Dot(flatRight)
​if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.yAxis end
if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir - Vector3.yAxis end
​flyBV.Velocity = dir * state.flySpeed
flyBG.CFrame = cam.CFrame
end)
end
​PlayerTab:Slider({
Title = "Fly Speed",
Step = 1,
Value = { Min = 10, Max = 300, Default = 60 },
Callback = function(v) state.flySpeed = v end,
})
PlayerTab:Toggle({
Title = "Fly",
Value = false,
Callback = function(on)
state.flyOn = on
if on then startFly() else stopFly() end
end,
})
​PlayerTab:Section({ Title = "Protection" })
PlayerTab:Toggle({
Title = "Anti AFK",
Value = false,
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
​PlayerTab:Toggle({
Title = "God Mode",
Value = false,
Callback = function(on)
if on then
bind("god", RunService.Heartbeat, function()
local h = getHum()
if h and h.Health > 0 and h.Health < h.MaxHealth then
h.Health = h.MaxHealth
end
end)
else
unbind("god")
end
end,
})
​-- =====================================================================
-- AIM TAB
-- =====================================================================
AimTab:Section({ Title = "Target Aim & Camera Lock" })
​local selectedAimTarget = nil
local aimEnabled = false
​local function getPlayerNames()
local names = {}
for _, p in ipairs(Players:GetPlayers()) do
if p ~= lp then table.insert(names, p.Name) end
end
if #names == 0 then table.insert(names, "None") end
return names
end
​AimTab:Dropdown({
Title = "Select Target Player",
Values = getPlayerNames(),
Value = "None",
Callback = function(v)
if type(v) == "table" then
selectedAimTarget = v[1]
else
selectedAimTarget = v
end
end,
})
​AimTab:Toggle({
Title = "Enable Aim Lock",
Value = false,
Callback = function(on)
aimEnabled = on
if on then
bind("aimlock", RunService.RenderStepped, function()
if not aimEnabled or not selectedAimTarget then return end
local targetPlayer = Players:FindFirstChild(tostring(selectedAimTarget))
if targetPlayer and targetPlayer.Character then
local targetRoot = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
local myRoot = getRoot()
local cam = workspace.CurrentCamera
if targetRoot and myRoot and cam then
local targetPos = targetRoot.Position + Vector3.new(0, 2, 0)
cam.CFrame = CFrame.lookAt(cam.CFrame.Position, targetPos)
myRoot.CFrame = CFrame.new(myRoot.Position, Vector3.new(targetRoot.Position.X, myRoot.Position.Y, targetRoot.Position.Z))
end
end
end)
else
unbind("aimlock")
end
end,
})
​-- =====================================================================
-- ESP
-- =====================================================================
local espFolder = Instance.new("Folder")
espFolder.Name = "BoostHubESP"
pcall(function()
espFolder.Parent = (gethui and gethui()) or game:GetService("CoreGui")
end)
​local function newESP(color, interval, collect)
local self = { entries = {}, conn = nil, last = 0 }
​local function remove(model)
local e = self.entries[model]
if e then
pcall(function() e.hl:Destroy() end)
pcall(function() e.gui:Destroy() end)
self.entries[model] = nil
end
end
​local function add(model, name)
local part = model:FindFirstChild("Head") or model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
if not part then return end
​local hl = Instance.new("Highlight")
hl.Adornee = model
hl.FillColor = color
hl.OutlineColor = Color3.new(1, 1, 1)
hl.FillTransparency = 0.6
hl.Parent = espFolder
​local gui = Instance.new("BillboardGui")
gui.Adornee = part
gui.Size = UDim2.fromOffset(200, 30)
gui.StudsOffset = Vector3.new(0, 2.5, 0)
gui.AlwaysOnTop = true
gui.Parent = espFolder
​local label = Instance.new("TextLabel")
label.BackgroundTransparency = 1
label.Size = UDim2.fromScale(1, 1)
label.TextColor3 = color
label.TextSize = 14
label.Font = Enum.Font.GothamBold
label.Parent = gui
​self.entries[model] = { hl = hl, gui = gui, label = label, name = name, part = part }
end
​function self.Start()
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
​local root = getRoot()
for model, e in pairs(self.entries) do
local hum = model:FindFirstChildOfClass("Humanoid")
local dist = root and math.floor((e.part.Position - root.Position).Magnitude) or 0
local hp = hum and string.format(" | %d HP", math.floor(hum.Health)) or ""
e.label.Text = string.format("%s [%dm]%s", e.name, dist, hp)
end
end)
end
​function self.Stop()
if self.conn then
self.conn:Disconnect()
self.conn = nil
end
for model in pairs(self.entries) do remove(model) end
end
​return self
end
​local playerESP = newESP(Color3.fromRGB(255, 70, 70), 0.25, function()
local t = {}
for _, plr in ipairs(Players:GetPlayers()) do
if plr ~= lp and plr.Character then
t[plr.Character] = plr.DisplayName
end
end
return t
end)
​ESPTab:Toggle({
Title = "ESP Player",
Value = false,
Callback = function(on)
if on then playerESP.Start() else playerESP.Stop() end
end,
})
​-- =====================================================================
-- SETTINGS
-- =====================================================================
SettingsTab:Section({ Title = "Community" })
SettingsTab:Button({
Title = "Join Discord Server",
Callback = function()
if setclipboard then pcall(setclipboard, "https://discord.gg/fdNcwysDg") end
notify("Discord", "Discord invite link copied to clipboard!")
end,
})
​Window:SelectTab(1)
notify("Boost Hub", "Loaded successfully!")
