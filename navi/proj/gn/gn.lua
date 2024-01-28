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

return gridNavigation
