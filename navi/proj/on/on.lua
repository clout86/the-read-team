local optionsNavigation = {}
function optionsNavigation.interact(key)
    if focusState == OPTIONS_NAVI then

    if key == ('up') then
        OptionsMenu.navigateOptionsUp()
        OptionsMenu.clearOptions()
        OptionsMenu.updateTalkieMsfOptionDesc()

    end
    if key == ('down') then
        OptionsMenu.navigateOptionsDown()
        OptionsMenu.clearOptions()
        OptionsMenu.updateTalkieMsfOptionDesc()

    end
    if key == ('a') then
        OptionsMenu.toggleOrSelectOption()

    end
    if key == ('b') then
        -- pop focusState
    end
end
end

return optionsNavigation
