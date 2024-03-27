local objc = require'objc.src'
objc.load'CoreLocation'
objc.load'UIKit'
objc.load'FLAnimatedImage'
--objc.load'CoreGraphics'
local json = require'json'
local ffi = require'ffi'
_ = ffi.load("/System/Library/PrivateFrameworks/Weather.framework/Weather",true)
_ = ffi.load("/System/Library/PrivateFrameworks/WeatherFoundation.framework/WeatherFoundation",true)

weatherhandler = {}
---Fetch the forecast.
---@param gmcurtime string|osdate
---@param path string
---@return table
local function fetchForecast(gmcurtime,path)
    print("fetching forecast!")
    local releasepool = objc.NSAutoreleasePool:new()
    print(tostring(objc.WeatherPreferences.sharedPreferences()))
    local watodaymodel = objc.WATodayModel:autoupdatingLocationModelWithPreferences_effectiveBundleIdentifier(objc.WeatherPreferences.sharedPreferences(),objc.toobj"com.apple.locationd.bundle-/System/Library/Frameworks/CoreTelephony.framework")
    local location = watodaymodel:location().geoLocation
   print("locationManager coordiante: "..tostring(location.coordinate))
    local str = string.format("http://api.openweathermap.org/data/3.0/onecall?lat=%f&lon=%f&appid=".."4cfd64f823763c23be0eb25c78eb5183",location.coordinate.latitude,location.coordinate.longitude)
    --print(str)
    print("Formatted string!")
    locationManager:stopUpdatingLocation()
    local response = dohttp(str)
    print(response)
    local obj = json.decode(response)
    local toencode = {forday = gmcurtime.yday,hourly = obj.hourly}
    local towrite
    print("About to pcall json!")
    local thepcall,err = pcall(function ()
        towrite = json.encode(toencode)
    end)
    if not thepcall and err then
        print("Uhoh." .. tostring(err))
        return {}
    end
    print("toencode: "..towrite)
    local fd,err = io.open(path,'w')
    if not fd then 
        print("Failed to write forecast.")
        print(err)
        return {}
    end
    fd:write(towrite)
    fd:close()
    print("Draining!")
    releasepool:drain()
    return toencode.hourly
end
local function file_exists(name)
    local f = io.open(name, "r")
    return f ~= nil and f:close()
 end
---@return table
local function getForecast()
    local path = rootpath'/Library/Application Support/WeatherWhirl/Forecast.json'
    --print(path)
    local time = os.date('*t')
    if not file_exists(path) then
        return fetchForecast(time,path)
    else 
      --  print('File exists!')
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
---@return integer,ffi.cdata*,ffi.cdata*
function weatherhandler.UIImageForCurrentWeather() 
    local name,id
    if Preferences.prefs then
    if not Preferences.prefs.overrideNext then
    name,id = getIDOfCurrentWeather()
    else
        name = Preferences.prefs.override
        if name == "light rain" then
            id = 500
        elseif name == "moderate rain" then
            id = 501
        elseif name == "heavy intensity rain" then
            id = 502
        elseif name == "clear sky" then
            id = 800
        elseif name == "few clouds" then
            id = 801
        elseif name == "scattered clouds" then
            id = 802
        elseif name == "broken clouds" then
            id = 803
        elseif name == "overcast clouds" then
            id = 804
        end
        Preferences.prefs.overrideNext = false
        Preferences.flush()
    end
else
    name,id = getIDOfCurrentWeather()
end
--    print(tostring(id))
    local animpath
    local filepath
    local animImg
    if id == 800 then
        animpath = rootpath"/Library/Application Support/WeatherWhirl/sunAnim.gif"
        filepath = rootpath"/Library/Application Support/WeatherWhirl/clearskies.jpg"
    elseif id <= 804 and id >= 801 then
        filepath = rootpath"/Library/Application Support/WeatherWhirl/clearskies.jpg"
    end
    if id >= 500 and id <= 531 then
        filepath = rootpath"/Library/Application Support/WeatherWhirl/grey.jpg"
    end
    print(filepath)
    local image
    print(name)
    image = Preferences.customBackground(name)
    if not image then
        image = objc.UIImage:imageWithContentsOfFile(objc.toobj(filepath))
    end
    if animpath then
        local gifData = objc.NSData:dataWithContentsOfFile(objc.toobj(animpath))
        animImg = objc.FLAnimatedImage:animatedImageWithGIFData(gifData)
    end
    return id, image, animImg

end
return weatherhandler