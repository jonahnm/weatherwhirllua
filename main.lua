local objc = require'objc.src'
table.insert(objc.searchpaths,"/var/jb/Library/Frameworks/")
local ffi = require'ffi'
local weatherhandler = require'weatherhandler'
objc.load'Foundation'
objc.load'CydiaSubstrate'
ffi.cdef[[
    void NSLog(void *format);
]]
---@type ffi.cdata*
local ogviewdidload

---viewDidLoad hook.
---@param _self ffi.cdata*
---@param _cmd ffi.cdata*
local hook = function(_self,_cmd)
    ogviewdidload(_self,_cmd)
    print("Hello from Lua Hook lol!")
    local ret
    local thepcall,err = pcall(function()
        ret = weatherhandler.UIImageForCurrentWeather()
    end)
    if thepcall then
    print(tostring(ret.id))
    print(tostring(ret.image))
    else 
        print("error ocurred!")
        if err then
            print(tostring(err))
        end
    end 
end
function Initme()
    print("Oh hello again!")
    local objcstr = objc.toobj('ABC')
    print(objc.tolua(objcstr))
    ogviewdidload = objc.MSHookMessageEx("SBHomeScreenViewController","viewDidLoad",hook);
end