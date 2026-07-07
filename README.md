# AvatarApp
Simple PNGTuber app for Godot 4.7.

Attempt to do a universal (MacOS and Windows) application for streaming or any similar use for Godot 4.7, using an external keyboard listener in Python (I couldn't find an in-engine solution, so I had to use something else).

A system-specific consideration is the mouse passthrough capacities of the application. Windows has an awkward way of dealing with this—being a bit hard to pass a mouse click at the OS-level through a visible window, however, extending this with the correct behaviour in C# is advised elsewhere.

Then, a Godot related problem is solved with the keyboard listener Python code—which works as a 'keylogger', but I couldn't find a better solution yet. Becuase of it, and to have all functionalities, it is recommended that anyone using this application to have Python installed on their machine.

This project is open-sourced (while the provided images I use personally—please, keep this in mind), you can use as you seem fit. Again, just be careful with the usage of the sprite art.

Cheers,
Mars!
