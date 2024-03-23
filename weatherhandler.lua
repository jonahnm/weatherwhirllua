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
    -- broken objc.NSAutoreleasePool:new()
    print("Made autoreleasepool!")
    local locationManager = objc.CLLocationManager:alloc():init()
    print("Inited!")
    locationManager:setAuthorizationStatus_forBundleIdentifier(objc.toobj(true),objc.NSBundle.mainBundle().bundleIdentifier)
    print("Authed!")
    locationManager:startUpdatingLocation()
    print("Updating location!")
    local str = string.format("http://api.openweathermap.org/data/3.0/onecall?lat=%f&lon=%f&appid=4cfd64f823763c23be0eb25c78eb5183",locationManager.location.coordinate.latitude,locationManager.location.coordinate.longitude)
    print(str)
    locationManager:stopUpdatingLocation()
    local response = dohttp(str)
    print(response)
    local obj = json.decode(response)
    local toencode = {forday = gmcurtime.yday,hourly = obj.hourly}
    print("toencode: "..tostring(toencode))
    local towrite
    print("About to pcall json!")
    local thepcall,err = pcall(function ()
        towrite = json.encode(toencode)
    end)
    if not thepcall and err then
        print("Uhoh." .. tostring(err))
        return {}
    end
    local fd,err = io.open(path,'w')
    if not fd then 
        print("Failed to write forecast.")
        print(err)
        return {}
    end
    fd:write(towrite)
    fd:close()
    -- broken objc.NSAutoreleasePool:release()
    return toencode
end
local function file_exists(name)
    local f = io.open(name, "r")
    return f ~= nil and f:close()
 end
---@return table
local function getForecast()
    local path = root .. "/Library/Application Support/WeatherWhirl/Forecast.json"
    print(path)
    local time = os.date('*t')
    if not file_exists(path) then
        return fetchForecast(time,path)
    else 
        print('File exists!')
        local fd = io.open(path)
        if not fd then
            print("Failed to open forecast file...")
            return {}
        end
        local jsonstr = fd:read('*a')
        local obj = json.decode(jsonstr)
        local wasForDay = obj.forday
        print(wasForDay)
        if wasForDay ~= time.yday then
            fd:close()
            os.remove(path)
            return fetchForecast(time,path)
        end
        fd:close()
        return obj.hourly
    end
end
---@return string,integer
local function getIDOfCurrentWeather()
    local forecast = getForecast()
    local curTime = os.date('*t')
    local name, id
    for i,v in ipairs(forecast) do
        --print(json.encode(v))
        --print(json.encode(v.weather[1]))
        local dt = v.dt
        --print(tostring(dt))
        local forecastTime = os.date('*t',dt)
        --print(tostring(forecastTime.hour))
        --print(tostring(curTime.hour))
        if forecastTime.hour ~= curTime.hour or forecastTime.wday ~= curTime.wday then 

        else 
            name = v.weather[1].description
            id = v.weather[1].id
            break
        end
    end
    return name, id
end
---@return integer,ffi.cdata*
function weatherhandler.UIImageForCurrentWeather() 
    --TODO: PREFERENCES IN LUA
    local name,id = getIDOfCurrentWeather();
    print(tostring(id))
    local animpath
    local filepath
    if id == 800 then
        animpath = root .. "/Library/Application Support/WeatherWhirl/sunAnim.gif"
    elseif id <= 804 and id >= 801 then
        filepath = root .. "/Library/Application Support/WeatherWhirl/clearskies.jpg"
    end
    if id >= 500 and id <= 531 then
        filepath = root .. "/Library/Application Support/WeatherWhirl/grey.jpg"
    end
    print(filepath)
    local image = objc.UIImage:imageWithContentsOfFile(objc.toobj(filepath))
    return id, image
end
return weatherhandler