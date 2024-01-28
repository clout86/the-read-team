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
return planetNavigation
