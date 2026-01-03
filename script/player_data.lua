local PlayerData = {}

---@class GuiInventorySlot.PlayerData
---@field public slot_objects table<uint32, GuiInventorySlot.SlotObject?> Weak index of LuaGuiElement::index to slot object.
PlayerData.prototype = {}
PlayerData.prototype.__index = PlayerData.prototype

PlayerData.slot_objects_metatable = {
    __mode = "v",
}


function PlayerData.on_init()
    ---@package
    ---@type table<uint32, GuiInventorySlot.PlayerData?>
    storage.players = {}
end

---@param player_index uint32
---@return GuiInventorySlot.PlayerData
function PlayerData.get_or_create(player_index)
    local instance = storage.players[player_index]
    if not instance then
        instance = setmetatable({
            slot_objects = setmetatable({}, PlayerData.slot_objects_metatable),
        }--[[@as GuiInventorySlot.PlayerData]], PlayerData.prototype)
        storage.players[player_index] = instance
    end
    return instance
end

---@param event EventData.on_player_removed
function PlayerData.on_player_removed(event)
    storage.players[event.player_index] = nil
end


return PlayerData
