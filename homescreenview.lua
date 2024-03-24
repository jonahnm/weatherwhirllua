local objc = require'objc.src'
objc.load'CoreGraphics'
local ffi = require'ffi'
local bit = require'bit'
objc.class("HomeScreenView","UIView")
local homescreenview = {}
homescreenview.AnimPlace = {
    TopLeftCorner = 0
}
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
    print('placeClouds with ID: '..tostring(weatherID))
    local cloud = objc.UIImage:imageWithContentsOfFile(root .. "/Library/Application Support/WeatherWhirl/cloud.png")
    local sephiroth = objc.UIImage:imageWithContentsOfFile(root .. "/Library/Application Support/WeatherWhirl/sephiroth.png")
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