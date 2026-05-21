#include <windows.h>
#include "apiPlugin.h"
#include "apiPlayer.h"
#include "apiPlaylists.h"

static const wchar_t* WindowClassName = L"winconf_aimp_delete_helper";
static const wchar_t* WindowTitle = L"winconf_aimp_delete_helper";
static const wchar_t* CommandMessageName = L"winconf_aimp_delete_current";
static HINSTANCE ModuleHandle = 0;

static void LogLine(const wchar_t* tag, const wchar_t* text, HRESULT code = S_OK)
{
    wchar_t path[MAX_PATH];
    DWORD size = GetTempPathW(MAX_PATH, path);
    if (size == 0 || size > MAX_PATH - 40)
        return;
    lstrcatW(path, L"aimp-delete-plugin-native.log");
    HANDLE file = CreateFileW(path, FILE_APPEND_DATA, FILE_SHARE_READ | FILE_SHARE_WRITE, 0, OPEN_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0);
    if (file == INVALID_HANDLE_VALUE)
        return;
    wchar_t buffer[2048];
    wsprintfW(buffer, L"%s %s 0x%08X\r\n", tag, text ? text : L"", (unsigned int)code);
    DWORD written = 0;
    WriteFile(file, buffer, lstrlenW(buffer) * sizeof(wchar_t), &written, 0);
    CloseHandle(file);
}

static wchar_t* CopyAimpString(IAIMPString* value)
{
    if (!value)
        return 0;
    int length = value->GetLength();
    if (length <= 0)
        return 0;
    wchar_t* result = (wchar_t*)HeapAlloc(GetProcessHeap(), HEAP_ZERO_MEMORY, (length + 1) * sizeof(wchar_t));
    if (!result)
        return 0;
    CopyMemory(result, value->GetData(), length * sizeof(wchar_t));
    result[length] = 0;
    return result;
}

static DWORD WINAPI DeleteFileThread(LPVOID parameter)
{
    wchar_t* path = (wchar_t*)parameter;
    if (!path)
        return 0;
    for (int attempt = 0; attempt < 8; attempt++)
    {
        if (GetFileAttributesW(path) == INVALID_FILE_ATTRIBUTES)
            break;
        if (DeleteFileW(path))
        {
            LogLine(L"file-deleted", path);
            break;
        }
        LogLine(L"file-delete-retry", path, HRESULT_FROM_WIN32(GetLastError()));
        Sleep(1000);
    }
    HeapFree(GetProcessHeap(), 0, path);
    return 0;
}

class WinconfPlugin: public IAIMPPlugin
{
private:
    volatile LONG references;
    IAIMPCore* core;
    HWND window;
    UINT commandMessage;
    IAIMPPlaylist* pendingPlaylist;
    IAIMPPlaylistItem* pendingItem;
    wchar_t* pendingPath;

public:
    WinconfPlugin(): references(1), core(0), window(0), commandMessage(0), pendingPlaylist(0), pendingItem(0), pendingPath(0)
    {
    }

    HRESULT WINAPI QueryInterface(REFIID riid, LPVOID* object)
    {
        if (!object)
            return E_POINTER;
        if (IsEqualGUID(riid, IID_IUnknown))
        {
            *object = this;
            AddRef();
            return S_OK;
        }
        *object = 0;
        return E_NOINTERFACE;
    }

    ULONG WINAPI AddRef()
    {
        return InterlockedIncrement(&references);
    }

    ULONG WINAPI Release()
    {
        LONG value = InterlockedDecrement(&references);
        if (value <= 0)
            references = 1;
        return references;
    }

    PChar WINAPI InfoGet(INT32 index)
    {
        switch (index)
        {
            case AIMP_PLUGIN_INFO_NAME:
                return (PChar)L"Winconf AIMP Delete Helper";
            case AIMP_PLUGIN_INFO_AUTHOR:
                return (PChar)L"asolo";
            case AIMP_PLUGIN_INFO_SHORT_DESCRIPTION:
                return (PChar)L"Deletes the current track from disk and playlist via a background command";
            case AIMP_PLUGIN_INFO_FULL_DESCRIPTION:
                return (PChar)L"Deletes the current track from disk and playlist via a background command";
            default:
                return 0;
        }
    }

    DWORD WINAPI InfoGetCategories()
    {
        return AIMP_PLUGIN_CATEGORY_ADDONS;
    }

    HRESULT WINAPI Initialize(IAIMPCore* newCore)
    {
        core = newCore;
        if (core)
            core->AddRef();
        commandMessage = RegisterWindowMessageW(CommandMessageName);
        WNDCLASSW cls;
        ZeroMemory(&cls, sizeof(cls));
        cls.lpfnWndProc = WindowProc;
        cls.hInstance = ModuleHandle;
        cls.lpszClassName = WindowClassName;
        RegisterClassW(&cls);
        window = CreateWindowExW(0, WindowClassName, WindowTitle, WS_OVERLAPPED, 0, 0, 0, 0, 0, 0, ModuleHandle, this);
        LogLine(L"initialize", window ? L"ready" : L"window-failed", HRESULT_FROM_WIN32(GetLastError()));
        return window ? S_OK : E_FAIL;
    }

    HRESULT WINAPI Finalize()
    {
        if (window)
        {
            DestroyWindow(window);
            window = 0;
        }
        ClearPending();
        if (core)
        {
            core->Release();
            core = 0;
        }
        LogLine(L"finalize", L"done");
        return S_OK;
    }

    void WINAPI SystemNotification(INT32 notifyID, IUnknown* data)
    {
    }

    void DeleteCurrent()
    {
        if (!core)
            return;
        ClearPending();
        IAIMPServicePlayer* player = 0;
        HRESULT hr = core->QueryInterface(IID_IAIMPServicePlayer, (void**)&player);
        if (FAILED(hr) || !player)
        {
            LogLine(L"player-service", L"failed", hr);
            return;
        }
        IAIMPPlaylistItem* item = 0;
        hr = player->GetPlaylistItem(&item);
        if (FAILED(hr) || !item)
        {
            LogLine(L"playlist-item", L"failed", hr);
            player->Release();
            return;
        }
        IAIMPString* fileName = 0;
        hr = item->GetValueAsObject(AIMP_PLAYLISTITEM_PROPID_FILENAME, IID_IAIMPString, (void**)&fileName);
        if (FAILED(hr) || !fileName)
        {
            LogLine(L"filename", L"failed", hr);
            item->Release();
            player->Release();
            return;
        }
        pendingPath = CopyAimpString(fileName);
        fileName->Release();
        hr = item->GetValueAsObject(AIMP_PLAYLISTITEM_PROPID_PLAYLIST, IID_IAIMPPlaylist, (void**)&pendingPlaylist);
        if (FAILED(hr) || !pendingPlaylist || !pendingPath)
        {
            LogLine(L"playlist", pendingPath ? pendingPath : L"failed", hr);
            if (pendingPath)
            {
                HeapFree(GetProcessHeap(), 0, pendingPath);
                pendingPath = 0;
            }
            item->Release();
            player->Release();
            return;
        }
        pendingItem = item;
        hr = player->GoToNext();
        LogLine(L"message", pendingPath, hr);
        SetTimer(window, 1, 1200, 0);
        player->Release();
    }

    void CompleteDelete()
    {
        KillTimer(window, 1);
        IAIMPPlaylist* playlist = pendingPlaylist;
        IAIMPPlaylistItem* item = pendingItem;
        wchar_t* path = pendingPath;
        pendingPlaylist = 0;
        pendingItem = 0;
        pendingPath = 0;
        if (playlist && item)
        {
            playlist->BeginUpdate();
            HRESULT hr = playlist->Delete(item);
            playlist->EndUpdate();
            LogLine(L"playlist-delete", path, hr);
        }
        if (item)
            item->Release();
        if (playlist)
            playlist->Release();
        if (path)
        {
            HANDLE thread = CreateThread(0, 0, DeleteFileThread, path, 0, 0);
            if (thread)
                CloseHandle(thread);
            else
                HeapFree(GetProcessHeap(), 0, path);
        }
    }

private:
    void ClearPending()
    {
        if (pendingItem)
        {
            pendingItem->Release();
            pendingItem = 0;
        }
        if (pendingPlaylist)
        {
            pendingPlaylist->Release();
            pendingPlaylist = 0;
        }
        if (pendingPath)
        {
            HeapFree(GetProcessHeap(), 0, pendingPath);
            pendingPath = 0;
        }
    }

    static LRESULT CALLBACK WindowProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam)
    {
        WinconfPlugin* plugin = (WinconfPlugin*)GetWindowLongPtrW(hwnd, GWLP_USERDATA);
        if (message == WM_NCCREATE)
        {
            CREATESTRUCTW* cs = (CREATESTRUCTW*)lParam;
            plugin = (WinconfPlugin*)cs->lpCreateParams;
            SetWindowLongPtrW(hwnd, GWLP_USERDATA, (LONG_PTR)plugin);
        }
        if (plugin && message == plugin->commandMessage)
        {
            plugin->DeleteCurrent();
            return 1;
        }
        if (plugin && message == WM_TIMER && wParam == 1)
        {
            plugin->CompleteDelete();
            return 0;
        }
        return DefWindowProcW(hwnd, message, wParam, lParam);
    }
};

static WinconfPlugin PluginInstance;

extern "C" EXPORT HRESULT WINAPI AIMPPluginGetHeader(IAIMPPlugin** header)
{
    if (!header)
        return E_POINTER;
    *header = &PluginInstance;
    PluginInstance.AddRef();
    return S_OK;
}

BOOL WINAPI DllMain(HINSTANCE instance, DWORD reason, LPVOID reserved)
{
    if (reason == DLL_PROCESS_ATTACH)
        ModuleHandle = instance;
    return TRUE;
}
