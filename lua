-- Blox Fruits Username Discord Webhook Script (Fixed)

-- Configuration
local WEBHOOK_URL = "https://discord.com/api/webhooks/1552377913238622251/kKXh-i41RJs4J51N233PIYqtirpPRZNhH42mQeljxWuLOzSMV8A0jAEgcEd6HJ3zWsms"
local PLAYER_NAME = game.Players.LocalPlayer.Name

-- Get Server ID safely
local function getServerId()
    -- Method 1: RunService (Most compatible)
    if pcall(function()
        return game:GetService("RunService"):GetServerId()
    end) then
        return game:GetService("RunService"):GetServerId()
    -- Method 2: game:GetServerId (Newer Roblox API)
    elseif pcall(function()
        return game:GetServerId()
    end) then
        return game:GetServerId()
    else
        return "Unknown"
    end
end

local SERVER_ID = getServerId()

-- 1. Send to Discord Webhook
local function sendToDiscord()
    local payload = {
        username = "BF Notifier",
        avatar_url = "https://bloxfruits.fandom.com/wiki/Blox_Fruits?action=raw&file=Blox_Fruits_Logo.png",
        embeds = {
            {
                title = "Player Connected",
                description = "**Username:** @" .. PLAYER_NAME,
                color = 5793266, -- Greenish color
                fields = {
                    {
                        name = "Server ID",
                        value = SERVER_ID,
                        inline = true
                    },
                    {
                        name = "Timestamp",
                        value = os.date("%Y-%m-%d %H:%M:%S"),
                        inline = true
                    }
                },
                footer = {
                    text = "Blox Fruits Auto-Notifier"
                },
                timestamp = os.date("!")
            }
        }
    }

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
        print("[BF Script] Successfully sent username to Discord.")
    else
        print("[BF Script] Failed to send to Discord. Check webhook URL.")
        if not success then
            print("PCall Error: " .. tostring(response))
        else
            print("Response Status: " .. tostring(response.StatusCode))
        end
    end
end

-- 2. Display On-Screen HUD
local function displayHUD()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "BF_WebhookHUD"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = game:GetService("CoreGui")

    local frame = Instance.new("Frame")
    frame.Name = "MainFrame"
    frame.Size = UDim2.fromOffset(320, 60)
    frame.Position = UDim2.fromScale(0.5, 0.05)
    frame.AnchorPoint = Vector2.new(0.5, 0)
    frame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    frame.BorderSizePixel = 0
    frame.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = frame

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(80, 80, 255)
    stroke.Thickness = 2
    stroke.Parent = frame

    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -10, 0, 25)
    title.Position = UDim2.new(0, 5, 0, 5)
    title.BackgroundTransparency = 1
    title.Text = "📡 Discord Webhook Active"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextScaled = true
    title.Font = Enum.Font.GothamMedium
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = frame

    local status = Instance.new("TextLabel")
    status.Name = "Status"
    status.Size = UDim2.new(1, -10, 0, 25)
    status.Position = UDim2.new(0, 5, 0, 30)
    status.BackgroundTransparency = 1
    status.Text = "User: " .. PLAYER_NAME .. " | Sent to Discord"
    status.TextColor3 = Color3.fromRGB(150, 255, 150)
    status.TextScaled = true
    status.Font = Enum.Font.Gotham
    status.TextXAlignment = Enum.TextXAlignment.Left
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

-- 3. Copy to Clipboard
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
print("=== Blox Fruits Discord Notifier ===")
print("Sending username: " .. PLAYER_NAME .. " to Discord...")

sendToDiscord()

local clipStatus = copyToClipboard(PLAYER_NAME)
print("Clipboard status: " .. tostring(clipStatus))

displayHUD()
