local objc = require'objc.src'
Preferences = {prefs = nil,flushTo = ""}

local function file_exists(name)
    local f = io.open(name, "r")
    return f ~= nil and f:close()
 end
function Preferences.loadPrefs()
    local autorelease = objc.NSAutoreleasePool:new()
    if not file_exists(rootpath"/var/mobile/Library/Preferences/com.sora.weatherwhirl.plist") then
        return
    end
    local objstr = objc.toobj(rootpath"/var/mobile/Library/Preferences/com.sora.weatherwhirl.plist")
    local dict = objc.NSDictionary:dictionaryWithContentsOfURL(objc.NSURL:fileURLWithPath(objstr),nil)
   -- print("converting dict to lua!")
    Preferences.prefs = objc.tolua(dict)
    Preferences.flushTo = rootpath"/var/mobile/Library/Preferences/com.sora.weatherwhirl.plist"
    autorelease:drain()
end

function Preferences.flush()
    local releasepool = objc.NSAutoreleasePool:new()
    local nsdict = objc.toobj(Preferences.prefs)
    nsdict:writeToURL_atomically(objc.NSURL:fileURLWithPath(objc.toobj(Preferences.flushTo)),true)
    releasepool:drain()
end
function Preferences.customBackground(For)
    print("In custom background!")
    if not Preferences.prefs then
        return nil
    end
    if not Preferences.prefs.customBackgrounds then
        return nil
    end
    if not Preferences.prefs.customBackgrounds[For] then
        return nil
    end
    return objc.UIImage:imageWithContentsOfFile(Preferences.prefs.customBackgrounds[For])
end
return Preferences