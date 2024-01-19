local metasploit = require("metasploit")
local authenticate = require("auth")

local DropdownMenu = require("DropdownMenu")
local enumDropdownMenus = {}

local currentSelection = 1
local inDropdown = false
local currentDropdownSelection = 1

local isEditing = false



-- track states
local State = {
    NAVIGATING_EXPLOITS = 1,
    NAVIGATING_OPTIONS = 2,
    EDITING_OPTION = 3
}

local stateStack = {}

function changeState(newState)
    if currentState ~= newState then
        table.insert(stateStack, currentState)
        currentState = newState
    end
end

function goBack()
    if #stateStack > 0 then
        currentState = table.remove(stateStack)
    else
        currentState = State.NAVIGATING_EXPLOITS -- default or initial state
    end
end





local ui_data = {
    name = "",
    description = "",
    references = {},
    options = {}
}

ui_data.editing = {
    active = false,
    type = nil,
    key = nil
}


local currentState = State.NAVIGATING_EXPLOITS

-- Pagination
local itemsPerPage = 9
local currentPage = 1
local totalPages
local allExploits = {} -- Store all exploits here
local menuItems = {} -- Items for the current page
local rows = 9
local cols = 1
local cellWidth = 100
local cellHeight = 50
local selectedItem = 1

-- Pagination variables
local moduleInfoLinesPerPage = 20 -- Set the number of lines you want to display per page
local currentModuleInfoPage = 1
local totalModuleInfoPages = 1

function clearOptions()
    ui_data.options = {}
    ui_data.optionKeys = {}
end

-- Function to calculate the total number of pages
function calculateTotalPages(module_info, linesPerPage)
    local lineCount = 0
    for category, data in pairs(module_info) do
        if type(data) == "table" then
            lineCount = lineCount + 1 -- for the category header
            for _, value in pairs(data) do
                lineCount = lineCount + 1 -- each subitem
            end
        else
            lineCount = lineCount + 1
        end

    end
    return math.ceil(lineCount / linesPerPage)
end

function countTableEntries(t)
    local count = 1 -- Count the table itself
    for k, v in pairs(t) do
        if type(v) == "table" then
            count = count + countTableEntries(v) --
        else
            count = count + 1
        end
    end
    return count
end
-- cut leading whitespace 
function trim(s)
    return (s:gsub("^%s*(.-)%s*$", "%1"))
end

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

function loadExploitsFromFile(filename)
    if love.filesystem.getInfo(filename) then
        for line in love.filesystem.lines(filename) do
            local name, module_type, full_module_name = line:match("([^,]+),([^,]+),([^,]+)")
            table.insert(allExploits, {
                name = name,
                module_type = module_type,
                full_module_name = full_module_name
            })
        end
    end
    totalPages = math.ceil(#allExploits / itemsPerPage)
end

function populateMenuItems()
    local startItem = (currentPage - 1) * itemsPerPage + 1
    local endItem = math.min(startItem + itemsPerPage - 1, #allExploits)
    menuItems = {}
    for i = startItem, endItem do
        table.insert(menuItems, allExploits[i])
    end
end

-----------------------------------------------------------------------------------------------------------------------
-- Adjusts the scroll offset based on navigation
function adjustScrollOffset(direction)
    if direction > 0 and selectedOptionIndex > scrollOffset + maxOptionsOnScreen then
        scrollOffset = scrollOffset + 1
    elseif direction < 0 and selectedOptionIndex < scrollOffset + 1 then
        scrollOffset = scrollOffset - 1
    end
end

-- Adjusts the value of the selected option
function adjustOptionValue(direction)
    local optionKeys = getOptionKeys()
    local currentOptionKey = optionKeys[selectedOptionIndex]
    local currentOption = ui_data.options[currentOptionKey]

    if currentOption.type == "number" then
        currentOption.value = currentOption.value + direction
        -- Add boundary checks if needed
    end
    -- Update the ui_data table with the new value
    ui_data.options[currentOptionKey] = currentOption
end

function getOptionKeys()
    local keys = {}
    for k in pairs(ui_data.options) do
        table.insert(keys, k)
    end
    table.sort(keys) -- Sort the keys to ensure consistent navigation order
    return keys
end

for k, v in pairs(ui_data.options) do
    print("OPTIONS: ", k, v)
end

function table.indexOf(tab, val)
    for index, value in ipairs(tab) do

        if value == val then
            return index
        end
    end
    return nil

end

----------------------------------------------------------------------------------

-- UI state variables
local selectedOptionIndex = 1
local scrollOffset = 0
local maxOptionsOnScreen = 10
-- Helper function to get the number of options for navigation purposes
function getOptionCount()
    local count = 0
    for _ in pairs(ui_data.options) do
        count = count + 1
    end
    return count
end

-- Adjusts the scroll offset based on navigation
function adjustScrollOffset(direction)
    if direction > 0 and selectedOptionIndex > scrollOffset + maxOptionsOnScreen then
        scrollOffset = scrollOffset + 1
    elseif direction < 0 and selectedOptionIndex < scrollOffset + 1 then
        scrollOffset = scrollOffset - 1
    end
end

function getOptionKeys()
    local keys = {}
    for k in pairs(ui_data.options) do
        table.insert(keys, k)
    end
    table.sort(keys) -- Sort the keys to ensure consistent navigation order
    return keys
end

for k, v in pairs(ui_data.options) do
    print("OPTIONS: ", k, v)
end

function table.indexOf(tab, val)
    for index, value in ipairs(tab) do

        if value == val then
            return index
        end
    end
    return nil

end

-- Helper function to get the number of options for navigation purposes
function getOptionCount()
    local count = 0
    for _ in pairs(ui_data.options) do
        count = count + 1
    end
    return count
end

-- Helper function to adjust values of the currently selected option
function adjustOptionValue(direction)
    local optionKeys = {} -- We will store the keys here to access them by index
    for k in pairs(ui_data.options) do
        table.insert(optionKeys, k)
    end

    local currentOptionKey = optionKeys[selectedOptionIndex]
    local currentOption = ui_data.options[currentOptionKey]

    if currentOption.type == "number" then
        currentOption.value = currentOption.value + direction
        -- Add boundary checks if needed, for example:
        -- currentOption.value = math.max(math.min(currentOption.value, maxValue), minValue)
    elseif currentOption.type == "bool" then
        currentOption.value = not currentOption.value
    elseif currentOption.type == "enum" then
        -- This assumes enums are stored as a list of strings in an 'enums' field
        local currentIndex = table.indexOf(currentOption.enums, currentOption.value)
        currentIndex = currentIndex + direction
        if currentIndex > #currentOption.enums then
            currentIndex = 1
        end -- Wrap around to the start
        if currentIndex < 1 then
            currentIndex = #currentOption.enums
        end -- Wrap around to the end
        currentOption.value = currentOption.enums[currentIndex]
    end

    -- Update the ui_data table with the new value
    ui_data.options[currentOptionKey] = currentOption
end

-- Toggles boolean options or cycles through enums
function toggleOrSelectOption()
    local optionKeys = getOptionKeys()
    local currentOptionKey = optionKeys[selectedOptionIndex]
    local currentOption = ui_data.options[currentOptionKey]

    if currentOption.type == "bool" then
        currentOption.value = not currentOption.value
    elseif currentOption.type == "enum" then
        -- Ensure the 'enums' field is structured as expected
        local enumValues = getEnumValues(currentOption)
        if enumValues then
            local currentIndex = table.indexOf(enumValues, currentOption.value)
            local nextIndex = currentIndex and ((currentIndex % #enumValues) + 1) or 1
            currentOption.value = enumValues[nextIndex]
        else
            print("Error: 'enums' field is not structured correctly for the option: " .. currentOptionKey)
        end
    else
        -- If current option is not a bool or an enum, do nothing or handle error
        print("Option is not a boolean or an enum.")
    end
    -- Update the ui_data table with the new value
    ui_data.options[currentOptionKey].value = currentOption.value
end

-- Helper function to extract enum values from the currentOption
function getEnumValues(currentOption)
    if currentOption.enums and type(currentOption.enums) == "table" then
        -- Convert enums from a numerical index table to a list if necessary
        local enumValues = {}
        for _, value in pairs(currentOption.enums) do
            table.insert(enumValues, value)
        end
        return enumValues
    end
    return nil
end

-- Helper function to find the index of a value in a table

-----------------------------------------------------------------------------------------------------------------------

-- Define option handlers for different types within 'options'

local optionHandler = {
    integer = function(key, option, action)
        if action == "edit" then
            -- Assuming you have a way to input numbers
            --   option.value = tonumber(inputNumber()) or option.value
        end
    end,
    string = function(key, option, action)
        if action == "edit" then
            -- Assuming you have a way to input text
            --    option.value = inputText() or option.value
        end
    end,
    bool = function(key, option, action)
        if action == "edit" then
            option.value = not option.value -- Toggle the boolean value
        end
    end,
    enum = function(key, option, action)
        if action == "edit" then

            DropdownMenu.load(option.value, 300, 300) -- Adjust x, y as needed
        end
    end
    -- Add more handlers for other types like 'port', 'address', etc.
}

local topLevelHandlers = {

    authors = function(value)
        -- Handle authors
    end,
    platform = function(value)
        -- Handle platform
    end,
    targets = function(value)
        -- Handle targets
    end,
    arch = function(value)
        -- Handle architecture
    end
    -- Add handlers for other known keys as necessary
}

topLevelHandlers.options = function(options)
    for key, option in pairs(options) do
        -- Populate the ui_data.options
        ui_data.options[key] = {
            key = key, -- Store the key here
            type = option.type,
            value = option.default, -- Assuming there is a 'default' field
            desc = option.desc, -- Assuming there is a 'desc' field
            required = option.required, -- Assuming there is a 'required' field
            advanced = option.advanced, -- Assuming there is an 'advanced' field
            enums = option.enums -- Store enums if available
        }
        ui_data.optionKeys = {}
        for key, _ in pairs(ui_data.options) do
            table.insert(ui_data.optionKeys, key)
        end
        -- Call the handler for the specific option type
        local handler = optionHandler[option.type]
        if handler then
            handler(key, ui_data.options[key])
        else
            print("No handler for option type:", option.type)
        end
    end
end

-- Example handler implementations
topLevelHandlers.references = function(references)
    ui_data.references = {}
    for i, ref in pairs(references) do
        -- print(ui_data.references, i, ref)
    end
    -- Process and store the references in a suitable format for the UI
    ui_data.references = references
end

topLevelHandlers.authors = function(authors)
    -- Process and store the authors in a suitable format for the UI
    ui_data.authors = authors
end

topLevelHandlers.platform = function(platform)
    -- Process and store the platform in a suitable format for the UI
    ui_data.platform = platform
end

-- ... Additional handlers for rank, fullname, default_target, etc.

-- Utility function to get the number of options
function getNumberOfOptions()
    local count = 0
    for _ in pairs(ui_data.options) do
        count = count + 1
    end
    return count
end

-- Process each top-level item with the appropriate handler
function processModuleInfo(module_info)
    for key, value in pairs(module_info) do
        local handler = topLevelHandlers[key]
        if handler then
            handler(value)
        else
            -- If there is no specific handler, you might just assign the value directly,
            -- or handle it as a generic case, or log that it's not handled.
            ui_data[key] = value
        end
    end
    print("Number of options:", #ui_data.options)
    print(type("print", ui_data.options))
    for k, v in pairs(ui_data.options) do
        print(k, v)
    end
end

----------------------------------------------------------------------------------
-- ;) 

-- Function to collect and return configured options
local function getPreparedOptions()
    local preparedOptions = {}
    for key, option in pairs(ui_data.options) do
        preparedOptions[key] = option.value
    end
    return preparedOptions
end

-- Function to execute a selected module with configured options
local function executeModule()
    local url = "http://localhost:55552/api/1.0"
    local username = "msf"
    local password = "badpass"
    local token = authenticate(url, username, password)

    -- Assuming 'selectedItem' holds the selected module information
    local module_type = menuItems[selectedItem].module_type
    local module_name = menuItems[selectedItem].full_module_name
    local options = getPreparedOptions()

    -- Execute the module
    local execution_result = metasploit.module_execute(url, token, module_type, module_name, options)
    print("Execution Result:")
end
----------------------------------------------------------------------------------

function love.load()
    -- Initialize menu items
    love.graphics.setFont(love.graphics.newFont(14)) -- Set the font size for drawing text
    loadExploitsFromFile("exploit_names.txt")
    populateMenuItems()
end

function love.update(dt)
    -- Update logic (if any)

end

function getColumnOfSelectedItem(selectedItem, cols)
    return (selectedItem - 1) % cols + 1
end

function getNextPage(currentPage, itemsPerPage)
    local newPage = currentPage + 1
    local newSelectedItem = (newPage - 1) * itemsPerPage + 1
    return newPage, newSelectedItem
end

function resetToFirstPage()
    return 1, 1
end

function getPreviousPage(currentPage, itemsPerPage, cols)
    local newPage = currentPage - 1
    local newSelectedItem = newPage * itemsPerPage - (cols - 1)
    return newPage, newSelectedItem
end

function resetToLastPage(totalPages, totalItems, cols)
    local newPage = totalPages
    local newSelectedItem = totalItems - (cols - 1)
    return newPage, newSelectedItem
end

function isItemInCurrentPage(itemIndex, currentPage, itemsPerPage, totalItems)
    local startIndex = (currentPage - 1) * itemsPerPage + 1
    local endIndex = math.min(startIndex + itemsPerPage - 1, totalItems)
    return itemIndex >= startIndex and itemIndex <= endIndex
end

function navigateRight()
    if selectedItem < #menuItems then
        selectedItem = selectedItem + 1
    elseif currentPage < totalPages then
        currentPage = currentPage + 1
        selectedItem = 1
        populateMenuItems() -- Repopulate menu items for the new page
    end
end

function navigateLeft()
    if selectedItem > 1 then
        selectedItem = selectedItem - 1
    elseif currentPage > 1 then
        currentPage = currentPage - 1
        selectedItem = itemsPerPage -- Set to the last item of the previous page
        populateMenuItems() -- Repopulate menu items for the new page
    end
end

function navigateDown()
    local potentialNextItem = selectedItem + cols
    -- Check if the potential next item is still on the current page
    if potentialNextItem <= #menuItems then
        selectedItem = potentialNextItem
    end
    -- If the potential next item would go past the end of the list, loop back to the top
    if potentialNextItem > itemsPerPage then
        selectedItem = selectedItem - itemsPerPage
    end
end

function navigateUp()
    local potentialPrevItem = selectedItem - cols
    -- Check if the potential previous item is still on the current page
    if potentialPrevItem >= 1 then
        selectedItem = potentialPrevItem
    end
    -- If the potential previous item would go before the start of the list, loop to the bottom
    if potentialPrevItem < 1 then
        selectedItem = selectedItem + itemsPerPage
        if selectedItem > #menuItems then
            selectedItem = #menuItems
        end
    end
end

function loadModuleInfo()
    local url = "http://localhost:55552/api/1.0"
    local username = "msf"
    local password = "badpass"

    -- Authenticate and get the token for msfprcd
    local token = authenticate(url, username, password)

    -- Retrieve exploit info
    local exploits = metasploit.get_exploits(url, token)

    print("Exploits:")

    -- Get information about a specific module
    local module_type = "exploit"
    local module_name = trim(menuItems[selectedItem].full_module_name)

    local unpacked_info = metasploit.get_module_info(url, token, module_type, module_name)
    print("Module Info for " .. module_name .. ":")
    module_info = walk_table(unpacked_info)
    totalModuleInfoPages = calculateTotalPages(module_info, moduleInfoLinesPerPage)
    clearOptions()
    processModuleInfo(module_info)

    print("Module Info for " .. module_name .. ":")
    walk_table(module_info)
end


function love.keypressed(key)
    if currentState == State.NAVIGATING_EXPLOITS then
        if key == "right" then
            navigateRight()
        elseif key == "left" then
            navigateLeft()
        elseif key == "a" then
            loadModuleInfo()
            currentState = State.NAVIGATING_OPTIONS
        elseif key == "b" then
            -- Return to a default or initial state
            currentState = State.NAVIGATING_EXPLOITS
        end
    elseif currentState == State.NAVIGATING_OPTIONS then
        if key == "up" then
            selectedOptionIndex = math.max(selectedOptionIndex - 1, 1)
            adjustScrollOffset(-1)
        elseif key == "down" then
            selectedOptionIndex = math.min(selectedOptionIndex + 1, getOptionCount())
            adjustScrollOffset(1)
        elseif key == "a" then
            local optionKeys = getOptionKeys()
            local currentOptionKey = optionKeys[selectedOptionIndex]
            local currentOption = ui_data.options[currentOptionKey]

            if currentOption.type == "enum" then
                DropdownMenu.load(currentOption.enums, 300, 300) -- Load dropdown with enum options
                currentState = State.EDITING_OPTION
            else
                -- Handle other types of options
                local handler = optionHandler[currentOption.type]
                if handler then
                    handler(currentOptionKey, currentOption, "edit")
                end
            end
        elseif key == "b" then
            currentState = State.NAVIGATING_EXPLOITS
        end

    elseif currentState == State.EDITING_OPTION then
        local optionKeys = getOptionKeys()
        local currentOptionKey = optionKeys[selectedOptionIndex]
        local currentOption = ui_data.options[currentOptionKey]

        if currentOption.type == "enum" then
            DropdownMenu.keypressed(key)
            if key == "a" and DropdownMenu.menu.isOpen then
                -- Save the selected enum value when the menu is open and 'a' is pressed
                currentOption.value = currentOption.enums[DropdownMenu.menu.selectedItem]
                currentState = State.NAVIGATING_OPTIONS
            end
        end

        if key == "b" then
            currentState = State.NAVIGATING_OPTIONS
        end
    end
end


-- The love.draw function remains mostly the same,
-- but we need to ensure the startIndex and endIndex are calculated correctly.

function love.draw()

    local startX = 20 -- X position where the drawing starts
    local startY = 20 -- Y position where the drawing starts
    local lineHeight = 20 -- Height of each line of text

    love.graphics.setColor(1, 1, 1) -- set color to white
    love.graphics.setBackgroundColor(0.16, 0.16, 0.16) -- dark grey background

    -- Set a base Y position for drawing text
    local y = 20
    local x = 20
    local valueColumnX = 400 -- X position for the changeable values

    -- Draw the module information
    love.graphics.print("Module: " .. (ui_data.name or "N/A"), x, y)
    y = y + lineHeight -- Increment y to draw the next item lower on the screen

    love.graphics.print("Description: " .. (ui_data.description or "N/A"), x, y)
    y = y + lineHeight

    -- Draw the authors
    love.graphics.print("Authors:", x, y)
    y = y + lineHeight
    for _, author in ipairs(ui_data.authors or {}) do
        love.graphics.print(author, x + 20, y)
        y = y + lineHeight
    end

    -- Draw the references
    love.graphics.print("References:", x, y)
    y = y + lineHeight
    for _, ref in pairs(ui_data.references or {}) do
        love.graphics.print(ref, x + 20, y)
        y = y + lineHeight
    end

    -- Determine the number of items in the last row for proper centering
    local itemsInLastRow = #menuItems % cols
    if itemsInLastRow == 0 and #menuItems > 0 then
        itemsInLastRow = cols -- If the last row is full, we use the maximum number of columns
    end

    -- Calculate the starting position for the grid based on the number of items in the last row
    local gridStartX = (love.graphics.getWidth() + love.graphics.getWidth() - 100 - itemsInLastRow * cellWidth) / 2
    local gridStartY = love.graphics.getHeight() - 100 - (rows * cellHeight)

    -- Draw each menu item for the current page
    for i, item in ipairs(menuItems) do
        local col = ((i - 1) % cols) + 1
        local row = math.floor((i - 1) / cols) + 1
        local x = gridStartX + (col - 1) * cellWidth
        local y = gridStartY + (row - 1) * cellHeight

        -- Set the color for the selected or unselected item
        love.graphics.setColor(i == selectedItem and {1, 0, 0} or {0, 1, 1})
        love.graphics.rectangle("fill", x, y, cellWidth, cellHeight)

        -- Set the color for the text and print the item's name
        love.graphics.setColor(0, 0, 0)
        love.graphics.print(item.name, x + 10, y + cellHeight / 2 - 7)
    end

    -- If an item is selected, display its name above the page information
    if selectedItem and menuItems[selectedItem] then
        local selectedItemName = menuItems[selectedItem].full_module_name
        local selectedItemType = menuItems[selectedItem].module_type
        love.graphics.print(selectedItemName, pageInfoX, gridStartY - 40)
    end

    local baseY = 100
    local optionKeys = getOptionKeys()
    for i, optionKey in ipairs(optionKeys) do
        local optionData = ui_data.options[optionKey]
        if i > scrollOffset and i <= scrollOffset + maxOptionsOnScreen then
            local y = baseY + (i - scrollOffset - 1) * 20
            love.graphics.rectangle("line", 50, y + 225, 200, 20)
            local displayText = optionKey
            local optionValue = tostring(optionData.value) or "No description available" -- Corrected line
            love.graphics.setColor(0, 255, 0)
            love.graphics.print(displayText, 60, y + 225)
            love.graphics.print(optionValue, 255, y + 225) -- Corrected line

            -- Highlight selected option
            if i == selectedOptionIndex then
                love.graphics.setColor(1, 1, 255)
                love.graphics.rectangle("line", 50, y + 225, 200, 20)
            end
            love.graphics.setColor(0, 255, 255)
        end
    end

    -- If an option is selected, draw its value and description in a dedicated column
    if selectedOptionIndex and optionKeys[selectedOptionIndex] then
        local selectedOptionKey = optionKeys[selectedOptionIndex]
        local selectedOptionData = ui_data.options[selectedOptionKey]

        -- Draw the selected option's value and description
        local optionValueText = selectedOptionKey .. ": " .. tostring(selectedOptionData.value)
        local optionDescriptionText = selectedOptionData.desc or "No description available"
        local windowWidth = love.graphics.getWidth()
        local font = love.graphics.getFont()
        local optionValueWidth = font:getWidth(optionValueText)
        local optionDescriptionWidth = font:getWidth(optionDescriptionText)

        -- Calculate X positions for value and description to be centered
        local optionValueX = (windowWidth - optionValueWidth) / 2
        local optionDescriptionX = (windowWidth - optionDescriptionWidth) / 2

        -- Calculate Y position for value and description
        local optionValueY = love.graphics.getHeight() / 2
        local optionDescriptionY = love.graphics.getHeight() / 2 + 20

        -- Draw the value and description
        love.graphics.print(optionValueText, optionValueX, optionValueY - 50)
        love.graphics.print(optionDescriptionText, optionDescriptionX, optionDescriptionY - 50)
    end
    if currentState == State.EDITING_OPTION then
        local currentOption = ui_data.options[getOptionKeys()[selectedOptionIndex]]
        if currentOption.type == "enum" then
            DropdownMenu.draw() -- Draw the DropdownMenu for enum options
        end
    end


end
