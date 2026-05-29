-- Thai-Bird Gallery App
-- Features: Remote image loading, swipe navigation, auto-slide, sound effects

display.setStatusBar( display.HiddenStatusBar )

-- Constants
local SCREEN_WIDTH = display.contentWidth
local SCREEN_HEIGHT = display.contentHeight
local GITHUB_BASE_URL = "https://raw.githubusercontent.com/mrJirawat07/Thai-Bird/main/test/"
local AUTO_SLIDE_INTERVAL = 5000 -- 5 seconds
local SWIPE_THRESHOLD = 50 -- minimum distance to register a swipe

-- Bird species data (from test folder)
local birds = {
	"ABBOTTS BABBLER",
	"ABBOTTS BOOBY",
	"ABYSSINIAN GROUND HORNBILL",
	"AFRICAN CROWNED CRANE",
	"AFRICAN EMERALD CUCKOO",
	"AFRICAN FIREFINCH",
	"AFRICAN OYSTER CATCHER",
	"AFRICAN PIED HORNBILL",
}

-- Gallery state
local gallery = {
	currentIndex = 1,
	totalImages = #birds,
	images = {},
	currentImage = nil,
	isLoading = false,
	autoSlideActive = true,
	autoSlideTimer = nil,
	swipeStartX = 0,
	swipeStartY = 0,
}

-- UI Elements
local sceneGroup = display.getCurrentStage()
local imageGroup = display.newGroup()
sceneGroup:insert(imageGroup)

local uiGroup = display.newGroup()
sceneGroup:insert(uiGroup)

-- Create background
local background = display.newRect(sceneGroup, SCREEN_WIDTH/2, SCREEN_HEIGHT/2, SCREEN_WIDTH, SCREEN_HEIGHT)
background:setFillColor(0.1, 0.1, 0.1)

-- Create image container
local imageContainer = display.newRect(imageGroup, SCREEN_WIDTH/2, SCREEN_HEIGHT/2 - 20, SCREEN_WIDTH - 20, SCREEN_HEIGHT * 0.7)
imageContainer:setFillColor(0.05, 0.05, 0.05)
imageContainer:setStrokeColor(0.5, 0.5, 0.5)
imageContainer.strokeWidth = 2

-- Counter display
local counterText = display.newText(uiGroup, "1 / " .. gallery.totalImages, SCREEN_WIDTH/2, SCREEN_HEIGHT - 40, native.systemFont, 16)
counterText:setFillColor(1, 1, 1)

-- Status text
local statusText = display.newText(uiGroup, "Loading...", SCREEN_WIDTH/2, 20, native.systemFont, 12)
statusText:setFillColor(0.7, 0.7, 0.7)

-- Title text
local titleText = display.newText(uiGroup, birds[1], SCREEN_WIDTH/2, SCREEN_HEIGHT - 65, native.systemFont, 14)
titleText:setFillColor(1, 1, 0.2)

-- Buttons
local buttonY = SCREEN_HEIGHT - 25

-- Auto slide toggle button
local autoSlideBtn = display.newRect(uiGroup, 50, buttonY, 40, 20)
autoSlideBtn:setFillColor(0.2, 0.8, 0.2)
autoSlideBtn.strokeWidth = 1
autoSlideBtn:setStrokeColor(1, 1, 1)

local autoSlideBtnText = display.newText(uiGroup, "AUTO", autoSlideBtn.x, autoSlideBtn.y, native.systemFont, 10)
autoSlideBtnText:setFillColor(1, 1, 1)

-- Random button
local randomBtn = display.newRect(uiGroup, SCREEN_WIDTH/2, buttonY, 40, 20)
randomBtn:setFillColor(0.8, 0.2, 0.2)
randomBtn.strokeWidth = 1
randomBtn:setStrokeColor(1, 1, 1)

local randomBtnText = display.newText(uiGroup, "RANDOM", randomBtn.x, randomBtn.y, native.systemFont, 10)
randomBtnText:setFillColor(1, 1, 1)

-- Sound toggle button
local soundBtn = display.newRect(uiGroup, SCREEN_WIDTH - 50, buttonY, 40, 20)
soundBtn:setFillColor(0.2, 0.2, 0.8)
soundBtn.strokeWidth = 1
soundBtn:setStrokeColor(1, 1, 1)

local soundBtnText = display.newText(uiGroup, "SOUND", soundBtn.x, soundBtn.y, native.systemFont, 10)
soundBtnText:setFillColor(1, 1, 1)

local soundEnabled = true

-- Create or get sound
local function getSwipeSound()
	local soundPath = system.pathForFile("swipe.wav", system.DocumentsDirectory)
	if not soundPath then
		-- Fallback: use a built-in beep
		return nil
	end
	return soundPath
end

-- Play sound effect
local function playSound()
	if soundEnabled then
		-- Simple beep sound (since we don't have audio file)
		native.showAlert("", "Swipe!", {"OK"})
	end
end

-- Load image from GitHub
local function loadImage(birdName, imageNumber)
	if gallery.isLoading then return end
	
	gallery.isLoading = true
	statusText.text = "Loading..."
	
	-- Remove old image
	if gallery.currentImage then
		display.remove(gallery.currentImage)
	end
	
	-- Construct URL
	local url = GITHUB_BASE_URL .. string.gsub(birdName, " ", "%%20") .. "/" .. imageNumber .. ".jpg"
	
	-- Create local filename
	local localFilename = string.gsub(birdName, " ", "_") .. "_" .. imageNumber .. ".jpg"
	
	-- Load image with callback
	local function onImageComplete(event)
		if event.isError then
			statusText.text = "Error loading image"
			gallery.isLoading = false
		else
			-- Create image display object from the downloaded file
			local localPath = system.pathForFile(localFilename, system.CachesDirectory)
			gallery.currentImage = display.newImage(imageGroup, localPath)
			gallery.currentImage.x = SCREEN_WIDTH/2
			gallery.currentImage.y = SCREEN_HEIGHT/2 - 20
			
			-- Scale image to fit container
			local maxWidth = SCREEN_WIDTH - 40
			local maxHeight = SCREEN_HEIGHT * 0.65
			
			if gallery.currentImage.width > maxWidth or gallery.currentImage.height > maxHeight then
				local scaleX = maxWidth / gallery.currentImage.width
				local scaleY = maxHeight / gallery.currentImage.height
				local scale = math.min(scaleX, scaleY)
				gallery.currentImage.xScale = scale
				gallery.currentImage.yScale = scale
			end
			
			-- Animate in
			transition.to(gallery.currentImage, {alpha = 1, time = 300})
			
			statusText.text = "Ready"
			gallery.isLoading = false
		end
	end
	
	local params = {
		url = url,
		filename = localFilename,
		baseDir = system.CachesDirectory,
		onComplete = onImageComplete
	}
	
	display.loadRemoteImage(params)
end

-- Update display
local function updateDisplay()
	gallery.currentIndex = (gallery.currentIndex - 1) % gallery.totalImages + 1
	titleText.text = birds[gallery.currentIndex]
	counterText.text = gallery.currentIndex .. " / " .. gallery.totalImages
	
	loadImage(birds[gallery.currentIndex], 1)
end

-- Navigate to next image
local function nextImage()
	if gallery.isLoading then return end
	
	gallery.currentIndex = gallery.currentIndex + 1
	if gallery.currentIndex > gallery.totalImages then
		gallery.currentIndex = 1
	end
	
	-- Animate transition
	if gallery.currentImage then
		transition.to(gallery.currentImage, {
			x = -SCREEN_WIDTH,
			alpha = 0,
			time = 200,
			onComplete = updateDisplay
		})
	else
		updateDisplay()
	end
	
	playSound()
end

-- Navigate to previous image
local function previousImage()
	if gallery.isLoading then return end
	
	gallery.currentIndex = gallery.currentIndex - 1
	if gallery.currentIndex < 1 then
		gallery.currentIndex = gallery.totalImages
	end
	
	-- Animate transition
	if gallery.currentImage then
		transition.to(gallery.currentImage, {
			x = SCREEN_WIDTH,
			alpha = 0,
			time = 200,
			onComplete = updateDisplay
		})
	else
		updateDisplay()
	end
	
	playSound()
end

-- Random image
local function randomImage()
	local randomIndex = math.random(1, gallery.totalImages)
	if randomIndex == gallery.currentIndex and gallery.totalImages > 1 then
		randomImage()
		return
	end
	
	gallery.currentIndex = randomIndex
	
	if gallery.currentImage then
		transition.to(gallery.currentImage, {
			rotation = 360,
			alpha = 0,
			time = 300,
			onComplete = updateDisplay
		})
	else
		updateDisplay()
	end
	
	playSound()
end

-- Auto slide
local function startAutoSlide()
	if gallery.autoSlideActive and not gallery.autoSlideTimer then
		gallery.autoSlideTimer = timer.performWithDelay(AUTO_SLIDE_INTERVAL, function()
			nextImage()
		end, 0)
		autoSlideBtn:setFillColor(0.2, 1, 0.2)
	end
end

local function stopAutoSlide()
	if gallery.autoSlideTimer then
		timer.cancel(gallery.autoSlideTimer)
		gallery.autoSlideTimer = nil
	end
	autoSlideBtn:setFillColor(0.2, 0.8, 0.2)
end

-- Button handlers
local function onAutoSlideTouch(event)
	if event.phase == "ended" then
		gallery.autoSlideActive = not gallery.autoSlideActive
		
		if gallery.autoSlideActive then
			startAutoSlide()
		else
			stopAutoSlide()
		end
	end
	return true
end

local function onRandomTouch(event)
	if event.phase == "ended" then
		randomImage()
	end
	return true
end

local function onSoundTouch(event)
	if event.phase == "ended" then
		soundEnabled = not soundEnabled
		if soundEnabled then
			soundBtn:setFillColor(0.2, 0.2, 1)
		else
			soundBtn:setFillColor(0.4, 0.4, 0.4)
		end
	end
	return true
end

-- Swipe handling
local function onSwipe(event)
	if event.phase == "began" then
		gallery.swipeStartX = event.x
		gallery.swipeStartY = event.y
	elseif event.phase == "ended" or event.phase == "cancelled" then
		local deltaX = event.x - gallery.swipeStartX
		local deltaY = event.y - gallery.swipeStartY
		
		-- Check if it's a horizontal swipe
		if math.abs(deltaX) > SWIPE_THRESHOLD and math.abs(deltaX) > math.abs(deltaY) then
			if deltaX > 0 then
				-- Swipe right: previous image
				previousImage()
			else
				-- Swipe left: next image
				nextImage()
			end
		end
	end
	return true
end

-- Touch event handler for swipe
local function onTouch(event)
	-- Ignore touches on buttons
	if event.x > 30 and event.x < 70 and event.y > buttonY - 10 and event.y < buttonY + 10 then
		return onAutoSlideTouch(event)
	elseif event.x > SCREEN_WIDTH/2 - 20 and event.x < SCREEN_WIDTH/2 + 20 and event.y > buttonY - 10 and event.y < buttonY + 10 then
		return onRandomTouch(event)
	elseif event.x > SCREEN_WIDTH - 70 and event.x < SCREEN_WIDTH - 30 and event.y > buttonY - 10 and event.y < buttonY + 10 then
		return onSoundTouch(event)
	end
	
	-- Handle swipe
	return onSwipe(event)
end

-- Add touch listener
Runtime:addEventListener("touch", onTouch)

-- Initialize
print("Gallery App Started")
print("Total Birds: " .. gallery.totalImages)
updateDisplay()
startAutoSlide()

-- Cleanup on exit
local function onSystemEvent(event)
	if event.type == "applicationExit" then
		if gallery.autoSlideTimer then
			timer.cancel(gallery.autoSlideTimer)
		end
		if gallery.currentImage then
			display.remove(gallery.currentImage)
		end
	end
end

Runtime:addEventListener("system", onSystemEvent)
