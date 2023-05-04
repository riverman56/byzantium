local UserInputService = game:GetService("UserInputService")

local MAX_RETRIES = 30

local function castFromMouse(raycastParams: RaycastParams, length: number, retry: boolean)
	-- the retry logic adds the intervening part to the raycast blacklist,
	-- and it cannot work with the whitelist filter type because sometimes
	-- the intervening instance is a descendant of a whitelisted object and not
	-- in the direct array. :/
	if raycastParams.FilterType ~= Enum.RaycastFilterType.Exclude and retry == true then
		error("cannot use retry logic while FilterType is not blacklist")
	end
	
	local tries = 0

	local function cast(raycastParams: RaycastParams, length: number, retry: boolean)
		tries += 1

		local mouseLocation = UserInputService:GetMouseLocation()
		
		-- get the 3d direction of the mouse pointer
		local ray = workspace.CurrentCamera:ViewportPointToRay(mouseLocation.X, mouseLocation.Y, 0.5)
		
		-- make an official lengthed raycast using the direction we retrieved
		local raycastResult = workspace:Raycast(workspace.CurrentCamera.CFrame.Position, ray.Direction * length, raycastParams)
		
		-- RaycastResult will be nil when the cast didn't hit anything, safeguard
		if raycastResult ~= nil then
			-- if the hit part is invisible, we want to retry if the user specifies.
			-- if not, just return the result
			
			-- TODO: add surface angle detection.
			
			if raycastResult.Instance ~= nil and raycastResult.Instance.Transparency == 1 then
				if retry == true then
					if tries == MAX_RETRIES then
						-- if we've hit the maximum number of retries allowed, return the
						-- cast result and don't retry
						return raycastResult, ray
					else
						-- if retries allowed, add the intervening part to the blacklist & continue
						local newFilter = table.clone(raycastParams.FilterDescendantsInstances)
						table.insert(newFilter, raycastResult.Instance)
						raycastParams.FilterDescendantsInstances = newFilter
						return cast(raycastParams, length, retry), ray
					end
				else
					return raycastResult, ray
				end
			else
				return raycastResult, ray
			end
		else
			return raycastResult, ray
		end
	end

	return cast(raycastParams, length, retry)
end

return castFromMouse