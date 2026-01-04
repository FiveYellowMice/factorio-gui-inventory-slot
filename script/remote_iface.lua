local util = require("util")
local SlotObject = require("script.slot_object")

---@class remote.gui-inventory-slot
local remote_iface = {}

local validate_args = {}

---Create a GUI inventory slot. The internals of the returned GUI element should not be relied upon or modified by the caller,
---other than the properties `name`, `visible`.
---Tags may also be modified, as long as the tag "gui-inventory-slot-private" is preserved.
---@param params GuiInventorySlot.create_params
---@return LuaGuiElement
function remote_iface.create(params)
    local slot_object = SlotObject.create(util.table.deepcopy(validate_args.create_params(params)))
    return slot_object.element
end

---Manually refresh the contents displayed in the slot to reflect the actual content in the target item stack.
---This function only needs to be called when the target item stack may change due to reasons other than interacting with this GUI,
---(e.g. if the target item stack can interact with inserters, call this during on_tick while the GUI is visible).
---@param element LuaGuiElement An element created with `create()`.
function remote_iface.refresh(element)
    local slot_object = SlotObject.get_by_element(element)
    if not slot_object then return end
    slot_object:refresh()
end

---@param element LuaGuiElement An element created with `create()`.
---@return GuiInventorySlot.Target?
function remote_iface.get_target(element)
    local slot_object = SlotObject.get_by_element(element)
    if not slot_object then return end
    return slot_object:get_target()
end

---@param element LuaGuiElement An element created with `create()`.
---@param target LuaItemStack? The new target.
function remote_iface.set_target(element, target)
    local slot_object = SlotObject.get_by_element(element)
    if not slot_object then return end
    slot_object:set_target(validate_args.target(target))
    slot_object:refresh()
end

---@param element LuaGuiElement An element created with `create()`.
---@return GuiInventorySlot.Options?
function remote_iface.get_options(element)
    local slot_object = SlotObject.get_by_element(element)
    if not slot_object then return end
    return util.table.deepcopy(slot_object.options)
end

---@param element LuaGuiElement An element created with `create()`.
---@param options GuiInventorySlot.Options
function remote_iface.set_options(element, options)
    local slot_object = SlotObject.get_by_element(element)
    if not slot_object then return end
    slot_object.options = util.table.deepcopy(validate_args.options(options))
    slot_object:refresh()
end

remote.add_interface("gui-inventory-slot", remote_iface)

---@param params GuiInventorySlot.create_params
---@return GuiInventorySlot.create_params
function validate_args.create_params(params)
    if type(params) ~= "table" then
        error("gui-inventory-slot: params must be a table")
    end
    if type(params.name) ~= "string" then
        error("gui-inventory-slot: name must be a string")
    end
    if type(params.parent) ~= "userdata" or params.parent.object_name ~= "LuaGuiElement" then
        error("gui-inventory-slot: parent must be a LuaGuiElement")
    end
    validate_args.target(params.target)
    if params.options then
        validate_args.options(params.options)
    end
    return params
end

local valid_inventory_index_pair_keys = util.list_to_map{"inventory", "stack_index"}

---@param target GuiInventorySlot.Target
---@return GuiInventorySlot.Target
function validate_args.target(target)
    if target == nil then
        return
    elseif type(target) == "userdata" then
        if target.object_name ~= "LuaItemStack" or not target.valid then
            error("gui-inventory-slot: target must be a valid LuaItemStack or a GuiInventorySlot.Target.InventoryIndexPair")
        end
    elseif type(target) == "table" then
        for k, _ in pairs(target) do
            if not valid_inventory_index_pair_keys[k] then
                error("gui-inventory-slot: target contains invalid key "..k)
            end
        end
        if type(target.inventory) ~= "userdata" or target.inventory.object_name ~= "LuaInventory" or not target.inventory.valid then
            error("gui-inventory-slot: target.inventory must be a valid LuaInventory")
        end
        if type(target.stack_index) ~= "number" or target.stack_index <= 0 then
            error("gui-inventory-slot: target.stack_index must be a positive number")
        end
    end

    return target
end

local valid_options = util.list_to_map{"empty_sprite", "empty_tooltip"}

---@param options GuiInventorySlot.Options
---@return GuiInventorySlot.Options
function validate_args.options(options)
    if type(options) ~= "table" then
        error("gui-inventory-slot: options must be a table")
    end
    for k, _ in pairs(options) do
        if not valid_options[k] then
            error("gui-inventory-slot: options contains invalid key "..k)
        end
    end
    if options.empty_sprite then
        if type(options.empty_sprite) ~= "string" or not helpers.is_valid_sprite_path(options.empty_sprite) then
            error("gui-inventory-slot: options.empty_sprite must be a valid sprite path")
        end
    end
    return options
end
