local UP = Vector3.new(0, 1, 0)
local FOV120 = math.rad(120)
local PI2 = math.pi/2

local VPF = Instance.new("ViewportFrame")
VPF.Size = UDim2.new(1, 0, 1, 0)
VPF.Position = UDim2.new(0.5, 0, 0.5, 0)
VPF.AnchorPoint = Vector2.new(0.5, 0.5)
VPF.BackgroundTransparency = 1

local function getCorners(part)
	local corners = {}
	local cf, size2 = part.CFrame, part.Size/2
	for x = -1, 1, 2 do
		for y = -1, 1, 2 do
			for z = -1, 1, 2 do
				table.insert(corners, cf * (size2 * Vector3.new(x, y, z)))
			end
		end
	end
	return corners
end

local Portal = {}
Portal.__index = Portal

function Portal.new(surfaceGUI)
	local self = setmetatable({}, Portal)
	
	self.SurfaceGUI = surfaceGUI
	self.SurfaceGUI.Name = "PortalViewport"
	self.Camera = Instance.new("Camera", surfaceGUI)
	self.ViewportFrame = VPF:Clone()
	self.ViewportFrame.CurrentCamera = self.Camera
	self.ViewportFrame.Parent = surfaceGUI
	
	return self
end

function Portal.fromPart(part, enum, parent)
	local surfaceGUI = Instance.new("SurfaceGui")
	surfaceGUI.Face = enum
	surfaceGUI.Adornee = part
	surfaceGUI.ClipsDescendants = true
	surfaceGUI.Parent = parent
	
	return Portal.new(surfaceGUI)
end

function Portal:AddToWorld(item)
	item.Parent = self.ViewportFrame
end

function Portal:ClipModel(model)
	local cf, size = self:GetSurfaceInfo()
	local descendants = model:GetDescendants()
	for i = 1, #descendants do
		local part = descendants[i]
		if (part:IsA("BasePart")) then
			local corners = getCorners(part)
			table.insert(corners, 1, part.Position)
			
			local pass = false
			for j = 1, #corners do
				if (cf:PointToObjectSpace(corners[j]).z <= 0) then
					pass = true
					break
				end
			end
			
			if (not pass) then
				part:Destroy()
			end
		end
	end
	return model
end

function Portal:GetPart()
	return self.SurfaceGUI.Adornee
end

function Portal:GetSurfaceInfo()
	local part = self.SurfaceGUI.Adornee
	local partCF, partSize = part.CFrame, part.Size
	
	local back = -Vector3.FromNormalId(self.SurfaceGUI.Face)
	local axis = (math.abs(back.y) == 1) and Vector3.new(back.y, 0, 0) or UP
	local right = CFrame.fromAxisAngle(axis, PI2) * back
	local top = back:Cross(right).Unit
	
	local cf = partCF * CFrame.fromMatrix(-back*partSize/2, right, top, back)
	local size = Vector3.new((partSize * right).Magnitude, (partSize * top).Magnitude, (partSize * back).Magnitude)

	return cf, size
end

function Portal:RenderFrame(camCF, surfaceCF, surfaceSize)
	local vpf = self.ViewportFrame
	local surfaceGUI = self.SurfaceGUI
	local camera = game.Workspace.CurrentCamera
	local nCamera = self.Camera
	
	local camCF = camCF or camera.CFrame
	if not (surfaceCF and surfaceSize) then 
		surfaceCF, surfaceSize = self:GetSurfaceInfo()
	end
	
	local rPoint = surfaceCF:PointToObjectSpace(camCF.p)
	local sX, sY = rPoint.x / surfaceSize.x, rPoint.y / surfaceSize.y
	
	local scale = 1 + math.max(
		surfaceSize.y / surfaceSize.x, 
		surfaceSize.x / surfaceSize.y, 
		math.max(math.abs(sX), math.abs(sY))*2
	)
	
	local height = surfaceSize.y/2
	local rDist = (camCF.p - surfaceCF.p):Dot(surfaceCF.LookVector)
	local newFov = 2*math.atan2(height, rDist)
	local clampedFov = math.clamp(math.deg(newFov), 1, 120)
	local pDist = height / math.tan(math.rad(clampedFov)/2)
	local adjust = rDist / pDist
	
	local factor = (newFov > FOV120 and adjust or 1) / scale
	local scaleCF = CFrame.new(0, 0, 0, factor, 0, 0, 0, factor, 0, 0, 0, 1)
	
	vpf.Position = UDim2.new(vpf.AnchorPoint.x - sX, 0, vpf.AnchorPoint.y - sY, 0)
	vpf.Size = UDim2.new(scale, 0, scale, 0)
	vpf.BackgroundColor3 = surfaceGUI.Adornee.Color
	
	local viewportSizeY = camera.ViewportSize.y
	surfaceGUI.CanvasSize = Vector2.new(viewportSizeY*(surfaceSize.x/surfaceSize.y), viewportSizeY)
	
	nCamera.FieldOfView = clampedFov
	nCamera.CFrame = CFrame.new(camCF.p) * (surfaceCF - surfaceCF.p) * CFrame.Angles(0, math.pi, 0) * scaleCF
end

return Portal