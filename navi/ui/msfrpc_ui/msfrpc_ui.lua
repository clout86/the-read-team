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
        preparedOptions[#preparedOptions + 1] =  key .. " " .. option.value
    end
    return preparedOptions
end


-- Process each top-level item with the appropriate handler
function rena.processModuleInfo(module_info)
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

function rena.loadModuleInfo()
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
    local module_name = trim(menuItems[selectedItem].full_module_name)

    local unpacked_info = metasploit.get_module_info(url, token, module_type, module_name)
    print("Module Info for " .. module_name .. ":")
    module_info = walk_table(unpacked_info)
    totalModuleInfoPages = navi_ui.calculateTotalPages(module_info, moduleInfoLinesPerPage)
    navi_ui.clearOptions()
    rena.processModuleInfo(module_info)

    print("Module Info for " .. module_name .. ":")
    walk_table(module_info)

end

-- Function to execute a selected module with configured options
-- This function should be integrated as an option in the main Talkies options under "Set Options".
 function rena.executeModule()
    local url = url or "http://localhost:55552/api/1.0"
    local username = username or "pakemon"
    local password = password or "pakemon"
    local token = authenticate(url, username, password)

    local module_type = menuItems[selectedItem].module_type
    local module_name = menuItems[selectedItem].full_module_name
    local options = getPreparedOptions()

    --
    local execution_result = metasploit.module_execute(url, token, module_type, module_name, options)
    print("Execution Result: ", execution_result) -- this should output to messageBox
end

function rena.updateTalkieMsfOptionDesc()
    if currentState == uiElements.MSF_GILMORE then
        local currentOptionKey = getOptionKeys()[selectedOptionIndex]
        local currentOption = ui_option_data.options[currentOptionKey]
        local description = currentOption.desc or "No description available"

        -- Clear the current dialog
        Talkies.clearMessages()

        -- Create a new dialog with updated content
        rena.updateTalkiesDialog("Option Description", description)
    end
end

function rena.updateTalkiesDialog(title, items ,image)
    -- Use the refactored tableToString function to handle the conversion
    local content = tableToString(items)
    Talkies.say(title, content, {
        image =  image or renaImage or nil
    })
end

--- when you select a dialog option, the text response should display in the messageBox not the talkie dialog.
local selectedTalkiesOptionIndex = 1
function rena.dialog() 
 --   for k,v in pairs(module_info) do print("key/values   :  ", k, v) end
 --   print("Module Info in Dialogue:", module_info)
    -- Define dialogue options with corresponding functions --
    local dialogueOptions = {
        {"Set Options", function() 
            currentState = uiElements.MSF_GILMORE 
        end}, 
        {"Execute Module", function() 
            executeModule() 
        end},
        {"View Author", function() 
            local authorText = tableToString(module_info.authors or {})
            updateTalkiesDialog("Author", authorText or {"NOTHING SET, SAD FACE", "NOTHING"}) -- the messageBox should display this
        end}, 
        {"View References", function()
            local referencesText = tableToString(module_info.references or {})
            updateTalkiesDialog("References", referencesText) -- Now passing a string
        end}, 
        {"View Platform", function()
            local platformText = tableToString(module_info.platform or {})
            updateTalkiesDialog("Platform", platformText or "N/A") -- the messageBox should display this
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

    -- Ensure the selectedTalkiesOptionIndex is reset every time the dialogue is shown
    selectedTalkiesOptionIndex = 1

  local  function showOptionsDialogue()  -- rename funtion to define better

        Talkies.say("Options", "Select an option:", {
            image = renaImage,
            options = dialogueOptions,
            onselect = function(selectedOption)
                -- Handle option selection
                dialogueOptions[selectedOption][2]()
            end
        })
    end

    Talkies.say("RENA", "REMOTE EXPLOIT NETWORK ATTACK", { --module_info.name, module_info.description, {
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
                navigateGirdRight()
            elseif key == "left" then
                navigateGridLeft()
            elseif key == "a" then
                loadModuleInfo()
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
                navigateOptionsUp()
                updateTalkieMsfOptionDesc()

            elseif key == 'down' then
                navigateOptionsDown()
                updateTalkieMsfOptionDesc()

            elseif key == 'right' or key == 'a' then
                enterOrConfirmOption()
            elseif key == 'left' or key == 'b' then
                exitEditingOrGoBack()
            end
        end
    end,

    draw = function()

        love.graphics.setColor(1, 1, 1) -- set color to white
        love.graphics.setBackgroundColor(0.16, 0.16, 0.16) -- dark grey background

        navi_ui.girdMenu(gridX, gridY)
        -- draw options: 
        navi_ui.drawOptions()
        -- Always draw Talkies
      --  Talkies.draw()
    end
}
----------------------------------------------------------------------------------
-- Return the module as an element for the uiElements table
return rena