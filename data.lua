local constants = require("constants")

for _, control in ipairs(constants.slot_interaction_controls) do
    data:extend{{
        type = "custom-input",
        name = constants.prefix..control,
        key_sequence = "",
        linked_game_control = control,
    }}
end

local styles = data.raw["gui-style"]["default"]

styles[constants.style_prefix.."main_button"] = {
    type = "button_style",
    parent = "inventory_slot",
    clicked_vertical_offset = 0,
}
