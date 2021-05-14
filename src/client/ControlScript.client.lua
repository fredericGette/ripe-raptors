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

-- Update player speed and direction on every frame.
local function onUpdate()	
	if player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character.Anchor:FindFirstChild("CylindricalConstraint") and player.Character.HumanoidRootPart:FindFirstChild("RootMotor") then
		
		local MoveVector = ControlModule:GetMoveVector()
		-- directionX [-1...+1]; left=-1; right=+1
		local directionX = MoveVector.X
		-- directionY [-1...+1]; down=-1; up=+1
		local directionY = -MoveVector.Z
			
		-- orientationX [-1,+1]; left=-1; right=+1
		local orientationX = player.Character.HumanoidRootPart.RootMotor.Transform.rightVector.x

		-- Calculate horizontal speed = angularVelocity.Y (radians per second) * rayon (studs)
		local horizontalSpeed = player.Character.HumanoidRootPart.AssemblyAngularVelocity.Y * (player.Character.Anchor.Position - player.Character.HumanoidRootPart.Position).Magnitude
		-- Calcule vertical speed = linearVelocity.Y (studs per second)
		local verticalSpeed = player.Character.HumanoidRootPart.AssemblyLinearVelocity.Y
		-- Calcule total speed = (horizontal + vertical).Magnitude (studs per second)
		local speed = Vector3.new(horizontalSpeed, verticalSpeed, 0).Magnitude

		-- Antigrav force
		local mass = player.Character.HumanoidRootPart.AssemblyMass
		local antiGravForceY = mass * game.Workspace.Gravity
		if (math.abs(horizontalSpeed)< 10) then
			antiGravForceY *= horizontalSpeed/10
		end 
		local antiGravForce = Vector3.new(0, antiGravForceY, 0)

		-- Elevator force
		local elevatorForce = Vector3.new(0, directionY*100, 0)
		
		-- Propulsion force
		local propulsionForce = Vector3.new(-directionX*1000, 0, 0)

		-- Air resistance = square of the speed
		local airResistance = Vector3.new(horizontalSpeed*horizontalSpeed*math.sign(horizontalSpeed), 0, 0)
		
		-- Move
		player.Character.HumanoidRootPart.VectorForce.Force = antiGravForce + elevatorForce + propulsionForce + airResistance

		-- Propeller simulation
		local motor = player.Character.Propeller.Torque
		if (player.Character.Propeller.AssemblyAngularVelocity.Magnitude < 30) then
			motor.Torque = Vector3.new(0.1*math.abs(directionX), 0, 0)
		else
			motor.Torque = Vector3.new(0,0,0)
		end

		local vfX = player.Character.HumanoidRootPart.VectorForce.Force.X
		local vfY = player.Character.HumanoidRootPart.VectorForce.Force.Y
		local vfZ = player.Character.HumanoidRootPart.VectorForce.Force.Z
		local lvX = player.Character.HumanoidRootPart.AssemblyLinearVelocity.X
		local lvY = player.Character.HumanoidRootPart.AssemblyLinearVelocity.Y
		local lvZ = player.Character.HumanoidRootPart.AssemblyLinearVelocity.Z
		local avX = player.Character.HumanoidRootPart.AssemblyAngularVelocity.X
		local avY = player.Character.HumanoidRootPart.AssemblyAngularVelocity.Y
		local avZ = player.Character.HumanoidRootPart.AssemblyAngularVelocity.Z
		local mav = player.Character.Propeller.AssemblyAngularVelocity.Magnitude


		print(string.format("dir:%+d,%+d o:%+d spd(H,V,T):%+03.0f,%+03.0f,%+03.0f mav:%+03.0f f:%+05.0f,%+05.0f,%+05.0f lv:%+03.0f,%+03.0f,%+03.0f av:%+03.1f,%+03.3f,%+03.1f",directionX,directionY, orientationX, horizontalSpeed,verticalSpeed,speed, mav, vfX,vfY,vfZ, lvX,lvY,lvZ, avX,avY,avZ))		

		if directionX > 0 and orientationX > 0 then
			player.Character.HumanoidRootPart.RootMotor.Transform = CFrame.Angles(0, 0, math.pi)
			changePlayerDirection:FireServer(orientationX)
		end
		
		if directionX < 0 and orientationX < 0 then
			player.Character.HumanoidRootPart.RootMotor.Transform = CFrame.Angles(0, 0, 0)
			changePlayerDirection:FireServer(orientationX)
		end
		
	end
end
RunService:BindToRenderStep("Control", Enum.RenderPriority.Input.Value, onUpdate)	


-- Called when the player's character is added
local function onCharacterAdded(character)

	-- Change state of the Humanoid
	-- State "Physics" allow free movement of the Cylindrical constraint
	local humanoid = character:WaitForChild("Humanoid")
	humanoid:ChangeState(Enum.HumanoidStateType.Physics)
	-- Force state to be "Physics"
	humanoid.StateChanged:Connect(function(oldState, newState)
		if newState ~= Enum.HumanoidStateType.Physics then
			humanoid:ChangeState(Enum.HumanoidStateType.Physics)
		end
	end)

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

