local gui_inventory_slot = {}

---@class GuiInventorySlot.Options
---@field empty_tooltip LocalisedString?
---@field empty_sprite SpritePath?

---@class GuiInventorySlot.create_params
---@field parent LuaGuiElement
---@field name string

---@param params GuiInventorySlot.create_params
---@return LuaGuiElement
function gui_inventory_slot.create(params)
    local button = params.parent.add{
        type = "sprite-button",
        name = params.name,
        style = "inventory_slot",
        mouse_button_filter = {"left", "middle", "right"},
    }
    button.style.clicked_vertical_offset = 0

    return button
end

---@class GuiInventorySlot.click_params
---@field element LuaGuiElement
---@field target_stack LuaItemStack
---@field options GuiInventorySlot.Options?
---@field player LuaPlayer
---@field button defines.mouse_button_type

---@param params GuiInventorySlot.click_params
function gui_inventory_slot.click(params)
    local player = params.player
    local cursor_stack = player.cursor_stack
    if not cursor_stack then return end
    local target_stack = params.target_stack

    local pickedup = false
    local dropped = false

    if
        player.controller_type == defines.controllers.character or
        player.controller_type == defines.controllers.editor or
        player.controller_type == defines.controllers.god
    then
        if params.button == defines.mouse_button_type.left then
            if -- If they should be stackable to each other
                cursor_stack.valid_for_read and
                target_stack.valid_for_read and
                target_stack.name == cursor_stack.name and
                target_stack.quality == cursor_stack.quality and
                target_stack.health == cursor_stack.health and
                not target_stack.is_item_with_label and
                not target_stack.is_item_with_entity_data and
                not target_stack.is_armor
            then
                -- Try transferring
                local old_cursor_count = cursor_stack.count
                target_stack.transfer_stack(cursor_stack)
                dropped = cursor_stack.count < old_cursor_count
            else
                -- Otherwise, try swapping
                local ret = target_stack.swap_stack(cursor_stack)
                pickedup = ret and cursor_stack.valid_for_read
                dropped = ret and target_stack.valid_for_read
            end

        elseif params.button == defines.mouse_button_type.right then
            if cursor_stack.valid_for_read then
                -- Try to put in 1 item
                local ret = target_stack.transfer_stack(cursor_stack, 1)
                dropped = ret
            elseif target_stack.valid_for_read then
                -- Take half of the stack
                cursor_stack.transfer_stack(target_stack, math.ceil(target_stack.count / 2))
                pickedup = cursor_stack.valid_for_read
            end
        end
    end

    if pickedup then
        if cursor_stack.valid_for_read and helpers.is_valid_sound_path("item-pick/"..cursor_stack.name) then
            player.play_sound{path = "item-pick/"..cursor_stack.name}
        end
    end
    if dropped then
        if target_stack.valid_for_read and helpers.is_valid_sound_path("item-drop/"..target_stack.name) then
            player.play_sound{path = "item-drop/"..target_stack.name}
        end
    end

    gui_inventory_slot.refresh(params --[[@as GuiInventorySlot.refresh_params]])
end

---@class GuiInventorySlot.refresh_params
---@field element LuaGuiElement
---@field target_stack LuaItemStack
---@field options GuiInventorySlot.Options?

---@param params GuiInventorySlot.refresh_params
function gui_inventory_slot.refresh(params)
    local element = params.element
    local target_stack = params.target_stack
    local options = params.options or {}

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
