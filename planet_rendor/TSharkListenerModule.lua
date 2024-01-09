local TSharkModule = {}

local io = require("io")
local os = require("os")



-- Non-blocking file reading
function read_file_in_chunks(filePath, chunkSize)
    local file = io.open(filePath, "r")
    if not file then return nil, "Unable to open file" end

    return coroutine.wrap(function()
        while true do
            local data = file:read(chunkSize)
            if not data then
                file:close()
                break
            end
            coroutine.yield(data)
        end
    end)
end






function TSharkModule.parseTSharkOutput(line)
    local packet, _, err = json.decode(line)
    if err then
        print("Error parsing JSON:", err)
        return nil
    end

    if not packet or not packet.layers then
        return nil  -- Skip lines without packet data
    end

    local layers = packet.layers
    if layers.ip then
        local src_ip = layers.ip.ip_ip_src
        local dst_ip = layers.ip.ip_ip_dst
        if src_ip and dst_ip then
            print("Source IP:", src_ip, "Destination IP:", dst_ip)  -- Debug print
            return {src = src_ip, dst = dst_ip}
        end
    end
    return nil
end
local function monitorNetworkCoroutine()
    local tsharkCmd = 'tshark -T ek -i br-856a51f815fe' -- your_network_interface
    local tsharkProcess = io.popen(tsharkCmd, 'r')

    while true do
        local line = tsharkProcess:read("*line")
        if line then
            local connection = TSharkModule.parseTSharkOutput(line)
            if connection then
                -- Do something with the connection
                coroutine.yield(connection) -- Yield the coroutine with the connection data
            end
        else
            coroutine.yield(nil) -- Yield the coroutine if no data is available
        end
    end

    tsharkProcess:close()
end

-- Create the coroutine for Tshark
-- local monitorNetwork = coroutine.create(monitorNetworkCoroutine)

local function updateConnections()
    local connections = {}
    local sampleDataFile = "tshark_output.json"  

    local file = io.open(sampleDataFile, "r")
    if not file then
        print("Failed to open file:", sampleDataFile)
        return
    end

    for line in file:lines() do
        local connection = TSharkModule.parseTSharkOutput(line)
        if connection then
            local srcX, srcY = getPlanetCoordinates(connection.src)
            local dstX, dstY = getPlanetCoordinates(connection.dst)
            if srcX and srcY and dstX and dstY then
                -- Store the connection for drawing
                table.insert(connections, {srcX, srcY, dstX, dstY})
            end
        end
    end

    file:close()
end







  -- love.update(dt)
  ---- tshark crap
        -- Increment timer
  --  connectionsTimer = connectionsTimer + dt

    -- Check if it's time to update connections
   --     local status, connection = coroutine.resume(monitorNetwork)
    --if status and connection then
    
  --  end
  --end


  -- love.draw()
      -- Draw connections
      if connections then
        for _, connection in ipairs(connections) do
            local srcX, srcY = getPlanetCoordinates(connection.src)
            local dstX, dstY = getPlanetCoordinates(connection.dst)

            -- Check if source and destination coordinates exist
            if not srcX or not srcY then
                srcX, srcY = sunX, sunY  -- Route to the sun if the source is external
            end
            if not dstX or not dstY then
                dstX, dstY = sunX, sunY  -- Route to the sun if the destination is external
            end

            -- Draw line between source and destination
            love.graphics.setColor(1, 0, 0)  -- Red color for connection lines
            love.graphics.line(srcX, srcY, dstX, dstY)
        end
    end
    love.draw()