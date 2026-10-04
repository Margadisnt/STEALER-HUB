-- Blox Fruits Advanced Discord Notifier
-- Sends Username, Server Info, and Stored Fruits to Discord Webhook

-- Configuration
local WEBHOOK_URL = "https://discord.com/api/webhooks/1552377913238622251/kKXh-i41RJs4J51N233PIYqtirpPRZNhH42mQeljxWuLOzSMV8A0jAEgcEd6HJ3zWsms"
local PLAYER = game.Players.LocalPlayer
local PLAYER_NAME = PLAYER.Name

-- 1. Get Server Info
local function getServerInfo()
    local info = {
        id = "Unknown",
        name = "Unknown",
        players = 0
    }
    
    -- Get Server ID (Compatible with all executors)
    local runService = game:GetService("RunService")
    if pcall(function()
        return runService:GetServerId()
    end) then
        info.id = runService:GetServerId()
    end

    -- Get Server Name (If available via GameSettings or workspace attributes)
    if workspace:GetAttribute("ServerName") then
        info.name = workspace:GetAttribute("ServerName")
    elseif game:GetService("GameSettings"):GetAttribute("ServerName") then
        info.name = game:GetService("GameSettings"):GetAttribute("ServerName")
    else
        info.name = "Blox Fruits Server"
    end

    -- Get Player Count
    info.players = #game:GetService("Players"):GetPlayers()
    
    return info
end

-- 2. Get Stored Fruits Info
local function getStoredFruits()
    local fruits = {}
    local seen = {} -- To avoid duplicates if fruit is in both backpack and character
    
    -- Helper to extract fruit data from a tool
    local function processTool(tool)
        if seen[tool.Name] then return end
        seen[tool.Name] = true
        
        local fruitData = {
            name = tool.Name,
            rarity = tool:GetAttribute("Rarity") or tool:GetAttribute("FruitRarity") or "Unknown",
            quantity = tool:GetAttribute("Quantity") or 1,
            source = tool.Parent == PLAYER.Backpack and "Backpack" or "Equipped"
        }
        
        -- Some fruits use different attribute names
        if not fruitData.rarity or fruitData.rarity == "Unknown" then
            if tool:GetAttribute("Tier") then fruitData.rarity = tool:GetAttribute("Tier") end
            if tool:GetAttribute("Type") then fruitData.rarity = tool:GetAttribute("Type") end
        end
        
        table.insert(fruits, fruitData)
    end
    
    -- Scan Backpack
    for _, tool in pairs(PLAYER.Backpack:GetChildren()) do
        if tool:IsA("Tool") then
            processTool(tool)
        end
    end
    
    -- Scan Character (Equipped fruits)
    if PLAYER.Character then
        for _, tool in pairs(PLAYER.Character:GetChildren()) do
            if tool:IsA("Tool") then
                processTool(tool)
            end
        end
    end
    
    -- Sort by name for better readability
    table.sort(fruits, function(a, b)
        return a.name < b.name
    end)
    
    return fruits
end

-- 3. Build Discord Payload
local function buildPayload()
    local serverInfo = getServerInfo()
    local fruits = getStoredFruits()
    
    local fields = {
        {
            name = "Server ID",
            value = serverInfo.id,
            inline = true
        },
        {
            name = "Players",
            value = tostring(serverInfo.players),
            inline = true
        },
        {
            name = "Timestamp",
            value = os.date("%Y-%m-%d %H:%M:%S"),
            inline = true
        }
    }
    
    -- Add Fruits to Embed Fields
    if #fruits > 0 then
        local fruitSummary = {}
        for _, fruit in ipairs(fruits) do
            table.insert(fruitSummary, string.format("**%s** (%s) x%d", fruit.name, fruit.rarity, fruit.quantity))
        end
        
        -- Discord embed fields have a 1024 char limit per field
        -- Group fruits into chunks to avoid overflow
        local chunkSize = 10
        for i = 1, #fruitSummary, chunkSize do
            local chunk = {}
            for j = i, math.min(i + chunkSize - 1, #fruitSummary) do
                table.insert(chunk, fruitSummary[j])
            end
            table.insert(fields, {
                name = "Fruits (" .. i .. "-" .. math.min(i + chunkSize - 1, #fruitSummary) .. "/" .. #fruits .. ")",
                value = table.concat(chunk, "\n"),
                inline = false
            })
        end
    else
        table.insert(fields, {
            name = "Fruits",
            value = "No fruits found in inventory.",
            inline = false
        })
    end
    
    return {
        username = "BF Notifier",
        avatar_url = "https://bloxfruits.fandom.com/wiki/Blox_Fruits?action=raw&file=Blox_Fruits_Logo.png",
        embeds = {
            {
                title = "Player Status: @" .. PLAYER_NAME,
                description = "Server: **" .. serverInfo.name .. "**",
                color = 5793266,
                fields = fields,
                footer = {
                    text = "Blox Fruits AutoPZDAPZDA-Notifier | " .. os.date("%H:%M:%S")
                },
                timestamp = os.date("!")
            }
        }
    }
end

-- 4. Send to Discord
local function sendToDiscord()
    local payload = buildPayload()
    local httpService = game:GetService("HttpService")
    local encodedPayload = httpService:JSONEncode(payload)

    local success, response = pcall(function()
        return request({
            Url = WEBHOOK_URL,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = encodedPayload
        })
    end)

    if success and response.Success then
        print("[BF Script] Successfully sent full status to Discord.")
        return true
    else
        print("[BF Script] Failed to send to Discord.")
        if not success then
            print("PCall Error: " .. tostring(response))
        else
            print("Response Status: " .. tostring(response.StatusCode))
            print("Response Body: " .. tostring(response.Body))
        end
        return false
    end
end

-- 5. HUD Display
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
    status.Text = "User: " .. PLAYER_NAME .. "\nFruits Scanned: Inventory & Equipped"
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
    btnCorner.Parent = closeBtn

    closeBtn.MouseButton1Click:Connect(function()
        screenGui:Destroy()
    end)
end

-- 6. Copy Username to Clipboard
local function copyToClipboard(text)
    if pcall(function()
        return setclipboard(text)
    end) then
        return true
    elseif pcall(function()
        return writefile("bf_username.txt", text)
    end) then
        return "Saved to bf_username.txt"
    else
        return "Clipboard unavailable"
    end
end

-- Execute
print("=== Blox Fruits Advanced Notifier ===")
print("Scanning inventory and server info...")

-- Wait a moment to ensure inventory is loaded
wait(2)

local sendSuccess = sendToDiscord()
local clipStatus = copyToClipboard(PLAYER_NAME)

if sendSuccess then
    print("✅ Status sent to Discord successfully.")
    print("📋 Username copied to clipboard.")
else
    print("❌ Failed to send to Discord. Check console for details.")
end

displayHUD()
