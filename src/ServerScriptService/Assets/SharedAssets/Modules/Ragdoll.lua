local RAGDOLL_OFFSETS = {
    ["Left Arm"] = Vector3.new(0, 0.5, 0),
    ["Right Arm"] = Vector3.new(0, 0.5, 0),
}
local BALL_SOCKET_CONSTRAINT_LIMITS = {
    Head = {
        UpperAngle = 30,
        TwistLowerAngle = -40,
        TwistUpperAngle = 40,
        MaxFrictionTorque = 5.5,
    },
    Shoulder = {
        UpperAngle = 45,
        TwistLowerAngle = -45,
        TwistUpperAngle = 45,
        MaxFrictionTorque = 5.5,
    },
    Hip = {
        UpperAngle = 30,
        TwistLowerAngle = -45,
        TwistUpperAngle = 60,
        MaxFrictionTorque = 0,
    },
}

local Ragdoll = {}

function Ragdoll:setup(character: Model)
    local ballSocketConstraints = {}

    for _, joint in character:GetDescendants() do
        if joint:isA("Motor6D") then
            if joint.Part1.Name == "Head" then
                continue
            end

            local ballSocketConstraint = Instance.new("BallSocketConstraint")
            ballSocketConstraint.Enabled = false
            ballSocketConstraint.LimitsEnabled = true
            ballSocketConstraint.TwistLimitsEnabled = true

            local attachment0 = Instance.new("Attachment")
            attachment0.CFrame = joint.C0
            attachment0.Parent = joint.Part0
            local attachment1 = Instance.new("Attachment")
            attachment1.CFrame = joint.C1 + if RAGDOLL_OFFSETS[joint.Part1.Name] then RAGDOLL_OFFSETS[joint.Part1.Name] else Vector3.zero
            attachment1.Parent = joint.Part1

            ballSocketConstraint.Attachment0 = attachment0
            ballSocketConstraint.Attachment1 = attachment1

            for jointName, values in BALL_SOCKET_CONSTRAINT_LIMITS do
                if string.find(joint.Name, jointName) then
                    for property, value in values do
                        ballSocketConstraint[property] = value
                    end
                end
            end

            --joint.Part1.CustomPhysicalProperties = PhysicalProperties.new(100, 0, 0)

            ballSocketConstraint.Parent = joint.Parent

            table.insert(ballSocketConstraints, ballSocketConstraint)
        end
    end

    

    return ballSocketConstraints
end

function Ragdoll:setRagdoll(character: Model, isRagdolled: boolean)
    for _, ballSocketConstraint in character:GetDescendants() do
        if ballSocketConstraint:IsA("BallSocketConstraint") then
            ballSocketConstraint.Enabled = isRagdolled
        end
    end

    for _, motor in character:GetDescendants() do
        if motor:IsA("Motor6D") then
            motor.Enabled = not isRagdolled
        end
    end
end

return Ragdoll