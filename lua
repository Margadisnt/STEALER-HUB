local WEBHOOK_URL = "https://discord.com/api/webhooks/1552377913238622251/kKXh-i41RJs4J51N233PIYqtirpPRZNhH42mQeljxWuLOzSMV8A0jAEgcEd6HJ3zWsms"

-- Test Payload
local payload = [[{
    "username": "Blox Fruits Host Bot",
    "embeds": [
        {
            "title": "👤 Connection Test",
            "description": "If you see this, the HTTP request works.",
            "color": 15158332,
            "fields": [
                { "name": "🆔 Username", "value": "TestUser", "inline": true },
                { "name": "🖥️ Executor", "value": "Active", "inline": true }
            ]
        }
    ]
}]]

print("[Host] Sending test payload...")
print("[Host] Payload Length: " .. #payload)

local success, err = pcall(function()
    local response = game:HttpGetAsync(WEBHOOK_URL, payload, true)
    print("[Host] Response: " .. tostring(response))
end, function(error)
    print("[Host] Error: " .. tostring(error))
    -- Fallback to HttpPost if available
    if game.HttpPost then
        local response = game:HttpPost(WEBHOOK_URL, payload, "application/json")
        print("[Host] HttpPost Response: " .. tostring(response))
    end
end)

if success then
    print("[Host] Send attempt completed successfully.")
else
    print("[Host] Send failed: " .. tostring(err))
end
