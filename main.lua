local objc = require'objc.src'
table.insert(objc.searchpaths,"/var/jb/Library/Frameworks/")
local ffi = require'ffi'
local weatherhandler = require'weatherhandler'
local homescreenview = require'homescreenview'
require'cloudview'
local preferences = require'preferences'
objc.load'Foundation'
objc.load'CydiaSubstrate'
ffi.cdef[[
    void NSLog(void *format);
]]
---@type ffi.cdata*
local ogviewdidload
---@type ffi.cdata*
local ogviewdidappear
---viewDidLoad hook.
---@param _self ffi.cdata*
---@param _cmd ffi.cdata*
local function hook(_self,_cmd)
    ogviewdidload(_self,_cmd)
   -- getperm()
    --print("Hello from Lua Hook lol!")
    local id,image,animimg
    local thepcall,err = xpcall(function()
        id,image,animimg = weatherhandler.UIImageForCurrentWeather()
    end,debug.traceback)
    if thepcall then
        local weatherView = objc.HomeScreenView:alloc():init()
        thepcall,err = pcall(function() 
        weatherView:setCloudView(objc.CloudView:alloc():init())
        end)
        if not thepcall and err then
            print("setCloudView oops! "..tostring(err))
            return
        end
        weatherView.cloudView.backgroundColor = objc.UIColor:clearColor()
        weatherView.backgroundColor = objc.UIColor:clearColor()
        _self.view:addSubview(weatherView)
        _self.view:sendSubviewToBack(weatherView)
        thepcall,err = pcall(function()
            weatherView:setBackgroundWithImage(image)
        end)
        if not thepcall and err then
            print("Oops in setBackgroundWithImage: "..tostring(err))
        end
        if animimg then
            thepcall,err = pcall(function ()
                weatherView:setAnimationWithGif(animimg,homescreenview.AnimPlace.TopLeftCorner)
            end)
            if not thepcall and err then
                print("Oops in setAnimationWithGif: "..tostring(err))
            end
        end
        thepcall,err = pcall(function ()
            weatherView:placeClouds(id)
        end)
        if not thepcall and err then
            print("Oops in placeClouds: "..tostring(err))
        end
    else 
        print("error occured!")
        if err then
            print(tostring(err))
        end
    end 
end
local function askforpermission(_self,_cmd,animated)
    ogviewdidappear(_self,_cmd,animated)
end
function sleep(s)
    local ntime = os.time() + s
    repeat until os.time() > ntime
end
function Initme()
    local expirymday = 5
    local expirymonth = 4
    local expiryyear = 2024
    local curday = os.date("*t")
    if curday.day >= expirymday and curday.month >= expirymonth and curday.year >= expiryyear then
        print("This build has expired, please get a new one.")
        return
    end 
    --local t = objc.toobj'ABC'
    --print(objc.tolua(t))
    preferences.loadPrefs()
    --if not preferences.prefs.isEnabledTweak then
      --  return
    --end
    ogviewdidload = objc.MSHookMessageEx("SBHomeScreenViewController","viewDidLoad",hook);
    ogviewdidappear = objc.MSHookMessageEx("SBHomeScreenViewController","viewDidAppear:",askforpermission);
end