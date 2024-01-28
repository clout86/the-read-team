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



return shipNavigation
