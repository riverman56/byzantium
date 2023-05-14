local function playSound(soundId: string, parent: Instance?, volume: number?)
    local sound = Instance.new("Sound")
    sound.SoundId = soundId
    sound.Parent = parent or workspace
    sound.Parent = volume or 5
end

return playSound