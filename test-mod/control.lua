
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

        remote.call("gui-inventory-slot", "create", {
            parent = frame,
            name = "gui-inventory-slot-test",
            target = target_stack,
            options = {
                empty_sprite = "utility/empty_ammo_slot",
                empty_tooltip = "Ammo\n[item=firearm-magazine] Firearm magazine",
            },
        })
    end
end)
