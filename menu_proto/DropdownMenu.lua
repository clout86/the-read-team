-- DropdownMenu.lua
local DropdownMenu = {}

function DropdownMenu.load(enums, x, y, width, height)
    DropdownMenu.enums = enums or {}

    DropdownMenu.menu = {
        x = x or 100,
        y = y or 100,
        width = width or 200,
        height = height or 20,
        isOpen = false,
        selectedItem = 1
    }
end

function DropdownMenu.draw()
    local menu = DropdownMenu.menu
    local enums = DropdownMenu.enums

    -- Draw the selected item
    love.graphics.rectangle("fill", menu.x, menu.y, menu.width, menu.height)
    love.graphics.setColor(0, 0, 0)
    if enums[menu.selectedItem] then
        love.graphics.print(enums[menu.selectedItem], menu.x + 5, menu.y + 5)
    end
    love.graphics.setColor(1, 1, 1)

    -- Draw the menu items if the menu is open
    if menu.isOpen then
        for i, enum in ipairs(enums) do
            love.graphics.rectangle("line", menu.x, menu.y + i * menu.height, menu.width, menu.height)
            love.graphics.print(enum, menu.x + 5, menu.y + i * menu.height + 5)
        end
    end
end

function DropdownMenu.keypressed(key)
    local menu = DropdownMenu.menu
    local enums = DropdownMenu.enums

    if key == "up" then
        if menu.isOpen then
            menu.selectedItem = math.max(1, menu.selectedItem - 1)
        end
    elseif key == "down" then
        if menu.isOpen then
            menu.selectedItem = math.min(#enums, menu.selectedItem + 1)
        end
    elseif key == "a" then
        if not menu.isOpen then
            menu.isOpen = true
        else
            -- Close the menu when an item is selected
            menu.isOpen = false
        end
    elseif key == "b" and menu.isOpen then
        menu.isOpen = false
    end
end

return DropdownMenu
