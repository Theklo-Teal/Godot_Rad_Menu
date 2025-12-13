For Paracortical Initiative, 2025, Diogo "Theklo" Duarte

Other projects:
- [Bluesky for news on any progress I've done](https://bsky.app/profile/diogo-duarte.bsky.social)
- [Itchi.io for my most stable playable projects](https://diogo-duarte.itch.io/)
- [The Github for source codes and portfolio](https://github.com/Theklo-Teal)
- [Ko-fi is where I'll accept donations](https://ko-fi.com/paracortical)

# DESCRIPTION
A control node that displays a radial menu where sectors can be pressed as buttons as well as the center. It's useful as a quick and dirty option for prototyping, or if you want to build upon to make a more elaborate radial menu.

# INSTALLATION
This isn't technically a Godot Plugin, it doesn't use the special Plugin features of the Editor, so don't put it inside the "plugin" folder. The folder of the tool can be anywhere else you want, though, but I suggest having it in a "modules" folder.

After that, the «class_name RadialMenu» registers the node so you can add it to a project like you add any Godot node.

# USAGE
You may set what to display in the menu by adding children, this will create "sectors", usually would be a Label node. Caveats:
- You might need to set `mouse_filter` in the children to "ignore".
- There isn't a way to have nodes in the center, but you can display images by overriding `draw_center_*()` with `draw_texture()`or `draw_texture_rect()`.

Several functions are available for override and variables like `center` and `proper_radius` allowing you to make your own drawings without needing to do any math.
When a sector or the center are pressed, they both emit a signal and call related functions you may override.

# TIPS
Look for the "Utility" and "Helper" function regions in the code that may be useful in for your overriding purposes.
There's a `draw_background()` to draw something constant behind any other thing.
Don't forget that Godot's `draw_*` are very varied. You can draw textures, StyleBoxes and even render text.
If you want to have the menu remember the last pressed sector, as in toggle it like Button nodes, just add a variable "pressed_item" and check for that in the `_draw_sector_normal()` function.
If you want text spelled radially to the center, rather than always horizontal, you may override the `arrange_children()` function (requires copying the default code) and add `item.rotation = center.angle_to_point(item.position)`. You may need to tweak position offsets, though.
# FUTURE IMPROVEMENTS
- Maybe the RadialMenu should extend the Container class.
- Fix the `start_angle` not being respected by mouse hotspots consistently.
- There's a positioning issue where the RadialMenu doesn't respect how parent Container nodes try to arrange the RadialMenu.
