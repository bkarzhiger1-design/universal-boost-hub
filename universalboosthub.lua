--[[
Boost Hub  |  built with WindUI (Footagesus)
Tabs: Main, Player, ESP, Aim, Emotes, Settings
]]
​-- Load WindUI with retries and fallback mirrors
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
if ok and lib then
WindUI = lib
break
end
end
if WindUI then break end
task.wait(2)
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
local HttpService      = game:GetService("HttpService")
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
​local function loadRemote(name, url)
task.spawn(function()
local ok, err = pcall(function()
local code = game:HttpGet(url)
local fn = loadstring(code)
if type(fn) == "function" then
fn()
end
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
local ESPTab      = Window:Tab({ Title = "ESP",      Icon = "eye" })
local AimTab      = Window:Tab({ Title = "Aim",      Icon = "crosshair" })
local EmotesTab   = Window:Tab({ Title = "Emotes",   Icon = "smile" })
local SettingsTab = Window:Tab({ Title = "Settings", Icon = "settings" })
​-- =====================================================================
-- MAIN
-- =====================================================================
MainTab:Section({ Title = "Script Loaders" })
​MainTab:Button({
Title = "Infinite Yield",
Desc = "Popular admin command script",
Callback = function()
loadRemote("Infinite Yield", "https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source")
end,
})
​MainTab:Button({
Title = "Dex Explorer",
Desc = "Game explorer / instance viewer",
Callback = function()
loadRemote("Dex Explorer", "https://raw.githubusercontent.com/infyiff/backup/main/dex.lua")
end,
})
​MainTab:Button({
Title = "SimpleSpy",
Desc = "Remote event / function spy",
Callback = function()
loadRemote("SimpleSpy", "https://raw.githubusercontent.com/exxtremestuffs/SimpleSpySource/master/SimpleSpy.lua")
end,
})
​MainTab:Button({
Title = "CMD-X",
Desc = "Command-line style admin script",
Callback = function()
loadRemote("CMD-X", "https://raw.githubusercontent.com/CMD-X/CMD-X/master/Source")
end,
})
​MainTab:Button({
Title = "Fates Admin",
Desc = "Feature-rich admin commands",
Callback = function()
loadRemote("Fates Admin", "https://raw.githubusercontent.com/fatesc/fates-admin/main/main.lua")
end,
})
​MainTab:Button({
Title = "Nameless Admin",
Desc = "Lightweight admin commands",
Callback = function()
loadRemote("Nameless Admin", "https://raw.githubusercontent.com/FilteringEnabled/NamelessAdmin/main/Source")
end,
})
​MainTab:Section({ Title = "Utility" })
​MainTab:Button({
Title = "Rejoin Server",
Desc = "Rejoin the current server",
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
​local function smallServerHop()
notify("Server Hop", "Searching for a small server...")
task.spawn(function()
local ok, result = pcall(function()
local url = ("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100"):format(game.PlaceId)
return HttpService:JSONDecode(game:HttpGet(url))
end)
if not ok or type(result) ~= "table" or not result.data then
notify("Server Hop", "Could not fetch the server list")
return
end
​local best
for _, s in ipairs(result.data) do
if s.id ~= game.JobId and s.playing and s.maxPlayers and s.playing < s.maxPlayers then
if not best or s.playing < best.playing then
best = s
end
end
end
​if best then
notify("Server Hop", ("Joining server with %d player(s)"):format(best.playing))
TeleportService:TeleportToPlaceInstance(game.PlaceId, best.id, lp)
else
notify("Server Hop", "No other server found")
end
end)
end
​MainTab:Button({
Title = "Small Server Hop",
Desc = "Joins the public server with the fewest players",
Callback = smallServerHop,
})
​-- =====================================================================
-- PLAYER
-- =====================================================================
local DEFAULT_SPEED, DEFAULT_JUMP, DEFAULT_GRAVITY = 16, 50, workspace.Gravity
​local state = {
speedOn = false, speed = 50,
jumpOn = false,  jump = 100,
flyOn = false,   flySpeed = 60,
}
​PlayerTab:Section({ Title = "Movement" })
​PlayerTab:Slider({
Title = "WalkSpeed",
Step = 1,
Value = { Min = 16, Max = 300, Default = 50 },
Callback = function(v)
if type(v) == "number" then state.speed = v end
end,
})
PlayerTab:Toggle({
Title = "Enable WalkSpeed",
Desc = "Keeps your custom speed applied",
Value = false, Default = false,
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
Callback = function(v)
if type(v) == "number" then state.jump = v end
end,
})
PlayerTab:Toggle({
Title = "Enable JumpPower",
Value = false, Default = false,
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
​PlayerTab:Slider({
Title = "Gravity",
Step = 1,
Value = { Min = 0, Max = 400, Default = math.floor(DEFAULT_GRAVITY) },
Callback = function(v)
if type(v) == "number" then workspace.Gravity = v end
end,
})
​PlayerTab:Toggle({
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
​PlayerTab:Toggle({
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
​-- Fly --------------------------------------------------------------
PlayerTab:Section({ Title = "Fly" })
​local flyBV, flyBG
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
​if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.yAxis end
if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir -= Vector3.yAxis end
​flyBV.Velocity = dir * state.flySpeed
flyBG.CFrame = cam.CFrame
end)
end
​PlayerTab:Slider({
Title = "Fly Speed",
Step = 1,
Value = { Min = 10, Max = 300, Default = 60 },
Callback = function(v)
if type(v) == "number" then state.flySpeed = v end
end,
})
PlayerTab:Toggle({
Title = "Fly",
Desc = "WASD / joystick to move, Space up, Ctrl down.",
Value = false, Default = false,
Callback = function(on)
state.flyOn = not not on
if on then startFly() else stopFly() end
end,
})
​-- Protection -------------------------------------------------------
PlayerTab:Section({ Title = "Protection" })
​PlayerTab:Toggle({
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
​PlayerTab:Toggle({
Title = "Anti Fling",
Desc = "Disables collisions with other players",
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
​-- Character --------------------------------------------------------
PlayerTab:Section({ Title = "Character" })
​PlayerTab:Toggle({
Title = "God Mode",
Desc = "Keeps health full",
Value = false, Default = false,
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
​local lastSafe
PlayerTab:Toggle({
Title = "Anti Void",
Desc = "Teleports you back if you fall",
Value = false, Default = false,
Callback = function(on)
if on then
bind("antivoid", RunService.Heartbeat, function()
local r, h = getRoot(), getHum()
if not (r and h) then return end
if h.FloorMaterial ~= Enum.Material.Air then
lastSafe = r.CFrame
elseif lastSafe and r.Position.Y < workspace.FallenPartsDestroyHeight + 100 then
r.AssemblyLinearVelocity = Vector3.zero
r.CFrame = lastSafe + Vector3.new(0, 5, 0)
end
end)
else
unbind("antivoid")
end
end,
})
​local spinSpeed = 20
PlayerTab:Slider({
Title = "Spin Speed",
Step = 1,
Value = { Min = 1, Max = 100, Default = 20 },
Callback = function(v)
if type(v) == "number" then spinSpeed = v end
end,
})
PlayerTab:Toggle({
Title = "Spin",
Value = false, Default = false,
Callback = function(on)
if on then
bind("spin", RunService.Heartbeat, function()
local r = getRoot()
if r then
r.CFrame = r.CFrame * CFrame.Angles(0, math.rad(spinSpeed), 0)
end
end)
else
unbind("spin")
end
end,
})
​PlayerTab:Button({
Title = "Sit",
Callback = function()
local h = getHum()
if h then h.Sit = true end
end,
})
​PlayerTab:Slider({
Title = "Field of View",
Step = 1,
Value = { Min = 30, Max = 120, Default = 70 },
Callback = function(v)
if type(v) == "number" then
local cam = workspace.CurrentCamera
if cam then cam.FieldOfView = v end
end
end,
})
​-- Target player ----------------------------------------------------
PlayerTab:Section({ Title = "Target Player" })
​local targetName = ""
local function findPlayer(name)
name = tostring(name or ""):lower()
if name == "" then return nil end
for _, p in ipairs(Players:GetPlayers()) do
if p ~= lp and (p.Name:lower():sub(1, #name) == name
or p.DisplayName:lower():sub(1, #name) == name) then
return p
end
end
end
​PlayerTab:Input({
Title = "Player Name",
Desc = "Username or display name",
Value = "",
Placeholder = "Username",
Callback = function(text)
if type(text) == "string" then targetName = text end
end,
})
​PlayerTab:Button({
Title = "Teleport to Player",
Callback = function()
local target = findPlayer(targetName)
local tr = target and target.Character and target.Character:FindFirstChild("HumanoidRootPart")
local root = getRoot()
if root and tr then
root.CFrame = tr.CFrame * CFrame.new(0, 0, 3)
else
notify("Teleport", "Player not found")
end
end,
})
​PlayerTab:Toggle({
Title = "Spectate Player",
Value = false, Default = false,
Callback = function(on)
local cam = workspace.CurrentCamera
if not cam then return end
if on then
local target = findPlayer(targetName)
local hum = target and target.Character and target.Character:FindFirstChildOfClass("Humanoid")
if hum then
cam.CameraSubject = hum
else
notify("Spectate", "Player not found")
end
else
cam.CameraSubject = getHum()
end
end,
})
​-- Misc -------------------------------------------------------------
PlayerTab:Section({ Title = "Misc" })
​local origLight = {
Brightness = Lighting.Brightness,
ClockTime = Lighting.ClockTime,
FogEnd = Lighting.FogEnd,
Ambient = Lighting.Ambient,
}
PlayerTab:Toggle({
Title = "Fullbright",
Desc = "Removes darkness and fog",
Value = false, Default = false,
Callback = function(on)
if on then
bind("fullbright", RunService.RenderStepped, function()
Lighting.Brightness = 2
Lighting.ClockTime = 14
Lighting.FogEnd = 1e9
Lighting.Ambient = Color3.new(1, 1, 1)
end)
else
unbind("fullbright")
for k, v in pairs(origLight) do
pcall(function() Lighting[k] = v end)
end
end
end,
})
​PlayerTab:Toggle({
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
​PlayerTab:Button({
Title = "Reset Character",
Callback = function()
local h = getHum()
if h then h.Health = 0 end
end,
})
​PlayerTab:Button({
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
​-- =====================================================================
-- AIM TAB
-- =====================================================================
AimTab:Section({ Title = "Target Lock & Shiftlock" })
​local aimTargetPlayer = nil
local aimLockEnabled = false
​local function setShiftlock(enabled)
pcall(function()
local PlayerScripts = lp:FindFirstChild("PlayerScripts")
if PlayerScripts then
local PlayerModule = PlayerScripts:FindFirstChild("PlayerModule")
if PlayerModule then
local module = require(PlayerModule)
if type(module) == "table" and type(module.GetCameras) == "function" then
local cameraModule = module:GetCameras()
if cameraModule and cameraModule.activeMouseLockController then
cameraModule.activeMouseLockController:EnableMouseLock(enabled)
end
end
end
end
end)
end
​local function getPlayerNames()
local names = {}
for _, p in ipairs(Players:GetPlayers()) do
if p ~= lp then
table.insert(names, p.DisplayName .. " (@" .. p.Name .. ")")
end
end
if #names == 0 then table.insert(names, "None Available") end
return names
end
​local initialNames = getPlayerNames()
local aimDropdown = AimTab:Dropdown({
Title = "Select Target Player",
Desc = "Choose which player to target",
Values = initialNames,
Value = initialNames[1],
Callback = function(selected)
aimTargetPlayer = nil
local str = type(selected) == "table" and selected[1] or selected
if type(str) == "string" then
for _, p in ipairs(Players:GetPlayers()) do
local label = p.DisplayName .. " (@" .. p.Name .. ")"
if label == str then
aimTargetPlayer = p
break
end
end
end
end,
})
​AimTab:Button({
Title = "Refresh Player List",
Desc = "Update target list with current server players",
Callback = function()
local newNames = getPlayerNames()
pcall(function()
if aimDropdown then
if type(aimDropdown.Refresh) == "function" then
aimDropdown:Refresh(newNames)
elseif type(aimDropdown.SetValues) == "function" then
aimDropdown:SetValues(newNames)
end
end
end)
notify("Aim", "Player list refreshed!")
end,
})
​AimTab:Toggle({
Title = "Enable Target Lock & Shiftlock",
Desc = "Enables Shiftlock and automatically locks camera onto target player",
Value = false,
Default = false,
Callback = function(on)
aimLockEnabled = not not on
setShiftlock(aimLockEnabled)
​if aimLockEnabled then
bind("aimlock", RunService.RenderStepped, function()
if aimLockEnabled and aimTargetPlayer and aimTargetPlayer.Character then
local targetHead = aimTargetPlayer.Character:FindFirstChild("Head") or aimTargetPlayer.Character:FindFirstChild("HumanoidRootPart")
local cam = workspace.CurrentCamera
if targetHead and cam then
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
-- EMOTES TAB (70 Custom Emotes)
-- =====================================================================
EmotesTab:Section({ Title = "Emotes Configuration (70 Emotes)" })
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
​for i = 1, 10 do
local slotIndex = i
selectedEmotes[slotIndex] = emoteList[1]
​EmotesTab:Dropdown({
Title = "Emotes Player " .. slotIndex,
Values = emoteList,
Value = emoteList[1],
Callback = function(v)
local str = type(v) == "table" and v[1] or v
if type(str) == "string" then
selectedEmotes[slotIndex] = str
end
end,
})
​EmotesTab:Button({
Title = "Play Emote Player " .. slotIndex,
Callback = function()
local chosenName = selectedEmotes[slotIndex]
local assetId = emoteIds[chosenName]
if not assetId then
notify("Emotes", "Invalid emote selected!")
return
end
​pcall(function()
local hum = getHum()
if hum then
local animator = hum:FindFirstChildOfClass("Animator") or Instance.new("Animator", hum)
local anim = Instance.new("Animation")
anim.AnimationId = "rbxassetid://" .. tostring(assetId)
local track = animator:LoadAnimation(anim)
track:Play()
notify("Emotes", "Playing: " .. tostring(chosenName))
end
end)
end,
})
end
​-- =====================================================================
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
local part = model:FindFirstChild("Head")
or model.PrimaryPart
or model:FindFirstChildWhichIsA("BasePart")
if not part then return end
​local hl = Instance.new("Highlight")
hl.Adornee = model
hl.FillColor = color
hl.OutlineColor = Color3.new(1, 1, 1)
hl.FillTransparency = 0.6
hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
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
label.TextStrokeTransparency = 0.3
label.TextScaled = false
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
​local npcESP = newESP(Color3.fromRGB(255, 200, 60), 2, function()
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
​ESPTab:Toggle({
Title = "ESP Player",
Desc = "Highlight, name, distance and health of other players",
Value = false, Default = false,
Callback = function(on)
if on then playerESP.Start() else playerESP.Stop() end
end,
})
​ESPTab:Toggle({
Title = "ESP NPC",
Desc = "Highlight every non-player humanoid",
Value = false, Default = false,
Callback = function(on)
if on then npcESP.Start() else npcESP.Stop() end
end,
})
​-- =====================================================================
-- SETTINGS
-- =====================================================================
​SettingsTab:Section({ Title = "Community" })
​SettingsTab:Button({
Title = "Join Discord Server",
Desc = "Opens the invite in Discord and copies the link",
Callback = function()
local link = "https://discord.gg/fdNcwysDg"
local code = "fdNcwysDg"
​local req = request or http_request or (syn and syn.request)
if req then
pcall(function()
req({
Url = "http://127.0.0.1:6463/rpc?v=1",
Method = "POST",
Headers = {
["Content-Type"] = "application/json",
["Origin"] = "https://discord.com",
},
Body = HttpService:JSONEncode({
cmd = "INVITE_BROWSER",
args = { code = code },
nonce = HttpService:GenerateGUID(false),
}),
})
end)
end
​if setclipboard then pcall(setclipboard, link) end
notify("Discord", "Invite sent to Discord (link also copied): " .. link)
end,
})
​Window:SelectTab(1)
notify("Boost Hub", "Loaded successfully with 70 Emotes & Aim!")
