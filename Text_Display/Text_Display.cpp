/*!
*	A simple hook that demonstrates displaying static text using BW's internal print text function.
*
*	Originally written 2008/08/06 by attilathedud.
*/
#define WIN32_LEAN_AND_MEAN
#include <windows.h>

#define address ((unsigned char*)0x48cc32)
unsigned long OldProt = 0;
char* text = "0xEcandy";

/*!
*	Our codecave simply prints the text and then replaces the original instruction.
*
*	The function prototype:
*		push y
*		mov esi, x
*		mov eax, text
*		call 4204a0h
*/
__declspec(naked) void replaced()
{
	__asm{
		pushad
		push 10h
		mov esi,10h
		mov eax,text
		mov ecx,4202a0h
		call ecx
		popad
		imul eax,eax,0dah
		retn
	}
}

/*!
*	Our main function unprotects a section of code within the main game display loop and 
*	then creates a codecave to our custom function.
*/
bool __stdcall DllMain(HANDLE hInstance, DWORD cReason, LPVOID lpReserved)
{
	if(cReason == DLL_PROCESS_ATTACH)
	{
		VirtualProtect(address,6,PAGE_EXECUTE_READWRITE, &OldProt);
		*(address) = 0xe8;
		*(address+1) = (unsigned char)&replaced - (int)address;
		*(address+5) = 0x90;
		VirtualProtect(address,6,OldProt,0);
	}
	else 
		return 0;

	return 1;
}
	
