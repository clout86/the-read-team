launcher = {}

local Navigator = require 'handylib' -- Replace with the path to the handy module
local cursorImage
local moveDelay = 0.2 -- Time in seconds between cursor moves
local lastMoveTime = 0 -- Time since last cursor move

-- Fixed dimensions for buttons
local buttonWidth = 64
local buttonHeight = 64

local totalButtons = 2 -- Total number of buttons
local visibleButtonsCount = 2 -- Number of buttons to display at a time
local currentButtonIndex = 1 -- Index of the first button in the visible set

-- Variables for button positions
local startX, startY

function launcher.load()
    -- Initialize the Navigator instance
    Navigator = Navigator:new()

    -- Load specific button images
    local msfButton = love.graphics.newImage('assets/msfButton.png')
    local bettercapButton = love.graphics.newImage('assets/bettercapButton.png')

    -- Window dimensions
    local windowWidth, windowHeight = love.graphics.getDimensions()

    -- Calculate startX and startY
    startX = windowWidth / 4 - buttonWidth / 2
    startY = windowHeight / 2 - (totalButtons * buttonHeight + (totalButtons - 1) * 10) / 2

    -- Calculate button positions
    local buttonY1 = startY
    local buttonY2 = startY + buttonHeight + 10 -- 10 pixels spacing

    -- Create the buttons with specific images and callbacks
    Navigator:addButton("reneButton", "Rene", startX, buttonY1, {buttonWidth, buttonHeight}, msfButton, function()
        rena.dialog()
    end)

    Navigator:addButton("captainButton", "Captain", startX, buttonY2, {buttonWidth, buttonHeight}, bettercapButton,
        function()
            bettercap_ui.showMenu()
        end)

    -- Load the cursor image
    cursorImage = love.graphics.newImage('assets/pointer.png')
    if not cursorImage then
        error("Failed to load 'assets/pointer.png'")
    end

    -- Initialize the cursor to the first button
    Navigator.cursor = 1
end

function launcher.update(dt)
    lastMoveTime = lastMoveTime + dt

    if lastMoveTime >= moveDelay then
        if love.keyboard.isDown('down') then
            Navigator.cursor = math.min(Navigator.cursor + 1, totalButtons)
            lastMoveTime = 0
        elseif love.keyboard.isDown('up') then
            Navigator.cursor = math.max(Navigator.cursor - 1, 1)
            lastMoveTime = 0
        end
    end
end

function launcher.draw()
    -- Reset color to white (default)
    love.graphics.setColor(1, 1, 1, 1) -- RGBA values range from 0 to 1

    -- Draw buttons
    for i = 1, totalButtons do
        local buttonName = (i == 1) and "reneButton" or "captainButton"
        local btn = Navigator:buttonExists(buttonName)
        if btn then
            love.graphics.draw(btn.image, btn.x, btn.y)
            love.graphics.print(btn.text, btn.x + 20, btn.y + 10)
        else
            print("Button not found:", buttonName)
            -- Draw a rectangle if the button is not found
            love.graphics.rectangle("fill", startX - 100 / 2, startY + (i - 1) * 60, 100, 50)
            love.graphics.print("Button " .. i, startX - 100 / 2 + 20, startY + (i - 1) * 60 + 10)
        end
    end

    -- Draw cursor on the right side of the selected button
    local selectedButton = Navigator:buttonExists("button" .. Navigator.cursor)
    if selectedButton then
        local cursorX = selectedButton.x + buttonWidth + 10 -- 10 pixels space from the right edge of the button
        local cursorY = selectedButton.y
        love.graphics.draw(cursorImage, cursorX, cursorY)
    else
        -- Debug: Draw a rectangle if the cursor position is not found
        local cursorDebugY = startY + (Navigator.cursor - 1) * (buttonHeight + 10)
        love.graphics.rectangle("line", startX + buttonWidth / 2 + 10, cursorDebugY, 20, 20) -- Small square as a cursor placeholder
    end

    -- Draw cursor on the right side of the selected button
    -- local selectedButton = Navigator:buttonExists("button" .. Navigator.cursor)
    -- if selectedButton then
    --     local cursorX = selectedButton.x + selectedButton.size[1] + 10 -- 10 pixels space from the right edge
    --     local cursorY = selectedButton.y
    --     love.graphics.draw(cursorImage, cursorX, cursorY)
    -- else
    --     -- Debug: Draw a rectangle if the cursor position is not found
    --     local cursorDebugY = startY + (Navigator.cursor - 1) * 60
    --     love.graphics.rectangle("line", startX + 50, cursorDebugY, 100, 50) -- Adjusted X for right side
    -- end
end

function launcher.keypressed(key)

    if key == 'a' or key == 'b' then
        Talkies.clearMessages()
        Navigator:callButtonIndex(Navigator.cursor)
    end
end

return launcher
