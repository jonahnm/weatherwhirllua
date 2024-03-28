local objc = require'objc.src'
table.insert(objc.searchpaths,"/var/jb/Library/Frameworks/")
table.insert(objc.searchpaths,"/Library/PrivateFrameworks")
objc.load'Foundation'
objc.load'CydiaSubstrate'
local ffi = require'ffi'
local weatherhandler
local preferences
local homescreenview
if not objc.class("TCCDService") then
 weatherhandler = require'weatherhandler'
 homescreenview = require'homescreenview'
require'cloudview'
preferences = require'preferences'
end
ffi.cdef[[
    void NSLog(void *format);
    struct NSOperatingSystemVersion {
        long majorVersion;
        long minorVersion;
        long patchVersion;
    };
]]
---@type ffi.cdata*
local ogviewdidload
---@type ffi.cdata*
local ogviewdidappear
---@type ffi.cdata*
local ogsetdefaultallowedidlist
---@type ffi.cdata*
local ogdidupdatelocations
---viewDidLoad hook.
---@param _self ffi.cdata*
---@param _cmd ffi.cdata*
function hook(_self,_cmd)
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
function forcepermhook(_self,_cmd,list)
    print("hi.")
   local succ,err = xpcall(function()
    local name = _self.name:UTF8String()
    print("Hola! " .. name)
    print(tostring(list))
    if name == "kTCCServiceLiverpool" or name == "kTCCServiceLocation" then
        local mut = objc.tolua(list)
        table.insert(mut,objc.toobj'com.apple.springboard')
        local obj = objc.toobj(mut)
        ogsetdefaultallowedidlist(_self,_cmd,obj:copy())
        return
    end
    ogsetdefaultallowedidlist(_self,_cmd,list)
end,debug.traceback)
if not succ and err then
    print(tostring(err))
    ogsetdefaultallowedidlist(_self,_cmd,list)
end
end
function didUpdateLocations(_self,_cmd)
    print'hiaaa'
    ogdidupdatelocations(_self,_cmd)
    local succ,err = xpcall(function()
    print'did update locations'
    repeat until _self._locationManager
    print(tostring(_self._locationManager))
    repeat until _self._locationManager.location
    print(tostring(_self._locationManager.location))
    fetchForecast(os.date('*t'), rootpath'/Library/Application Support/WeatherWhirl/Forecast.json',_self._locationManager)
    print'yay'
    end,debug.traceback)
    if not succ and err then
        print(tostring(err))
    end
    return _self
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
    --if not preferences.prefs.isEnabledTweak then
      --  return
    --end
    if objc.class("DNDSLocationLifetimeMonitor") then 
        print'it exists.'
        ogdidupdatelocations = objc.MSHookMessageEx("DNDSLocationLifetimeMonitor","init",didUpdateLocations)
        if is15orhigher() then
            print'we are greater than or equal to iOS 15.'
            return
        end
    elseif objc.class("UNSLocationMonitor") and is15orhigher() then
        print'UNSLocationMonitor'
        ogdidupdatelocations = objc.MSHookMessageEx("UNSLocationMonitor","init",didUpdateLocations)
        return
    end
    if objc.class("TCCDService") then
        print("We're tccd!")
        ogsetdefaultallowedidlist = objc.MSHookMessageEx("TCCDService","setDefaultAllowedIdentifiersList:",function (_self,_cmd,list)
            forcepermhook(_self,_cmd,list)
        end)
    else
        preferences.loadPrefs()
        ogviewdidload = objc.MSHookMessageEx("SBHomeScreenViewController","viewDidLoad",function (_self,_cmd)
            hook(_self,_cmd)
        end);
    end
end
jit.off(Initme)