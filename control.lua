local constants = require("constants")
local PlayerData = require("script.player_data")
local SlotObject = require("script.slot_object")
require("script.remote_iface")

script.register_metatable("PlayerData.prototype", PlayerData.prototype)
script.register_metatable("PlayerData.slot_objects_metatable", PlayerData.slot_objects_metatable)
script.register_metatable("SlotObject.prototype", SlotObject.prototype)


script.on_init(function()
    SlotObject.on_init()
    PlayerData.on_init()
end)


-- Listen to custom input events on our elements.
local slot_interaction_custom_inputs = {}
for _, control in ipairs(constants.slot_interaction_controls) do
    table.insert(slot_interaction_custom_inputs, constants.prefix..control)
end
---@param event EventData.CustomInputEvent
script.on_event(slot_interaction_custom_inputs, function(event)
    if not event.element or not event.element.tags[constants.gui_tag_private] then return end

    local player = game.get_player(event.player_index) --[[@as LuaPlayer]]
    local control_name = event.input_name:sub(#constants.prefix + 1)
    local slot_object = SlotObject.get_by_element(event.element)
    if not slot_object then return end

    -- Call handler of this interaction.
    local handler = slot_object["handle_"..control_name:gsub("-", "_")]
    if handler then
        handler(slot_object, player)
    end
end)


script.on_event(defines.events.on_player_removed, function(event)
    PlayerData.on_player_removed(event)
end)

script.on_event(defines.events.on_object_destroyed, function(event)
    SlotObject.on_object_destroyed(event)
end)
