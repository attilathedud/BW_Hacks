; A simple hack that displays a clock with the current time on the top resources bar of BW.
; Works for BW version 1.16.1.
;
; Originally written 2009/04/19 by attilathedud.

; System descriptors
.386
.model flat,stdcall
option casemap:none

VirtualAlloc proto stdcall :DWORD, :DWORD, :DWORD, :DWORD
VirtualProtect proto stdcall :DWORD, :DWORD, :DWORD, :DWORD
VirtualFree proto stdcall :DWORD, :DWORD, :DWORD

include \masm32\include\kernel32.inc
includelib \masm32\lib\kernel32.lib
include \masm32\include\user32.inc
includelib \masm32\lib\user32.lib

include \masm32\include\windows.inc

.data
time_holder SYSTEMTIME <>
time_formatted db 0

.code
	main:
		jmp @F
			ori_printtext dd 4202b0h
			ori_jmpback dd 48cf7eh 
			ori_drawbox dd 4e1d20h
			ori_refresh dd 41e0d0h	
			format db "%02d: %02d: %02d",0
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
			
		; Our main hook. Responsible for drawing our title box and displaying the current time.
		@hook:
			pushad

			; Display a black bar across the whole top.
			mov byte ptr ds:[6cf4ach],0
			push 14h
			push 280h
			push 0h
			push 0h
			call dword ptr cs:[ori_drawbox]

			; Display a blue box for menu text
			mov byte ptr ds:[6cf4ach],1h
			push 14h
			push 20h
			push 0h
			push 0dh
			call dword ptr cs:[ori_drawbox]

			; Display "Menu". We use text already located at 763e07a1h that is used for the main menu.
			push 3h
			mov esi,10h
			mov eax,763e07a1h
			call dword ptr cs:[ori_printtext]

			; Display | | around our time.
			push 3h
			mov esi,1aah
			mov eax,597238h
			call dword ptr cs:[ori_printtext]
			push 3h
			mov esi,16ah
			mov eax,597238h
			call dword ptr cs:[ori_printtext]

			; Get the current time and format it.
			lea eax,time_holder
			push eax
			call GetLocalTime
			xor eax,eax
			mov ax,time_holder.wSecond
			push eax
			mov ax,time_holder.wMinute
			push eax
			mov ax,time_holder.wHour
			push eax
			lea eax,format
			push eax
			lea eax,time_formatted
			push eax
			call wsprintf 
			add esp,14h

			; Print out the current time.
			push 3h
			mov esi,170h
			lea eax,time_formatted
			call dword ptr cs:[ori_printtext]

			; Trigger a refresh since we need to place the minerals and gas on top of our
			; bar we drew.
			push 200h
			mov eax,0
			mov edx,6h
			mov ecx,0
			call dword ptr cs:[ori_refresh]
			popad

			; The original instruction.
			mov edi,70h
			jmp ori_jmpback

	end main