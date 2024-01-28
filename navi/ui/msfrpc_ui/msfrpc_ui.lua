rena = {}

-- for dialog
local Talkies = require("lib.talkies")

-- for msfrpcd
local metasploit = require("lib.metasploit")
local authenticate = require("lib.auth")

-- input handlers
local DropdownMenu = require("lib.DropdownMenu")
local keyboard = require("lib.keyboard")
-- navi_ui = require("ui.navi_ui.navi_ui")

-- Function to collect and return configured options
-- Format options as: [OPTION_NAME] [OPTION]
function rena.getPreparedOptions()
    local preparedOptions = {}
    for key, option in pairs(ui_data.options) do
        preparedOptions[#preparedOptions + 1] = key .. " " .. option.value
    end
    return preparedOptions
end

-- Function to execute a selected module with configured options
-- This function should be integrated as an option in the main Talkies options under "Set Options".
function rena.executeModule()
    local url = url or "http://localhost:55552/api/1.0"
    local username = username or "pakemon"
    local password = password or "pakemon"
    local token = authenticate(url, username, password)

    local selectedItem = GridMenu.getSelectedItem()
    local module_type = selectedItem.module_type
    local module_name = OptionsMenu.trim(selectedItem.full_module_name)

    local options = OptionsMenu.getCurrentOptions()

    local execution_result = metasploit.module_execute(url, token, module_type, module_name, options)
    print("Execution Result: ", execution_result) -- this should output to messageBox
end

function rena.updateTalkieMsfOptionDesc()
    if OptionsMenu.getCurrentState() == uiElements.MSF_GRIMOIRE then
        local currentOption = OptionsMenu.getCurrentOptionData()
        local description = currentOption.desc or "No description available"

        -- Clear the current dialog
        Talkies.clearMessages()

        -- Create a new dialog with updated content
        rena.updateTalkiesDialog("Option Description", description)
    end
end

function rena.updateTalkiesDialog(title, items, image)
    -- Use the refactored tableToString function to handle the conversion
    local content = tableToString(items)
    Talkies.say(title, content, {
        image = image or renaImage or nil
    })
end

--- when you select a dialog option, the text response should display in the messageBox not the talkie dialog.
local selectedTalkiesOptionIndex = 1
function rena.dialog()
    --   for k,v in pairs(module_info) do print("key/values   :  ", k, v) end
    --   print("Module Info in Dialogue:", module_info)
    -- Define dialogue options with corresponding functions --
    local dialogueOptions = {{"Set Options", function()
        currentState = uiElements.MSF_GRIMOIRE
    end}, {"Execute Module", function()
        rena.executeModule()
    end}, {"View Author", function()
        local authorText = tableToString(module_info.authors or {})
        updateTalkiesDialog("Author", authorText or {"NOTHING SET, SAD FACE", "NOTHING"}) -- the messageBox should display this
    end}, {"View References", function()
        local referencesText = tableToString(module_info.references or {})
        updateTalkiesDialog("References", referencesText) -- Now passing a string
    end}, {"View Platform", function()
        local platformText = tableToString(module_info.platform or {})
        updateTalkiesDialog("Platform", platformText or "N/A") -- the messageBox should display this
    end} -- more options 
    }

    -- Load the image if needed
    local renaImage = love.graphics.newImage("assets/rena.png") -- Assuming 'rena.png' is the image you want to display

    -- Extract the option titles for display
    local formattedOptions = {}
    for _, option in ipairs(dialogueOptions) do
        table.insert(formattedOptions, option[1])
    end

    -- Ensure the selectedTalkiesOptionIndex is reset every time the dialogue is shown
    selectedTalkiesOptionIndex = 1

    local function showOptionsDialogue() -- rename funtion to define better

        Talkies.say("Options", "Select an option:", {
            image = renaImage,
            options = dialogueOptions,
            onselect = function(selectedOption)
                -- Handle option selection
                dialogueOptions[selectedOption][2]()
            end
        })
    end

    Talkies.say("RENA", "REMOTE EXPLOIT NETWORK ATTACK", { -- module_info.name, module_info.description, {
        image = renaImage,
        oncomplete = function()
            -- Trigger the next dialog with options once the first dialog completes
            showOptionsDialogue()
        end

    })
end

local rena = {
    interact = function(dt)

        if currentState == uiElements.NAVIGATING_EXPLOITS then
            if key == "right" then
                GridMenu.navigateGirdRight()
            elseif key == "left" then
                GridMenu.navigateGridLeft()
            elseif key == "a" then
                OptionsMenu.loadModuleInfo()
                showMsfDialog()
                pushState(uiElements.MSF_DIALOG)
            end

        elseif currentState == uiElements.MSF_DIALOG then
            if key == 'up' then
                Talkies.prevOption()
            elseif key == 'down' then
                Talkies.nextOption()
            elseif key == 'a' then
                Talkies.onAction()
            elseif key == 'b' then
                Talkies.clearMessages()
                popState()
            end
        elseif currentState == uiElements.MSF_OPTIONS then
            if key == 'up' then
                OptionsMenu.navigateOptionsUp()
                OptionsMenu.updateTalkieMsfOptionDesc()

            elseif key == 'down' then
                OptionsMenu.navigateOptionsDown()
                OptionsMenu.updateTalkieMsfOptionDesc()

            elseif key == 'right' or key == 'a' then
                OptionsMenu.enterOrConfirmOption()
            elseif key == 'b' then
                OptionsMenu.exitEditingOrGoBack()
            end
        end
    end,

    draw = function()
        local gridX = 400
        local gridY = 400
        OptionsMenu.drawOptions()
        GridMenu.drawGrid(gridX, gridY)
    end
}
----------------------------------------------------------------------------------
-- Return the module as an element for the uiElements table
return rena
