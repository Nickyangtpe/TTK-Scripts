-- By BriefBassoon117 | Discord
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local BulletController = require(
    ReplicatedStorage.Modules.Client.Controllers.BulletController
)

local TRACER_SETTINGS = {
    Color = Color3.fromRGB(255, 200, 50),
    Material = Enum.Material.Neon,
    Thickness = 0.1,
    Duration = 2,
    FadeDelay = 0.5,
    AbsoluteMaxLifespan = 3,
}

local ActiveTracers = {}
local LocalActiveShots = {}

local OldDischarge

OldDischarge = hookfunction(BulletController.Discharge, function(self, weaponId, origin, direction, cameraCFrame)
    local shotKey = string.format("%.2f,%.2f,%.2f", origin.X, origin.Y, origin.Z)

    LocalActiveShots[shotKey] = {
        origin = origin,
        direction = direction,
        timestamp = os.clock()
    }

    return OldDischarge(self, weaponId, origin, direction, cameraCFrame)
end)

local function CreateTracer(origin, hitPosition)
    local distance = (hitPosition - origin).Magnitude

    if distance <= 0.1 then
        return
    end

    local tracer = Instance.new("Part")
    tracer.Name = "bullet_tracer"
    tracer.Size = Vector3.new(
        TRACER_SETTINGS.Thickness,
        TRACER_SETTINGS.Thickness,
        distance
    )
    tracer.Color = TRACER_SETTINGS.Color
    tracer.Material = TRACER_SETTINGS.Material
    tracer.Anchored = true
    tracer.CanCollide = false
    tracer.CanQuery = false
    tracer.CanTouch = false
    tracer.CastShadow = false
    tracer.CFrame = CFrame.lookAt(origin, hitPosition) * CFrame.new(0, 0, -distance / 2)

    tracer.Parent = workspace:FindFirstChild("_CosmeticProjectiles") or workspace

    table.insert(ActiveTracers, {
        part = tracer,
        bornAt = os.clock(),
        distance = distance
    })

    local fadeTime = TRACER_SETTINGS.Duration - TRACER_SETTINGS.FadeDelay

    task.delay(TRACER_SETTINGS.FadeDelay, function()
        if tracer.Parent then
            TweenService:Create(
                tracer,
                TweenInfo.new(
                    fadeTime,
                    Enum.EasingStyle.Quad,
                    Enum.EasingDirection.In
                ),
                {
                    Size = Vector3.new(0, 0, distance),
                    Transparency = 1
                }
            ):Play()
        end
    end)
end

BulletController.ImpactSpawned:Connect(function(hitPosition)
    local matchedOrigin
    local matchedKey
    local shortestDistance = math.huge

    for shotKey, shotData in pairs(LocalActiveShots) do
        local toHit = hitPosition - shotData.origin
        local angle = math.acos(math.clamp(
            shotData.direction.Unit:Dot(toHit.Unit),
            -1,
            1
        ))

        if math.deg(angle) <= 45 then
            local distance = toHit.Magnitude

            if distance < shortestDistance then
                shortestDistance = distance
                matchedOrigin = shotData.origin
                matchedKey = shotKey
            end
        end
    end

    if not matchedOrigin then
        return
    end

    LocalActiveShots[matchedKey] = nil

    CreateTracer(matchedOrigin, hitPosition)
end)

RunService.Heartbeat:Connect(function()
    local now = os.clock()

    for i = #ActiveTracers, 1, -1 do
        local tracer = ActiveTracers[i]
        local elapsed = now - tracer.bornAt

        if tracer.part and tracer.part.Parent then
            if elapsed >= TRACER_SETTINGS.FadeDelay then
                local progress = math.clamp(
                    (elapsed - TRACER_SETTINGS.FadeDelay)
                        / (TRACER_SETTINGS.Duration - TRACER_SETTINGS.FadeDelay),
                    0,
                    1
                )

                local thickness = TRACER_SETTINGS.Thickness * (1 - progress)

                tracer.part.Size = Vector3.new(
                    thickness,
                    thickness,
                    tracer.distance
                )
                tracer.part.Transparency = progress
            end

            if elapsed >= TRACER_SETTINGS.Duration
                or elapsed >= TRACER_SETTINGS.AbsoluteMaxLifespan
            then
                tracer.part:Destroy()
                table.remove(ActiveTracers, i)
            end
        else
            table.remove(ActiveTracers, i)
        end
    end

    for key, shotData in pairs(LocalActiveShots) do
        if now - shotData.timestamp > 1 then
            LocalActiveShots[key] = nil
        end
    end
end)
