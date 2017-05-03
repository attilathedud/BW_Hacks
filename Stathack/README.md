Brood War Drag-and-Drop Stathack (BWDDS) is a hack that displays all the players' minerals using an interface built from Drag_and_Drop_GUI. Works for BW version 1.16.1.

The injector was written in C++ and compiled in VS6, but should compile with any C++ compiler.

The hack was written in mASM and needs to be linked as a dll. To do this:
```
\masm32\bin\ml /c /coff BWDDS.asm
\masm32\bin\Link /SUBSYSTEM:WINDOWS /DLL BWDDS.obj
```

![Hack Screenshot](screenshot.jpg?raw=true "Screenshot Hack")

Originally written 2009/06/09 by attilathedud.
