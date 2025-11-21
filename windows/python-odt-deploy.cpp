#define UNICODE
#define _UNICODE
#include <windows.h>
#include <winhttp.h>
#include <stdio.h>

#pragma comment(lib, "winhttp.lib")

static const wchar_t *ODT_URL =
    L"https://download.microsoft.com/download/"
    L"6c1eeb25-cf8b-41d9-8d0d-cc1dbc032140/"
    L"officedeploymenttool_19328-20210.exe";

static const unsigned int LENGTH_HOST_NAME = 256;
static const unsigned int LENGTH_URL_PATH  = 1024;

BOOL DownloadFileWinHTTP(const wchar_t *url, const wchar_t *outputPath)
{
    BOOL result = FALSE;
    DWORD size = 0;
    BYTE buffer[8192];

    URL_COMPONENTS urlComponents = {0};
    wchar_t host[LENGTH_HOST_NAME];
    wchar_t path[LENGTH_URL_PATH];

    urlComponents.dwStructSize     = sizeof(urlComponents);
    urlComponents.lpszHostName     = host;
    urlComponents.dwHostNameLength = LENGTH_HOST_NAME;
    urlComponents.lpszUrlPath      = path;
    urlComponents.dwUrlPathLength  = LENGTH_URL_PATH;

    if (!WinHttpCrackUrl(url, 0, 0, &urlComponents))
        return FALSE;

    HINTERNET session = WinHttpOpen(
        L"WinHTTPDownloader/1.0",
        WINHTTP_ACCESS_TYPE_DEFAULT_PROXY,
        WINHTTP_NO_PROXY_NAME,
        WINHTTP_NO_PROXY_BYPASS, 0);

    if (session)
    {
        HINTERNET connection = WinHttpConnect(
            session,
            urlComponents.lpszHostName,
            urlComponents.nPort,
            0);

        if (connection)
        {
            DWORD flags = (urlComponents.nPort == 443) ? WINHTTP_FLAG_SECURE : 0;
            HINTERNET request = WinHttpOpenRequest(
                connection,
                L"GET",
                urlComponents.lpszUrlPath,
                NULL,
                WINHTTP_NO_REFERER,
                WINHTTP_DEFAULT_ACCEPT_TYPES,
                flags
            );

            if (request)
            {
                bool isRequestSent = WinHttpSendRequest(
                    request, WINHTTP_NO_ADDITIONAL_HEADERS, 0, 0, 0, 0, 0);
                bool isResponseReceived = WinHttpReceiveResponse(request, NULL);
                if (isRequestSent && isResponseReceived)
                {
                    HANDLE file = CreateFileW(
                        outputPath,
                        GENERIC_WRITE,
                        0,
                        NULL,
                        CREATE_ALWAYS,
                        FILE_ATTRIBUTE_NORMAL,
                        NULL);

                    bool isFileCreated = file != INVALID_HANDLE_VALUE;
                    if (isFileCreated)
                    {
                        while (WinHttpReadData(request, buffer, sizeof(buffer), &size)
                               && size > 0)
                        {
                            DWORD written = 0;
                            WriteFile(file, buffer, size, &written, NULL);
                        }

                        CloseHandle(file);
                        result = TRUE;
                    }
                }
                else
                {
                    WinHttpCloseHandle(request);
                }
            }
            else
            {
                WinHttpCloseHandle(request);
            }
        }
        else
        {
            WinHttpCloseHandle(connection);
        }
    }

    return result;
}

int RunProcess(const wchar_t *exe, const wchar_t *args)
{
    wchar_t command[4096];
    swprintf(command, 4096, L"\"%s\" %s", exe, args);

    STARTUPINFOW startupInfo = {0};
    PROCESS_INFORMATION processInfo = {0};
    startupInfo.cb = sizeof(startupInfo);

    if (!CreateProcessW(NULL, command, NULL, NULL, FALSE, 0, NULL, NULL, &startupInfo, &processInfo))
    {
        wprintf(L"CreateProcess failed (%u)\n", GetLastError());
        return -1;
    }

    WaitForSingleObject(processInfo.hProcess, INFINITE);

    DWORD exitCode = 0;
    GetExitCodeProcess(processInfo.hProcess, &exitCode);

    CloseHandle(processInfo.hThread);
    CloseHandle(processInfo.hProcess);

    return (int)exitCode;
}

void InstallPython()
{
    wprintf(L"Installing Python...\n");
    RunProcess(L"winget", L"install 9NQ7512CXL7T");
}

int InstallOffice365(const wchar_t *configXml)
{
    wchar_t tempPath[MAX_PATH];
    GetTempPathW(MAX_PATH, tempPath);

    wchar_t odtExe[MAX_PATH];
    swprintf(odtExe, MAX_PATH, L"%soffice_odt.exe", tempPath);

    wprintf(L"Downloading Office Deployment Tool...\n");
    if (!DownloadFileWinHTTP(ODT_URL, odtExe)) {
        wprintf(L"Failed to download ODT.\n");
        return 1;
    }

    wchar_t extractDir[MAX_PATH];
    swprintf(extractDir, MAX_PATH, L"%sODT", tempPath);

    wchar_t extractArgs[MAX_PATH];
    swprintf(extractArgs, MAX_PATH, L"/extract:\"%s\" /quiet", extractDir);

    wchar_t setupPath[MAX_PATH];
    swprintf(setupPath, MAX_PATH, L"%s\\setup.exe", extractDir);

    wchar_t cfgDest[MAX_PATH];
    swprintf(cfgDest, MAX_PATH, L"%s\\configuration.xml", extractDir);

    wchar_t argsDownload[MAX_PATH];
    swprintf(argsDownload, MAX_PATH, L"/download \"%s\"", cfgDest);

    wchar_t argsConfigure[MAX_PATH];
    swprintf(argsConfigure, MAX_PATH, L"/configure \"%s\"", cfgDest);

    CreateDirectoryW(extractDir, NULL);
    RunProcess(odtExe, extractArgs);
    CopyFileW(configXml, cfgDest, FALSE);

    wprintf(L"ODT: downloading Office files...\n");
    RunProcess(setupPath, argsDownload);

    wprintf(L"ODT: installing Office...\n");
    RunProcess(setupPath, argsConfigure);

    return 0;
}

int wmain(int argc, wchar_t **argv)
{
    if (argc != 2)
    {
        wprintf(L"Usage:\n  install.exe C:\\path\\to\\configuration.xml\n");
        return 1;
    }

    const wchar_t *configXml = argv[1];

    InstallPython();
    InstallOffice365(configXml);

    return 0;
}
