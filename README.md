# GUI Inventory Slot (WIP)

A Factorio mod library to create a LuaGuiElement that represents an inventory slot, allowing the player to pick/drop items via modded GUI.

The GUI element does not store the items by itself, but instead requires a target item stack, which may come from an entity or a script inventory. The GUI element displays the content of the target stack, and proxies item pick/drop actions to that item stack.

This is useful for, for example, compound entities where you want to display the contents of a hidden entity in another entity's GUI (e.g. a turret with module slots).

Lmitations compared to vanilla GUI inventory slots (to be improved in the future):

* The bars for durability, ammo magazine, spoilage, health are not displayed.
* Tooltips for an item's data are not displayed, only their prototype information are shown.
* Filters and bars cannot be modified or shown.
* Item ghosts cannot be modified or shown.
* The behaviour of inserting items with data may be inconistent with vanilla slots.
