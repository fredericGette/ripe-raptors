local ReplicatedStorage = game:GetService("ReplicatedStorage")
 
-- RemoteFunction for when a projectile is launched
local launchProjectile = Instance.new("RemoteFunction")
launchProjectile.Name = "LaunchProjectile"
launchProjectile.Parent = ReplicatedStorage
 
-- RemoteFunction to measure the ping for all clients
local pingChecker = Instance.new("RemoteFunction")
pingChecker.Name = "Ping"
pingChecker.Parent = ReplicatedStorage
  
-- RemoteEvent for when the client detects a projectile should be destroyed
local destroyProjectile = Instance.new("RemoteEvent")
destroyProjectile.Name = "DestroyProjectile"
destroyProjectile.Parent = ReplicatedStorage