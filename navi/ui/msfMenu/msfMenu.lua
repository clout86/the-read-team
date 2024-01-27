-- for dialog
local msfMenu = {}

local Talkies = require("lib.talkies")

-- for msfrpcd
local metasploit = require("lib.metasploit")
local authenticate = require("lib.auth")

-- input handlers
local DropdownMenu = require("lib.DropdownMenu")
local keyboard = require("lib.keyboard")
local enumDropdownMenus = {}


-- msfrpcd 
local username = "pakemon"
local password = "pakemon"
local url = "http://localhost:55552/api/1.0"

-- conext of DropdownMenu
local currentSelection = 1
local inDropdown = false
local currentDropdownSelection = 1

-- for option selection
local isEditing = false

-- we should do a state stack instead of the way we handle "(b)ack" in the keypressed function


local module_info
  



 msfMenu.ui_data = {
    name = "",
    description = "",
    references = {},
    options = {}
}

-- for editing options return. 
msfMenu.ui_data.editing = {
    active = false,
    type = nil,
    key = nil
}


-- set state management 
local State = {
    NAVIGATING_EXPLOITS = 1,
    TALKIES_DIALOGUE = 2, -- New state for Talkies dialogue
    NAVIGATING_OPTIONS = 3,
    EDITING_OPTION = 4,
    KEYBOARD_INPUT = 5
    -- ... other states
}

-- set the main state
local currentState = State.NAVIGATING_EXPLOITS
-- Function to push a state onto the stack
function msfMenu.pushState(newState)
    table.insert(stateStack, currentState)
    currentState = newState
end

-- Function to pop a state from the stack
function msfMenu.popState()
    if #stateStack > 0 then
        currentState = table.remove(stateStack)
    end
end


-- Pagination
local itemsPerPage = 9
local currentPage = 1
local totalPages
local allExploits = {} -- Store all exploit infos here
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

-- Define option handlers for different types within 'options'
local optionHandler = {
    integer = function(key, option, action)
        if action == "edit" then
            currentState = State.KEYBOARD_INPUT
            keyboard.inputText = tostring(option.value)
            keyboard.currentIndex = 1
            keyboard.inputPosition = #keyboard.inputText + 1
        end
    end,
    string = function(key, option, action)
        if action == "edit" then
            currentState = State.KEYBOARD_INPUT
            keyboard.inputText = tostring(option.value)
            keyboard.currentIndex = 1
            keyboard.inputPosition = #keyboard.inputText + 1
        end
    end,
    port = function(key, option, action)
        if action == "edit" then
            currentState = State.KEYBOARD_INPUT
            keyboard.inputText = tostring(option.value)
            keyboard.currentIndex = 1
            keyboard.inputPosition = #keyboard.inputText + 1
        end
    end,
    address = function(key, option, action)
        if action == "edit" then
            currentState = State.KEYBOARD_INPUT
            keyboard.inputText = tostring(option.value)
            keyboard.currentIndex = 1
            keyboard.inputPosition = #keyboard.inputText + 1
        end
    end,
    bool = function(key, option, action)
        if action == "edit" then
            option.value = not option.value
        end
    end,
    enum = function(key, option, action)
        if action == "edit" then
            currentState = State.EDITING_OPTION
            DropdownMenu.load(option.enums, 300, 300)
        end
    end
    -- ... other handlers ...
    -- rport
    -- path
}

function msfMenu.clearOptions()
    msfMenu.ui_data.options = {}
    msfMenu.ui_data.optionKeys = {}
end
function msfMenu.tableToString(tbl)
    if type(tbl) ~= "table" then
        return tostring(tbl)  -- Return the string representation of non-tables
    end

    local str = ""
    for k, v in pairs(tbl) do
        if type(v) == "table" then
            str = str .. k .. ": {" .. msfMenu.tableToString(v) .. "}, "
        else
            str = str .. k .. ": " .. tostring(v) .. ", "
        end
    end
    return str
end
----------------------------------------------------------------------------------
-- ;) 
-- Function to collect and return configured options
-- Format options as: [OPTION_NAME] [OPTION]
 function msfMenu.getPreparedOptions()
    local preparedOptions = {}
    for key, option in pairs(msfMenu.ui_data.options) do
        preparedOptions[#preparedOptions + 1] = "[" .. key .. "] " .. option.value
    end
    return preparedOptions
end

-- Function to execute a selected module with configured options
-- This function should be integrated as an option in the main Talkies options under "Set Options".
 function msfMenu.executeModule()
    local url = url or "http://localhost:55552/api/1.0"
    local username = username or "pakemon"
    local password = password or "pakemon"
    local token = authenticate(url, username, password)

    local module_type = menuItems[selectedItem].module_type
    local module_name = menuItems[selectedItem].full_module_name
    local options = msfMenu.getPreparedOptions()

    --
    local execution_result = metasploit.module_execute(url, token, module_type, module_name, options)
    print("Execution Result: ", execution_result) -- this should output to messageBox
end

----------------------------------------------------------------------------------

function msfMenu.updateTalkiesDialog(title, items)
    -- Use the refactored msfMenu.tableToString function to handle the conversion
    local content = msfMenu.tableToString(items)
    Talkies.say(title, content)
end

--- when you select a dialog option, the text response should display in the messageBox not the talkie dialog.
 msfMenu.selectedTalkiesOptionIndex = 1
function msfMenu.showTalkiesDialogue() -- TODO: rename function 
    -- for k,v in pairs(module_info) do print("key/values   :  ", k, v) end
    -- print("Module Info in Dialogue:", module_info)
    -- Define dialogue options with corresponding functions --
    local dialogueOptions = {
        {"Set Options", function() 
            currentState = State.NAVIGATING_OPTIONS 
        end}, 
        {"Execute Module", function() 
            msfMenu.executeModule() 
        end},
        {"View Author", function() 
            local authorText = msfMenu.tableToString(module_info.authors or {})
            msfMenu.updateTalkiesDialog("Author", authorText or {"NOTHING SET, SAD FACE", "NOTHING"}) -- the messageBox should display this
        end}, 
        {"View References", function()
            local referencesText = msfMenu.tableToString(module_info.references or {})
            msfMenu.updateTalkiesDialog("References", referencesText) -- Now passing a string
        end}, 
        {"View Platform", function()
            local platformText = msfMenu.tableToString(module_info.platform or {})
            msfMenu.updateTalkiesDialog("Platform", platformText or "N/A") -- the messageBox should display this
        end} 
        -- more options 
    }

    -- Load the image if needed
    local renaImage = love.graphics.newImage("assets/rena.png") -- Assuming 'rena.png' is the image you want to display

    -- Extract the option titles for display
    local formattedOptions = {}
    for _, option in ipairs(dialogueOptions) do
        table.insert(formattedOptions, option[1])
    end

    -- Ensure the msfMenu.selectedTalkiesOptionIndex is reset every time the dialogue is shown
    msfMenu.selectedTalkiesOptionIndex = 1

    function msfMenu.showOptionsDialogue()  -- rename funtion to define better

        Talkies.say("Options", "Select an option:", {
            image = renaImage,
            options = dialogueOptions,
            onselect = function(selectedOption)
                -- Handle option selection
                dialogueOptions[selectedOption][2]()
            end
        })
    end

    Talkies.say("HIHI HAHA", { --module_info.name, module_info.description, {
        image = renaImage,
        oncomplete = function()
            -- Trigger the next dialog with options once the first dialog completes
            msfMenu.showOptionsDialogue()
        end
        
    })
end

-- we should add a special dial that displays module_info.name and the discription of the selection option (that is if talkie can take realtime input)
-- Function to calculate the total number of pages
function msfMenu.calculateTotalPages(module_info, linesPerPage)
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

function msfMenu.countTableEntries(t)
    local count = 1 -- Count the table itself
    for k, v in pairs(t) do
        if type(v) == "table" then
            count = count + msfMenu.countTableEntries(v) --
        else
            count = count + 1
        end
    end
    return count
end
-- cut leading whitespace 
function msfMenu.trim(s)
    return (s:gsub("^%s*(.-)%s*$", "%1"))
end

-- This function will create a nested table from the given table t
function msfMenu.walk_table(t, depth)
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
function msfMenu.loadExploitsFromFile(filename)
    if love.filesystem.getInfo(filename) then
        for line in love.filesystem.lines(filename) do
            local name, module_type, full_module_name = line:match("([^,]+),([^,]+),([^,]+)")
            if name and module_type and full_module_name then
                table.insert(allExploits, {
                    name = name,
                    module_type = module_type,
                    full_module_name = full_module_name
                })
            else
                print("Failed to parse line:", line)
            end
        end
        totalPages = math.ceil(#allExploits / itemsPerPage)
    else
        print("File not found:", filename)
    end
end


function msfMenu.populateMenuItems()
    local startItem = (currentPage - 1) * itemsPerPage + 1
    local endItem = math.min(startItem + itemsPerPage - 1, #allExploits)
    menuItems = {}
    for i = startItem, endItem do
        table.insert(menuItems, allExploits[i])
    end
end

-----------------------------------------------------------------------------------------------------------------------
-- Adjusts the scroll offset based on navigation
function msfMenu.adjustScrollOffset(direction)
    if direction > 0 and selectedOptionIndex > scrollOffset + maxOptionsOnScreen then
        scrollOffset = scrollOffset + 1
    elseif direction < 0 and selectedOptionIndex < scrollOffset + 1 then
        scrollOffset = scrollOffset - 1
    end
end


function msfMenu.getOptionKeys()
    local keys = {}
    for k in pairs(msfMenu.ui_data.options) do
        table.insert(keys, k)
    end
    table.sort(keys) -- Sort the keys to ensure consistent navigation order
    return keys
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
function msfMenu.getOptionCount()
    local count = 0
    for _ in pairs(msfMenu.ui_data.options) do
        count = count + 1
    end
    return count
end

-- Adjusts the scroll offset based on navigation
function msfMenu.adjustScrollOffset(direction)
    if direction > 0 and selectedOptionIndex > scrollOffset + maxOptionsOnScreen then
        scrollOffset = scrollOffset + 1
    elseif direction < 0 and selectedOptionIndex < scrollOffset + 1 then
        scrollOffset = scrollOffset - 1
    end
end

-- Helper function to adjust values of the currently selected option

function msfMenu.toggleOrSelectOption()
    local optionKeys = msfMenu.getOptionKeys()
    local currentOptionKey = optionKeys[selectedOptionIndex]
    local currentOption = msfMenu.ui_data.options[currentOptionKey]

    -- Call the handler for the specific option type
    local handler = optionHandler[currentOption.type]
    if handler then
        handler(currentOptionKey, currentOption, "edit")
    else
        print("No handler for option type:", currentOption.type)
    end

    -- Update the msfMenu.ui_data table with the new value
    msfMenu.ui_data.options[currentOptionKey].value = currentOption.value
end

-----------------------------------------------------------------------------------------------------------------------

msfMenu.topLevelHandlers = {

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

msfMenu.topLevelHandlers.options = function(options)
    for key, option in pairs(options) do
        -- Populate the msfMenu.ui_data.options
        msfMenu.ui_data.options[key] = {
            key = key, -- Store the key here
            type = option.type,
            value = option.default, -- Assuming there is a 'default' field
            desc = option.desc, -- Assuming there is a 'desc' field
            required = option.required, -- Assuming there is a 'required' field
            advanced = option.advanced, -- Assuming there is an 'advanced' field
            enums = option.enums -- Store enums if available
        }
        msfMenu.ui_data.optionKeys = {}
        for key, _ in pairs(msfMenu.ui_data.options) do
            table.insert(msfMenu.ui_data.optionKeys, key)
        end
        -- Call the handler for the specific option type
        local handler = optionHandler[option.type]
        if handler then
            handler(key, msfMenu.ui_data.options[key])
        else
            print("No handler for option type:", option.type)
        end
    end
end

-- Example handler implementations
msfMenu.topLevelHandlers.references = function(references)
    msfMenu.ui_data.references = {}
    for i, ref in pairs(references) do
        -- print(msfMenu.ui_data.references, i, ref)
    end
    -- Process and store the references in a suitable format for the UI
    msfMenu.ui_data.references = references
end

msfMenu.topLevelHandlers.authors = function(authors)
    -- Process and store the authors in a suitable format for the UI
    msfMenu.ui_data.authors = authors
end

msfMenu.topLevelHandlers.platform = function(platform)
    -- Process and store the platform in a suitable format for the UI
    msfMenu.ui_data.platform = platform
end

-- ... Additional handlers for rank, fullname, default_target, etc.

-- Utility function to get the number of options
function msfMenu.getNumberOfOptions()
    local count = 0
    for _ in pairs(msfMenu.ui_data.options) do
        count = count + 1
    end
    return count
end

-- Process each top-level item with the appropriate handler
function msfMenu.processModuleInfo(module_info)
    for key, value in pairs(module_info) do
        local handler = msfMenu.topLevelHandlers[key]
        if handler then
            handler(value)
        else
            -- If there is no specific handler, you might just assign the value directly,
            -- or handle it as a generic case, or log that it's not handled.
            msfMenu.ui_data[key] = value
        end
    end
    print("Number of options:", #msfMenu.ui_data.options)
    print(type("print", msfMenu.ui_data.options))
    for k, v in pairs(msfMenu.ui_data.options) do
        print(k, v)
    end
end



function msfMenu.load()
    -- Initialize menu items
    love.graphics.setFont(love.graphics.newFont(14)) -- Set the font size for drawing text
    msfMenu.loadExploitsFromFile("exploit_names.txt")
    msfMenu.populateMenuItems()
end

-- function love.update(dt)
--     -- Update logic (if any)
--     Talkies.update(dt)
-- end

function msfMenu.getColumnOfSelectedItem(selectedItem, cols)
    return (selectedItem - 1) % cols + 1
end

function msfMenu.getNextPage(currentPage, itemsPerPage)
    local newPage = currentPage + 1
    local newSelectedItem = (newPage - 1) * itemsPerPage + 1
    return newPage, newSelectedItem
end

function msfMenu.resetToFirstPage()
    return 1, 1
end

function msfMenu.getPreviousPage(currentPage, itemsPerPage, cols)
    local newPage = currentPage - 1
    local newSelectedItem = newPage * itemsPerPage - (cols - 1)
    return newPage, newSelectedItem
end

function msfMenu.resetToLastPage(totalPages, totalItems, cols)
    local newPage = totalPages
    local newSelectedItem = totalItems - (cols - 1)
    return newPage, newSelectedItem
end

function msfMenu.isItemInCurrentPage(itemIndex, currentPage, itemsPerPage, totalItems)
    local startIndex = (currentPage - 1) * itemsPerPage + 1
    local endIndex = math.min(startIndex + itemsPerPage - 1, totalItems)
    return itemIndex >= startIndex and itemIndex <= endIndex
end

function msfMenu.navigateRight()
    if selectedItem < #menuItems then
        selectedItem = selectedItem + 1
    elseif currentPage < totalPages then
        currentPage = currentPage + 1
        selectedItem = 1
        msfMenu.populateMenuItems() -- Repopulate menu items for the new page
    end
end

function msfMenu.navigateLeft()
    if selectedItem > 1 then
        selectedItem = selectedItem - 1
    elseif currentPage > 1 then
        currentPage = currentPage - 1
        selectedItem = itemsPerPage -- Set to the last item of the previous page
        msfMenu.populateMenuItems() -- Repopulate menu items for the new page
    end
end

function msfMenu.navigateDown()
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

function msfMenu.navigateUp()
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

function msfMenu.loadModuleInfo()
    local url = url or "http://localhost:55552/api/1.0"
    local username = username or "pakemon"
    local password = password or "pakemon"

    -- Authenticate and get the token for msfprcd
    local token = authenticate(url, username, password)

    -- Retrieve exploit info
    local exploits = metasploit.get_exploits(url, token)

    print("Exploits:")

    -- Get information about a specific module
    local module_type = "exploit"
    local module_name = msfMenu.trim(menuItems[selectedItem].full_module_name)

    local unpacked_info = metasploit.get_module_info(url, token, module_type, module_name)
    print("Module Info for " .. module_name .. ":")
    module_info = walk_table(unpacked_info)
    totalModuleInfoPages = msfMenu.calculateTotalPages(module_info, moduleInfoLinesPerPage)
    msfMenu.clearOptions()
    msfMenu.processModuleInfo(module_info)

    print("Module Info for " .. module_name .. ":")
    msfMenu.walk_table(module_info)

end

function msfMenu.interact(key)
    if currentState == State.NAVIGATING_EXPLOITS then
        if key == "right" then
            msfMenu.navigateRight()
        elseif key == "left" then
            msfMenu.navigateLeft()
        elseif key == "a" then
            msfMenu.loadModuleInfo()
            msfMenu.showTalkiesDialogue()
            msfMenu.pushState(State.TALKIES_DIALOGUE)
        end
    elseif currentState == State.TALKIES_DIALOGUE then
        if key == 'up' then
            Talkies.prevOption()
        elseif key == 'down' then
            Talkies.nextOption()
        elseif key == 'a' then
            Talkies.onAction()
            -- Assuming the action might lead to options configuration
           -- msfMenu.pushState(State.NAVIGATING_OPTIONS)
        elseif key == 'b' then
            Talkies.clearMessages()
            msfMenu.popState()
        end
    elseif currentState == State.NAVIGATING_OPTIONS then
        if key == "up" then
            selectedOptionIndex = math.max(selectedOptionIndex - 1, 1)
            msfMenu.adjustScrollOffset(-1)
        elseif key == "down" then
            selectedOptionIndex = math.min(selectedOptionIndex + 1, msfMenu.getOptionCount())
            msfMenu.adjustScrollOffset(1)
        elseif key == "a" then
            msfMenu.toggleOrSelectOption()
        elseif key == "b" then
            msfMenu.popState()
        end
    elseif currentState == State.EDITING_OPTION then
        local currentOption = msfMenu.ui_data.options[msfMenu.getOptionKeys()[selectedOptionIndex]]
        if currentOption.type == "enum" then
            DropdownMenu.keypressed(key)
            if key == "a" and not DropdownMenu.menu.isOpen then
                currentOption.value = DropdownMenu.enums[DropdownMenu.menu.selectedItem]
                msfMenu.popState()
            elseif key == "b" then
                msfMenu.popState()
            end
        end
    elseif currentState == State.KEYBOARD_INPUT then
        if key == "return" then
            local optionKeys = msfMenu.getOptionKeys()
            local currentOptionKey = optionKeys[selectedOptionIndex]
            local currentOption = msfMenu.ui_data.options[currentOptionKey]
            if currentOption.type == "string" or currentOption.type == "integer" or
               currentOption.type == "port" or currentOption.type == "address" then
                currentOption.value = keyboard.inputText
                msfMenu.popState()
            end
        else
            keyboard.handleInput(key)
        end
    end
end


function msfMenu.draw()

    local startX = 20 -- X position where the drawing starts
    local startY = 20 -- Y position where the drawing starts
    local lineHeight = 20 -- Height of each line of text

    love.graphics.setColor(1, 1, 1) -- set color to white
  --  love.graphics.setBackgroundColor(0.16, 0.16, 0.16) -- dark grey background

    -- Set a base Y position for drawing text
    local y = 20
    local x = 20
    local valueColumnX = 400 -- X position for the changeable values

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

    -- draw options: 
    local baseY = 50
    local optionKeys = msfMenu.getOptionKeys()
    for i, optionKey in ipairs(optionKeys) do
        local optionData = msfMenu.ui_data.options[optionKey]
        if i > scrollOffset and i <= scrollOffset + maxOptionsOnScreen then
            local y = baseY + (i - scrollOffset - 1) * 20
            love.graphics.rectangle("line", 50, y , 200, 20)
            local displayText = optionKey
            local optionValue = tostring(optionData.value) or "No description available" -- Corrected line
            love.graphics.setColor(0, 255, 0)
            love.graphics.print(displayText, 60, y )
            love.graphics.print(optionValue, 255, y ) -- Corrected line

            -- Highlight selected option
            if i == selectedOptionIndex then
                love.graphics.setColor(1, 1, 255)
                love.graphics.rectangle("line", 50, y, 200, 20)
                if currentState == State.KEYBOARD_INPUT then
                    keyboard.draw(255, y - 5 ) -- should be next to the option or something else
                end
            end
            if currentState == State.EDITING_OPTION then
                local currentOption = msfMenu.ui_data.options[msfMenu.getOptionKeys()[selectedOptionIndex]]
                print("CUROPTION", currentOption)
                if currentOption.type == "enum" then
                    DropdownMenu.draw() -- Draw the DropdownMenu for enum options
                end
            end
                -- If an option is selected, draw its value and description in a dedicated column
 
            love.graphics.setColor(0, 255, 255)
        end
    end



--    Talkies.draw()
end


return msfMenu
-- return {
--     interact = msfMenu.interact,
--     draw = msfMenu.draw
-- }