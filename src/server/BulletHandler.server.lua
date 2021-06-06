-- This script handles blaster projectiles on the server-side of the game
 
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
 
-- Variables for RemoteEvents and Functions (see the BlasterHandler Script)
local launchProjectile = ReplicatedStorage:WaitForChild("LaunchProjectile")
local destroyProjectile = ReplicatedStorage:WaitForChild("DestroyProjectile")
local pingChecker = ReplicatedStorage:WaitForChild("Ping")
 
-- Variable to store the basic projectile object
local projectileTemplate = ReplicatedStorage.Bullet
-- Table to keep track of the ping of all connected clients
local currentPing = {}

-- This function is called when the client launches a projectile
launchProjectile.OnServerInvoke = function(player, cFrame, impulse)
	-- Consume a metal
	player.leaderstats.Metal.Value = player.leaderstats.Metal.Value -1
	
	-- Make a new projectile
	local projectile = projectileTemplate:Clone()
	
	-- Calculate where the projectile should be based on the latency
	-- of the player who launched it
	local ping = 0
	if currentPing[player] then
		ping = currentPing[player]
	end
	local offset = ping * impulse * 1.5
	projectile.CFrame = cFrame + offset
	
	-- Zero out gravity on the projectile so it doesn't fall through the ground
	local mass = projectile:GetMass()
	projectile.VectorForce.Force = Vector3.new(0, 1, 0) * mass * game.Workspace.Gravity
	
		
	-- Put the projectile in the workspace and make sure the server is the owner
	projectile.Parent = game.Workspace
	projectile:SetNetworkOwner(nil)

	-- Apply impulse (the projectile must be in the workspace)
	projectile:ApplyImpulse(impulse)
	
	Debris:AddItem(projectile, 1)
	
	-- Set up touched event for the projectile
	projectile.Touched:Connect(function(hit)
		-- if hit.Parent:FindFirstChild("Humanoid") and hit.Parent.Name ~= player.Name then
		-- print(hit.Name," ",hit.Parent.Name)
		if hit.Parent.Name ~= player.Name then
			projectile:Destroy()
			if hit.Parent:FindFirstChild("Humanoid") then 
				hit.Parent.Humanoid:TakeDamage(10)
				--print("Damage:",player.Name, " ", hit.Name, " ", hit.Parent.Name);
			end
		else
			--print("No damage:",player.Name, " ", hit.Name, " ", hit.Parent.Name);
		end
	end)

	
	-- Send the projectile back to the player who launched it
	return projectile
end
 
-- Called when the client detects a projectile should be destroyed
local function onDestroyProjectile(player, projectile)
	projectile:Destroy()
end
  
-- Called when a player joins the game. This function sets up a loop that
-- measures the ping of the player
local function onPlayerAdded(player)	
	while player and wait(2) do
		local start = tick()
		pingChecker:InvokeClient(player)
		local ping = tick() - start
		currentPing[player] = ping
	end
end
 
-- Called when a player leaves the game. Removes their entry from the
-- ping table
local function onPlayerRemoving(player)
	currentPing[player] = nil
end
 
-- Set up event bindings
destroyProjectile.OnServerEvent:Connect(onDestroyProjectile)
Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
