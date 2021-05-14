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
	
	local anchorPart = character:WaitForChild("Anchor")

	-- Move the anchor of the character at the center (axis) of the workspace
	-- But keep the position of the rootPart of the character 
	anchorPart.WeldConstraint.Enabled = false
	anchorPart.Position = Vector3.new(workspace.Center.Position.x, anchorPart.Position.y, workspace.Center.Position.z)
	anchorPart.WeldConstraint.Enabled = true
	
	-- Add a cylindrical constraint between the anchor of the character and the center of the workspace
	local cc = Instance.new("CylindricalConstraint", anchorPart)
	cc.Attachment0 = workspace.Center.Attachment
	cc.Attachment1 = anchorPart.Attachment
	cc.AngularActuatorType=0 -- None
	cc.ActuatorType=0 -- None
	cc.LimitsEnabled=true
	cc.LowerLimit=0 -- Min altitude
	cc.UpperLimit=40 -- Max altitude	
	cc.InclinationAngle = 0
	cc.Restitution = 0 -- No elastic lower/upper limit
	
	-- Gives control of the ship to the player
	rootPart:SetNetworkOwner(game.Players:GetPlayerFromCharacter(character))

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

