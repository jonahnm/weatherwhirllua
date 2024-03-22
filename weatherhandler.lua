local objc = require'objc.src'
objc.load'CoreLocation'
objc.load'UIKit'
local json = require'json'
local ffi = require'ffi'
weatherhandler = {}
---Fetch the forecast.
---@param gmcurtime string|osdate
---@param path string
---@return table
local function fetchForecast(gmcurtime,path)
    print("fetching forecast!")
    objc.NSAutoreleasePool:new()
    print("Made autoreleasepool!")
    local locationManager = objc.CLLocationManager:alloc():init()
    print("Inited!")
    locationManager:setAuthorizationStatus_forBundleIdentifier(objc.toobj(true),objc.NSBundle.mainBundle().bundleIdentifier)
    print("Authed!")
    locationManager:startUpdatingLocation()
    print("Updating location!")
    local str = string.format("http://api.openweathermap.org/data/3.0/onecall?lat=%f&lon=%f&appid=4cfd64f823763c23be0eb25c78eb5183",locationManager.location.coordinate.latitude,locationManager.location.coordinate.longitude)
    print(str)
    local url = objc.NSURL:URLWithString(objc.toobj(str))
    locationManager:stopUpdatingLocation()
    local out
    local shouldret = false
    local taskBlock = objc.block(function (data,response,err)
        print("Hey, I made a request!")
        if not err then
            local jsonStr = objc.NSString:alloc():initWithData_encoding(data,4)
            local obj = json.decode(objc.tolua(jsonStr))
            out = obj.hourly
        end
        shouldret = true
    end,"v@@@")
    local downTask = objc.NSURLSession:sharedSession():dataTaskWithURL_completionHandler(url,taskBlock)
    downTask:resume()
    repeat until shouldret
    if not out then
        return nil
    end
    local toencode = {forday = gmcurtime.yday,hourly = out}
    local towrite = json.encode(toencode)
    local fd = io.open(path)
    if not fd then 
        print("Failed to write forecast.")
        return
    end
    fd:write(towrite)
    fd:close()
   -- objc.NSAutoreleasePool:release()
    return toencode
end
local function file_exists(name)
    local f = io.open(name, "r")
    return f ~= nil and io.close(f)
 end
---@return table
local function getForecast()
    local path = root .. "/Library/Application Support/WeatherWhirl/Forecast.json"
    local time = os.date()
    if not file_exists(path) then
        return fetchForecast(time,path)
    else 
        local fd = io.open(path)
        if not fd then
            print("Failed to open forecast file...")
            return {}
        end
        local jsonstr = fd:read('*a')
        local obj = json.decode(jsonstr)
        local wasForDay = obj.forday
        if wasForDay ~= time.yday then
            fd:close()
            os.remove(path)
            return fetchForecast(time,path)
        end
        fd:close()
        return obj.hourly
    end
end
---@return table
local function getIDOfCurrentWeather()
    local out = {}
    local forecast = getForecast()
    local curTime = os.date()
    for i,v in ipairs(forecast) do
        local dt = v.dt
        local forecastTime = os.date('*t',dt)
        if forecastTime.hour ~= curTime.hour or forecastTime.wday ~= curTime.wday then goto continue end
        out.name = v.weather[1].description
        out.id = v.weather[1].id
        ::continue::
    end
    return out
end
---@return table
function weatherhandler.UIImageForCurrentWeather() 
    local out = {}
    --TODO: PREFERENCES IN LUA
    out.id = getIDOfCurrentWeather()
    local animpath
    local filepath
    if out.id == 800 then
        animpath = root .. "/Library/Application Support/WeatherWhirl/sunAnim.gif"
    elseif out.id <= 804 and out.id >= 801 then
        filepath = root .. "/Library/Application Support/WeatherWhirl/clearskies.jpg"
    end
    if out.id >= 500 and out.id <= 531 then
        filepath = root .. "/Library/Application Support/WeatherWhirl/grey.jpg"
    end
    print(filepath)
    out.image = objc.UIImage:imageWithContentsOfFile(objc.toobj(filepath))
    return out
end
return weatherhandler