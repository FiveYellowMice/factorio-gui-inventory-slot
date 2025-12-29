local gui_inventory_slot = {}


---@param parent LuaGuiElement
---@param name string
---@return LuaGuiElement
function gui_inventory_slot.create(parent, name)
    local button = parent.add{
        type = "sprite-button",
        name = name,
        style = "inventory_slot",
        mouse_button_filter = {"left", "middle", "right"},
    }
    button.style.clicked_vertical_offset = 0

    return button
end

---@param element LuaGuiElement
---@param target LuaItemStack
---@param player LuaPlayer
---@param button defines.mouse_button_type
function gui_inventory_slot.click(element, target, player, button)
    local cursor_stack = player.cursor_stack
    if not cursor_stack then return end

    if button == defines.mouse_button_type.left then
        if -- If they should be stackable to each other
            cursor_stack.valid_for_read and
            target.valid_for_read and
            target.name == cursor_stack.name and
            target.quality == cursor_stack.quality and
            target.health == cursor_stack.health and
            target.prototype.stack_size ~= 1 and
            cursor_stack.prototype.stack_size ~= 1 and
            not target.item and
            not cursor_stack.item
        then
            -- Try transferring as long as items are in cusor
            target.transfer_stack(cursor_stack)
        else
            -- Otherwise, try swapping
            target.swap_stack(cursor_stack)
        end

    elseif button == defines.mouse_button_type.right then
        if cursor_stack.valid_for_read then
            -- Try to put in 1 item
            target.transfer_stack(cursor_stack, 1)
        elseif target.valid_for_read then
            -- Take half of the stack
            cursor_stack.transfer_stack(target, math.ceil(target.count / 2))
        end
    end

    gui_inventory_slot.refresh(element, target)
end

---@param element LuaGuiElement
---@param target LuaItemStack
function gui_inventory_slot.refresh(element, target)
    if target.valid_for_read then
        element.sprite = "item/"..target.name
        element.quality = target.quality
        element.number = target.count
    else
        element.sprite = nil
        element.quality = nil
        element.number = nil
    end
end

return gui_inventory_slot
