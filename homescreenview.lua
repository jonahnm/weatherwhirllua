local objc = require'objc.src'
objc.load'CoreGraphics'
local ffi = require'ffi'
local bit = require'bit'
objc.class("HomeScreenView","UIView")
local homescreenview = {}
homescreenview.AnimPlace = {
    TopLeftCorner = 0
}
function sleep(s)
    local ntime = os.time() + s
    repeat coroutine.yield() until os.time() > ntime
end
homescreenviewisupdating = false
function objc.HomeScreenView:update()
    local id,image,animimg
    local thepcall,err = pcall(function()
        id,image,animimg = weatherhandler.UIImageForCurrentWeather()
    end)
    if thepcall then
        local weatherView = self
        thepcall,err = pcall(function() 
        weatherView:setCloudView(objc.CloudView:alloc():init())
        end)
        if not thepcall and err then
         print("setCloudView oops! "..tostring(err))
         return
       end
        weatherView.cloudView.backgroundColor = objc.UIColor:clearColor()
        weatherView.backgroundColor = objc.UIColor:clearColor()
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
end
end
local loop = coroutine.wrap(function (inst)
    local first = true
    while true do
        coroutine.yield()
        local time = os.date('*t')
        local sleeptime = (60-time.min)*60
        if not first then
            inst:update()
            sleep(sleeptime) 
        else
            first = false
            sleep(sleeptime)
            inst:update()
        end
    end
end)
function homescreenview.CGRectMake(x,y,width,height)
    local rect = ffi.new'CGRect'
    rect.origin.x = x
    rect.origin.y = y
    rect.size.width = width
    rect.size.height = height
    return rect
end
function objc.HomeScreenView:setImgView(imgView)
    if self.imgView then
        self.imgView:removeFromSuperview()
        self.imgView:release()
    end
    imgView.backgroundColor = objc.UIColor:clearColor()
    local bounds = objc.UIScreen:mainScreen().bounds
    imgView.frame = homescreenview.CGRectMake(0,0,bounds.size.width,bounds.size.height)
    self:addSubview(imgView)
    self:sendSubviewToBack(imgView)
    self.imgView = imgView
end
function objc.HomeScreenView:setBackgroundWithImage(img)
    if img:isKindOfClass(objc.UIImage:class()) then
       -- print('Setting imageView!')
        self:setImgView(objc.UIImageView:alloc():initWithImage(img))
        loop(self)
    end
end
function objc.HomeScreenView:setCloudView(cloudView)
    local bounds = objc.UIScreen:mainScreen().bounds
    cloudView.frame = homescreenview.CGRectMake(0,0,bounds.size.width,bounds.size.height)
    self:addSubview(cloudView)
    self:bringSubviewToFront(cloudView)
    self.cloudView = cloudView
end
function objc.HomeScreenView:setAnimationWithGif(animImg,whereto)
    local imageView = objc.FLAnimatedImageView:alloc():init()
    imageView.animatedImage = animImg
  --  imageView.translatesAutoresizingMaskIntoConstraints = false
    self:addSubview(imageView)
    self:bringSubviewToFront(imageView)
    --if whereto == homescreenview.AnimPlace.TopLeftCorner then
        --local vertConstraints = objc.NSLayoutConstraint:constraintsWithVisualFormat_options_metrics_views(objc.toobj("V:|[imgView]"),bit.lshift(0,16),nil,objc.toobj{
        --    imgView = imageView
      --  })
        --local horizConstraints = objc.NSLayoutConstraint:constraintsWithVisualFormat_options_metrics_views(objc.toobj("H:|[imgView]"),bit.lshift(0,16),nil,objc.toobj{
         --   imgView = imageView
      --  })
       -- self:addConstraints(vertConstraints)
       -- self:addConstraints(horizConstraints)
       -- print("constraints!")
  --  end
end
function objc.HomeScreenView:placeClouds(weatherID)
    local releasepool = objc.NSAutoreleasePool:new()
    if not self.cloudView then
        return
    end
   -- print('placeClouds with ID: '..tostring(weatherID))
    local cloud = objc.UIImage:imageWithContentsOfFile(rootpath"/Library/Application Support/WeatherWhirl/cloud.png")
    local sephiroth = objc.UIImage:imageWithContentsOfFile(rootpath"/Library/Application Support/WeatherWhirl/sephiroth.png")
    -- Non-Rainy
    if weatherID == 801 then
        self.cloudView:placeClouds(CloudTypes.FewClouds,cloud,RainTypes.None)
    elseif weatherID == 802 then
        self.cloudView:placeClouds(CloudTypes.ScatterClouds,cloud,RainTypes.None)
    elseif weatherID == 803 then
        self.cloudView:placeClouds(CloudTypes.BrokeClouds,cloud,RainTypes.None)
    elseif weatherID == 804 then
        self.cloudView:placeClouds(CloudTypes.OverClouds,cloud,RainTypes.None)
    end
    -- Rainy
    if weatherID == 500 then
        self.cloudView:placeClouds(CloudTypes.FewClouds,sephiroth,RainTypes.Light)
    elseif weatherID == 501 then
        self.cloudView:placeClouds(CloudTypes.ScatterClouds,sephiroth,RainTypes.Moderate)
    elseif weatherID == 502 then
        self.cloudView:placeClouds(CloudTypes.BrokeClouds,sephiroth,RainTypes.Heavy)
    end
    releasepool:drain()
end
return homescreenview