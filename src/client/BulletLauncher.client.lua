-- This script handles blaster events on the client-side of the game

-- How fast the projectile moves
local PROJECTILE_SPEED = 80
-- How often a projectile can be made on mouse clicks (in seconds)
local LAUNCH_COOLDOWN = 0.1
 
-- Variables for Roblox services
local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
 
-- Variables for RemoteEvents and Functions (see the BulletHandler Script)
local launchProjectile = ReplicatedStorage:WaitForChild("LaunchProjectile")
local destroyProjectile = ReplicatedStorage:WaitForChild("DestroyProjectile")
local ping = ReplicatedStorage:WaitForChild("Ping")
 
-- Variable to store the basic projectile object
local projectileTemplate = ReplicatedStorage:WaitForChild("Bullet")
-- Variable for the player object
local player = Players.LocalPlayer
 
local canLaunch = true

local bulletSound = Instance.new("Sound")
bulletSound.SoundId = "http://www.roblox.com/asset/?id=1489924400"
bulletSound.Volume = 2.5
bulletSound.Looped = false
bulletSound.Parent = game.Workspace
 
local function onLaunch(actionName, inputState, inputObj)
	-- Only launch if the player's character exists and the blaster isn't on cooldown
	if inputState == Enum.UserInputState.Begin and canLaunch and player.Character and player.Character:FindFirstChild("Head") then
		-- Prevents the player from launching again until the cooldown is done
		canLaunch = false
		spawn(function()
			wait(LAUNCH_COOLDOWN)
			canLaunch = true
		end)
		
		-- Player direction: 
		-- -to the right = -1
		-- -to the left = +1
		local playerDirection = player.Character.HumanoidRootPart.RootMotor.Transform.RightVector.X
		
		-- Create a new projectile
		local projectile = projectileTemplate:Clone()
		local playerCFrame = player.Character.Head.CFrame -- Bullets are shooted by the cockpit (head).
		local direction = playerCFrame.RightVector -- Forward vector
		local random = math.random()/5 -- Randomise a little the direction of the bullets.
		direction = direction - playerDirection * playerCFrame.LookVector*random -- Bullets are slighlty aimed at the inside of the world.
		projectile.CFrame = playerCFrame * CFrame.Angles (0,playerDirection * math.pi/4*random,0) -- Rotate the bullet in accordance to its direction.
		projectile.Velocity = direction * PROJECTILE_SPEED
		
		-- Zero out gravity on the projectile so it doesn't fall through the ground
		local mass = projectile:GetMass()
		projectile.VectorForce.Force = Vector3.new(0, 1, 0) * mass * game.Workspace.Gravity
		
		-- Put the projectile in the workspace
		projectile.Parent = game.Workspace
		
		bulletSound:Play()
		
		-- Tell the server to create a new projectile and send it back to us
		local serverProjectile = launchProjectile:InvokeServer(projectile.CFrame, projectile.Velocity)
		-- Hide the server copy of the projectile
		serverProjectile.LocalTransparencyModifier = 1
		
		-- Set up touched event for the projectile
		projectile.Touched:Connect(function(hit)
			-- if hit.Parent:FindFirstChild("Humanoid") and hit.Parent.Name ~= player.Name then
			if hit.Name ~= 'Bullet' and hit.Parent.Name ~= player.Name then
				projectile:Destroy()
			end
		end)
		
		-- Life time of the projectile
		Debris:AddItem(projectile, 1)
	end
end
 
-- Connect a function to the ping RemoteFunction. This can be empty because all
-- the server needs to hear is a response
ping.OnClientInvoke = function() end

local function onFireGamepad()
	print("Fire Gamepad")
	onLaunch()
end

local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui") -- Wait PlayerGui to create touch button
ContextActionService:BindAction("Fire", onLaunch, true, Enum.KeyCode.Space)
ContextActionService:BindAction("FireGamepad", onFireGamepad, false, Enum.KeyCode.ButtonR2)
local fireButton = ContextActionService:GetButton("Fire")
if fireButton then -- we have a touch button
	local contextActionGui = playerGui:FindFirstChild("ContextActionGui")
	contextActionGui.ResetOnSpawn=false -- avoid destroy of the touch button when player resets.
end