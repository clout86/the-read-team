
local planetNavigation = {}
function planetNavigation.interact(key)
    if focusState == PLANET_NAVI then
        if key == ('up') then
            navi_ui.planetSelectUp()

        end
        if key == ('down') then
            navi_ui.planetSelectDown()

        end
        if key == ('a') then
            navi_ui.toggleDisplayDetails()

        end
    end
end

local gridNavigation = {}
function gridNavigation.interact(key)
    if focusState == GRID_NAVI then

    if key == ('up') then
        GridMenu.navigateGridDown()

    end
    if key == ('down') then
        GridMenu.navigateGridDown()

    end
    if key == ('left') then
        GridMenu.navigateGridLeft()

    end
    if key == ('right') then
        GridMenu.navigateGridRight()
    end
    end
end


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


local shipNavigation = {}
function shipNavigation.interact(key)
    if focusState == SHIP_NAVI then
        if key == ('up') then
            ship.y = ship.y - ship.speed * dt

        end
        if key == ('down') then
            ship.y = ship.y + ship.speed * dt

        end
        if key == ('left') then
            ship.x = ship.x - ship.speed * dt

        end
        if key == ('right') then
            ship.x = ship.x + ship.speed * dt

        end
    end
end



