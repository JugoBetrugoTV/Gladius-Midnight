-- PASTE THIS INTO CHAT IN-GAME TO EXPORT YOUR ACTUAL CURRENT SETTINGS
-- This bypasses the theme data cache and reads directly from your live profile

/run local function S(t,i) i=i or"" if type(t)~="table" then return type(t)=="string" and string.format("%q",t) or tostring(t) end local r="{" for k,v in pairs(t) do r=r.."\n"..i.."  ["..(type(k)=="string" and string.format("%q",k) or tostring(k)).."] = "..S(v,i.."  ").."," end return r.."\n"..i.."}" end local d={arenaFrames=ArenaCore.DB.profile.arenaFrames,trinkets=ArenaCore.DB.profile.trinkets,racials=ArenaCore.DB.profile.racials,specIcons=ArenaCore.DB.profile.specIcons,diminishingReturns=ArenaCore.DB.profile.diminishingReturns,castBars=ArenaCore.DB.profile.castBars,textures=ArenaCore.DB.profile.textures,classPacks=ArenaCore.DB.profile.classPacks,classIcons=ArenaCore.DB.profile.classIcons} print("-- CURRENT SETTINGS EXPORT") print("-- Generated: "..date("%Y-%m-%d %H:%M:%S")) print("return "..S(d))

-- NOTE: This is a ONE-LINE command that will print your settings to chat
-- Copy the output and paste it into the GetThe1500SpecialDefaults() function
