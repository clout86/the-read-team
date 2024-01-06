local BettercapAPI = require("BettercapAPI")
local api = BettercapAPI:new("localhost", 8081, "pakemon", "pakemon")

-- Start net.sniff module
local success, response = pcall(api.startModule, api, "net.sniff")
if not success then
    print("Failed to start net.sniff module:", response)
else
    print("net.sniff module started successfully")
end

-- Function to fetch and process network data
local function fetchAndProcessNetworkData()
    while true do
        local success, sessionData = pcall(api.getSession, api)
        if success and sessionData and sessionData.data then
            -- Process the session data
            for _, event in ipairs(sessionData.data) do
                if event.type == "packet" and event.packet then
                    local packet = event.packet
                    -- Add your packet processing logic here
                    -- Example: print source and destination IP
                    if packet.src_ip and packet.dst_ip then
                        print("Packet from " .. packet.src_ip .. " to " .. packet.dst_ip)
                    end
                end
            end
        else
            print("Failed to fetch session data:", sessionData)
        end

        -- Wait for a bit before fetching data again
        os.execute("sleep 1")
    end
end

-- Start fetching and processing network data
fetchAndProcessNetworkData()
