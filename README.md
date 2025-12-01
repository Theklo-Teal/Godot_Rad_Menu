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
You have to set what text to display in the sectors, with the `items` variable. If you want text in the center, you can add Label node as a child of the RadialMenu, but it could anything else.
The visuals are created in a custom drawing (`_draw()`) function. Several functions are available for override allowing you to make your own drawings without needing to do any math.
When a sector or the center are pressed, it both emits a signal and calls related functions you may override.


# FUTURE IMPROVEMENTS
- The detection of mouse over center and the drawing of the center don't match and I don't know why.
