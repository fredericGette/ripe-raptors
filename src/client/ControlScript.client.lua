--This script determines what functions to call when a player presses a button when playing.
 
-- Roblox Services
local ContextActionService = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
 
-- Variables for the player
local player = game.Players.LocalPlayer	

-- Player module
local PlayerScripts = player:WaitForChild("PlayerScripts")
local PlayerModule = require(PlayerScripts:WaitForChild("PlayerModule"))
local ControlModule = PlayerModule:GetControls()

-- Variables for RemoteEvents (see the PlayerShipRemotes Script)
local changePlayerDirection = ReplicatedStorage:WaitForChild("ChangePlayerDirection")
local playerExplodes = ReplicatedStorage:WaitForChild("PlayerExplodes")

-- When an other player change of direction
local function onChangePlayerDirection(otherPlayer, direction)
	if direction > 0 then
		otherPlayer.Character.HumanoidRootPart.RootMotor.Transform = CFrame.Angles(0, 0, math.pi)
	end
	if direction < 0 then
		otherPlayer.Character.HumanoidRootPart.RootMotor.Transform = CFrame.Angles(0, 0, 0)
	end	
end
changePlayerDirection.OnClientEvent:connect(onChangePlayerDirection)

local engineSound = Instance.new("Sound")
engineSound.SoundId = "http://www.roblox.com/asset/?id=578468221"
engineSound.Volume = 2.5
engineSound.Looped = true

local explosionSound = Instance.new("Sound")
explosionSound.SoundId = "http://www.roblox.com/asset/?id=691216625"
explosionSound.Volume = 2.5
explosionSound.Looped = false

local moveZ = 0
local moveX = 0

-- Update player speed and direction on every frame.
local function onUpdate()	
	if player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character.Anchor:FindFirstChild("CylindricalConstraint") and player.Character.HumanoidRootPart:FindFirstChild("RootMotor") then
		
		local MoveVector = ControlModule:GetMoveVector()
		local horizontalSpeed = MoveVector.X
		local verticalSpeed = -MoveVector.Z
				
		if (verticalSpeed > 0 and moveZ < 10) or (verticalSpeed < 0 and moveZ > -10)  then
			moveZ = moveZ+0.1*math.sign(verticalSpeed)
		end

		if verticalSpeed == 0 and moveZ ~= 0 then
			moveZ = moveZ-0.1*math.sign(moveZ)
		end

		if (horizontalSpeed > 0 and moveX < 1) or (horizontalSpeed < 0 and moveX > -1) then
			moveX = moveX+0.01*math.sign(horizontalSpeed)
		end

		local horizontalOrientation = player.Character.HumanoidRootPart.RootMotor.Transform.rightVector.x
		
		local cc = player.Character.Anchor.CylindricalConstraint

		if horizontalSpeed == 0 and math.abs(moveX) < 0.1 and cc.CurrentPosition > 0.1 then
			moveX = -0.1*math.sign(horizontalOrientation)
		end

		cc.AngularVelocity = moveX	
		cc.Velocity = moveZ		
				
		if moveX > 0 and horizontalOrientation > 0 then
			player.Character.HumanoidRootPart.RootMotor.Transform = CFrame.Angles(0, 0, math.pi)
			changePlayerDirection:FireServer(horizontalOrientation)
		end
		
		if moveX < 0 and horizontalOrientation < 0 then
			player.Character.HumanoidRootPart.RootMotor.Transform = CFrame.Angles(0, 0, 0)
			changePlayerDirection:FireServer(horizontalOrientation)
		end
		
		-- Real vertical speed.
		local effectiveMoveZ = player.Character.HumanoidRootPart.Velocity.y 
		if math.abs(effectiveMoveZ) < 0.1 and moveZ < -0.1 and verticalSpeed >= 0 then
			-- Player is blocked by the floor and wants to take off. 
			moveZ = 0
		end
		if math.abs(effectiveMoveZ) < 0.1 and moveZ > 0.1 and verticalSpeed <= 0 then
			-- Player is at max altitude and wants to land. 
			moveZ = 0
		end
		  
		-- Real horizontal speed.
		local effectiveMoveX = math.sqrt(player.Character.HumanoidRootPart.Velocity.x^2 + player.Character.HumanoidRootPart.Velocity.z^2)
	end
end
RunService:BindToRenderStep("Control", Enum.RenderPriority.Input.Value, onUpdate)	


-- Called when the player's character is added
local function onCharacterAdded(character)
	-- Stops player movement when respawning
	moveX = 0
	moveZ = 0
	
	-- No jump when player is on the ground
	local humanoid = character:WaitForChild("Humanoid")
	humanoid.JumpPower=0
	
	-- Destroy player when a humanoid's part (head, torso, ...) is not protected by a ForceField
	-- and is touched by something that is not: 
	--  another part of the player
	--  a bullet (damages taken by bullets are managed by BulletHandler)
	character.Torso.Touched:Connect(function(touchingPart, humanoidPart)  
		if 
			touchingPart.Parent.Name ~= player.Name 
			and 
			touchingPart.Name ~= "Bullet" 
			and
			not character:FindFirstChildOfClass("ForceField")
		then			
			-- Caculates the force of the impact: velocity of the player minus velocity of the touched object
			local playerVelocity = character.HumanoidRootPart.Velocity
			local objectVelocity = touchingPart.Velocity
			local energy = playerVelocity - objectVelocity
			print(playerVelocity.Magnitude," ",objectVelocity.Magnitude," ",energy.Magnitude)
			if energy.Magnitude > 0 then
				explosionSound.Parent = character
				explosionSound:Play() 

				wait(0.2) -- synchro sound with explosion
				
				local explosion = Instance.new("Explosion")
				explosion.Position = character.Torso.Position
				explosion.Parent = workspace
				
				-- Sends an event to the server to destroy near players
				playerExplodes:FireServer(explosion.Position)
				-- The Explosion is enough to destroy the player
				--humanoid:TakeDamage(humanoid.Health)
			end
		end
	end)
		
	-- Starts engine
	engineSound.Parent = character.Torso
	engineSound:Play()
end

-- Game starts
-- see https://developer.roblox.com/api-reference/property/Player/Character
local character = player.Character
if not character or not character.Parent then
    character = player.CharacterAdded:wait()
end
onCharacterAdded(character)

-- Player respawn
player.CharacterAdded:Connect(onCharacterAdded)	

