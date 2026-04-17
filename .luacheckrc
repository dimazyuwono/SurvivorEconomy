-- Luacheck configuration for Project Zomboid mods
-- PZ uses Lua 5.1 via Kahlua

std = "lua51"
max_line_length = 150

-- PZ engine globals that are available at runtime
globals = {
    -- Mod globals defined by this mod
    "SEConstants",
    "SEConfig",
    "SEUtils",
    "SEItemValues",
    "SETraderManager",
    "SETraderUI",
    "SEClientMain",
    "SEServerMain",
    "SEContextMenus",
    "SEWalletHUD",
    "SECurrencySink",
    "SEFarmEconomy",
}

read_globals = {
    -- PZ core globals
    "getPlayer",
    "getSpecificPlayer",
    "getGameTime",
    "getCore",
    "getCell",
    "getWorld",

    -- PZ events system
    "Events",

    -- PZ networking
    "sendClientCommand",
    "sendServerCommand",

    -- PZ random
    "ZombRand",

    -- PZ data
    "ModData",
    "ScriptManager",

    -- PZ UI framework
    "ISPanel",
    "ISButton",
    "ISScrollingListBox",
    "ISLabel",
    "ISWorldObjectContextMenu",
    "ISToolTip",
    "UIFont",

    -- Lua standard
    "require",
    "print",
    "tostring",
    "tonumber",
    "type",
    "setmetatable",
    "pairs",
    "ipairs",
    "table",
    "math",
    "string",
}

-- Ignore unused self in methods (common in PZ UI patterns)
self = false

-- Per-file overrides
files["**/server/**"] = {
    read_globals = {
        "isServer",
    },
}

files["**/client/**"] = {
    read_globals = {
        "isClient",
    },
}
