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

styles[constants.style_prefix.."inside_sprite"] = {
    type = "button_style",
    parent = "transparent_slot",
    disabled_graphical_set = {},
    draw_shadow_under_picture = false,
}

styles[constants.style_prefix.."inside_flow"] = {
    type = "vertical_flow_style",
    width = 32,
    height = 32,
    horizontal_align = "right",
    vertical_spacing = 0,
}

styles[constants.style_prefix.."ghost_number"] = {
    type = "label_style",
    font = "count-font",
    top_margin = 4,
    right_margin = -1,
    parent_hovered_font_color = {1, 1, 1},
}
