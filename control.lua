local gui_inventory_slot = require("lib")

local test_slot_options = {
    empty_sprite = "utility/empty_ammo_slot",
    empty_tooltip = "Ammo\n[font=default-large][item=firearm-magazine][/font] Firearm magazine\n",
}

script.on_event(defines.events.on_gui_opened, function(event)
    if event.entity and event.entity.name == "iron-chest" then
        local player = game.get_player(event.player_index)
        if not player then return end

        local frame = player.gui.relative["gui-inventory-slot-test-frame"]
        if frame then frame.destroy() end

        frame = player.gui.relative.add{
            type = "frame",
            name = "gui-inventory-slot-test-frame",
            caption = "Test",
            anchor = {
                gui = defines.relative_gui_type.container_gui,
                name = "iron-chest",
                ghost_mode = "only_real",
                position = defines.relative_gui_position.right,
            },
        }

        local target_stack = player.opened.get_inventory(defines.inventory.chest)[1]

        local button = gui_inventory_slot.create{
            parent = frame,
            name = "gui-inventory-slot-test"
        }
        gui_inventory_slot.refresh{element = button, target = target_stack, options = test_slot_options}
    end
end)

script.on_event(defines.events.on_gui_click, function(event)
    if event.element.name == "gui-inventory-slot-test" then
        local player = game.get_player(event.player_index)
        if not player then return end

        if player.opened.object_name ~= "LuaEntity" then return end
        local target_stack = player.opened.get_inventory(defines.inventory.chest)[1]

        gui_inventory_slot.click{
            element = event.element,
            target = target_stack,
            options = test_slot_options,
            player = player,
            button = event.button,
        }
    end
end)
