local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- RemoteEvent for when the client change the direction of the local player.
local changePlayerDirection = Instance.new("RemoteEvent")
changePlayerDirection.Name = "ChangePlayerDirection"
changePlayerDirection.Parent = ReplicatedStorage

-- RemoteEvent for when the client explodes.
local playerExplodes = Instance.new("RemoteEvent")
playerExplodes.Name = "PlayerExplodes"
playerExplodes.Parent = ReplicatedStorage