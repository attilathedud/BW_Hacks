/*!
*	A trainer for SC:BW 1.15.1 that modifies your minerals in a single-player game. 
*	Makes use of a thread to listen for a key-press to activate.
*
*	Originally written 2007/10/06 by attilathedud.
*/
#include <windows.h>

/*!
*	Injected thread that listens for 'L' to be pressed before modifying the mineral address' value.
*/
DWORD WINAPI inject()
{
	bool keydown = 0;
	int *minerals = (int*)0x0057f0d8;

	while(true)
	{
		if(!GetAsyncKeyState('L'))
		{
			Sleep(100);
			keydown = 0;
		}
		else 
		{
			if(keydown == 0)
			{
				*minerals = 50000;
				keydown = 1;
			}
		}
	}
	return 0;
}

/*!
*	Our main simply creates a thread within BW.
*/
BOOL WINAPI DllMain(HANDLE hHandle, DWORD cReason, LPVOID lpvoid)
{
	if(cReason == DLL_PROCESS_ATTACH)
	{
		CreateThread(NULL, NULL, (LPTHREAD_START_ROUTINE)inject, NULL, NULL, NULL);
	}
	else
		return false;
		
	return true;
}