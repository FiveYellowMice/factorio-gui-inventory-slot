local constants = {}

constants.prefix = "gui-inventory-slot-"

constants.style_prefix = constants.prefix:gsub("-", "_")

constants.slot_interaction_controls = {
    "pick-item",
    -- "stack-transfer",
    -- "inventory-transfer",
    "cursor-split",
    -- "stack-split",
    -- "inventory-split",
    -- "toggle-filter",
    -- "copy-inventory-filter",
    -- "paste-inventory-filter",
}

constants.gui_tag_private = constants.prefix.."private"

return constants
