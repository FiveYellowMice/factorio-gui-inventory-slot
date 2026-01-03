local constants = require("constants")
local util = require("util")
local PlayerData = require("script.player_data")

local SlotObject = {}

---Represents a managed GUI inventory slot in storage. Lifetime bound to the corresponding GUI element.
---@class GuiInventorySlot.SlotObject
---@field private registration_number uint64 Registration number of the element.
---@field public element LuaGuiElement The root GUI element.
---@field public target LuaItemStack? The target stack.
---@field public options GuiInventorySlot.Options
SlotObject.prototype = {}
SlotObject.prototype.__index = SlotObject.prototype

---Private data stored in the `constants.gui_tag_private` tag on the root element.
---@class (exact) GuiInventorySlot.PrivateTags

---Options to adjust the behaviour of the slot.
---@class (exact) GuiInventorySlot.Options
---@field empty_tooltip LocalisedString? Display a tooltip when the slot is empty.
---@field empty_sprite SpritePath? Display a sprite in the slot when it is empty.


function SlotObject.on_init()
    ---Pool of SlotObject's, indexed by registration number.
    ---@package
    ---@type table<uint64, GuiInventorySlot.SlotObject?>
    storage.slot_objects = {}
end

---@class GuiInventorySlot.create_params
---@field parent LuaGuiElement The parent GUI element to create the new element in.
---@field name string Name of the GUI element.
---@field target LuaItemStack? Where the items are actually stored.
---@field options GuiInventorySlot.Options? Options to adjust the behaviour of the slot.

---@param params GuiInventorySlot.create_params
---@return GuiInventorySlot.SlotObject
function SlotObject.create(params)
    local element = params.parent.add{
        type = "sprite-button",
        name = params.name,
        style = constants.style_prefix.."main_button",
        mouse_button_filter = {"left", "middle", "right"},
        tags = {
            [constants.gui_tag_private] = {}--[[@as GuiInventorySlot.PrivateTags]],
        },
    }

    local registration_number = script.register_on_object_destroyed(element)

    local instance = setmetatable({
        registration_number = registration_number,
        element = element,
        target = params.target,
        options = params.options or {},
    }--[[@as GuiInventorySlot.SlotObject]], SlotObject.prototype)

    storage.slot_objects[registration_number] = instance
    PlayerData.get_or_create(params.parent.player_index).slot_objects[element.index] = instance

    instance:refresh()

    return instance
end

---@param element LuaGuiElement
---@return GuiInventorySlot.SlotObject?
function SlotObject.get_by_element(element)
    local instance = PlayerData.get_or_create(element.player_index).slot_objects[element.index]
    if instance and instance:valid() then
        return instance
    else
        return nil
    end
end

---@param event EventData.on_object_destroyed
function SlotObject.on_object_destroyed(event)
    storage.slot_objects[event.registration_number] = nil
end

---@return boolean
function SlotObject.prototype:valid()
    return self.element.valid
end

---Get a valid target stack.
---@private
---@return LuaItemStack?
function SlotObject.prototype:get_target_stack()
    if self.target and self.target.valid then
        return self.target
    else
        return nil
    end
end

---Refresh the appearance of the GUI element to reflect the contents of the target.
function SlotObject.prototype:refresh()
    local target_stack = self:get_target_stack()

    if target_stack and target_stack.valid_for_read then
        self.element.sprite = "item/"..target_stack.name
        self.element.quality = target_stack.quality
        self.element.number = not target_stack.prototype.has_flag("not-stackable") and target_stack.count or nil
        self.element.elem_tooltip = {
            type = "item-with-quality",
            name = target_stack.name,
            quality = target_stack.quality.name,
        }
        self.element.tooltip = nil
    else
        self.element.sprite = self.options.empty_sprite
        self.element.quality = nil
        self.element.number = nil
        self.element.elem_tooltip = nil
        self.element.tooltip = self.options.empty_tooltip
    end
end

---Player controllers that are allowed to actually pick/drop items.
SlotObject.real_player_controllers = util.list_to_map{
    defines.controllers.character,
    defines.controllers.god,
    defines.controllers.editor,
}

---@param player LuaPlayer
function SlotObject.prototype:handle_pick_item(player)
    local cursor_stack = player.cursor_stack
    local target_stack = self:get_target_stack()
    if not cursor_stack or not target_stack then return end

    if SlotObject.real_player_controllers[player.controller_type] then
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

            if cursor_stack.count < old_cursor_count then
                self:play_sound(player, "drop", target_stack)
            end
        else
            -- Otherwise, try swapping
            local ret = target_stack.swap_stack(cursor_stack)

            if ret and cursor_stack.valid_for_read then
                self:play_sound(player, "pick", cursor_stack)
            end
            if ret and target_stack.valid_for_read then
                self:play_sound(player, "drop", target_stack)
            end
        end
    end

    self:refresh()
end

---@param player LuaPlayer
function SlotObject.prototype:handle_cursor_split(player)
    local cursor_stack = player.cursor_stack
    local target_stack = self:get_target_stack()
    if not cursor_stack or not target_stack then return end

    if SlotObject.real_player_controllers[player.controller_type] then
        if cursor_stack.valid_for_read then
            -- Try to put in 1 item
            local ret = target_stack.transfer_stack(cursor_stack, 1)

            if ret then
                self:play_sound(player, "drop", target_stack)
            end
        elseif target_stack.valid_for_read then
            -- Take half of the stack
            cursor_stack.transfer_stack(target_stack, math.ceil(target_stack.count / 2))

            if cursor_stack.valid_for_read then
                self:play_sound(player, "pick", cursor_stack)
            end
        end
    end

    self:refresh()
end

---@param player LuaPlayer
---@param kind "pick" | "drop"
---@param item LuaItemStack
function SlotObject.prototype:play_sound(player, kind, item)
    if item.valid_for_read and helpers.is_valid_sound_path("item-"..kind.."/"..item.name) then
        player.play_sound{path = "item-"..kind.."/"..item.name}
    end
end


return SlotObject
