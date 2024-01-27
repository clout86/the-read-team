local GridMenu = require("GridMenu")

OptionsMenu = {}

-- Dependencies
local DropdownMenu = require("lib.DropdownMenu")
local keyboard = require("lib.keyboard")

-- Option Menu Variables
local selectedOptionIndex = 1
local scrollOffset = 0
local maxOptionsOnScreen = 10
local ui_option_data = {
    options = {},
    optionKeys = {}
    -- ... other related variables ...
}

local OPTION_STATE = {

    NAVIGATING_OPTIONS = "navigate_options",
    EDITING_OPTION = "enum_or_bool",
    KEYBOARD_INPUT = "text_input",
}
-----------------------------------------------------------------------------------------------------------------------
-- Define option handlers for different types within 'options'
local optionHandler = {
    integer = function(key, option, action)
        if action == "edit" then
            CURRENT_STATE = OPTION_STATE.KEYBOARD_INPUT
            keyboard.inputText = tostring(option.value)
            keyboard.currentIndex = 1
            keyboard.inputPosition = #keyboard.inputText + 1
        end
    end,
    string = function(key, option, action)
        if action == "edit" then
            CURRENT_STATE = OPTION_STATE.KEYBOARD_INPUT
            keyboard.inputText = tostring(option.value)
            keyboard.currentIndex = 1
            keyboard.inputPosition = #keyboard.inputText + 1
        end
    end,
    port = function(key, option, action)
        if action == "edit" then
            CURRENT_STATE = OPTION_STATE.KEYBOARD_INPUT
            keyboard.inputText = tostring(option.value)
            keyboard.currentIndex = 1
            keyboard.inputPosition = #keyboard.inputText + 1
        end
    end,
    address = function(key, option, action)
        if action == "edit" then
            CURRENT_STATE = OPTION_STATE.KEYBOARD_INPUT
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
            CURRENT_STATE = OPTION_STATE.EDITING_OPTION
            DropdownMenu.load(option.enums, 300, 300)
        end
    end
    -- ... other handlers ...
    -- rport
    -- path
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
        -- Populate the ui_option_data.options
        ui_option_data.options[key] = {
            key = key, -- Store the key here
            type = option.type,
            value = option.default,
            desc = option.desc,
            required = option.required,
            advanced = option.advanced,
            enums = option.enums
        }
        ui_option_data.optionKeys = {}
        for key, _ in pairs(ui_option_data.options) do
            table.insert(ui_option_data.optionKeys, key)
        end
        -- Call the handler for the specific option type
        local handler = optionHandler[option.type]
        if handler then
            handler(key, ui_option_data.options[key])
        else
            print("No handler for option type:", option.type)
        end
    end
end

-- Example handler implementations
topLevelHandlers.references = function(references)
    ui_option_data.references = {}
    for i, ref in pairs(references) do
        -- print(ui_option_data.references, i, ref)
    end
    -- Process and store the references in a suitable format for the UI
    ui_option_data.references = references
end

topLevelHandlers.authors = function(authors)
    -- Process and store the authors in a suitable format for the UI
    ui_option_data.authors = authors
end

topLevelHandlers.platform = function(platform)
    -- Process and store the platform in a suitable format for the UI
    ui_option_data.platform = platform
end

function OptionsMenu.pushState(newState)
    print("Pushing state: " .. tostring(newState)) -- Debug log
    table.insert(stateStack, currentState)
    currentState = newState
end

-- Function to pop a state from the stack
function OptionsMenu.popState()
    if #stateStack > 0 then
        local poppedState = table.remove(stateStack)
        print("Popping state: " .. tostring(poppedState)) -- Debug log
        currentState = poppedState
    else
        print("State stack is empty, cannot pop") -- Debug log
    end
end



function OptionsMenu.updateTalkiesDialog(title, items) -- ,image)
    -- Use the refactored tableToString function to handle the conversion
    local content = tableToString(items)
    Talkies.say(title, content, {
        image = renaImage -- image or nil
    })
end

function OptionsMenu.clearOptions()
    ui_option_data.options = {}
    ui_option_data.optionKeys = {}
end
function OptionsMenu.tableToString(tbl)
    if type(tbl) ~= "table" then
        return tostring(tbl) -- Return the string representation of non-tables
    end

    local str = ""
    for k, v in pairs(tbl) do
        if type(v) == "table" then
            str = str .. k .. ": {" .. tableToString(v) .. "}, "
        else
            str = str .. k .. ": " .. tostring(v) .. ", "
        end
    end
    return str
end

-- cut leading whitespace 
function OptionsMenu.trim(s)
    return (s:gsub("^%s*(.-)%s*$", "%1"))
end

-- This function will create a nested table from the given table t
function OptionsMenu.walk_table(t, depth)
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


-- Adjusts the scroll offset based on navigation
function OptionsMenu.adjustScrollOffset(direction)
    if direction > 0 and selectedOptionIndex > scrollOffset + maxOptionsOnScreen then
        scrollOffset = scrollOffset + 1
    elseif direction < 0 and selectedOptionIndex < scrollOffset + 1 then
        scrollOffset = scrollOffset - 1
    end
end

function OptionsMenu.getOptionKeys()
    local keys = {}
    for k in pairs(ui_option_data.options) do
        table.insert(keys, k)
    end
    table.sort(keys) -- Sort the keys to ensure consistent navigation order
    return keys
end


function OptionsMenu.getOptionCount()
    local count = 0
    for _ in pairs(ui_option_data.options) do
        count = count + 1
    end
    return count
end

-- Adjusts the scroll offset based on navigation
function OptionsMenu.adjustScrollOffset(direction)
    if direction > 0 and selectedOptionIndex > scrollOffset + maxOptionsOnScreen then
        scrollOffset = scrollOffset + 1
    elseif direction < 0 and selectedOptionIndex < scrollOffset + 1 then
        scrollOffset = scrollOffset - 1
    end
end


function OptionsMenu.updateTalkieMsfOptionDesc()
    if CURRENT_STATE == OPTION_STATE.NAVIGATING_OPTIONS then
        local currentOptionKey = OptionsMenu.getOptionKeys()[selectedOptionIndex]
        local currentOption = ui_option_data.options[currentOptionKey]
        local description = currentOption.desc or "No description available"

        -- Clear the current dialog
        Talkies.clearMessages()

        -- Create a new dialog with updated content
        OptionsMenu.updateTalkiesDialog("Option Description", description)
    end
end

function OptionsMenu.toggleOrSelectOption()
    local optionKeys = OptionsMenu.getOptionKeys()
    local currentOptionKey = optionKeys[selectedOptionIndex]
    local currentOption = ui_option_data.options[currentOptionKey]

    -- Call the handler for the specific option type
    local handler = optionHandler[currentOption.type]
    if handler then
        handler(currentOptionKey, currentOption, "edit")
    else
        print("No handler for option type:", currentOption.type)
    end

    -- Update the ui_option_data table with the new value
    ui_option_data.options[currentOptionKey].value = currentOption.value
    OptionsMenu.updateTalkieMsfOptionDesc()
end


-- Process each top-level item with the appropriate handler
function OptionsMenu.processMsfModuleInfo(module_info)
    for key, value in pairs(module_info) do
        local handler = topLevelHandlers[key]
        if handler then
            handler(value)
        else
            -- If there is no specific handler, you might just assign the value directly,
            -- or handle it as a generic case, or log that it's not handled.
            ui_option_data[key] = value
        end
    end
end


-- Helper Functions
function OptionsMenu.getOptionKeys()
    local keys = {}
    for k in pairs(ui_option_data.options) do
        table.insert(keys, k)
    end
    table.sort(keys) -- Sort the keys to ensure consistent navigation order
    return keys
end

function OptionsMenu.loadModuleInfo()
    local url = url or "http://localhost:55552/api/1.0"
    local username = username or "pakemon"
    local password = password or "pakemon"

    -- Authenticate and get the token for msfprcd
    local token = authenticate(url, username, password)


local selectedItem = GridMenu.getSelectedItem()
local module_type = "exploit"
local module_name = OptionsMenu.trim(selectedItem.full_module_name)

    local unpacked_info = metasploit.get_module_info(url, token, module_type, module_name)

    module_info = walk_table(unpacked_info)
    OptionsMenu.clearOptions()
    OptionsMenu.processMsfModuleInfo(module_info)

    OptionsMenu.walk_table(module_info)

end

function OptionsMenu.getOptionCount()
    local count = 0
    for _ in pairs(ui_option_data.options) do
        count = count + 1
    end
    return count
end


-- Navigates up in the options list
function OptionsMenu.navigateOptionsUp()
    if selectedOptionIndex > 1 then
        selectedOptionIndex = selectedOptionIndex - 1
        OptionsMenu.adjustScrollOffset(-1)
    end
end

-- Navigates down in the options list
function OptionsMenu.navigateOptionsDown()
    if selectedOptionIndex < OptionsMenu.getOptionCount() then
        selectedOptionIndex = selectedOptionIndex + 1
        OptionsMenu.adjustScrollOffset(1)
    end
end

-- Enters editing mode for the selected option or confirms an action
function OptionsMenu.enterOrConfirmOption()
    local currentOptionKey = OptionsMenu.getOptionKeys()[selectedOptionIndex]
    local currentOption = ui_option_data.options[currentOptionKey]
    local handler = optionHandler[currentOption.type]
    if handler then
        handler(currentOptionKey, currentOption, "edit")
    end
end

-- Exits editing mode or goes back to the previous menu
function OptionsMenu.exitEditingOrGoBack()
    if CURRENT_STATE == OPTION_STATE.EDITING_OPTION or CURRENT_STATE == OPTION_STATE.KEYBOARD_INPUT then
        CURRENT_STATE = OPTION_STATE.NAVIGATING_OPTIONS
    else
        OptionsMenu.popState()
    end
end



function OptionsMenu.keypressed(key)
    if CURRENT_STATE == OPTION_STATE.NAVIGATING_EXPLOITS then
        if key == "right" then
            GridMenu.navigateGirdRight()
        elseif key == "left" then
            GridMenu.navigateGridLeft()
        elseif key == "a" then
            OptionsMenu.loadModuleInfo()
            -- showMsfDialog()
            OptionsMenu.pushState(OPTION_STATE.TALKIES_DIALOGUE)
        end

    elseif CURRENT_STATE == OPTION_STATE.TALKIES_DIALOGUE then
        if key == 'up' then
            Talkies.prevOption()
        elseif key == 'down' then
            Talkies.nextOption()
        elseif key == 'a' then
            Talkies.onAction()
        elseif key == 'b' then
            Talkies.clearMessages()
            OptionsMenu.popState()
        end
    elseif CURRENT_STATE == OPTION_STATE.NAVIGATING_OPTIONS then
        if key == 'up' then
            OptionsMenu.navigateOptionsUp()
            OptionsMenu.updateTalkieMsfOptionDesc()

        elseif key == 'down' then
            OptionsMenu.navigateOptionsDown()
            OptionsMenu.updateTalkieMsfOptionDesc()

        elseif key == 'right' or key == 'a' then
            OptionsMenu.enterOrConfirmOption()
        elseif key == 'left' or key == 'b' then
            OptionsMenu.exitEditingOrGoBack()
        end
    end

end


-- Drawing Functions
function OptionsMenu.drawOptions()
    local baseY = 50
    local optionKeys = OptionsMenu.getOptionKeys()
    for i, optionKey in ipairs(optionKeys) do
        local optionData = ui_option_data.options[optionKey]
        if i > scrollOffset and i <= scrollOffset + maxOptionsOnScreen then
            local y = baseY + (i - scrollOffset - 1) * 20
            -- Drawing logic for options
            love.graphics.rectangle("line", 50, y, 200, 20)
            local displayText = optionKey
            local optionValue = tostring(optionData.value) or "No description available" -- Corrected line
            love.graphics.setColor(0, 255, 0)
            love.graphics.print(displayText, 60, y)
            love.graphics.print(optionValue, 255, y) -- Corrected line

            -- Highlight selected option
            if i == selectedOptionIndex then
                love.graphics.setColor(1, 1, 255)
                love.graphics.rectangle("line", 50, y, 200, 20)
                if CURRENT_STATE == OPTION_STATE.KEYBOARD_INPUT then
                    keyboard.draw(255, y - 5) -- should be next to the option or something else
                end
            end
            if CURRENT_STATE == OPTION_STATE.EDITING_OPTION then
                local currentOption = ui_option_data.options[OptionsMenu.getOptionKeys()[selectedOptionIndex]]
                if currentOption.type == "enum" then
                    DropdownMenu.draw() -- Draw the DropdownMenu for enum options
                end
            end
            -- If an option is selected, draw its value and description in a dedicated column

            love.graphics.setColor(0, 255, 255)
            -- ...
        end
    end
end

return OptionsMenu
