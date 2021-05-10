--This script handles plane behavior on the server-side of the game
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- RemoteEvent for when the client change the direction of the local player.
local changePlayerDirection = ReplicatedStorage:WaitForChild("ChangePlayerDirection")

-- RemoteEvent for when a player explodes.
local playerExplodes = ReplicatedStorage:WaitForChild("PlayerExplodes")

-- When a player change of direction
local function onChangePlayerDirection(player, direction)
	if direction > 0 then
		player.Character.HumanoidRootPart.RootMotor.Transform = CFrame.Angles(0, 0, math.pi)
	end
	if direction < 0 then
		player.Character.HumanoidRootPart.RootMotor.Transform = CFrame.Angles(0, 0, 0)
	end	
	
	-- Replicate event to the others players.
	local players = game.Players:GetPlayers( )
    for i = 1, #players do
        if players[i] ~= player then 
			changePlayerDirection:FireClient(players[i], player, direction) 
		end
    end
end

-- When a player explodes
local function onPlayerExplodes(player, position)
	local explosion = Instance.new("Explosion")
	explosion.Position = position
	explosion.Parent = workspace
end

-- Set up event bindings
changePlayerDirection.OnServerEvent:Connect(onChangePlayerDirection)
playerExplodes.OnServerEvent:Connect(onPlayerExplodes)

-- Called when the character is added
local function onCharacterAdded(character)	
	local rootPart = character:WaitForChild("HumanoidRootPart")

	-- Wait until rootPart is part of the workspace		
	while not rootPart:IsDescendantOf(workspace) do
		wait()
	end
	-- Gives control of the ship to the player
	rootPart:SetNetworkOwner(game.Players:GetPlayerFromCharacter(character))

	local anchorPart = character:WaitForChild("Anchor")
	
	--wait(1) -- waits for player touching the ground
	
	local cc = Instance.new("CylindricalConstraint", anchorPart)
	cc.Attachment0 = workspace.Center.Attachment
	cc.Attachment1 = anchorPart.Attachment
	cc.AngularActuatorType=1 -- Motor
	cc.AngularVelocity=0 -- horizontal speed
	cc.MotorMaxAngularAcceleration=1000
	cc.MotorMaxTorque=100000
	cc.ActuatorType=1 -- Motor
	cc.Velocity=0 -- vertical speed
	cc.MotorMaxAcceleration=1000
	cc.MotorMaxForce=100000
	cc.LimitsEnabled=true
	cc.LowerLimit=0 -- min altitude
	cc.UpperLimit=40 -- max altitude
	cc.AngularVelocity = 0	
	cc.InclinationAngle = 0
	
end
 
-- Called when a player is added to the game
local function onPlayerAdded(player)
	player.CharacterAdded:Connect(onCharacterAdded)	
	
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player
	
	local metal = Instance.new("IntValue")
	metal.Name = "Metal"
	metal.Value = 100
	metal.Parent = leaderstats
end

-- Case when the players are already there (we are too slow and we missed the "playerAdded" event)
local players = game.Players:GetPlayers( )
for i = 1, #players do
	onPlayerAdded(players[i]) 
end
 
-- Connect onPlayerAdded() to the PlayerAdded event.
game.Players.PlayerAdded:Connect(onPlayerAdded)

