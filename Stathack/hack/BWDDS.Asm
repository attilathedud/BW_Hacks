; Brood War Drag-and-Drop Stathack (BWDDS) is a hack that displays all the players' 
; minerals using an interface built from Drag_and_Drop_GUI. Works for BW version 1.16.1.
;
; Originally written 2009/06/09 by attilathedud.

; System descriptors
.386							
.model flat,stdcall
option casemap:none

VirtualAlloc proto stdcall :DWORD, :DWORD, :DWORD, :DWORD
VirtualProtect proto stdcall :DWORD, :DWORD, :DWORD, :DWORD
VirtualFree proto stdcall :DWORD, :DWORD, :DWORD
includelib \masm32\lib\kernel32.lib

; Import in wsprintf so we can combine together the minerals and player.
wsprintfA proto c :DWORD, :VARARG
GetAsyncKeyState proto stdcall :DWORD
includelib \masm32\lib\user32.lib

.data
x dd 10h
y dd 10h
info db 0h
wr db 0h

.code
	main:
		jmp @F
			ori_printtext dd 4202b0h
			ori_jmpbackt dd 48cf7eh
			ori_jmpbackr dd 41e28dh
			ori_drawbox dd 4e1d20h
			ori_refresh dd 41e0d0h	
			ori_mousesel dd 4d19c0h
			ori_drawborder dd 4e1c70h
			format db "%d",0
			text db "BWDDS",0
			players db "Players:",0
			minerals db "Minerals:",0
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
			
		; Our main hook. Responsible for drawing our box and moving our box if we are in
		; the process of dragging it.
		@hook:
			pushad

			; Check to see if we are holding down mouse1.
			push 1h
			call GetAsyncKeyState 						
			test eax,eax

			; If not, jump to the drawing routine.
			jz @draw	

			; Check to see if we are in the bounds of our box.
			; If so, add a drag offset based on the vector of movement from the center of our
			; box and toggle off the movement event so we don't get stuck in a loop.
			mov ebx,dword ptr ds:[6cddc8h]		
			cmp ebx,y
			jl @draw		
			mov ecx,y
			add ecx,30h
			cmp ebx,ecx
			jg @draw						
			mov ebx,dword ptr ds:[6cddc4h]			
			cmp ebx,x
			jl @draw	
			mov ecx,x							
			add ecx,0b8h						
			cmp ebx,ecx
			jg @draw
			cmp ebx,1edh
			jle @lessx
			mov ebx,1edh
			@lessx: 					
				cmp ebx,50h
				jge @finx
				mov ebx,50h
			@finx:							
				sub ebx,x				
				sub ebx,50h
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
						
			; Draw our title box and the title bar info.
			@draw: 
				mov byte ptr ds:[6cf4ach],2
				push 10h
				push 0b8h
				push y
				push x
				call dword ptr cs:[ori_drawbox]
				push y
				mov esi,x
				add esi,4h
				lea eax,text
				call dword ptr cs:[ori_printtext]		
				mov edi,y
				add edi,0eh
				push edi
				mov esi,x
				add esi,2h
				lea eax,players
				call dword ptr cs:[ori_printtext]
				push edi
				add esi,80h
				lea eax,minerals
				call dword ptr cs:[ori_printtext]
						
				; Iterate through the players' names and mineral counts. Combine them using
				; wsprintf and display the result.
				mov eax,57eec7h
				mov edx,y
				add edx,0eh
				xor edi,edi
				mov esi,57f0ech
				@playerloop:
					add eax,24h
					add esi,4h
					cmp byte ptr ds:[eax],0h
					jz @cms
					add edx,0eh
					push eax
					push edx
					push edx
					push esi
					mov esi,x
					add esi,0ah
					push edx
					call dword ptr cs:[ori_printtext]
					pop esi
					mov ebx,dword ptr ds:[esi]
					push ebx
					lea ebx,format
					push ebx
					lea ebx,info
					push ebx		
					call wsprintfA 
					add esp,0ch
					pop edx
					push esi
					lea eax,info
					push edx
					mov esi,x
					add esi,88h
					call dword ptr cs:[ori_printtext]
					pop esi
					pop edx
					pop eax
					inc edi
					@cms:
						cmp eax,57efe7h
						jnz @playerloop
						
				; Draw the border outlines around the display.
				mov al,byte ptr ds:[6ceb21h]
				mov byte ptr ds:[6cf4ach],al
				push 10h
				push 0b8h
				push x
				mov esi,y
				call dword ptr cs:[ori_drawborder]
				mov eax,edi
				mov ecx,0eh
				mul ecx
				add eax,0eh
				push eax
				push 0b8h
				push x
				mov esi,y
				add esi,0eh
				call dword ptr cs:[ori_drawborder]
			
			popad

			; The original instruction replaced.
			mov edi,70h
			jmp ori_jmpbackt
	
	end main