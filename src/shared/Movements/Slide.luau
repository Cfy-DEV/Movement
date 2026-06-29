local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local trove = require(ReplicatedStorage.Packages.trove)
local localPlayer = Players.LocalPlayer
local CurrentCamera = workspace.CurrentCamera

local started = tick()

local module = {
	SlideSpeed = 25,
	TurningSpeed = 25,
	Gravity = 0.75,
}

local newTrove = trove.new()

--[[
Vector3.ProjectOnPlane(targetPoint, planeNormal) + 
						 (Vector3.Dot(planeOrigin, planeNormal) * planeNormal);
						 ]]

local function projectVectorOnPlane(vector: Vector3, planeNormal: Vector3): Vector3
	local normal = planeNormal.Unit
	local projectionOnNormal = normal * vector:Dot(normal)

	return vector - projectionOnNormal
end

local function projectPointOnPlane(p: Vector3, plane_origin: Vector3, plane_normal: Vector3)
	local to_point = p - plane_origin
	local scalar = to_point:Dot(plane_normal)
	local projected = p - (scalar * plane_normal)

	return projected
end

local function getReflection(incidentVector: Vector3, surfaceNormal: Vector3): Vector3
	local unitNormal = surfaceNormal.Unit

	return incidentVector - 2 * (incidentVector:Dot(unitNormal)) * unitNormal
end

function module.Init()
	if not RunService:IsClient() then
		return
	end
	local char = localPlayer.Character
	if not char then
		return
	end
	local hrs: BasePart = char:FindFirstChild("HumanoidRootPart")
	if not hrs then
		return
	end

	hrs.Anchored = true

	local lastDir = Vector3.new(hrs.CFrame.LookVector.X, 0, hrs.CFrame.LookVector.Z)
	local rayLenght = 2.5
	local lastTimeOnGround = tick() - started

	local param = RaycastParams.new()
	param.FilterType = Enum.RaycastFilterType.Exclude
	param.FilterDescendantsInstances = { char }

	newTrove:Add(RunService.RenderStepped:Connect(function(deltaTime: number)
		local diff = tick() - started
		local rayOrigin = hrs.Position
		local rayDir = -hrs.CFrame.UpVector * (rayLenght * 1.05)
		local nextPos
		local rayCast = workspace:Raycast(rayOrigin, rayDir, param)

		local nextDir

		if rayCast then
			lastTimeOnGround = diff
			local dir1 = Vector3.new(lastDir.X, 0, lastDir.Z)

			local dir2 = CFrame.lookAt(
				CurrentCamera.CFrame.Position,
				Vector3.new(
					CurrentCamera.CFrame.Position.X + CurrentCamera.CFrame.LookVector.X,
					CurrentCamera.CFrame.Position.Y,
					CurrentCamera.CFrame.Position.Z + CurrentCamera.CFrame.LookVector.Z
				)
			).LookVector -- Neutral camera rotation

			local dir3 = (dir1:Lerp(dir2, module.TurningSpeed * deltaTime)).Unit -- slight and FINAL rotation.
			local posOnPlane = projectPointOnPlane(rayOrigin, rayCast.Position, rayCast.Normal)

			nextPos = posOnPlane + rayCast.Normal * rayLenght
			nextDir = projectVectorOnPlane(dir3, rayCast.Normal)

			if nextDir.Magnitude > 1e-4 then
				nextDir = nextDir.Unit
			else
				nextDir = lastDir
			end
		else
			nextPos = rayOrigin
			nextDir = lastDir:Lerp(Vector3.new(lastDir.X, -1, lastDir.Z), module.Gravity * deltaTime)
		end

		local distance = module.SlideSpeed * deltaTime
		local rayCast2 = workspace:Raycast(nextPos, nextDir * distance, param) -- Checking for any "bumps"

		if rayCast2 then
			local reflection = getReflection(nextDir, rayCast2.Normal.Unit)
			hrs.CFrame = CFrame.new(rayCast2.Position, rayCast2.Position + reflection)
				* CFrame.new(0, 0, -(distance - rayCast2.Distance))
			lastDir = reflection.Unit
		else
			hrs.CFrame = CFrame.new(nextPos, nextPos + (nextDir * distance)) * CFrame.new(0, 0, -distance)
			lastDir = nextDir.Unit
		end
	end))
end

module.End = function() end

return module
