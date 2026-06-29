local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local trove = require(ReplicatedStorage.Packages.trove)
local localPlayer = Players.LocalPlayer
local CurrentCamera = workspace.CurrentCamera

local module = {
	SlideSpeed = 20,
	TurningSpeed = 5,
	Gravity = 10,
}

local newTrove = trove.new()

local function projectVectorOnPlane(vector: Vector3, planeNormal: Vector3): Vector3
	local normal = planeNormal.Unit
	local projectionOnNormal = normal * vector:Dot(normal)

	return vector - projectionOnNormal
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

	local lastDir = hrs.CFrame.LookVector
	local rayLenght = 2.5

	local param = RaycastParams.new()
	param.FilterType = Enum.RaycastFilterType.Exclude
	param.FilterDescendantsInstances = { char }

	newTrove:Add(RunService.RenderStepped:Connect(function(deltaTime: number)
		local rayOrigin = hrs.Position
		local rayDir = -hrs.CFrame.UpVector * rayLenght
		local rayCast = workspace:Raycast(rayOrigin, rayDir, param)

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
		local nextDir

		if rayCast then
			nextDir = projectVectorOnPlane(dir3, rayCast.Normal)
		else
			nextDir = lastDir:Lerp(Vector3.new(lastDir.X, -1, lastDir.Z))
		end

		local distance = module.SlideSpeed * deltaTime
		local rayCast2 = workspace:Raycast(hrs.Position, nextDir * distance, param) -- Checking for any "bumps"

		if rayCast2 then
			local reflection = getReflection(nextDir, rayCast2.Normal.Unit)
			hrs.CFrame = CFrame.new(rayCast2.Position, rayCast2.Position + reflection)
				* CFrame.new(0, 0, -(distance - rayCast2.Distance))
			lastDir = reflection.Unit
			return
		else
			hrs.CFrame = CFrame.new(hrs.Position, hrs.Position + (nextDir * distance)) * CFrame.new(0, 0, -distance)
			lastDir = nextDir.Unit
			return
		end
	end))
end

return module
