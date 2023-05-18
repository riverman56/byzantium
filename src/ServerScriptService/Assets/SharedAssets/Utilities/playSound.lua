local function playSound(soundId: string, parent: Instance?, volume: number?)
    local sound = Instance.new("Sound")
    sound.SoundId = soundId
    sound.Volume = volume or 5
    sound.Parent = parent or workspace

    sound:Play()
    sound.Ended:Connect(function()
        sound:Destroy()
    end)
end

return playSound