local constants = require("constants")
local util = require("util")
local PlayerData = require("script.player_data")

local SlotObject = {}

---Represents a managed GUI inventory slot in storage. Lifetime bound to the corresponding GUI element.
---@class GuiInventorySlot.SlotObject
---@field private registration_number uint64 Registration number of the element.
---@field public element LuaGuiElement The root GUI element.
---@field private target_stack LuaItemStack? The target stack.
---@field private target_inventory LuaInventory? The target inventory, if provided by the caller.
---@field private target_stack_index uint32? The index of the target stack in target inventory, if provided by the caller.
---@field public options GuiInventorySlot.Options
SlotObject.prototype = {}
SlotObject.prototype.__index = SlotObject.prototype

---Private data stored in the `constants.gui_tag_private` tag on the root element.
---@class (exact) GuiInventorySlot.PrivateTags

---Specifies a target stack for the items to be actually stored.
---@alias GuiInventorySlot.Target
---| nil
---| LuaItemStack
---| GuiInventorySlot.Target.InventoryIndexPair

---Specifies a target stack with an inventory and a slot index.
---If the inventory belongs to an entity, doing so enables ghost item placement.
---@class (exact) GuiInventorySlot.Target.InventoryIndexPair
---@field inventory LuaInventory
---@field stack_index uint32

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
---@field target GuiInventorySlot.Target Where the items are actually stored.
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
    element.add{
        type = "sprite-button",
        name = "inside_sprite",
        style = constants.style_prefix.."inside_sprite",
        ignored_by_interaction = true,
        visible = false,
        enabled = false,
    }
    element.add{
        type = "flow",
        name = "inside_flow",
        direction = "vertical",
        style = constants.style_prefix.."inside_flow",
    }
    element.inside_flow.add{
        type = "label",
        name = "ghost_number",
        style = constants.style_prefix.."ghost_number",
        ignored_by_interaction = true,
        visible = false,
    }

    local registration_number = script.register_on_object_destroyed(element)

    local instance = setmetatable({
        registration_number = registration_number,
        element = element,
        options = params.options or {},
    }--[[@as GuiInventorySlot.SlotObject]], SlotObject.prototype)

    storage.slot_objects[registration_number] = instance
    PlayerData.get_or_create(params.parent.player_index).slot_objects[element.index] = instance

    instance:set_target(params.target)
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

---@return GuiInventorySlot.Target
function SlotObject.prototype:get_target()
    if self.target_inventory and self.target_stack_index then
        return {
            inventory = self.target_inventory,
            stack_index = self.target_stack_index,
        }
    else
        return self.target_stack
    end
end

---@param target GuiInventorySlot.Target
function SlotObject.prototype:set_target(target)
    if type(target) == "userdata" and target.object_name == "LuaItemStack" then
        self.target_inventory = nil
        self.target_stack_index = nil
        self.target_stack = target
    elseif type(target) == "table" then
        self.target_inventory = target.inventory
        self.target_stack_index = target.stack_index
        self.target_stack = target.inventory[target.stack_index]
    else
        self.target_inventory = nil
        self.target_stack_index = nil
        self.target_stack = nil
    end
end

---Get a valid target stack.
---@private
---@return LuaItemStack?
function SlotObject.prototype:get_target_stack()
    if self.target_stack and self.target_stack.valid then
        return self.target_stack
    else
        return nil
    end
end

---Get the first insert or removal plan in the item request proxy corresponding to the target stack.
---@private
---@return { name: string, quality: string, count: integer }?
function SlotObject.prototype:get_target_ghost()
    if not self.target_inventory or not self.target_stack_index then return end

    if not self.target_inventory.valid then return end
    if not self.target_inventory.index or not self.target_inventory.entity_owner then return end

    local item_request_proxy = self.target_inventory.entity_owner.item_request_proxy
    if not item_request_proxy then return end

    for plan_kind, plan_list in pairs{[1] = item_request_proxy.insert_plan, [-1] = item_request_proxy.removal_plan} do
        for _, plan in ipairs(plan_list) do
            local inventory_positions = plan.items.in_inventory
            if not inventory_positions then goto continue end
            for _, inventory_position in ipairs(inventory_positions) do
                if
                    inventory_position.inventory == self.target_inventory.index and
                    inventory_position.stack + 1 == self.target_stack_index
                then
                    return {
                        name = plan.id.name,
                        quality = plan.id.quality or "normal",
                        count = (inventory_position.count or 1) * plan_kind,
                    }
                end
            end
            ::continue::
        end
    end
end

---Refresh the appearance of the GUI element to reflect the contents of the target.
function SlotObject.prototype:refresh()
    local target_stack = self:get_target_stack()
    local target_ghost = self:get_target_ghost()

    if target_stack and target_stack.valid_for_read then
        self.element.sprite = "item/"..target_stack.name
        self.element.quality = target_stack.quality
        self.element.number = not target_stack.prototype.has_flag("not-stackable") and target_stack.count or nil
        self.element.tooltip = nil
        self.element.elem_tooltip = {
            type = "item-with-quality",
            name = target_stack.name,
            quality = target_stack.quality.name,
        }

        if target_ghost and target_ghost.count > 0 then
            self.element.inside_sprite.visible = false
            self.element.inside_flow.ghost_number.visible = true
            self.element.inside_flow.ghost_number.caption = target_ghost.count
        elseif target_ghost and target_ghost.count < 0 then
            self.element.inside_sprite.visible = true
            self.element.inside_sprite.enabled = true
            self.element.inside_sprite.sprite = "utility/deconstruction_mark"
            self.element.inside_flow.ghost_number.visible = false
        else
            self.element.inside_sprite.visible = false
            self.element.inside_flow.ghost_number.visible = false
        end

    else
        if target_ghost and target_ghost.count > 0 then
            self.element.sprite = nil
            self.element.quality = nil
            self.element.number = nil
            self.element.elem_tooltip = nil
            self.element.tooltip = nil
            self.element.inside_sprite.visible = true
            self.element.inside_sprite.enabled = false
            self.element.inside_sprite.sprite = "item/"..target_ghost.name
            self.element.inside_sprite.quality = target_ghost.quality
            self.element.inside_flow.ghost_number.visible = true
            self.element.inside_flow.ghost_number.caption = target_ghost.count

        else
            self.element.sprite = self.options.empty_sprite
            self.element.quality = nil
            self.element.number = nil
            self.element.elem_tooltip = nil
            self.element.tooltip = self.options.empty_tooltip
            self.element.inside_sprite.visible = false
            self.element.inside_flow.ghost_number.visible = false
        end
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
