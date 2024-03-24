local objc = require'objc.src'
local ffi  = require 'ffi'
local CGRectMake = require'homescreenview'.CGRectMake
local json       = require 'json'
objc.class("CloudView","UIView")
ffi.cdef[[
    bool CGRectContainsPoint(CGRect rect, CGPoint point);
]]
CloudTypes = {
    FewClouds = 0,
    ScatterClouds = 1,
    BrokeClouds = 2,
    OverClouds = 3
}
RainTypes = {
    None = 0,
    Light = 1,
    Moderate = 2,
    Heavy = 3,
    VeryHeavy = 4,
    EXTREME = 5,
    Freezing = 6,
    LightShower = 7,
    Shower = 8,
    HeavyShower = 9,
    RagShower = 10
}
local function CGPointMake(x,y)
    local point = ffi.new'CGPoint'
    point.x = x
    point.y = y
    return point
end
local function randomPointOnScreen(rect,checker)
    math.randomseed(os.time() + tonumber(tostring({}):sub(8)))
    local UIScreenBounds = objc.UIScreen:mainScreen().bounds
    local toret = CGPointMake(math.random(0,UIScreenBounds.size.width),math.random(0,UIScreenBounds.size.height))
    --toret = objc.UIScreen:mainScreen().coordinateSpace:convertPoint_toCoordinateSpace(toret,checker)
  if checker then 
       -- print("converting array")
      local toiter = objc.tolua(checker.subviews)
       -- print("converted array")
      if toiter ~= {} then
      for _,v in ipairs(toiter) do
           --print('Iteration!')
           if ffi.C.CGRectContainsPoint(v.frame,toret) then
               return randomPointOnScreen(rect,checker)
           end
       end
     end
 return toret
   else 
       return toret
   end
end
function objc.CloudView:placeClouds(cloudType,cloud,rain)
    local coveragePercent
    local rainFramePathsIter,rainFramePathsobj
    if cloudType == CloudTypes.FewClouds then
        coveragePercent = math.random(11,25)
    elseif cloudType == CloudTypes.ScatterClouds then
        coveragePercent = math.random(25,50)
    elseif cloudType == CloudTypes.BrokeClouds then
        coveragePercent = math.random(51,84)
    elseif cloudType == CloudTypes.OverClouds then
        coveragePercent = math.random(85,100)
    end
    --print("Coverage Percentage: "..tostring(coveragePercent))
    local imgs = {}
    if rain ~= RainTypes.None and rain ~= RainTypes.EXTREME then
        for file in lfs.dir(root .. "/Library/Application Support/WeatherWhirl/lightrain") do
            if file ~= "." and file ~= ".." then
                local fullpath = root .. "/Library/Application Support/WeatherWhirl/lightrain/" .. file
                local img = objc.UIImage:imageWithContentsOfFile(objc.toobj(fullpath))
                if img then
                    table.insert(imgs,img)
                end
            end
        end
    end
    local UIScreenBounds = objc.UIScreen:mainScreen().bounds
    local UIScreenScale  = objc.UIScreen:mainScreen().scale
    local screenArea = (UIScreenBounds.size.width * UIScreenScale) * (UIScreenBounds.size.height * UIScreenScale)
    local imgArea = cloud.size.width * cloud.size.height
    local requiredClouds = math.ceil(screenArea/imgArea * (coveragePercent/100))
    --print(tostring(requiredClouds))
    for i=1,requiredClouds do
        local cloudimgView = objc.UIImageView:alloc():initWithImage(cloud)
        local randomPoint = randomPointOnScreen(cloud,self)
        --randomPoint = objc.UIScreen:mainScreen().coordinateSpace:convertPoint_toCoordinateSpace(randomPoint,self)
        cloudimgView.frame = CGRectMake(randomPoint.x,randomPoint.y,cloud.size.width,cloud.size.height)
        self:addSubview(cloudimgView)
        self:bringSubviewToFront(cloudimgView)
        if imgs ~= {} then
            local tobottom = (UIScreenBounds.size.height) - ((cloud.size.height) + cloudimgView.frame.origin.y)
            --print("dist to bottom: "..tostring(tobottom))
            local animImageView = objc.UIImageView:alloc():initWithFrame(CGRectMake(cloudimgView.frame.origin.x-85,cloudimgView.frame.origin.y,cloudimgView.bounds.size.width,tobottom))
            animImageView.animationImages = objc.toobj(imgs)
            animImageView.animationDuration = (0.15*4)*2
            if rain == RainTypes.Moderate then
                animImageView.animationDuration = (0.15*4)/1.75
            elseif rain == RainTypes.Heavy then
                animImageView.animationDuration = (0.15*4)/2.5
            end
            --print(tostring(animImageView.animationDuration))
            animImageView.animationRepeatCount = math.huge
            animImageView:startAnimating()
            cloudimgView:addSubview(animImageView)
            cloudimgView:sendSubviewToBack(animImageView)
        end
    end
end