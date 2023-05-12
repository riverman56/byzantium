--[[

	kesect, 2023
	Holds the functions which handles viewports, portals, and tieing them together.

]]--

local Y_SPIN = CFrame.Angles(0, math.pi, 0)

local PortalClass = require(script:WaitForChild("Portal"))

local function planeIntersect(point, vector, origin, normal) -- unused function? - luca
	local rpoint = point - origin;
	local t = -rpoint:Dot(normal)/vector:Dot(normal);
	return point + t * vector, t;
end

local function rayPlane(p, v, o, n)
	local r = p - o
	local t = -r:Dot(n) / v:Dot(n)
	return p + t*v, t
end

local DualWorlds = {}
DualWorlds.__index = DualWorlds

function DualWorlds.new(character, partA, partB, surface, parent)
	local self = setmetatable({}, DualWorlds)
	
	self.Character = character
	self.HRP = character:WaitForChild("HumanoidRootPart")
	self.Humanoid = character:WaitForChild("Humanoid")
	
	self.PortalA = PortalClass.fromPart(partA, surface, parent)
	self.PortalB = PortalClass.fromPart(partB, surface, parent)
	
	self.LastCamCF = workspace.CurrentCamera.CFrame

	game:GetService("RunService"):BindToRenderStep("BeforeInput", Enum.RenderPriority.Input.Value - 1, function(dt)
		workspace.CurrentCamera.CFrame = self.LastCamCF
	end)
	
	game:GetService("RunService"):BindToRenderStep("AfterCamera", Enum.RenderPriority.Camera.Value + 1, function(dt)
		self:OnRenderStep(dt)
	end)

	return self
end

function DualWorlds:CheckCameraIntersect(surface, size)
	local camCF = workspace.CurrentCamera.CFrame
	local focusCF = workspace.CurrentCamera.Focus
	
	local v = camCF.p - focusCF.p
	local p, t = rayPlane(focusCF.p, camCF.p - focusCF.p, surface.p, surface.LookVector)
	if (v:Dot(surface.LookVector) < 0 and t >= 0 and t <= 1) then
		local lp = surface:PointToObjectSpace(p)
		if (math.abs(lp.x) <= size.x/2 and math.abs(lp.y) <= size.y/2) then
			return true
		end
	end
	
	return false
end

function DualWorlds:CameraIntersectOffset(surfaceA, surfaceB)
	local camCF = workspace.CurrentCamera.CFrame
	local focusCF = workspace.CurrentCamera.Focus
	
	local offset = surfaceA:Inverse() * camCF
	local newCam = surfaceB * Y_SPIN * offset
	
	local offset = surfaceA:Inverse() * focusCF
	local newFocus = surfaceB * Y_SPIN * offset
	
	workspace.CurrentCamera.CFrame = newCam
	workspace.CurrentCamera.Focus = newFocus
end

function DualWorlds:InfrontOf(pos, surface, size)
	local lp = (surface - surface.p + pos):PointToObjectSpace(self.HRP.Position)
	if (lp.z <= 0 and math.abs(lp.x) <= size.x/2 and math.abs(lp.y) <= size.y/2) then
		return true
	end
	return false
end

function DualWorlds:CheckCollision(surface, size, dt)
	local p, t = rayPlane(self.HRP.Position, self.HRP.Velocity*dt, surface.p, surface.LookVector)
	local lp = surface:PointToObjectSpace(p)
	if (t >= 0 and t <= 1 and math.abs(lp.x) <= size.x/2 and math.abs(lp.y) <= size.y/2) then
		return true
	end
	return false
end

function DualWorlds:MoveToPortal(surfaceA, surfaceB)
	local hrpCF = self.HRP.CFrame
	local camCF = workspace.CurrentCamera.CFrame
	local velocity = self.HRP.Velocity
	local moveDir = self.Humanoid.MoveDirection
	
	local hrpOffset = surfaceA:Inverse() * hrpCF
	local c = {hrpOffset:GetComponents()}
	local alteredOffset = CFrame.new(-c[1], select(2, unpack(c)))
	local newHrp = surfaceB * alteredOffset * Y_SPIN
	
	local lVel = hrpCF:VectorToObjectSpace(velocity)
	local newVel = newHrp:VectorToWorldSpace(lVel)
	
	local lMove = hrpCF:VectorToObjectSpace(moveDir)
	local newMove = newHrp:VectorToWorldSpace(lMove)
	
	local camOffset = surfaceA:Inverse() * camCF
	local newCam = surfaceB * Y_SPIN * camOffset
	
	self.HRP.CFrame = newHrp
	self.HRP.Velocity = newVel
	self.Humanoid:Move(newMove, false)
	return newCam
end

function DualWorlds:OnRenderStep(dt)
	local portalA, portalB = self.PortalA, self.PortalB
	local surfaceA, sizeA = portalA:GetSurfaceInfo()
	local surfaceB, sizeB = portalB:GetSurfaceInfo()
	
	-- collision check
	
	self.LastCamCF = workspace.CurrentCamera.CFrame
	
	if (self:CheckCollision(surfaceA, sizeA, dt)) then
		self.LastCamCF = self:MoveToPortal(surfaceA, surfaceB)
	elseif (self:CheckCollision(surfaceB, sizeB, dt)) then
		self.LastCamCF = self:MoveToPortal(surfaceB, surfaceA)
	end
	
	-- camera adjustment
	
	if (self:CheckCameraIntersect(surfaceA, sizeA)) then
		self:CameraIntersectOffset(surfaceA, surfaceB)
	elseif (self:CheckCameraIntersect(surfaceB, sizeB)) then
		self:CameraIntersectOffset(surfaceB, surfaceA)
	end
	
	-- render portal
	
	local camCF = workspace.CurrentCamera.CFrame
	
	local offset = surfaceA:Inverse() * camCF
	local newCamCF = surfaceB * Y_SPIN * offset
	portalA:RenderFrame(newCamCF, surfaceB * Y_SPIN, sizeB)
	
	local offset = surfaceB:Inverse() * camCF
	local newCamCF = surfaceA * Y_SPIN * offset
	portalB:RenderFrame(newCamCF, surfaceA * Y_SPIN, sizeA)
end

return DualWorlds