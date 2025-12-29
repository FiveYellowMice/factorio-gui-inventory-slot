local gui_inventory_slot = require("lib")

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

        local button = gui_inventory_slot.create(frame, "gui-inventory-slot-test")
        gui_inventory_slot.refresh(button, target_stack)
    end
end)

script.on_event(defines.events.on_gui_click, function(event)
    if event.element.name == "gui-inventory-slot-test" then
        local player = game.get_player(event.player_index)
        if not player then return end

        if player.opened.object_name ~= "LuaEntity" then return end
        local target_stack = player.opened.get_inventory(defines.inventory.chest)[1]

        gui_inventory_slot.click(event.element, target_stack, player, event.button)
    end
end)
