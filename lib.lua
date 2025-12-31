local gui_inventory_slot = {}

---@class GuiInventorySlotOptions
---@field target_stack LuaItemStack
---@field empty_tooltip LocalisedString?
---@field empty_sprite SpritePath?

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
---@param options GuiInventorySlotOptions
---@param player LuaPlayer
---@param button defines.mouse_button_type
function gui_inventory_slot.click(element, options, player, button)
    local cursor_stack = player.cursor_stack
    if not cursor_stack then return end
    local target_stack = options.target_stack

    if button == defines.mouse_button_type.left then
        if -- If they should be stackable to each other
            cursor_stack.valid_for_read and
            target_stack.valid_for_read and
            target_stack.name == cursor_stack.name and
            target_stack.quality == cursor_stack.quality and
            target_stack.health == cursor_stack.health and
            not target_stack.is_item_with_label and
            not target_stack.is_item_with_entity_data
        then
            -- Try transferring as long as items are in cusor
            target_stack.transfer_stack(cursor_stack)
        else
            -- Otherwise, try swapping
            target_stack.swap_stack(cursor_stack)
        end

    elseif button == defines.mouse_button_type.right then
        if cursor_stack.valid_for_read then
            -- Try to put in 1 item
            target_stack.transfer_stack(cursor_stack, 1)
        elseif target_stack.valid_for_read then
            -- Take half of the stack
            cursor_stack.transfer_stack(target_stack, math.ceil(target_stack.count / 2))
        end
    end

    gui_inventory_slot.refresh(element, options)
end

---@param element LuaGuiElement
---@param options GuiInventorySlotOptions
function gui_inventory_slot.refresh(element, options)
    local target_stack = options.target_stack
    if target_stack.valid_for_read then
        element.sprite = "item/"..target_stack.name
        element.quality = target_stack.quality
        element.number = not target_stack.prototype.has_flag("not-stackable") and target_stack.count or nil
        element.elem_tooltip = {
            type = "item",
            name = target_stack.name,
            quality = target_stack.quality.name,
        }
        element.tooltip = nil
    else
        element.sprite = options.empty_sprite
        element.quality = nil
        element.number = nil
        element.elem_tooltip = nil
        element.tooltip = options.empty_tooltip
    end
end

return gui_inventory_slot
