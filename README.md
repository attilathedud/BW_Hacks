# BW_Hacks
A collection of older Starcraft: Brood War hacks.

## Clock
A simple hack that displays a clock with the current time on the top resources bar of BW. Works for BW version 1.16.1.

![Hack Screenshot](Clock/screenshot.jpg?raw=true "Screenshot Hack")

## Drag_and_Drop_GUI
Basic drag-and-drop interface for StarCraft: Brood War 1.16.1. Draws a dot every other space to simulate a transparent effect.

![Hack Screenshot](Drag_and_Drop_GUI/screenshot.jpg?raw=true "Screenshot Hack")

## Money_Trainer
A trainer for SC:BW 1.15.1 that modifies your minerals and gas in a single-player game. Makes use of a thread to listen for a key-press to activate.

Both a C++ and asm version are available.

## Stathack
Brood War Drag-and-Drop Stathack (BWDDS) is a hack that displays all the players' minerals using an interface built from Drag_and_Drop_GUI. Works for BW version 1.16.1.

![Hack Screenshot](Stathack/screenshot.jpg?raw=true "Screenshot Hack")

## Text_Display
A simple hook that demonstrates displaying static text using BW's internal print text function.

![Hack Screenshot](Text_Display/screenshot.jpg?raw=true "Screenshot Hack")

## Some notes
A bunch of random addresses related to patch 1.16.1.

### Printing text
```
push y
mov eax, text
mov esi, x
CALL StarCraf.004202B0  ;PrintText
```

### Places that call PrintText
```
References in StarCraf:.text to 004202B0
Address    Disassembly                               Comment
00416967   CALL StarCraf.004202B0		-	chat text(while typing)
00457525   CALL StarCraf.004202B0		-	armor/weapon upgrade text(numbers)
00458FDC   CALL StarCraf.004202B0		-	mineral amount when buying a unit
004590DC   CALL StarCraf.004202B0		-	unit name, move, stop commands in boxes
004E556F   CALL StarCraf.004202B0		-	minerals/gas/etc.
004EF987   CALL StarCraf.004202B0		-	unit information
00417BFE   CALL StarCraf.004202B0		-	main menu text
```

### Drawing a border
```
push height
push width
push x
mov esi,y
call StarCraf.004E1C70
```

### Drawing a box
```
push height
push width
push y
push x
call StarCraf.004E1D20
```

### Player 1 Mineral Address
```
57f0f0
```

### Mouse coordinates
```
add ax,word ptr ds:[006CDDC8h]		;mouse cords y
add bx,word ptr ds:[006CDDC4h]		;mouse cords X
```

### Sending a mouse click
```
004D2355     6A 04          PUSH 4                                   ; /Arg1 = 00000004
004D2357     B8 02000000    MOV EAX,2                                ; |
004D235C     E8 5FF6FFFF    CALL StarCraf.004D19C0                   ; \StarCraf.004D19C0
004D2361  |. 5F             POP EDI
;lmousebutton down
```

### Changing the mouse cursor
```
004D1460     A1 C8DD6C00    MOV EAX,DWORD PTR DS:[6CDDC8]
```

### Refresh function
```
41e0d0h
```

### Names
```
57eeeb	-	player 1 name
57ef0f	-	p2
57ef33	-	p3
57ef57  -   etc.
57ef7b
57ef9f
57efc3
57efe7
```
