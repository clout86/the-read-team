local http = require("socket.http")
local ltn12 = require("ltn12")
local json = require("dkjson")


local metasploit = require("metasploit")
local authenticate = require("auth")

local url = "http://localhost:55552/api/1.0"
local username = "msf"
local password = "badpass"


local BettercapAPI = require("BettercapAPI")
local api = require("BettercapAPI"):new("localhost", 8081, "pakemon", "pakemon")


local displayStartIndex = 1
local maxDisplayCount = 6

local useDatabase = false
local useActive = true

local messageWindowTimer = 0

local connectionsUpdateInterval = 5  -- Time in seconds between updates
local connectionsTimer = 0



local function base64_encode(data)
    local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    return ((data:gsub('.', function(x) 
        local r, b = '', x:byte()
        for i = 8, 1, -1 do r = r .. (b % 2^i - b % 2^(i-1) > 0 and '1' or '0') end
        return r;
    end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
        if (#x < 6) then return '' end
        local c = 0
        for i = 1, 6 do c = c + (x:sub(i,i) == '1' and 2^(6-i) or 0) end
        return b:sub(c+1,c+1)
    end)..({ '', '==', '=' })[#data%3+1])
end

-- function that defines orbit
function calculateEllipticalOrbit(semiMajorAxis, eccentricity, angle, tiltAngle)
    local semiMinorAxis = semiMajorAxis * math.sqrt(1 - eccentricity^2)
    local r = semiMajorAxis * (1 - eccentricity^2) / (1 + eccentricity * math.cos(angle))
    local x = r * math.cos(angle)
    local y = r * math.sin(angle) * (semiMinorAxis / semiMajorAxis)

    -- Apply rotation for the tilt
    local tiltRadian = math.rad(tiltAngle)
    local rotatedX = x * math.cos(tiltRadian) - y * math.sin(tiltRadian)
    local rotatedY = x * math.sin(tiltRadian) + y * math.cos(tiltRadian)

    return rotatedX, rotatedY -- x and y coods 
end

local TSharkModule = {}

local io = require("io")
local os = require("os")

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


local function printTable(t, indent, result)
        indent = indent or ""
        result = result or ""

    for k, v in pairs(t) do
        if type(v) == "table" then
            result = result .. indent .. k .. ":\n"
            result = result .. printTable(v, indent .. "  ", "")
        else
            result = result .. indent .. k .. ": " .. tostring(v) .. "\n"
        end
    end

    return result
end

local function fetchLanStructure(api)
    local response = api:request("/api/session/lan", "GET")
    if response and response.hosts then
        return response.hosts  -- Return all hosts
    end
    return nil
end

local hosts = fetchLanStructure(api)
if hosts then 
	print("hosts struct found!!: ")
	print(printTable(hosts))

end

function updateSelectedPlanet()
    if planets and selectedPlanetIndex then
        selectedPlanet = planets[selectedPlanetIndex]
    else
        selectedPlanet = nil
    end
end

local messageWindow = {
    x = 0,
    y = 0,
    width = 400,
    height = 200,
    message = "Welcome to the Message Window!",
}

function updateMessage(newMessage)
    messageWindow.message = newMessage
    messageWindowTimer = 6 
end

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

-- Function to run active processing on data
local function runActive(dataTable)
    local function buildLuaTable(dataTable)
        local hostTable = {}
        local semiMajorAxis = 50 -- Starting value
        local angle = 0
        local speed = .8
        local eccentricity = .5


	for _, hostData in ipairs(dataTable) do
        
	    local host = {}
            -- Create a new table for each host, copying the values from the row
            local host = {}
            for key, value in pairs(hostData) do
                host[key] = value
            end

            host.satellites = {}
            if hostData.meta and hostData.meta.values and hostData.meta.values.ports then
                for portNumber, portData in pairs(hostData.meta.values.ports) do
                    table.insert(host.satellites, {
                        name = tostring(portNumber),  -- Using port number as satellite name
                        angle = math.random() * 360,
                        distance = 25,
                        speed = 1
                    })
                end
            end

            print("Host:", host.hostname, "Ports:", host.ports)  -- Debug print ports

	    -- Add additional properties
            host.semiMajorAxis = semiMajorAxis
            host.angle = angle
            host.speed = speed
            host.eccentricity = eccentricity

            -- Insert the host into the hostTable
            table.insert(hostTable, host)

            -- Update properties for the next host
            angle = math.random() * 360
            semiMajorAxis = semiMajorAxis + math.random(10,35)
            if semiMajorAxis > 400 then semiMajorAxis = math.ceil(math.random(400,500)) end
            eccentricity = math.random(0.09,0.65)
        end
        return hostTable
    end

    return buildLuaTable(dataTable)
end

--
-- Database function is self contained and you can delete
local function runDatabase ()
    local luasql = require("luasql.sqlite3")
    local env = luasql.sqlite3()
    local conn = env:connect('netmap.db')
 
    local function getAllData()
    	local cursor = assert(conn:execute("SELECT id, ipv4, mac, hostname, alias, vendor, first_seen, last_seen FROM your_table"))
    	return cursor
    end

    local function buildLuaTable()
    	local cursor = getAllData()
    	local hostTable = {}
    	local semiMajorAxis = 50
    	local angle = 0
    	local speed = .8
    	local eccentricity = .5
    	-- Iterate through each row in the database
    	local row = cursor:fetch({}, "a")
    	while row do
            table.insert(hostTable, {
                name = row.hostname,
                semiMajorAxis = semiMajorAxis,
                id = row.id,
                ipv4 = row.ipv4,
                mac = row.mac,
                alias = row.alias,
                vendor = row.vendor,
                first_seen = row.first_seen,
                last_seen = row.last_seen,
                angle = angle,
                speed = speed,
                eccentricity = eccentricity
            })
	    -- place to define orbit props per host
            angle = math.random() * 360 
	    -- speed = speed - math.random(0.13,0.17)
	    -- if speed <= 0 then speed = math.random(0.09,0.13) end
	    semiMajorAxis = semiMajorAxis + math.random(10,35)
	    if semiMajorAxis > 400 then semiMajorAxis = math.ceil(math.random(400,500)) end
	    eccentricity = math.random(0.09,0.65)
            row = cursor:fetch(row, "a") -- Fetch the next row
    	end
    	cursor:close()
    	return hostTable
    end
    local hostTable = buildLuaTable()
    conn:close()
    env:close()
    return hostTable
end

function love.load()

    -- login to bettercap and walk the lan
    local api = BettercapAPI:new("localhost", 8081, "pakemon", "pakemon")
    local hosts = fetchLanStructure(api)
    if hosts then
        planets = runActive(hosts)
        -- Do something with processedData
    end

    updateSelectedPlanet()
    -- updateConnections() -- Tshark bork

    -- Load the planet sprite
    planetSprite = love.graphics.newImage("assets/planet.png")

    -- Define the sun's position
    sunX, sunY = love.graphics.getWidth() / 2, love.graphics.getHeight() / 2
    
    -- Adjust sun placement because i'm lazy and suck at maths
    sunX = sunX + 240
    sunY = sunY - 140

    -- run check if should even run
    -- if useDatabase then hostTable = runDatabase() end

    -- Example: Print the Lua table (for debugging)
    --for _, host in ipairs(planets) do
   -- 	print(host.name, host.semiMajorAxis)
    --end

    -- Initialize variables for cycling display
    displayStartIndex = 1
    maxDisplayCount = 6
    
    -- planets orbit if true
    isOrbiting = true

    -- Initialize selected planet index
    selectedPlanetIndex = 1

    displayDetails = false

    messageWindow.x = (love.graphics.getWidth() - messageWindow.width) / 2
    messageWindow.y = (love.graphics.getHeight() - messageWindow.height) / 2
--	updateMessage(commandResponseText)

end

function love.update(dt)

	--DEBUG STUFF
    require("lovebird").update()	
   -- require("lurker").update() -- breaks UI placement 
        --DEBUG STUFF
    
    -- main start of update func	
    if messageWindowTimer > 0 then
        messageWindowTimer = messageWindowTimer - dt
        if messageWindowTimer <= 0 then
            messageWindow.message = ""  -- Clear the message when timer runs out
        end
    end

    if isOrbiting then
    -- Update the planets' angles
       for i, planet in ipairs(planets) do
         planet.angle = planet.angle + planet.speed * dt
       end

       for _, planet in ipairs(planets) do
           for _, satellite in ipairs(planet.satellites) do
                satellite.angle = satellite.angle + satellite.speed * dt
           end
        end
    end


    ---- tshark crap
        -- Increment timer
  --  connectionsTimer = connectionsTimer + dt

    -- Check if it's time to update connections
   --     local status, connection = coroutine.resume(monitorNetwork)
    --if status and connection then
    
  --  end
    updateSelectedPlanet()
end

-- value for messageWindow
local commandResponseText = ""


-- functions for menu:

function net_probe_off()
    local api = require("BettercapAPI"):new("localhost", 8081, "pakemon", "pakemon")
    local command = '{"cmd": "net.probe off"}'

    local success, commandResponse = pcall(api.postCommand, api, "/api/session", command)
    if success then
        print("Command Response: ")
        print(commandResponse)
        commandResponseText = tostring(commandResponse)  -- Convert to string if necessary
        updateMessage(commandResponseText)  -- Update the message
    else
        print("Error occurred: " .. tostring(commandResponse))
        updateMessage("Error occurred: " .. tostring(commandResponse))  -- Display error
    end
end

local metasploit = require("metasploit")
local authenticate = require("auth")

local url = "http://localhost:55552/api/1.0"
local username = "msf"
local password = "badpass"

-- Authenticate and get the token
local token = authenticate(url, username, password)

function is_known_pipename(rhost)
    print("Executing is_known_pipename for:", rhost)

    local module_type = "exploit"
    local module_name = "linux/samba/is_known_pipename"
    local options = {
        ["RHOST"] = rhost,
        ["RPORT"] = "445"
    }

    local success, execution_result = pcall(function()
        return metasploit.module_execute(url, token, module_type, module_name, options)
    end)

    if success then
        print("Execution Result:")
        commandResponseText = metasploit.walk_table(execution_result)
    else
        print("Error executing module:", execution_result)
        commandResponseText = execution_result
    end
end




function net_probe_on()
    local api = require("BettercapAPI"):new("localhost", 8081, "pakemon", "pakemon")
    local command = '{"cmd": "net.probe on"}'

    -- Try to post the command and handle any errors
    local success, commandResponse = pcall(api.postCommand, api, "/api/session", command)

    -- Check if the command was successful
    if success then
        print("Command Response: ")
        print(commandResponse)
	        commandResponseText = commandResponse  -- Store the response
    else
        -- Handle the error (e.g., log it or show a message to the user)
        print("Error occurred: " .. commandResponse)
    end
end


function executeSynScan(ipAddress)
    local api = require("BettercapAPI"):new("localhost", 8081, "pakemon", "pakemon")
    local command

    if ipAddress then
        command = string.format('{"cmd": "syn.scan %s"}', ipAddress)
        updateMessage("Starting SYN scan on IP: ", ipAddress)
    else
        command = '{"cmd": "syn.scan stop"}'
        updateMessage("Stopping SYN scan")
    end

    local success, commandResponse = pcall(api.postCommand, api, "/api/session", command)

    if success then
        print("Command Response: ", commandResponse)
        updateMessage("Command Response: " .. tostring(commandResponse))
    else
        print("Error occurred: ", commandResponse)
        updateMessage("Error occurred: " .. tostring(commandResponse))
    end
end




function syn_scan_stop()
    local api = require("BettercapAPI"):new("localhost", 8081, "pakemon", "pakemon")
    local command = '{"cmd": "syn.scan stop"}'

    -- Try to post the command and handle any errors
    local success, commandResponse = pcall(api.postCommand, api, "/api/session", command)

    -- Check if the command was successful
    if success then
        print("Command Response: ")
        print(commandResponse)
	        commandResponseText = commandResponse  -- Store the response
    else
        -- Handle the error (e.g., log it or show a message to the user)
        print("Error occurred: " .. commandResponse)
    end
end

function syn_scan(ipAddress)
    local api = require("BettercapAPI"):new("localhost", 8081, "pakemon", "pakemon")

    print(ipAddress)
    local command = string.format('{"cmd": "syn.scan %s"}', ipAddress)

    -- Try to post the command and handle any errors
    local success, commandResponse = pcall(api.postCommand, api, "/api/session", command)

    -- Check if the command was successful
    if success then
        print("Command Response: ")
        print(commandResponse)
            commandResponseText = commandResponse  -- Store the response
	else
        -- Handle the error (e.g., log it or show a message to the user)
        print("Error occurred: " .. commandResponse)
    end
end


local displayDetails = false
local currentTableIndex = 1
local currentItemIndex = 1
local nestedTables = {}  -- List of nested table names



local isContextMenuOpen = false
local contextMenuOptions = { "net.probe on", "net.probe off", "syn.scan host", "stop syn.scan", "is_known_pipename"}  -- Add your options here
local selectedOptionIndex = 1

function getPlanetCoordinates(ipAddress)
    local planet = planets[ipAddress]
    if planet then
	    print("debug getPlanetCoords: ", panet.x, planet.y)
        return planet.x, planet.y
    else
        -- Return nil if the planet for the given IP address is not found
        return nil, nil
    end
end


function executeContextMenuOption(index)
    if index == 1 then
        net_probe_on()
    elseif index == 2 then
        net_probe_off()
    elseif index == 3 and planets[selectedPlanetIndex] then
        syn_scan(planets[selectedPlanetIndex].ipv4)
    elseif index == 4 then
        syn_scan_stop()
    elseif index == 5 and planets[selectedPlanetIndex] then
	  is_known_pipename(planets[selectedPlanetIndex].ipv4)
    end
end
function updatePlanetSelection(direction)
    selectedPlanetIndex = selectedPlanetIndex + direction
    if selectedPlanetIndex > #planets then
        selectedPlanetIndex = 1  -- Cycle back to the first planet
    elseif selectedPlanetIndex < 1 then
        selectedPlanetIndex = #planets  -- Cycle to the last planet
    end
end
function toggleDisplayDetails()
    displayDetails = not displayDetails
end
function togglePlanetDisplay()
    if maxDisplayCount ~= #planets then
        -- Save current state for toggling back
        prevMaxDisplayCount = maxDisplayCount
        prevDisplayStartIndex = displayStartIndex

        -- Set to display all planets
        maxDisplayCount = #planets
        displayStartIndex = 1
    else
        -- Restore previous state
        maxDisplayCount = prevMaxDisplayCount or 6
        displayStartIndex = prevDisplayStartIndex or 1
    end
end
function updatePlanets()
    local api = BettercapAPI:new("localhost", 8081, "pakemon", "pakemon")
    local hosts = fetchLanStructure(api)
    if hosts then
        planets = runActive(hosts)
    end
end



function love.keypressed(key)
        if isContextMenuOpen then
        if key == "right" then
            selectedOptionIndex = selectedOptionIndex + 1
            if selectedOptionIndex > #contextMenuOptions then
                selectedOptionIndex = 1  -- Cycle back to the first option
            end
        elseif key == "left" then
            selectedOptionIndex = selectedOptionIndex - 1
            if selectedOptionIndex < 1 then
                selectedOptionIndex = #contextMenuOptions  -- Cycle to the last option
            end
        end
    end



	if key == "right" then
        selectedPlanetIndex = selectedPlanetIndex + 1
        if selectedPlanetIndex > displayStartIndex + maxDisplayCount - 1 then
            displayStartIndex = math.min(displayStartIndex + maxDisplayCount, #planets - maxDisplayCount + 1)
            selectedPlanetIndex = displayStartIndex
        end
    elseif key == "left" then
        selectedPlanetIndex = selectedPlanetIndex - 1
        if selectedPlanetIndex < displayStartIndex then
            displayStartIndex = math.max(displayStartIndex - maxDisplayCount, 1)
            selectedPlanetIndex = displayStartIndex
        end

    elseif key == "z" then
        displayDetails = not displayDetails
	        print("displayDetails toggled: " .. tostring(displayDetails))  -- Debug print
        if displayDetails then
            nestedTables = {"ports"}  -- other nested table names here
            currentTableIndex = 1
            currentItemIndex = 1
        end
    	elseif displayDetails then
            if key == "right" or key == "left" then
                -- Cycle through nested tables
                currentTableIndex = key == "right" and (currentTableIndex % #nestedTables) + 1 or (currentTableIndex - 2) % #nestedTables + 1
                currentItemIndex = 1  -- Reset item index
                updateSelectedPlanet() 
    	    elseif key == "up" or key == "down" then
            -- Cycle through items in the current nested table
        
        	if selectedPlanet and selectedPlanet.meta and selectedPlanet.meta.values then
            	local currentTable = selectedPlanet.meta.values[nestedTables[currentTableIndex]]
            	if currentTable then
                    currentItemIndex = key == "up" and (currentItemIndex - 2) % #currentTable + 1 or (currentItemIndex % #currentTable) + 1
            	end
    	    end
	end
    elseif key == "a" then

	if isContextMenuOpen then
            -- Add functionality for each option here
	    if selectedOptionIndex == 1 then
                net_probe_on()
	updateMessage(commandResponseText)
            elseif selectedOptionIndex == 2 then
                net_probe_off()
            elseif selectedOptionIndex == 3 then
	        syn_scan(planets[selectedPlanetIndex].ipv4)
	elseif selectedOptionIndex == 4 then
		syn_scan_stop() 
	    elseif index == 5 then
          is_known_pipename(planets[selectedPlanetIndex].ipv4)
	  print("IP: ",planets[selectedPlanetIndex].ipv4 ,"RHOST: ", rhost )
	    end

        else
            isContextMenuOpen = true
            selectedOptionIndex = 1
        end
    elseif key == "b" then
        isContextMenuOpen = false
    elseif key == "up" or key == "down" then
        if isContextMenuOpen then
            -- Navigate through options
            selectedOptionIndex = (selectedOptionIndex % #contextMenuOptions) + 1
        end
    elseif key == "e" then 
        planets[selectedPlanetIndex].speed = planets[selectedPlanetIndex].speed * 0.9
    elseif key == "d" then
        planets[selectedPlanetIndex].speed = planets[selectedPlanetIndex].speed * 1.1
    elseif key == "i" then
	    executeSynScan(planets[selectedPlanetIndex].ipv4)
	   -- sys_scan(planets[selectedPlanetIndex].ipv4)
    elseif key == "p" then


    local api = BettercapAPI:new("localhost", 8081, "pakemon", "pakemon")
    local hosts = fetchLanStructure(api)
    if hosts then
        planets = runActive(hosts)
        -- Do something with processedData
    end


    elseif key == "s" then
        isOrbiting = not isOrbiting
    -- displayStartIndex = 1  -- Reset to first set of planets when paused
--    elseif key == "up" then -- and not isOrbiting then
--        displayStartIndex = math.max(displayStartIndex - maxDisplayCount, 1)
--    elseif key == "down" then --and not isOrbiting then
--        displayStartIndex = math.min(displayStartIndex + maxDisplayCount, #planets - maxDisplayCount + 1)
    elseif key == "f" then
        -- Toggle between displaying all planets and the previous state
        if maxDisplayCount ~= #planets then
            -- Save current state for toggling back
            prevMaxDisplayCount = maxDisplayCount
            prevDisplayStartIndex = displayStartIndex

            -- Set to display all planets
            maxDisplayCount = #planets
            displayStartIndex = 1
        else
            -- Restore previous state
            maxDisplayCount = prevMaxDisplayCount or 6
            displayStartIndex = prevDisplayStartIndex or 1
        end
    end
end


local function printTable(t, indent)
    indent = indent or ""
    local result = ""

    for k, v in pairs(t) do
        if type(v) == "table" then
            result = result .. indent .. k .. ":\n"
            result = result .. printTable(v, indent .. "  ")
        else
            result = result .. indent .. k .. ": " .. tostring(v) .. "\n"
        end
    end

    return result
end


function drawDetailsBox(selectedPlanet)
    if displayDetails and nestedTables[currentTableIndex] and selectedPlanet and selectedPlanet.meta and selectedPlanet.meta.values then
        local currentTable = selectedPlanet.meta.values[nestedTables[currentTableIndex]]

        if currentTable and #currentTable > 0 then
            local screenWidth, screenHeight = love.graphics.getWidth(), love.graphics.getHeight()
            local boxWidth, boxHeight = 300, 100
            local startX, startY = (screenWidth - boxWidth) / 2, screenHeight - boxHeight - 10

            if startX and startY then
                love.graphics.setColor(0, 0, 0, 0.7)  -- Semi-transparent black
                love.graphics.rectangle("fill", startX, startY, boxWidth, boxHeight)

                love.graphics.setColor(1, 1, 1)  -- White for text
                if currentItemIndex <= #currentTable then
                    local currentItem = currentTable[currentItemIndex]
                    local text = nestedTables[currentTableIndex] .. ": " .. tostring(currentItem)
                    love.graphics.print(text, startX + 10, startY + 10)
                else
                    love.graphics.print("No item at index: " .. currentItemIndex, startX + 10, startY + 10)
                end
            else
                print("Error: startX or startY is nil")
            end
        else
            love.graphics.print("Table is empty or nil", 300, 100) -- Default position if startX or startY is nil
        end
    else
     --   print("Details not displayed or data missing")
    end
end

local function printTable(t, indent, result)
        indent = indent or ""
        result = result or ""

    for k, v in pairs(t) do
        if type(v) == "table" then
            result = result .. indent .. k .. ":\n"
            result = result .. printTable(v, indent .. "  ", "")
        else
            result = result .. indent .. k .. ": " .. tostring(v) .. "\n"
        end
    end

    return result
end

local function printNestedTable(t, startX, startY, width, indent)
    love.graphics.setColor(0, 255, 255, 0.7)
    love.graphics.rectangle("fill", startX, startY, width, 200)  -- Adjust size as needed
    love.graphics.setColor(0, 255, 255)

    local nestedText = ""
    indent = indent or ""

    for k, v in pairs(t) do
        if type(v) == "table" then
            nestedText = nestedText .. indent .. k .. ":\n"
            for subK, subV in pairs(v) do
                nestedText = nestedText .. indent .. "  " .. subK .. ": " .. tostring(subV) .. "\n"
            end
        else
            nestedText = nestedText .. indent .. k .. ": " .. tostring(v) .. "\n"
        end
    end

    love.graphics.printf(nestedText, startX + 10, startY + 10, width - 20, "left")
end



function love.draw()
    -- Set color for orbit lines
    love.graphics.setColor(0, 255, 255)
    local endIndex = math.min(displayStartIndex + maxDisplayCount - 1, #planets)

    -- Draw orbit lines for the planets within the specified range
    for i = displayStartIndex, endIndex do
        local planet = planets[i]
        local x, y = calculateEllipticalOrbit(planet.semiMajorAxis, planet.eccentricity, 0, 335)
        love.graphics.ellipse("line", sunX, sunY, x, y)
    end

    -- Reset color to white for drawing planets and text
    love.graphics.setColor(1, 1, 1)

    -- Draw the sun
    love.graphics.circle("fill", sunX, sunY, 20)



  function getPlanetCoordinates(ipAddress)
    for _, planet in ipairs(planets) do
        if planet.ipv4 == ipAddress then
            local x, y = calculateEllipticalOrbit(planet.semiMajorAxis, planet.eccentricity, planet.angle, 335)
            return sunX + x, sunY + y
        end
    end
    return nil, nil  -- IP address not found among planets
  end





    -- Draw planets and satellites
    for i = displayStartIndex, endIndex do
        local planet = planets[i]
        local planetX, planetY = calculateEllipticalOrbit(planet.semiMajorAxis, planet.eccentricity, planet.angle, 335)
        love.graphics.draw(planetSprite, sunX + planetX, sunY + planetY, 0, 0.1, 0.1, planetSprite:getWidth() / 2, planetSprite:getHeight() / 2)
        local textX = sunX + planetX - planetSprite:getWidth() / 4
        local textY = sunY + planetY - planetSprite:getHeight() / 4 - 15
        love.graphics.print(planet.hostname, textX, textY)

        for _, satellite in ipairs(planet.satellites) do
            local satelliteX, satelliteY = calculateEllipticalOrbit(satellite.distance, 0, satellite.angle, 0)
            satelliteX, satelliteY = satelliteX + planetX, satelliteY + planetY
            love.graphics.setColor(0, 255, 255)
            love.graphics.circle("fill", sunX + satelliteX, sunY + satelliteY, 5)
            love.graphics.setColor(1, 1, 1)
        end
    end

    -- Message window
    if messageWindowTimer > 0 then
        love.graphics.setColor(0, 255, 255, 0.65)  -- semi-transparent cyan
        love.graphics.rectangle("fill", messageWindow.x, messageWindow.y, messageWindow.width, messageWindow.height)
        love.graphics.setColor(0, 0, 0)  -- red color for the text
        love.graphics.printf(messageWindow.message, messageWindow.x, messageWindow.y + 20, messageWindow.width, "center")
    end

    -- Display details of the selected planet
    if displayDetails and planets and selectedPlanetIndex and planets[selectedPlanetIndex] then
        local selectedPlanet = planets[selectedPlanetIndex]
        local x, y = calculateEllipticalOrbit(selectedPlanet.semiMajorAxis, selectedPlanet.eccentricity, selectedPlanet.angle, 335)
        
        -- Draw details box
        drawDetailsBox(selectedPlanet)

        -- Draw line from selected planet to displayDetails
        love.graphics.setColor(0, 255, 255)
        love.graphics.line(sunX + x, sunY + y, 10, 210)

        -- Draw displayDetails for main properties
        love.graphics.setColor(0, 255, 255, 0.7)
        love.graphics.rectangle("fill", 10, 10, 150, 200)
        love.graphics.setColor(0, 255, 255)
        local displayText = "Name: " .. selectedPlanet.hostname .. "\n"
        for k, v in pairs(selectedPlanet) do
            if k ~= "hostname" and type(v) ~= "table" then
                displayText = displayText .. k .. ": " .. tostring(v) .. "\n"
            end
        end
        love.graphics.printf(displayText, 20, 20, 130, "left")

        -- Separate drawing for nested tables
        if selectedPlanet.meta and selectedPlanet.meta.values and selectedPlanet.meta.values.ports then
            printNestedTable(selectedPlanet.meta.values.ports, 200, 10, 150)
        end
        love.graphics.setColor(1, 1, 1)
    end

    -- Context menu
    if isContextMenuOpen then
    local menuWidth, menuHeight = 300, 100
    local startX, startY = (love.graphics.getWidth() - menuWidth) / 2, love.graphics.getHeight() - menuHeight - 10

    -- Draw the menu background
    love.graphics.setColor(0, 255, 255, 0.7)
    love.graphics.rectangle("fill", startX, startY, menuWidth, menuHeight)

    -- Draw the options
    for i, option in ipairs(contextMenuOptions) do
        if i == selectedOptionIndex then
            love.graphics.setColor(1, 0, 0)  -- Highlight selected option
        else
            love.graphics.setColor(1, 1, 1)  -- White for non-selected options
        end
        love.graphics.print(option, startX + 10, startY + i * 20)
    end
end

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

end




