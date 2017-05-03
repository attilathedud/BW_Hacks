; A trainer for SC:BW 1.15.1 that modifies your minerals and gas in a single-player game. Makes use
; of a thread to listen for a key-press to activate.
;
; Originally written 2008/06/10 by attilathedud.

; System descriptors
.386
.model flat,stdcall
option casemap:none

include \masm32\include\kernel32.inc
includelib \masm32\lib\kernel32.lib
include \masm32\include\user32.inc
includelib \masm32\lib\user32.lib

tMoney proto

.data
sMoney dd 0057F0D8h
sGas dd 0057F0DCh
newMoney dd 9999d
message db "hack activated!",0
bwprinttext dd 004B1C40h

.data?
OldProt dd ?

.code

; Create the tMoney thread inside BW to listen for our keypresses.
DllMain proc hInstance:DWORD, reason:DWORD, lpReserved:DWORD
      mov eax,reason
      cmp eax,1
      jnz @returnf											
      invoke CreateThread, 0, 0, addr tMoney, 0, 0, 0		
	
      @returnf:
            ret 0ch
DllMain endp

; Helper function to write memory. Unprotects the memory at address and then write the value
; passed in nData.
WriteMemory proc address:DWORD, nData:DWORD, len:DWORD
      invoke VirtualProtect,address,len,40h,addr OldProt
      invoke RtlMoveMemory,address,nData,len
      invoke VirtualProtect,address,len,OldProt,0

      ret 0ch
WriteMemory endp

; Helper function to print chat messages. 
printText proc text:DWORD
      push text
      call bwprinttext

      ret 4h
printText endp

; Listen for the 'M' keypress and write our new values to the minerals and gas if received.
tMoney proc
      @thread_loop:
      invoke GetAsyncKeyState,4dh
      cmp eax,0
      jz @sleep
      invoke printText,message
      invoke WriteMemory,sMoney,addr newMoney,4
      invoke WriteMemory,sGas,addr newMoney,4
      @sleep:
      invoke Sleep,100
      jmp @thread_loop
      retn
tMoney endp
        
End DllMain