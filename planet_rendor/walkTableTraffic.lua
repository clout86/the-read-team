
local api = require("BettercapAPI")


local function printTable(t, indent)
    indent = indent or ""
    for key, value in pairs(t) do
        if type(value) == "table" then
            print(indent .. tostring(key) .. ":")
            printTable(value, indent .. "  ")
        else
            print(indent .. tostring(key) .. ": " .. tostring(value))
        end
    end
end

-- Example usage in your fetchAndProcessNetworkData function
local function fetchAndProcessNetworkData()
    while true do
        local success, sessionData = pcall(api.getSession, api)
        if success and sessionData then
            -- Print the entire sessionData table
            print("Session Data:")
            printTable(sessionData)
        else
            print("Failed to fetch session data:", sessionData)
            -- If sessionData is a table, print its contents
            if type(sessionData) == "table" then
                printTable(sessionData)
            end
        end

        -- Wait for a bit before fetching data again
        os.execute("sleep 1")
    end
end
fetchAndProcessNetworkData()

