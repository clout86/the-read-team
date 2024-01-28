Talkies = require("lib.talkies")
Camera = require("lib.camera")
camera = Camera(love.graphics.getWidth() / 2, love.graphics.getHeight() / 2)

-- custom lua deps
metasploit = require("lib.metasploit")
authenticate = require("lib.auth")
-- navi_ui = require("ui.navi_ui.navi_ui")
bettercap_ui = require("ui.bettercap_ui.bettercap_ui")
msfMenu = require("ui.msfMenu.msfMenu")

local GridMenu = require("GridMenu")
local OptionsMenu = require("OptionsMenu")
local launcher = require("launcher")

url = "http://localhost:55552/api/1.0"
username = "pakemon"
password = "pakemon"

-- Authenticate and get the token for msfrpcd
token = authenticate(url, username, password)

BettercapAPI = require("lib.BettercapAPI")
api = require("lib.BettercapAPI"):new("localhost", 8081, "pakemon", "pakemon")

uiElements = {}
planets = {}

-- local navigationRails = {
--     ["mainMenu"] = { up = nil, down = "optionsMenu", left = nil, right = nil },
--     ["optionsMenu"] = { up = "mainMenu", down = "detailsMenu", left = nil, right = "settingsMenu" },
--     -- Add other UI elements as necessary
-- }
------------------
local useDatabase = false
local useActive = true
local runActive

local module_info

-- Pagination variables
local moduleInfoLinesPerPage = 20 -- Set the number of lines you want to display per page
local currentModuleInfoPage = 1
local totalModuleInfoPages = 1

-- UI state variables
local selectedOptionIndex = 1
local scrollOffset = 0
local maxOptionsOnScreen = 10
-- Helper function to get the number of options for navigation purposes

local networkDataTimer = 0
local networkDataFetchInterval = 5 -- Fetch data every 5 seconds

-- inital focus state
-- local uiElements = SHIP

-- Variables to maintain the UI state
local focusedIndex = 1 -- Default focus on the first UI element
-- currentState = "rena"

-- -- set focus state management 
-- uiElements = {
--     SHIP = "ship",
--     NAVI = "launcher",
--     NAVI_DETAILS = "navi_details",
--     NAVIGATING_GRIMOIRE = "grimoire",
--     BETTERCAP_DIALOG = "bc_dialog",
--     MSF_DIALOG = "msf_dialog",
--     OPTIONS_MENU = "options_menu",
--     EDIT_OPTION = "edit_option",
--     INPUT_MODE = "input_mode"
--     -- ... other states
-- }
uiElements = {}

-- Menu and selection variables
local selectedPlanetIndex = 1 -- Default selected planet index

local planetInfo = false
local currentTableIndex = 1
local currentItemIndex = 1

local displayStartIndex = 1
local maxDisplayCount = 100

local selectedOptionIndex = 1

-- This function will create a nested table from the given table t
function walk_table(t, depth)
    local result = {}
    depth = depth or 0

    -- Avoid going too deep into nested tables
    if depth > 5 then
        return "..."
    end

    for k, v in pairs(t) do
        if type(v) == "table" then
            -- Recursively process nested tables
            result[k] = walk_table(v, depth + 1)
        else
            -- Directly assign non-table values
            result[k] = v
        end
    end
    return result
end

function loadModules(directory)
    local files = love.filesystem.getDirectoryItems(directory)
    for _, file in ipairs(files) do
        local folderPath = directory .. file
        if love.filesystem.getInfo(folderPath, "directory") then
            -- The module name is the same as the folder name
            local modulePath = folderPath .. "/" .. file
            if love.filesystem.getInfo(modulePath .. ".lua") then
                print("Loading module:", modulePath) -- Debug print
                local uiModule = require(modulePath)
                table.insert(uiElements, uiModule)
            end
        end
    end
end

function love.load()
    GridMenu.loadGilmore("exploit_names.txt")
    GridMenu.populateMenuItems()

    msfMenu.load()

    launcher.load()

    loadModules("ui/")

    navi_ui.ship = {
        x = love.graphics.getWidth() / 2,
        y = love.graphics.getHeight() / 2,
        speed = 200, -- pixels per second
        image = nil
    }

    navi_ui.ui_data = {
        name = "",
        description = "",
        references = {},
        options = {}
    }

    -- for editing options return. 
    navi_ui.ui_data.editing = {
        active = false,
        type = nil,
        key = nil
    }

    networkDataTimer = 0
    networkDataFetchInterval = 5

    -- Initialize or integrate UI elements 
    isOrbiting = true

    -- login to bettercap and walk the lan
    local hosts = navi_ui.fetchLanStructure(api)
    if hosts then
        planets = navi_ui.runActive(hosts, currentPlanets)
    end
    -- Load the sprite/background
    sunSprite = love.graphics.newImage("assets/sun.png")
    planetSprite = love.graphics.newImage("assets/planet.png")
    background = love.graphics.newImage("assets/background.png")
    navi_ui.ship.image = love.graphics.newImage("assets/ship.png")
    -- music 
    music = love.audio.newSource("assets/music.mp3", "stream")

    -- Define the sun's position
    sunX, sunY = love.graphics.getWidth() / 2, love.graphics.getHeight() / 2

    -- -- Adjust sun placement because i'm lazy and suck at maths
    sunX = sunX + 240 -- this should be more dynamic playcement like above
    sunY = sunY - 140

    -- Initialize selected planet index
    selectedPlanetIndex = 1

    planetInfo = true
    bettercap_ui.showMenu()
    -- rena.dialog()

end

function netTimer(dt)
    networkDataTimer = networkDataTimer + dt

    if networkDataTimer >= networkDataFetchInterval then
        local hosts = navi_ui.fetchLanStructure(api)
        if hosts then
            local currentAngles = {}
            local currentPlanets = {} -- Initialize currentPlanets

            for i, planet in ipairs(planets) do
                table.insert(currentPlanets, planet) -- Copy current planets state
                currentAngles[i] = planet.angle
            end
            navi_ui.updatePlanets(currentPlanets) -- Pass currentPlanets to updatePlanets function
            navi_ui.updateSelectedPlanet()
        end
        networkDataTimer = 0 -- Reset the timer
    end
end

function love.update(dt)
  --  msfMenu.update()
    launcher.update(dt)
    --  DEBUG STUFF
    require("lib.lovebird").update()
    --  END DEBUG STUFF
    Talkies.update(dt)
    netTimer(dt)
    -- ship start of update func
    -- if not music:isPlaying() then
    --     --  love.audio.play( music )
    -- end
    navi_ui.shipDeadzone()

    if love.keyboard.isDown('q') then
        camera:zoom(1 + 2 * dt) -- Zoom in
    elseif love.keyboard.isDown('e') then
        camera:zoom(1 - 2 * dt) -- Zoom out
    end

    if uiElements == SHIP then
        if love.keyboard.isDown('up') then
            navi_ui.ship.y = navi_ui.ship.y - navi_ui.ship.speed * dt
        end
        if love.keyboard.isDown('down') then
            navi_ui.ship.y = navi_ui.ship.y + navi_ui.ship.speed * dt
        end
        if love.keyboard.isDown('left') then
            navi_ui.ship.x = navi_ui.ship.x - navi_ui.ship.speed * dt
        end
        if love.keyboard.isDown('right') then
            navi_ui.ship.x = navi_ui.ship.x + navi_ui.ship.speed * dt
        end
    end

    -- if false orbit stops
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

end

function love.keypressed(key)
    if key == "space" then
        Talkies.onAction()
    elseif key == "up" then
        Talkies.prevOption()
    elseif key == "down" then
        Talkies.nextOption()
    end
    -- Navigate between UI elements
    if key == 'left' then
        focusedIndex = math.max(1, focusedIndex - 1)
    elseif key == 'right' then
        focusedIndex = math.min(#uiElements, focusedIndex + 1)
    end

    -- Interact with the focused UI element
    if key == 'tab' then
        local focusedElement = uiElements[focusedIndex]
        if focusedElement and focusedElement.interact then
            focusedElement.interact()
        end
    end

    -- Cancel or go back action
    if key == 'b' then
        -- Implement the logic to handle 'back' action
        -- This might involve changing the game state or closing a menu
    end
    launcher.keypressed(key)
end

-- In your draw function, highlight the focused UI element
function love.draw()
    love.graphics.draw(background)

    love.graphics.print("HAHA")
    for i, element in ipairs(uiElements) do
        if element.draw then
            element.draw()
        else
            print("failed to load " .. uiElements)
        end
    end
    launcher.draw()
    -- msfMenu.draw()
    Talkies.draw()


end
