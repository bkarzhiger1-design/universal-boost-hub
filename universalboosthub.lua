--[[
Boost Hub  |  built with WindUI (Footagesus)
Tabs: Main, Player, Aim, Emotes, ESP, Settings
]]
​-- Load WindUI with fallback mirrors
local WINDUI_URLS = {
"https://github.com/Footagesus/WindUI/releases/latest/download/main.lua",
"https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua",
"https://cdn.jsdelivr.net/gh/Footagesus/WindUI@main/dist/main.lua",
}
​local WindUI
for _, url in ipairs(WINDUI_URLS) do
local ok, lib = pcall(function()
return loadstring(game:HttpGet(url))()
end)
if ok and lib then
WindUI = lib
break
end
end
​if not WindUI then
warn("[Boost Hub] Could not load WindUI library.")
return
end
​-- Services
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TeleportService  = game:GetService("TeleportService")
local VirtualUser      = game:GetService("VirtualUser")
local HttpService      = game:GetService("HttpService")
local Lighting         = game:GetService("Lighting")
​local lp = Players.LocalPlayer
​-- Helper Functions
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
WindUI:Notify({ Title = tostring(title), Content = tostring(content), Duration = 3 })
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
if signal then
conns[name] = signal:Connect(fn)
end
end
​-- Window Creation
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
local ESPTab      = Window:Tab({ Title = "ESP",      Icon = "eye" })
local AimTab      = Window:Tab({ Title = "Aim",      Icon = "crosshair" })
local EmotesTab   = Window:Tab({ Title = "Emotes",   Icon = "smile" })
local SettingsTab = Window:Tab({ Title = "Settings", Icon = "settings" })
​-- =====================================================================
-- MAIN TAB
-- =====================================================================
MainTab:Section({ Title = "Script Loaders" })
​local function loadRemote(name, url)
task.spawn(function()
local ok, err = pcall(function()
local code = game:HttpGet(url)
local fn = loadstring(code)
if type(fn) == "function" then fn() end
end)
if ok then
notify("Loader", name .. " loaded")
else
notify("Loader", name .. " failed: " .. tostring(err))
end
end)
end
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
-- PLAYER TAB
-- =====================================================================
local DEFAULT_SPEED, DEFAULT_JUMP, DEFAULT_GRAVITY = 16, 50, workspace.Gravity
local state = { speedOn = false, speed = 50, jumpOn = false, jump = 100, flyOn = false, flySpeed = 60 }
​PlayerTab:Section({ Title = "Movement" })
PlayerTab:Slider({
Title = "WalkSpeed",
Step = 1,
Value = { Min = 16, Max = 300, Default = 50 },
Callback = function(v) if type(v) == "number" then state.speed = v end end,
})
PlayerTab:Toggle({
Title = "Enable WalkSpeed",
Value = false,
Callback = function(on)
state.speedOn = not not on
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
Callback = function(v) if type(v) == "number" then state.jump = v end end,
})
PlayerTab:Toggle({
Title = "Enable JumpPower",
Value = false,
Callback = function(on)
state.jumpOn = not not on
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
​-- =====================================================================
-- AIM TAB
-- =====================================================================
AimTab:Section({ Title = "Target Lock & Shiftlock" })
​local aimTargetPlayer = nil
local aimLockEnabled = false
​local function getPlayerNames()
local names = {}
for _, p in ipairs(Players:GetPlayers()) do
if p ~= lp then
table.insert(names, p.Name)
end
end
if #names == 0 then table.insert(names, "None") end
return names
end
​AimTab:Dropdown({
Title = "Select Target Player",
Values = getPlayerNames(),
Value = "None",
Callback = function(selected)
local str = type(selected) == "table" and selected[1] or selected
if type(str) == "string" then
aimTargetPlayer = Players:FindFirstChild(str)
end
end,
})
​AimTab:Toggle({
Title = "Enable Aim Lock & Shiftlock",
Value = false,
Callback = function(on)
aimLockEnabled = not not on
if aimLockEnabled then
bind("aimlock", RunService.RenderStepped, function()
if aimLockEnabled and aimTargetPlayer and aimTargetPlayer.Character then
local targetHead = aimTargetPlayer.Character:FindFirstChild("Head") or aimTargetPlayer.Character:FindFirstChild("HumanoidRootPart")
local cam = workspace.CurrentCamera
if targetHead and cam then
lp.DevEnableMouseLock = true
cam.CFrame = CFrame.new(cam.CFrame.Position, targetHead.Position)
end
end
end)
else
unbind("aimlock")
end
end,
})
​-- =====================================================================
-- EMOTES TAB (70 Emotes across 10 Player Slots)
-- =====================================================================
EmotesTab:Section({ Title = "Emotes Configuration" })
​local emoteList = {
"Floating Aura", "Monkey", "Curtsy", "Godlike", "Helicopter", "Happy", "TWICE The Feels",
"Baby Queen - Bouncy Twirl", "Rat Dance", "Plane", "Sleep", "Tank", "Hero Landing", "Shy",
"Car", "Floss Dance", "Sit", "Quiet Waves", "Fake MM2 Death", "Yungblud Happier Jump",
"Baby Dance", "Baby Queen - Face Frame", "Box", "Top Rock", "Hide", "Baby Queen - Strut",
"Bored", "KATSEYE - Touch", "Dog", "L Dance", "Ragdoll Push", "Take The L", "Fry Dance",
"Twirl", "Fashionable", "Line Dance", "Cower", "High Wave", "Worm", "TWICE Feel Special",
"V Pose", "Lotus Position", "Frosty Flair", "Effortless Aura Pose", "HOT TO GO!", "Dolphin Dance",
"Old Town Road Dance", "Phase", "Sturdy Dance", "Piano Hands", "Around Town", "Head Bop",
"Celebrate", "SHAKE", "Show Dem Wrists", "Side to Side", "Dorky Dance", "Cute Levitating",
"TWICE LIKEY", "Chill Bounce", "Telekinesis Head Floating Aura", "Hornet's Spider Dance",
"Spiderman Hang", "Shuffle", "Fancy Feet", "Dizzy", "TWICE What Is Love", "Jamal Brazil Groove",
"HOLIDAY Dance", "Hip Sway"
}
​local emoteIds = {
["Floating Aura"] = 79795305221612,
["Monkey"] = 3716636630,
["Curtsy"] = 4646306583,
["Godlike"] = 3823158750,
["Helicopter"] = 110553756436163,
["Happy"] = 4849499887,
["TWICE The Feels"] = 12874468267,
["Baby Queen - Bouncy Twirl"] = 14353423348,
["Rat Dance"] = 83606297144428,
["Plane"] = 134913783169182,
["Sleep"] = 4689362868,
["Tank"] = 85076031433488,
["Hero Landing"] = 5104377791,
["Shy"] = 3576717965,
["Car"] = 115407270129592,
["Floss Dance"] = 5917570207,
["Sit"] = 129668542320076,
["Quiet Waves"] = 7466046574,
["Fake MM2 Death"] = 107498554725527,
["Yungblud Happier Jump"] = 15610015346,
["Baby Dance"] = 4272484885,
["Baby Queen - Face Frame"] = 14353421343,
["Box"] = 73500261613116,
["Top Rock"] = 3570535774,
["Hide"] = 84868707350198,
["Baby Queen - Strut"] = 14353425085,
["Bored"] = 5230661597,
["KATSEYE - Touch"] = 139021427684680,
["Dog"] = 84198855496510,
["L Dance"] = 73039500693145,
["Ragdoll Push"] = 91452077708399,
["Take The L"] = 75633408126191,
["Fry Dance"] = 124799741487022,
["Twirl"] = 3716633898,
["Fashionable"] = 3576745472,
["Line Dance"] = 4049646104,
["Cower"] = 4940597758,
["High Wave"] = 5915776835,
["Worm"] = 108956933782219,
["TWICE Feel Special"] = 14900153406,
["V Pose"] = 10214418283,
["Lotus Position"] = 12507097350,
["Frosty Flair"] = 10214406616,
["Effortless Aura Pose"] = 101573394483995,
["HOT TO GO!"] = 79312439851071,
["Dolphin Dance"] = 5938365243,
["Old Town Road Dance"] = 5938394742,
["Phase"] = 79653736088166,
["Sturdy Dance"] = 17746270218,
["Piano Hands"] = 16553249658,
["Around Town"] = 3576747102,
["Head Bop"] = 15554010118,
["Celebrate"] = 3994127840,
["SHAKE"] = 132367660388476,
["Show Dem Wrists"] = 7202898984,
["Side to Side"] = 3762641826,
["Dorky Dance"] = 4212499637,
["Cute Levitating"] = 101601077005248,
["TWICE LIKEY"] = 14900151704,
["Chill Bounce"] = 132112297758791,
["Telekinesis Head Floating Aura"] = 81666519067619,
["Hornet's Spider Dance"] = 74716792202343,
["Spiderman Hang"] = 108635834286627,
["Shuffle"] = 4391208058,
["Fancy Feet"] = 3934988903,
["Dizzy"] = 3934986896,
["TWICE What Is Love"] = 13344121112,
["Jamal Brazil Groove"] = 104131847054135,
["HOLIDAY Dance"] = 5938396308,
["Hip Sway"] = 80963950541052
}
​local selectedEmotes = {}
​for slot = 1, 10 do
selectedEmotes[slot] = emoteList[1]
​pcall(function()
EmotesTab:Dropdown({
Title = "Emotes Player " .. slot,
Values = emoteList,
Value = emoteList[1],
Callback = function(v)
local val = type(v) == "table" and v[1] or v
if type(val) == "string" then
selectedEmotes[slot] = val
end
end,
})
end)
​pcall(function()
EmotesTab:Button({
Title = "Play Emote Player " .. slot,
Callback = function()
local chosenName = selectedEmotes[slot]
local assetId = emoteIds[chosenName]
if not assetId then return end
​pcall(function()
local hum = getHum()
if hum then
local animator = hum:FindFirstChildOfClass("Animator") or Instance.new("Animator", hum)
local anim = Instance.new("Animation")
anim.AnimationId = "rbxassetid://" .. tostring(assetId)
local track = animator:LoadAnimation(anim)
if track then track:Play() end
end
end)
end,
})
end)
end
​-- =====================================================================
-- ESP TAB
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
-- SETTINGS TAB
-- =====================================================================
SettingsTab:Section({ Title = "Community" })
SettingsTab:Button({
Title = "Join Discord Server",
Callback = function()
if setclipboard then pcall(setclipboard, "https://discord.gg/fdNcwysDg") end
notify("Discord", "Link copied to clipboard!")
end,
})
​Window:SelectTab(1)
notify("Boost Hub", "Loaded successfully!")
