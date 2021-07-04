--Get service needed for events used in this script
local RunService = game:GetService("RunService")

-- Variables for the camera and player
local camera = workspace.CurrentCamera
local localPlayer = game.Players.LocalPlayer

-- Table to keep track of thumbnail of all players
local imageLabels = {}

-- Enables the camera to do what this script says
camera.CameraType = Enum.CameraType.Scriptable
camera.FieldOfView = 100
game.Lighting.FogEnd=150
game.Lighting.FogStart=80

local cameraPositionX = 0
local cameraPositionY = 0

-- Called every time the screen refreshes
local function onRenderStep()
	-- Check if the player's character has spawned
	local character = localPlayer.Character
	if character then
		local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
		local humanoid = character:WaitForChild("Humanoid")
		if humanoidRootPart and humanoid.Health > 0 then  

			if localPlayer:GetAttribute("motionX") == "stop" and cameraPositionX > 0 then cameraPositionX -= 0.1*(math.abs(cameraPositionX)+0.1) end
			if localPlayer:GetAttribute("motionX") == "stop" and cameraPositionX < 0 then cameraPositionX += 0.1*(math.abs(cameraPositionX)+0.1) end
			if localPlayer:GetAttribute("motionX") == "left" and cameraPositionX > -1 then cameraPositionX -= 0.1*(math.abs(cameraPositionX)+0.1) end
			if localPlayer:GetAttribute("motionX") == "right" and cameraPositionX < 1 then cameraPositionX += 0.1*(math.abs(cameraPositionX)+0.1) end

			if localPlayer:GetAttribute("motionY") == "stop" and cameraPositionY > 0 then cameraPositionY -= 0.1 end
			if localPlayer:GetAttribute("motionY") == "stop" and cameraPositionY < 0 then cameraPositionY += 0.1 end
			if localPlayer:GetAttribute("motionY") == "up" and cameraPositionY > -2 then cameraPositionY -= 0.1 end
			if localPlayer:GetAttribute("motionY") == "down" and cameraPositionY < 2 then cameraPositionY += 0.1 end

			local cameraOffset = CFrame.new(cameraPositionX, cameraPositionY, -15)

			-- make the camera follow the player
			local cameraPosition = humanoidRootPart.CFrame:toWorldSpace(cameraOffset).Position
			camera.CFrame = CFrame.new(cameraPosition, humanoidRootPart.CFrame.Position)

			-- Update the focus of the camera to follow the character
			camera.Focus = humanoidRootPart.CFrame			
		end
	end
	
	-- Display a thumbnail above each player
	local players = game.Players:GetPlayers( )
	local viewportSize = camera.ViewportSize
	local ratio = viewportSize.x / viewportSize.y
    for i = 1, #players do  
		local player = players[i]
		if imageLabels[player] and player.Character and player.Character:FindFirstChild("Torso") then
			local imageLabel = imageLabels[player]
			local vector, onScreen = camera:WorldToScreenPoint(player.Character.Torso.Position)
			if onScreen and vector.Z < 90 then
				imageLabel.Size = UDim2.new(0.1/ratio, 0, 0.1, 0)
				imageLabel.Position = UDim2.new(0, vector.X, 0, vector.Y-viewportSize.Y*imageLabel.Size.Height.Scale)
				imageLabel.Visible=true
			else
				imageLabel.Visible=false
			end
		end 
    end
end

-- This function will wait for up to timeOut seconds for the thumbnail to be generated.
-- It will just return a fallback (probably N/A) url if it's not generated in time.
function getPlayerImage(userId, thumbnailSize, thumbnailType, timeOut)
	if not thumbnailSize then thumbnailSize = Enum.ThumbnailSize.Size48x48 end
	if not thumbnailType then thumbnailType = Enum.ThumbnailType.AvatarBust end
	if not timeOut then timeOut = 5 end

	local finished = false
	local finishedBindable = Instance.new("BindableEvent") -- fired with one parameter: imageUrl

	delay(timeOut, function()
		if not finished then
			finished = true
			finishedBindable:Fire("https://www.roblox.com/headshot-thumbnail/image?width=48&height=48&format=png&userId=1")
		end
	end)

	spawn(function()
		while true do
			if finished then
				break
			end

			local thumbnailUrl, isFinal = game.Players:GetUserThumbnailAsync(userId, thumbnailType, thumbnailSize)

			if finished then
				break
			end

			if isFinal then
				finished = true
				finishedBindable:Fire(thumbnailUrl)
				break
			end

			wait(1)
		end
	end)

	local imageUrl = finishedBindable.Event:Wait()
	return imageUrl
end

-- Create the thumbnail of a player
local function addImageLabel(player)
	local imageLabel = Instance.new("ImageLabel")
	if imageLabels[player] then
		imageLabel:Destroy()
		return
	else
		imageLabels[player] = imageLabel
	end
	local thumbnail = getPlayerImage(player.UserId)
		 		
	imageLabel.Image = thumbnail
	imageLabel.BackgroundTransparency = 1
	
	local viewPortsize = camera.ViewportSize
	local ratio = viewPortsize.x / viewPortsize.y
	
	imageLabel.Size = UDim2.new(0.1/ratio, 0, 0.1, 0)
	imageLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	imageLabel.Visible = false
	imageLabel.Name = "thumbnail-"..player.Name
	imageLabel.Parent = localPlayer.PlayerGui.ScreenGui -- adds the thumbnail in our screen			
end

-- Called when a player is added to the game
local function onPlayerAdded(player)
	addImageLabel(player)
end

-- Creates thumbnail of existing players
local function initImageLabels()
	local players = game.Players:GetPlayers( )
    for i = 1, #players do  
		addImageLabel(players[i])
	end	
end

-- Game starts
game.Players.PlayerAdded:Connect(onPlayerAdded)
spawn(function() -- don't block player when getting thumbnails
	initImageLabels()
end)
RunService:BindToRenderStep("Camera", Enum.RenderPriority.Camera.Value, onRenderStep)