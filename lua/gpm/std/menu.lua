local _G = _G
local std = _G.gpm.std

---@class gpm.std.menu
local menu = {
    openURL = _G.gui.OpenURL
}

if std.MENU then

    menu.getWorkshopStatus = _G.GetAddonStatus
    menu.runCommand = _G.RunGameUICommand

    ---@class gpm.std.menu.loading
    local loading = {
        getDefaultURL = _G.GetDefaultLoadingHTML,
        getFileCount = _G.NumDownloadables,
        getFiles = _G.GetDownloadables,
        getStatus = _G.GetLoadStatus,
        cancel = _G.CancelLoading,
    }

    menu.loading = loading

end

return menu
