; Basic drag-and-drop interface for StarCraft: Brood War 1.16.1. Draws a dot every other space
; to simulate a transparent effect.
;
; Originally written on 2009/05/29 by attilathedud.

; System descriptors
.386							
.model flat,stdcall
option casemap:none

VirtualAlloc proto stdcall :DWORD, :DWORD, :DWORD, :DWORD
VirtualProtect proto stdcall :DWORD, :DWORD, :DWORD, :DWORD
VirtualFree proto stdcall :DWORD, :DWORD, :DWORD
includelib \masm32\lib\kernel32.lib

GetAsyncKeyState proto stdcall :DWORD
includelib \masm32\lib\user32.lib

.data
x dd 10h
y dd 10h
sel db 0 						
wr db 0

.code
	main:
		jmp @F
			ori_printtext dd 4202b0h
			ori_jmpbackt dd 48cf7eh
			ori_jmpbackr dd 41e28dh
			ori_drawbox dd 4e1d20h
			ori_refresh dd 41e0d0h	
			ori_mousesel dd 4d19c0h
			text db "Example",0
			dot db ".",0				
		@@:
		; Save the current state of the stack.
		push ebp
		mov ebp,esp

		; Ensure our dll was loaded validily.
		mov eax,dword ptr ss:[ebp+0ch]
		cmp eax,1
		jnz @returnf

		; Allocate memory for the old protection type.
		; Store this location in ebx.
		push eax
		push 40h
	    push 1000h
	    push 4h
	    push 0
	    call VirtualAlloc 
		mov ebx,eax

		; Unprotect the memory at 48cf79h-48cf7eh
	    push ebx
	    push 40h
	    push 5h
	    push 48cf79h
	    call VirtualProtect 

		; Create a codecave in the drawing routine that will jmp to our hook function.
		; e9h is the opcode to jmp, with the address of the jump being calculated by subtracting
		; the address of the function to jump to from our current location.
	    mov byte ptr ds:[48cf79h],0e9h
	    lea ecx,@hook
	    sub ecx,48cf7eh
	    mov dword ptr ds:[48cf7ah],ecx

		; Reprotect the memory we just wrote.
	    push 0
	    push dword ptr ds:[ebx]
	    push 5h
	    push 48cf79h
	    call VirtualProtect 

		; Unprotect the memory at 41e287h - 41e28ch
	    push ebx
	    push 40h
	    push 5h
	    push 41e287h
	    call VirtualProtect 

		; Create a codecave in the refresh routine that will jmp to our refresh hook function.
	    mov byte ptr ds:[41e287h],0e9h
	    lea ecx,@refresh
	    sub ecx,41e28ch
	    mov dword ptr ds:[41e288h],ecx
	    mov byte ptr ds:[41e28ch],90h

		; Reprotect the memory we just wrote.
	    push 0
	    push dword ptr ds:[ebx]
	    push 5h
	    push 41e287h
	    call VirtualProtect 

		; Unprotect the memory at 4d235dh - 4d2361h
	   	push ebx
	    push 40h
	    push 4h
	    push 4d235dh
	    call VirtualProtect 

		; Create a codecave in the routine that checks for mouse input that will jmp to our mouse hook.
		; Because this is already a call instruction we only need to write the destination opcodes.
	    lea ecx,@mouse_hook
	    sub ecx,4d2361h
	    mov dword ptr ds:[4d235dh],ecx

		; Reprotect the memory we just wrote.
	    push 0
	    push dword ptr ds:[ebx]
	    push 4h
	    push 4d235dh
	    call VirtualProtect 

		; Free the memory we allocated for our protection type.
	    push 4000h
	    push 4h
	    push ebx
	    call VirtualFree 

		; Restore eax and the stack
		pop eax
		@returnf:
			leave
			retn 0ch
			
		; Our mouse hook checks to see if we are currently dragging our box. If so,
		; disable mouse inputs to the game field.
		@mouse_hook:
			cmp sel,0
			jnz @st
			push 4
			call dword ptr cs:[ori_mousesel]
			@st:
				retn
			
		; Since we are adding a new box to the screen, we need to add another call to the 
		; refresh function in the main game loop to avoid flickering.
		@refresh:
			pushad
			push 640h
			mov eax,0
			mov edx,480h
			mov ecx,0
			call dword ptr cs:[ori_refresh]
			popad
			
			mov edi,dword ptr ds:[6ceff4h]
			jmp ori_jmpbackr
			
		; Helper function to draw a transparent box by drawing a '.' every other space.
		; Takes 4 arguments on the stack and is called like so:
		; push height
		; push width
		; push y
		; push x
		; call @drawtbox
		@drawtbox:						
			push ebp
			mov ebp,esp
			xor ebx,ebx
			@yloop:
				xor edx,edx
				@xloop:
					push edx
					mov eax,[ebp+0ch]
					add eax,ebx
					push eax
					mov esi,[ebp+8h]
					add esi,edx
					lea eax,dot
					call dword ptr cs:[ori_printtext]
					pop edx
					add edx,3h
					cmp edx,[ebp+10h]
					jl @xloop
				add ebx,2h
				cmp ebx,[ebp+14h]
				jl @yloop
			leave
			retn 10h
			
		; Our main hook. Responsible for drawing our transparent box and moving our box if we are in
		; the process of dragging it.
		@hook:
			pushad

			; Check to see if we are in the bounds of our box.
			mov sel,0
			mov ebx,dword ptr ds:[6cddc4h]			
			cmp ebx,x
			jl @keycheck	
			mov ecx,x							
			add ecx,100h						
			cmp ebx,ecx
			jg @keycheck
			mov ebx,dword ptr ds:[6cddc8h]
			cmp ebx,y
			jl @keycheck		
			mov ecx,y
			add ecx,30h
			cmp ebx,ecx
			jg @keycheck
			mov sel,1	

			; Check to see if we are holding down mouse1.
			@keycheck:
				push 1h
				call GetAsyncKeyState 						
				test eax,eax
				jz @mouse_up	
				cmp wr,1
				
				; If not, jump to the drawing routine.
				jz @draw	

				; If so, add a drag offset based on the vector of movement from the center of our
				; box and toggle off the movement event so we don't get stuck in a loop.
				mov ebx,dword ptr ds:[6cddc8h]		
				cmp ebx,y
				jl @difloc		
				mov ecx,y
				add ecx,30h
				cmp ebx,ecx
				jg @difloc							
				mov ebx,dword ptr ds:[6cddc4h]			
				cmp ebx,x
				jl @difloc	
				mov ecx,x							
				add ecx,100h						
				cmp ebx,ecx
				jg @difloc
				cmp ebx,1edh
				jle @lessx
				mov ebx,1edh
				@lessx: 						
					cmp ebx,70h
					jge @finx
					mov ebx,70h
				@finx:							
					sub ebx,x				
					sub ebx,70h
					add x,ebx	
				mov ebx,dword ptr ds:[6cddc8h]
				cmp ebx,150h
				jle @lessy
				mov ebx,150h
				@lessy:							
					cmp ebx,15h
					jge @finy
					mov ebx,15h
				@finy:
					sub ebx,y
					sub ebx,15h
					add y,ebx
				jmp @draw
			@mouse_up:
				mov wr,0
				jmp @draw
			@difloc:
				mov wr,1				
			@draw:	
				push 6fh
				push 100h
				push y
				push x
				call @drawtbox	
				mov byte ptr ds:[6cf4ach],2
				push 10h
				push 100h
				push y
				push x
				call dword ptr cs:[ori_drawbox]
				push y
				mov esi,x
				add esi,4h
				lea eax,text
				call dword ptr cs:[ori_printtext]
			
			popad

			; The original instruction replaced.
			mov edi,70h
			jmp ori_jmpbackt
	
	end main