-- No matter where you go, everyone's conneted. -- Lain Iwakura; Serial Experiments Lain
-- Do not, under any circumstances, depend on a partial feeling. -- Miyaoto Musashi

-- Hack the planet
-- just one more line for good measure  

local http = require("socket.http")
local ltn12 = require("ltn12")
local json = require("dkjson")

local metasploit = require("metasploit")
local authenticate = require("auth")

local url = "http://localhost:55552/api/1.0"
local username = "msf"
local password = "badpass"

-- Authenticate and get the token
local token = authenticate(url, username, password)

local BettercapAPI = require("BettercapAPI")
local api = require("BettercapAPI"):new("localhost", 8081, "pakemon", "pakemon")

local useDatabase = false
local useActive = true

local messageWindowTimer = 0
local messageWindow = {}
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

-- for navigation 
function updateSelectedPlanet()
    if planets and selectedPlanetIndex then
        selectedPlanet = planets[selectedPlanetIndex]
        -- Populate nestedTables based on selectedPlanet
        nestedTables = {}  -- Reset nestedTables
        if selectedPlanet.meta and selectedPlanet.meta.values then
            for key, _ in pairs(selectedPlanet.meta.values) do
                table.insert(nestedTables, key)
            end
        end
    else
        selectedPlanet = nil
    end
end

function updateMessage(newMessage)
    messageWindow.message = newMessage
    messageWindowTimer = 6 
end

local messageWindow = {
    x = 0,
    y = 0,
    width = 400,
    height = 200,
    message = "Welcome to the Message Window!",
}
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

    -- Load the sprite/background
    sunSprite = love.graphics.newImage("assets/sun.png")
    planetSprite = love.graphics.newImage("assets/planet.png")
    background = love.graphics.newImage("assets/background.png")
    -- music 
    music = love.audio.newSource("assets/music.mp3", "stream")    
    
        -- Define the sun's position
    sunX, sunY = love.graphics.getWidth() / 2, love.graphics.getHeight() / 2
    
    -- Adjust sun placement because i'm lazy and suck at maths
    sunX = sunX + 240
    sunY = sunY - 140

    -- Initialize variables for cycling display
    displayStartIndex = 1
    maxDisplayCount = 6
    
    -- planets orbit if true
    isOrbiting = true

    -- Initialize selected planet index
    selectedPlanetIndex = 1

    planetInfo = false

    messageWindow.x = (love.graphics.getWidth() - messageWindow.width) / 2
    messageWindow.y = (love.graphics.getHeight() - messageWindow.height) / 2
	updateMessage(commandResponseText)
end

function love.update(dt)

--  DEBUG STUFF
    require("lovebird").update()	
    require("lurker").update() -- breaks UI placement sometimes?       
--  END DEBUG STUFF

    -- main start of update func
    if not music:isPlaying( ) then
        love.audio.play( music )
    end
    
    if messageWindowTimer > 0 then
        messageWindowTimer = messageWindowTimer - dt
        if messageWindowTimer <= 0 then
            messageWindow.message = ""  -- Clear the message when timer runs out
        end
    end

    -- this should be built outside of update and ran as func to clean
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

-- Game states
local MAIN_STATE = "main"
local PLANET_SELECTION_STATE = "planet_selection"
local CONTEXT_MENU_STATE = "context_menu"
local PLANET_DETAILS_STATE = "planet_details"
-- Current state
local gameState = MAIN_STATE

-- Menu and selection variables
local selectedPlanetIndex = 1  -- Default selected planet index

local planetInfo = false
local currentTableIndex = 1
local currentItemIndex = 1
-- local nestedTables = {}  -- List of nested table names

local displayStartIndex = 1
local maxDisplayCount = 6

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
    planetInfo = not planetInfo
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
    if gameState == MAIN_STATE then
        if key == 'a' then
            gameState = PLANET_SELECTION_STATE
        end
        -- Handle other main state keys (up, down, left, right) here
    elseif gameState == PLANET_SELECTION_STATE then
        if key == 'up' then
            -- Navigate through planets
            selectedPlanetIndex = selectedPlanetIndex - 1
            if selectedPlanetIndex < 1 then selectedPlanetIndex = #planets end
        elseif key == 'down' then
            selectedPlanetIndex = selectedPlanetIndex + 1
            if selectedPlanetIndex > #planets then selectedPlanetIndex = 1 end
        elseif key == 'a' then
            gameState = PLANET_DETAILS_STATE
            displayInfo = true
        elseif key == 'b' then
            gameState = MAIN_STATE
        end
    elseif gameState == PLANET_DETAILS_STATE then
        if key == 'a' then
            gameState = CONTEXT_MENU_STATE
            isContextMenuOpen = true
        elseif key == 'b' then
            gameState = PLANET_SELECTION_STATE
        end
    elseif gameState == CONTEXT_MENU_STATE then
        if key == 'up' then
            selectedOptionIndex = selectedOptionIndex - 1
            if selectedOptionIndex < 1 then selectedOptionIndex = #contextMenuOptions end
        elseif key == 'down' then
            selectedOptionIndex = selectedOptionIndex + 1
            if selectedOptionIndex > #contextMenuOptions then selectedOptionIndex = 1 end
        elseif key == 'a' then
            -- Execute context menu action here
            executeContextMenuOption(selectedOptionIndex)
            isContextMenuOpen = false
            gameState = MAIN_STATE
        elseif key == 'b' then
            gameState = PLANET_DETAILS_STATE
            isContextMenuOpen = false
        end
    end
end

function drawDetailsBox(selectedPlanet)
    if not selectedPlanet then
        return
    end

    -- Define box dimensions and position
    local boxWidth, boxHeight = 300, 150
    local boxX, boxY = 10, 10  -- Top left corner

    -- Draw the details box
    love.graphics.setColor(0, 0, 0, 0.7)  -- Semi-transparent black for background
    love.graphics.rectangle("fill", boxX, boxY, boxWidth, boxHeight)

    -- Set text color to cyan and prepare text details
    love.graphics.setColor(0, 255, 255)  -- Cyan color for text
    local textDetails = "Planet Details:\n"
    textDetails = textDetails .. "Name: " .. tostring(selectedPlanet.hostname) .. "\n"
    textDetails = textDetails .. "IP: " .. tostring(selectedPlanet.ipv4) .. "\n"
    -- Add more details as needed

    -- Draw the text
    love.graphics.print(textDetails, boxX + 10, boxY + 10)

    -- Draw line from planet to box
    local planetX, planetY = calculateEllipticalOrbit(selectedPlanet.semiMajorAxis, selectedPlanet.eccentricity, selectedPlanet.angle, 335)
    planetX, planetY = sunX + planetX, sunY + planetY
    love.graphics.line(planetX, planetY, boxX, boxY + boxHeight)
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

function getPlanetCoordinates(ipAddress)
    for _, planet in ipairs(planets) do
        if planet.ipv4 == ipAddress then
            local x, y = calculateEllipticalOrbit(planet.semiMajorAxis, planet.eccentricity, planet.angle, 335)
            return sunX + x, sunY + y
        end
    end
    return nil, nil  -- IP address not found among planets
end

function love.draw()
	love.graphics.draw(background)
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
    love.graphics.draw(sunSprite, sunX - sunSprite:getHeight() / 16 , sunY - sunSprite:getWidth() / 16, 0, .1, .1)

    -- Draw planets and satellites
    for i = displayStartIndex, endIndex do
        local planet = planets[i]
        local planetX, planetY = calculateEllipticalOrbit(planet.semiMajorAxis, planet.eccentricity, planet.angle, 335)
        love.graphics.draw(planetSprite, sunX + planetX, sunY + planetY, 0, 0.1, 0.1, planetSprite:getWidth() / 2, planetSprite:getHeight() / 2)
        local textX = sunX + planetX - planetSprite:getWidth() + 296  -- text placemnet for hostname to follow planets orbit 
        local textY = sunY + planetY - planetSprite:getHeight() / 6 + 30
        love.graphics.print(planet.hostname, textX, textY)

        -- place to draw connected planet/hosts??b

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

    -- PLANET_SELECTION_STATE: Highlight the selected planet
    if gameState == PLANET_SELECTION_STATE then
        local selectedPlanet = planets[selectedPlanetIndex]
        local x, y = calculateEllipticalOrbit(selectedPlanet.semiMajorAxis, selectedPlanet.eccentricity, selectedPlanet.angle, 335)
        love.graphics.setColor(0, 255, 255) -- Cyan color for highlighting
        love.graphics.rectangle("line", sunX + x, sunY + y, 30, 30) -- Draw a rectangle around the selected planet
        love.graphics.setColor(1, 1, 1) -- Reset color to white
    end

    -- PLANET_DETAILS_STATE: Display details of the selected planet
    if gameState == PLANET_DETAILS_STATE and planets and selectedPlanetIndex and planets[selectedPlanetIndex] then
        local selectedPlanet = planets[selectedPlanetIndex]
        drawDetailsBox(selectedPlanet)
        -- Additional code for drawing details if needed...
    end

    -- CONTEXT_MENU_STATE: Context menu
    if gameState == CONTEXT_MENU_STATE and isContextMenuOpen then
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
end
