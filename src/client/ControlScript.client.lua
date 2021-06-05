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
local playerExplodes = ReplicatedStorage:WaitForChild("PlayerExplodes")

local engineSound = Instance.new("Sound")
engineSound.SoundId = "http://www.roblox.com/asset/?id=578468221"
engineSound.Volume = 2.5
engineSound.Looped = true

local explosionSound = Instance.new("Sound")
explosionSound.SoundId = "http://www.roblox.com/asset/?id=691216625"
explosionSound.Volume = 2.5
explosionSound.Looped = false

local animationOrientationLeftTrack = nil
local animationOrientationRightTrack = nil
local animationFlipLeftTrack = nil
local animationFlipRightTrack = nil
local animationTurnLeftTrack = nil
local animationTurnRightTrack = nil
local targetOrientationKeyFrame = "+22.5"
local currentOrientationKeyFrame = "+22.5"
local turningRight=false
local turningLeft=false
local ground=true
local grounding=false
local takingOff=false
local speedVector = nil

local function freezeAnimationAtKeyframe(animationTrack, keyframeName)
	if not animationTrack.IsPlaying then
		-- Play the animation if it is not playing
		animationTrack:Play() 
	end
	local keyFrameTime = animationTrack:GetTimeOfKeyframe(keyframeName)
	-- Jump to the desired TimePosition
	animationTrack.TimePosition = keyFrameTime
	-- Set the speed to 0 to freeze the animation
	animationTrack:AdjustSpeed(0)
	--print("freeze",animationTrack,keyframeName)
end

local function orientationReached(animationTrack, keyframeName)
	-- print("Keyframe reached:"..keyframeName)
	if keyframeName == targetOrientationKeyFrame then
		--print("targetOrientationKeyFrame reached")
		currentOrientationKeyFrame = targetOrientationKeyFrame
		freezeAnimationAtKeyframe(animationTrack, currentOrientationKeyFrame)

		if turningRight and (keyframeName == "-180" or keyframeName == "+180") then
			--print("flip")
			animationTrack:Stop()
		end

		if turningLeft and (keyframeName == "-180" or keyframeName == "+180") then
			--print("flip")
			animationTrack:Stop()
		end

		if grounding then
			grounding = false
		end

		if takingOff then
			takingOff = false
		end
	end
end

local function orientationLeftReached(keyframeName)
	orientationReached(animationOrientationLeftTrack, keyframeName)
end

local function orientationRightReached(keyframeName)
	orientationReached(animationOrientationRightTrack, keyframeName)
end

local function orientationLeftStopped()
	--print("Orientation stopped")
	if ground then
		animationTurnRightTrack:Play()
	else
		animationFlipRightTrack:Play()
	end
end

local function orientationRightStopped()
	--print("Orientation stopped")
	if ground then
		animationTurnLeftTrack:Play()
	else
		animationFlipLeftTrack:Play()
	end
end

local function flipLeftStopped()
	--print("Flip stopped")
	currentOrientationKeyFrame="0"
	freezeAnimationAtKeyframe(animationOrientationLeftTrack, currentOrientationKeyFrame)
	turningLeft = false
end

local function flipRightStopped()
	--print("Flip stopped")
	currentOrientationKeyFrame="0"
	freezeAnimationAtKeyframe(animationOrientationRightTrack, currentOrientationKeyFrame)
	turningRight = false
end

local function turnLeftStopped()
	--print("Turn stopped")
	currentOrientationKeyFrame="+22.5"
	freezeAnimationAtKeyframe(animationOrientationLeftTrack, currentOrientationKeyFrame)
	turningLeft = false
end

local function turnRightStopped()
	--print("Turn stopped")
	currentOrientationKeyFrame="+22.5"
	freezeAnimationAtKeyframe(animationOrientationRightTrack, currentOrientationKeyFrame)
	turningRight = false
end

local function getTargetOrientationKeyFrame(angle)
	if angle == 0 then
		return "0"
	end
	if angle > 180 then
		angle = angle-360
	elseif angle < -180 then
		angle = angle+360
	end
	if angle == math.round(angle) then
		return string.format("%+.f", angle)
	end
	return string.format("%+.1f", angle)
end

local function checkGround(plane)
	ground = false
	local raycastResult = workspace:Raycast(plane.Position, -1.1*plane.CFrame.UpVector)
	if raycastResult then
		local isRoad = raycastResult.Instance:GetAttribute("road")
		if isRoad then
			ground = true
		end
	end
end

local function checkUp(directionY)
	local currentAngle = tonumber(currentOrientationKeyFrame)
	if directionY >= 1 then return true end
	if directionY >= 0.6 and directionY < 1 and currentAngle < 45 then return true end
	if directionY >= 0.3 and directionY < 0.6 and currentAngle < 22.5 then return true end
	if directionY > 0 and directionY < 0.3 and currentAngle < 0 then return true end
	return false
end

local function checkDown(directionY)
	local currentAngle = tonumber(currentOrientationKeyFrame)
	if directionY <= -1 then return true end
	if directionY <= -0.6 and directionY > -1 and currentAngle > -45 then return true end
	if directionY <= -0.3 and directionY > -0.6 and currentAngle > -22.5 then return true end
	if directionY < 0 and directionY > -0.3 and currentAngle > 0 then return true end
	return false
end

local function prettyVal(v)
	local pv = ""
	local sign = "+"
	if (v < 0) then
		sign = "-"
	end
	pv = string.format("\t%s\t%03.2f", sign, math.abs(v))
	return pv
end

local function engineRun(mass)
	local thrustForceX = mass*25
	if not engineSound.IsPlaying then
		engineSound:Play()
	end
	return thrustForceX
end

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
		speedVector = Vector3.new(horizontalSpeed, verticalSpeed, 0)

		-- Lift force
		local mass = player.Character.Torso.AssemblyMass
		local liftForce = Vector3.new(0,0,0)
		
		if orientationX>0 and horizontalSpeed>0 or orientationX<0 and horizontalSpeed<0 then
			local liftForceY = mass * game.Workspace.Gravity
			-- Under a limit speed the lift force descreases
			if math.abs(speedVector.Magnitude)< 10 then
				liftForceY *= speedVector.Magnitude/10
			end 
			
			-- Air must flow from the front to the rear of the plane
			-- Calcul the angle between the air flow (speed vector) and the plane (torso)
			local projectedVector = speedVector * Vector3.new(1, 1, 0)
			projectedVector = player.Character.HumanoidRootPart.CFrame:VectorToWorldSpace(projectedVector)
			projectedVector = player.Character.Torso.CFrame:VectorToObjectSpace(projectedVector)
			local angle = math.atan2(projectedVector.Y, projectedVector.X)
			liftForceY += -mass*speedVector.Magnitude*angle

			if ground and currentOrientationKeyFrame == "0" and math.abs(speedVector.Magnitude)>10 and directionY > 0 then
				-- Boost to take off
				liftForceY += mass*game.Workspace.Gravity/2
			end

			if not ground and currentOrientationKeyFrame == "0" and directionY > 0.15 and directionY < 0.3 then
				liftForceY += mass*game.Workspace.Gravity/4
			end

			if not ground and currentOrientationKeyFrame == "0" and directionY < -0.15 and directionY > -0.3 then
				liftForceY -= mass*game.Workspace.Gravity/4
			end

			-- Lift force direction is up with respect of the orientation of the plane
			liftForce = Vector3.new(0,liftForceY,0)
		end
		--print("lift:",prettyVal(projectedVector.X), prettyVal(projectedVector.Y), prettyVal(math.deg(angle)), prettyVal(liftForce.Y))
		
		-- Thrust force
		local thrustForceX = 0
		if ground and directionX<0 and (animationOrientationLeftTrack.IsPlaying or animationTurnLeftTrack.IsPlaying) then
			thrustForceX = engineRun(mass)
		elseif ground and directionX>0 and (animationOrientationRightTrack.IsPlaying or animationTurnRightTrack.IsPlaying) then
			thrustForceX = engineRun(mass)
		elseif not ground and math.abs(directionX) > 0.5 then
			thrustForceX = engineRun(mass)
		elseif engineSound.IsPlaying then
			engineSound:Stop()
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

		-- To the left: Hspeed>0, Xforce>0
		-- Up: Vspeed>0, Yforce>0
		-- print("dir:",prettyVal(directionX),prettyVal(directionY)," o:",prettyVal(orientationX)," spd(H,V,T):",prettyVal(speedVector.X),prettyVal(speedVector.Y),prettyVal(speedVector.Magnitude)," f:",prettyVal(vfX),prettyVal(vfY)," ar:",prettyVal(airResistance.X),prettyVal(airResistance.Y))		
		
		-- Use animation with jump to timeposition (see https://developer.roblox.com/en-us/api-reference/function/AnimationTrack/Play)
		-- Animation mus have the "loop" flag.
		-- And the name of the keyframes must be the angle of the orientation 
		-- Negatives are down
		-- Positives are up
		-- Zero is horizontal
		-- Example: "-45", "0", "+45"
		if not ground and checkUp(directionY) and animationOrientationLeftTrack.IsPlaying and animationOrientationLeftTrack.Speed == 0 then
			local currentAngle = tonumber(currentOrientationKeyFrame)
			targetOrientationKeyFrame=getTargetOrientationKeyFrame(currentAngle+22.5)
			animationOrientationLeftTrack:AdjustSpeed(0.5)
			--print("^", currentOrientationKeyFrame, targetOrientationKeyFrame)
		end

		if not ground and checkDown(directionY) and animationOrientationLeftTrack.IsPlaying and animationOrientationLeftTrack.Speed == 0 then
			local currentAngle = tonumber(currentOrientationKeyFrame)
			targetOrientationKeyFrame=getTargetOrientationKeyFrame(currentAngle-22.5)
			animationOrientationLeftTrack:AdjustSpeed(-0.5)
			--print("v", currentOrientationKeyFrame, targetOrientationKeyFrame)
		end

		if not ground and checkUp(directionY) and animationOrientationRightTrack.IsPlaying and animationOrientationRightTrack.Speed == 0 then
			local currentAngle = tonumber(currentOrientationKeyFrame)
			targetOrientationKeyFrame=getTargetOrientationKeyFrame(currentAngle+22.5)
			animationOrientationRightTrack:AdjustSpeed(0.5)
			--print("^", currentOrientationKeyFrame, targetOrientationKeyFrame)
		end

		if not ground and checkDown(directionY) and animationOrientationRightTrack.IsPlaying and animationOrientationRightTrack.Speed == 0 then
			local currentAngle = tonumber(currentOrientationKeyFrame)
			targetOrientationKeyFrame=getTargetOrientationKeyFrame(currentAngle-22.5)
			animationOrientationRightTrack:AdjustSpeed(-0.5)
			--print("v", currentOrientationKeyFrame, targetOrientationKeyFrame)
		end

		if not ground and directionX>0.5 and animationOrientationLeftTrack.IsPlaying and not turningRight then
			turningRight=true
			local currentAngle = tonumber(currentOrientationKeyFrame)
			if currentAngle < 0 then
				targetOrientationKeyFrame = "-180"
				animationOrientationLeftTrack:AdjustSpeed(-0.5)
			else
				targetOrientationKeyFrame = "+180"
				animationOrientationLeftTrack:AdjustSpeed(0.5)
			end
		end

		if not ground and directionX<-0.5 and animationOrientationRightTrack.IsPlaying and not turningLeft then
			turningLeft=true
			local currentAngle = tonumber(currentOrientationKeyFrame)
			if currentAngle < 0 then
				targetOrientationKeyFrame = "-180"
				animationOrientationRightTrack:AdjustSpeed(-0.5)
			else
				targetOrientationKeyFrame = "+180"
				animationOrientationRightTrack:AdjustSpeed(0.5)
			end
		end

		if ground and not grounding and liftForce.Y < mass*game.Workspace.Gravity/2 and currentOrientationKeyFrame ~= "+22.5" and animationOrientationLeftTrack.IsPlaying then
			grounding = true
			local currentAngle = tonumber(currentOrientationKeyFrame)
			if currentAngle <= 0 then
				animationOrientationLeftTrack:AdjustSpeed(0.5)
			else
				animationOrientationLeftTrack:AdjustSpeed(-0.5)
			end
			targetOrientationKeyFrame = "+22.5"
		end

		if ground and not grounding and liftForce.Y < mass*game.Workspace.Gravity/2 and currentOrientationKeyFrame ~= "+22.5" and animationOrientationRightTrack.IsPlaying then
			grounding = true
			local currentAngle = tonumber(currentOrientationKeyFrame)
			if currentAngle <= 0 then
				animationOrientationRightTrack:AdjustSpeed(0.5)
			else
				animationOrientationRightTrack:AdjustSpeed(-0.5)
			end
			targetOrientationKeyFrame = "+22.5"
		end

		if ground and not takingOff and liftForce.Y >= mass*game.Workspace.Gravity/2 and currentOrientationKeyFrame ~= "0" and animationOrientationLeftTrack.IsPlaying then
			takingOff = true
			-- currentAngle must be +22.5
			animationOrientationLeftTrack:AdjustSpeed(-0.5)
			targetOrientationKeyFrame = "0"
		end

		if ground and not takingOff and liftForce.Y >= mass*game.Workspace.Gravity/2 and currentOrientationKeyFrame ~= "0" and animationOrientationRightTrack.IsPlaying then
			takingOff = true
			-- currentAngle must be +22.5
			animationOrientationRightTrack:AdjustSpeed(-0.5)
			targetOrientationKeyFrame = "0"
		end

		if ground and directionX>0.5 and animationOrientationLeftTrack.IsPlaying and currentOrientationKeyFrame=="+22.5" and not turningRight then
			turningRight=true
			animationOrientationLeftTrack:Stop()
		end

		if ground and directionX<-0.5 and animationOrientationRightTrack.IsPlaying and currentOrientationKeyFrame=="+22.5" and not turningLeft then
			turningLeft=true
			animationOrientationRightTrack:Stop()
		end

		checkGround(player.Character.Torso)
		

	end
end
RunService:BindToRenderStep("Control", Enum.RenderPriority.Input.Value, onUpdate)	


local function touchPlane(touchingPart, planePart)  
	-- Filter any instances of the model coming in contact with itself
	if touchingPart:IsDescendantOf(player.Character) then return end

	if  
		touchingPart.Name ~= "Bullet" 
		and
		not player.Character:FindFirstChildOfClass("ForceField")
	then	
		local resistance = 0	
		if planePart:GetAttribute("tough") then 
			resistance = 40
		elseif ground then
			if planePart:GetAttribute("fragile") then
				resistance = 0
			else
				resistance = 40
			end
		end
		
		-- Caculates the force of the impact: velocity of the player minus velocity of the touched object
		local objectVelocity = touchingPart.AssemblyLinearVelocity
		local energy = speedVector - objectVelocity
		if energy.Magnitude > resistance and player.Character.Humanoid.Health > 0 then
			--print(touchingPart.Name.." touches "..planePart.Name.."   speed:"..prettyVal(speedVector.Magnitude).."   obstacle:"..prettyVal(objectVelocity.Magnitude).."   energy:"..prettyVal(energy.Magnitude).."   resistance:"..resistance)
			explosionSound.Parent = player.Character
			explosionSound:Play() 

			wait(0.2) -- synchro sound with explosion
			
			local explosion = Instance.new("Explosion")
			explosion.Position = player.Character.Torso.Position
			explosion.Parent = workspace
			
			-- Sends an event to the server to destroy near players
			playerExplodes:FireServer(explosion.Position)
			-- The Explosion is enough to destroy the player
			player.Character.Humanoid:TakeDamage(player.Character.Humanoid.Health)
		end
	end
end

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

	local animSaves = character:WaitForChild("AnimSaves")

	--local assetFlipLeft = game:GetService("KeyframeSequenceProvider"):RegisterKeyframeSequence(animSaves.flipLeft)
	local animationFlipLeft = Instance.new("Animation",workspace)
	animationFlipLeft.Name = "AnimationFlipLeft"
	--animationFlipLeft.AnimationId = assetFlipLeft
	animationFlipLeft.AnimationId = "rbxassetid://6887394830"

	--local assetFlipRight = game:GetService("KeyframeSequenceProvider"):RegisterKeyframeSequence(animSaves.flipRight)
	local animationFlipRight = Instance.new("Animation",workspace)
	animationFlipRight.Name = "AnimationFlipRight"
	--animationFlipRight.AnimationId = assetFlipRight
	animationFlipRight.AnimationId = "rbxassetid://6887404755"

	--local assetTurnLeft = game:GetService("KeyframeSequenceProvider"):RegisterKeyframeSequence(animSaves.turnLeft)
	local animationTurnLeft = Instance.new("Animation",workspace)
	animationTurnLeft.Name = "AnimationTurnLeft"
	--animationTurnLeft.AnimationId = assetTurnLeft
	animationTurnLeft.AnimationId = "rbxassetid://6887410128"

	--local assetTurnRight = game:GetService("KeyframeSequenceProvider"):RegisterKeyframeSequence(animSaves.turnRight)
	local animationTurnRight = Instance.new("Animation",workspace)
	animationTurnRight.Name = "AnimationTurnRight"
	--animationTurnRight.AnimationId = assetTurnRight
	animationTurnRight.AnimationId = "rbxassetid://6887415225"

	--local assetOrientationLeft = game:GetService("KeyframeSequenceProvider"):RegisterKeyframeSequence(animSaves.orientationLeft)
	local animationOrientationLeft = Instance.new("Animation",workspace)
	animationOrientationLeft.Name = "AnimationOrientationLeft"
	--animationOrientationLeft.AnimationId = assetOrientationLeft
	animationOrientationLeft.AnimationId = "rbxassetid://6887418719"

	--local assetOrientationRight = game:GetService("KeyframeSequenceProvider"):RegisterKeyframeSequence(animSaves.orientationRight)
	local animationOrientationRight = Instance.new("Animation",workspace)
	animationOrientationRight.Name = "AnimationOrientationRight"
	--animationOrientationRight.AnimationId = assetOrientationRight
	animationOrientationRight.AnimationId = "rbxassetid://6887422186"

	local animator = humanoid:WaitForChild("Animator")
	-- Load animations onto the animator
	animationOrientationLeftTrack = animator:LoadAnimation(workspace.AnimationOrientationLeft)
	animationOrientationRightTrack = animator:LoadAnimation(workspace.AnimationOrientationRight)
	animationFlipLeftTrack = animator:LoadAnimation(workspace.AnimationFlipLeft)
	animationFlipRightTrack = animator:LoadAnimation(workspace.AnimationFlipRight)
	animationTurnLeftTrack = animator:LoadAnimation(workspace.AnimationTurnLeft)
	animationTurnRightTrack = animator:LoadAnimation(workspace.AnimationTurnRight)
	
	animationOrientationLeftTrack.KeyframeReached:Connect(orientationLeftReached)
	animationOrientationRightTrack.KeyframeReached:Connect(orientationRightReached)

	animationOrientationLeftTrack.Stopped:Connect(orientationLeftStopped)
	animationOrientationRightTrack.Stopped:Connect(orientationRightStopped)

	animationFlipRightTrack.Stopped:Connect(flipRightStopped)
	animationFlipLeftTrack.Stopped:Connect(flipLeftStopped)

	animationTurnRightTrack.Stopped:Connect(turnRightStopped)
	animationTurnLeftTrack.Stopped:Connect(turnLeftStopped)

	while animationOrientationLeftTrack.Length == 0 do
		wait()
	end
	freezeAnimationAtKeyframe(animationOrientationLeftTrack, "+22.5")


	-- Destroy player when a humanoid's part (head, torso, ...) is not protected by a ForceField
	-- and is touched by something that is not: 
	--  another part of the player
	--  a bullet (damages taken by bullets are managed by BulletHandler)
	for _, child in pairs(character:GetChildren()) do
		if child:IsA("BasePart") and not child:GetAttribute("scaffold") then
			--print("connect:",child.Name)
			child.Touched:Connect(function(touchingPart) 
				touchPlane(touchingPart, child)
			end)
		end
	end

		
	-- Starts engine
	engineSound.Parent = character.Torso
	--engineSound:Play()
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

