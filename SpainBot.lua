--By BriefBassoon117 | Discord
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local CONFIG = {
    ENABLE_SPIN = true,
    SPIN_SPEED = 60,

    PITCH_MODE = "DOWN",

    ENABLE_JITTER = true,
    JITTER_INTENSITY = 2,
}

local spinAngle = 0
local jitterPitch = 0
local jitterYaw = 0

RunService.Heartbeat:Connect(function(dt)
    if CONFIG.ENABLE_SPIN then
        spinAngle = (spinAngle + CONFIG.SPIN_SPEED * dt) % (math.pi * 2)
    end

    if CONFIG.ENABLE_JITTER then
        jitterPitch = (math.random() - 0.5) * CONFIG.JITTER_INTENSITY
        jitterYaw = (math.random() - 0.5) * CONFIG.JITTER_INTENSITY
    else
        jitterPitch = 0
        jitterYaw = 0
    end
end)

local function GetPitch(value)
    local base

    if CONFIG.PITCH_MODE == "DOWN" then
        base = -1.4
    elseif CONFIG.PITCH_MODE == "UP" then
        base = 1.4
    else
        base = value
    end

    return base + jitterPitch
end

local function GetYaw(value)
    if CONFIG.ENABLE_SPIN then
        return spinAngle + jitterYaw
    end

    return value + jitterYaw
end

local OldNewIndex

OldNewIndex = hookmetamethod(game, "__newindex", function(self, key, value)
    if key == "CFrame"
        and typeof(value) == "CFrame"
        and self:IsA("BasePart")
        and LocalPlayer.Character
        and self == LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    then
        local pos = value.Position
        local _, y, _ = value:ToOrientation()

        local cf = CFrame.new(pos) * CFrame.Angles(0, GetYaw(y), 0)

        return OldNewIndex(self, key, cf)
    end

    return OldNewIndex(self, key, value)
end)

local OldNamecall

OldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    local args = { ... }

    if method == "FireServer" then
        local ok, name = pcall(function()
            return self.Name
        end)

        if ok then
            if name == "MercAimReplicate"
                and typeof(args[1]) == "number"
            then
                args[1] = GetPitch(args[1])
                return OldNamecall(self, unpack(args))
            end

            if name == "MercLeanReplicate"
                and typeof(args[1]) == "number"
            then
                args[1] = GetYaw(args[1])
                return OldNamecall(self, unpack(args))
            end
        end
    end

    return OldNamecall(self, ...)
end)
