A trainer for SC:BW 1.15.1 that modifies your minerals and gas in a single-player game. Makes use of a thread to listen for a key-press to activate.

The asm version was written in mASM and needs to be linked as a dll. To do this:
```
\masm32\bin\ml /c /coff Money_Trainer.asm
\masm32\bin\Link /SUBSYSTEM:WINDOWS /DLL Money_Trainer.obj
```

The C++ version was compiled using VS6.0 but should work with any C++ compiler.

Originally written 2008/06/10 by attilathedud.
