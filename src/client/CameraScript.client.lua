--Get service needed for events used in this script
local RunService = game:GetService("RunService")

-- Variables for the camera and player
local camera = workspace.CurrentCamera
local localPlayer = game.Players.LocalPlayer

-- Table to keep track of thumbnail of all players
local imageLabels = {}

-- Enables the camera to do what this script says
camera.CameraType = Enum.CameraType.Scriptable
camera.FieldOfView = 70
local CAMERA_DISTANCE = 250

-- Called every time the screen refreshes
local function onRenderStep()
	-- Check if the player's character has spawned
	local character = localPlayer.Character
	if character then
		local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
		local humanoid = character:WaitForChild("Humanoid")
		if humanoidRootPart and humanoid.Health > 0 then  

			local viewPortsize = camera.ViewportSize
			local ratio = viewPortsize.x / viewPortsize.y
			ratio = math.exp(ratio)
			local cameraOffset = CFrame.new(0, 0, -CAMERA_DISTANCE/ratio)
			game.Lighting.FogEnd=CAMERA_DISTANCE/ratio+150
			game.Lighting.FogStart=CAMERA_DISTANCE/ratio+50

			
			-- make the camera follow the player
			camera.CFrame = humanoidRootPart.CFrame:toWorldSpace(cameraOffset)* CFrame.Angles(0, math.pi, 0)
			--camera.CFrame = CFrame.new(humanoidRootPart.Position+Vector3.new(0,20,0), humanoidRootPart.Position) -- top view
			
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