local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- RemoteEvent for when the client explodes.
local playerExplodes = Instance.new("RemoteEvent")
playerExplodes.Name = "PlayerExplodes"
playerExplodes.Parent = ReplicatedStorage