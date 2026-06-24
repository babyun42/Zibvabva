local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local darkThemes = {"AmberBlue"(Default), "Amethyst", "DarkBlue"}
local lightThemes = {"Light", "Bloom", "Green", "Ocean", "Serenity"}

local savedTheme = "Default"
pcall(function()
    if isfile and isfile("Zibvabva_Hub_Theme.txt") then
        savedTheme = readfile("Zibvabva_Hub_Theme.txt")
    end
end)

_G.HubTheme = savedTheme

local initialBase = "Dark"
if table.find(lightThemes, savedTheme) then
    initialBase = "Light"
end

local initialOptions = initialBase == "Dark" and darkThemes or lightThemes

local Window = Rayfield:CreateWindow({
   Name = "Zibvabva Hub",
   LoadingTitle = "Loading",
   LoadingSubtitle = "by babyun42",
   Theme = savedTheme,
   ConfigurationSaving = { Enabled = false },
   KeySystem = false,
})

local ScriptsTab = Window:CreateTab("Script", 4483362458)

ScriptsTab:CreateSection("Zibvabva Hub")

ScriptsTab:CreateButton({
   Name = "Universal Script",
   Callback = function()
       Rayfield:Notify({
           Title = "Launch",
           Content = "Loading Universal.lua",
           Duration = 3,
           Image = 4483362458,
       })
       
       Rayfield:Destroy()
       task.wait(0.5)
       
       loadstring(game:HttpGet("https://raw.githubusercontent.com/babyun42/Zibvabva/refs/heads/main/Univeral.lua"))()
   end,
})

ScriptsTab:CreateLabel("New releases coming soon...")

local SettingsTab = Window:CreateTab("Settings", 10013098653)

SettingsTab:CreateSection("Interface customization")

local AccentDropdown

SettingsTab:CreateDropdown({
    Name = "1. Basic style",
    Options = {"Dark", "Light"},
    CurrentOption = {initialBase},
    MultipleOptions = false,
    Callback = function(Option)
        local selectedBase = Option[1]
        
        if selectedBase == "Dark" then
            AccentDropdown:Refresh(darkThemes, {"Default"})
            _G.HubTheme = "Default"
        else
            AccentDropdown:Refresh(lightThemes, {"Light"})
            _G.HubTheme = "Light"
        end
        
        pcall(function()
            if writefile then writefile("Zibvabva_Hub_Theme.txt", _G.HubTheme) end
        end)
    end,
})

AccentDropdown = SettingsTab:CreateDropdown({
    Name = "2. Choosing an accent",
    Options = initialOptions,
    CurrentOption = {savedTheme},
    MultipleOptions = false,
    Callback = function(Option)
        _G.HubTheme = Option[1]
        
        pcall(function()
            if writefile then writefile("Zibvabva_Hub_Theme.txt", _G.HubTheme) end
        end)
        
        Rayfield:Notify({
            Title = "Topic updated",
            Content = "The hub theme will change after restarting. The selected cheat will launch in color." .. _G.HubTheme .. " now!",
            Duration = 4,
            Image = 4483362458,
        })
    end,
})
