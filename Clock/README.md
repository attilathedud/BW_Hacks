A simple hack that displays a clock with the current time on the top resources bar of BW. Works for BW version 1.16.1.

The hack was written in mASM and needs to be linked as a dll. To do this:
```
\masm32\bin\ml /c /coff Clock.asm
\masm32\bin\Link /SUBSYSTEM:WINDOWS /DLL Clock.obj
```

![Hack Screenshot](screenshot.jpg?raw=true "Screenshot Hack")

Originally written 2009/04/19 by attilathedud.
