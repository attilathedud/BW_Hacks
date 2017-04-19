Basic drag-and-drop interface for StarCraft: Brood War 1.16.1. Draws a dot every other space to simulate a transparent effect.

The hack was written in mASM and needs to be linked as a dll. To do this:
```
\masm32\bin\ml /c /coff Drag_and_Drop_GUI.asm
\masm32\bin\Link /SUBSYSTEM:WINDOWS /DLL Drag_and_Drop_GUI.obj
```

![Hack Screenshot](screenshot.jpg?raw=true "Screenshot Hack")

Originally written on 2009/05/29 by attilathedud.