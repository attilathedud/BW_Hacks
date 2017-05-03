/*!
*	The front-end responsible for injecting the BWDDS.dll into the target process.
*	Assumes the target process is open before injecting and the dll resides in the same directory
*	as the injector.
*
*	Originally written 2009/06/09 by attilathedud.
*/

#include <windows.h>
#include <stdio.h>

DWORD curwindowid;
int c;

HANDLE (*LoadLib)(LPCSTR);

/*!
*	Given a window title, fill curwindowid with the process id of that process. Note that 
*	FindWindow is a terrible method.
*/
void getProcessIdCur(char* window)
{
	HWND curwindow;
	while(!(curwindow = FindWindow(NULL, window)));

	GetWindowThreadProcessId(curwindow, &curwindowid);
}

/*!
*   Our injection function works by the following process:
*
*   1. Open a process handle to BW as given by the process id.
*   2. Allocate and write our dlls path into the process' memory space.
*   3. Create a thread inside BW that will invoke LoadLibrary along with a parameter to our dll's name
*       inside the process.
*/
HANDLE inject(DWORD pid, char* dllname)
{
	HANDLE process, pointless;
	
	char* dllnamet;

	if(!pid)
		return false;

	// Get BW's process handle.
	process = OpenProcess(PROCESS_ALL_ACCESS, TRUE, pid);
	
	// Get the address of Loadlib
	LoadLib = (HANDLE (*)(LPCSTR))GetProcAddress(LoadLibrary("kernel32.dll"), "LoadLibraryA");

	// Allocate the space for our dll name inside the process.
	dllnamet = (char*)VirtualAllocEx(process, NULL, strlen(dllname) + 1, MEM_COMMIT, PAGE_READWRITE);
	
	// Check for permission errors.
	c = GetLastError();
	
	// Write our dll's name inside the process.
	WriteProcessMemory(process, dllnamet, dllname, strlen(dllname) + 1, NULL);
		
	// Create our thread that will invoke LoadLibrary on our dll name.	
	HANDLE thread = CreateRemoteThread(process, NULL, 0, (LPTHREAD_START_ROUTINE)LoadLib, dllnamet, 0, NULL);
	WaitForSingleObject(thread, INFINITE);
	GetExitCodeThread(thread, (DWORD*)&pointless );

	if( ! pointless)
		printf("Cannot inject\n");
	else
		printf("Injected Succesfully\n");
	
	// Free the memory we allocated and close active handles.
	VirtualFreeEx(process, NULL, strlen(dllname) + 1, MEM_DECOMMIT);
	
	printf(" Error: %d\n Dll Name: %s\n",c, dllname);
	
	CloseHandle(process);
	CloseHandle(thread);

	return pointless;
}

/*!
*   When Blizzard released patch 1.15.1 for Starcraft: Brood War, they introduced a new method
*   of anti-hack protection that was intended as a low-wall to keep out inexperienced hackers.
*   All this new method did was ensure that any process touching a Blizzard process had an elevated 
*   privilege (SE_DEBUG).
*/
void AdjustTokenPrivs(void)
{
	HANDLE token;
    LUID luid;
    TOKEN_PRIVILEGES tp;

	OpenProcessToken(GetCurrentProcess(), 40, &token);
	LookupPrivilegeValue(NULL, "SeDebugPrivilege", &luid);

	tp.PrivilegeCount = 1;
    tp.Privileges[0].Luid = luid;
    tp.Privileges[0].Attributes = 2;

	AdjustTokenPrivileges(token, FALSE, &tp, 28, NULL, NULL);
}

int main(int argc, char* argv[])
{
    char path[256] = {0};

	// Adjust our applications privilege to SE_DEBUG.
	AdjustTokenPrivs();

	// Get BW's process id.
	getProcessIdCur("Brood War");

	// Create a path to our dll. Assume it resides in the same folder as the launcher.
	GetModuleFileName(NULL, path, sizeof(path));

	for(int i = strlen(path); path[i] != '\\'; i--)
		path[i] = 0;
	strcat(path, "BWDDS.dll");
	
	printf("BWDDS.exe\n\n");

	inject(curwindowid, path);

	printf("Coded by attilathedud.\n");

	getchar();
	
	return 0;
}
