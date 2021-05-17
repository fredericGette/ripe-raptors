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
local function onChangePlayerDirection(otherPlayer, transform)
	otherPlayer.Character.HumanoidRootPart.RootMotor.Transform = transform
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
		
		-- we work with x and y coordinates. z coordinate should not be used.

		local MoveVector = ControlModule:GetMoveVector()
		-- directionX [-1...+1]; left=-1; right=+1
		local directionX = MoveVector.X
		-- directionY [-1...+1]; down=-1; up=+1
		local directionY = -MoveVector.Z
			
		-- orientationX [-1,+1]; left=+1; right=-1
		local orientationX = player.Character.HumanoidRootPart.RootMotor.Transform.rightVector.x

		-- Calculate horizontal speed = angularVelocity.Y (radians per second) * rayon (studs)
		-- negative to be consistent with the sign of the Thrust force
		-- To the left: Hspeed>0, Xforce>0
		local horizontalSpeed = -player.Character.Torso.AssemblyAngularVelocity.Y * (player.Character.Anchor.Position - player.Character.Torso.Position).Magnitude
		-- Calcul vertical speed = linearVelocity.Y (studs per second)
		local verticalSpeed = player.Character.Torso.AssemblyLinearVelocity.Y
		-- Calcul total speed = (horizontal + vertical).Magnitude (studs per second)
		local speedVector = Vector3.new(horizontalSpeed, verticalSpeed, 0)

		-- Lift force
		local mass = player.Character.Torso.AssemblyMass
		local liftForce = Vector3.new(0,0,0)
		-- Air must flow from the front to the rear of the plane
		-- Calcul the angle between the air flow (speec vector) and the plane (torso)
		local projectedVector = speedVector * Vector3.new(1, 1, 0)
		projectedVector = player.Character.HumanoidRootPart.CFrame:VectorToWorldSpace(projectedVector)
		projectedVector = player.Character.Torso.CFrame:VectorToObjectSpace(projectedVector)
		local angle = math.atan2(projectedVector.Y, projectedVector.X)
		print(string.format("%+03.0f,%+03.0f,%+03.0f", projectedVector.X, projectedVector.Y, math.deg(angle)))
		if (orientationX>0 and horizontalSpeed>0 or orientationX<0 and horizontalSpeed<0) then
			local liftForceY = mass * game.Workspace.Gravity
			-- Under a limit speed the lift force descreases
			if (math.abs(speedVector.Magnitude)< 10) then
				liftForceY *= speedVector.Magnitude/10
			end 
			-- Lift force direction is up with respect of the orientation of the plane
			liftForce = Vector3.new(0,liftForceY,0)
		end
		
		-- Thrust force
		local thrustForceX = 0
		if (math.abs(directionX)> 0) then
			thrustForceX = mass*25
		end 
		-- Thurst force direction is the same than the plane
		local thrustForce = Vector3.new(thrustForceX, 0, 0)

		-- Air resistance = square of the speed with respect of the sign.
		-- The speed vectors ignore the orientation of the plane, 
		-- as the Air resistance will be applied to the plane, 
		-- we have to update the oriention of the Air resistance.
		-- We use the CFrame of the HumanoidRootPart that - as the speed -- ignores the orientation of the plane.
		local airResistance = Vector3.new(speedVector.X*math.abs(speedVector.X), speedVector.Y*math.abs(speedVector.Y), speedVector.Z*math.abs(speedVector.Z))
		airResistance = player.Character.HumanoidRootPart.CFrame:VectorToWorldSpace(airResistance)
		airResistance = player.Character.Torso.CFrame:VectorToObjectSpace(airResistance)
		
		-- Move
		-- Forces are applied regarding the orientation of the torso.
		player.Character.Torso.VectorForce.Force = liftForce + thrustForce - airResistance

		-- Propeller simulation
		local propellerMotor = player.Character.Propeller.Torque
		if (player.Character.Propeller.AssemblyAngularVelocity.Magnitude < 30) then
			propellerMotor.Torque = Vector3.new(0.1*math.abs(directionX), 0, 0)
		else
			propellerMotor.Torque = Vector3.new(0,0,0)
		end

		local vfX = player.Character.Torso.VectorForce.Force.X
		local vfY = player.Character.Torso.VectorForce.Force.Y
		local vfZ = player.Character.Torso.VectorForce.Force.Z

		-- To the left: Hspeed>0, Xforce>0
		-- Up: Vspeed>0, Yforce>0
		print(string.format("dir:%+d,%+d o:%+d spd(H,V,T):%+03.0f,%+03.0f,%+03.0f f:%+05.0f,%+05.0f,%+05.0f s:%+05.0f,%+05.0f,%+05.0f ar:%+05.0f,%+05.0f,%+05.0f",directionX,directionY, orientationX, speedVector.X,speedVector.Y,speedVector.Magnitude, vfX,vfY,vfZ, speedVector.X,speedVector.Y,speedVector.Z, airResistance.X,airResistance.Y,airResistance.Z ))		

		if directionY == 1 then
			player.Character.HumanoidRootPart.RootMotor.Transform = CFrame.Angles(0, math.pi/16, 0)
		end 
		if directionY == 0 then
			player.Character.HumanoidRootPart.RootMotor.Transform = CFrame.Angles(0, 0, 0)
		end 
		if directionY == -1 then
			player.Character.HumanoidRootPart.RootMotor.Transform = CFrame.Angles(0, -math.pi/16, 0)
		end 

		if directionX > 0 and orientationX > 0 then
			player.Character.HumanoidRootPart.RootMotor.Transform = CFrame.Angles(0, 0, math.pi)
			changePlayerDirection:FireServer(player.Character.HumanoidRootPart.RootMotor.Transform)
		end
		
		if directionX < 0 and orientationX < 0 then
			player.Character.HumanoidRootPart.RootMotor.Transform = CFrame.Angles(0, 0, 0)
			changePlayerDirection:FireServer(player.Character.HumanoidRootPart.RootMotor.Transform)
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
				
				--local explosion = Instance.new("Explosion")
				--explosion.Position = character.Torso.Position
				--explosion.Parent = workspace
				
				-- Sends an event to the server to destroy near players
				-- playerExplodes:FireServer(explosion.Position)
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

