local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BulletController = require(
    ReplicatedStorage.Modules.Client.Controllers.BulletController
)
local CameraController = require(
    ReplicatedStorage.Modules.Client.Controllers.CameraController
)
local FirearmRuntime = require(
    ReplicatedStorage.Registries.FirearmRuntime
)

local OldDischarge

OldDischarge = hookfunction(BulletController.Discharge, function(self, weaponId, p3, p4, p5)
    local runtimeSpec = FirearmRuntime[weaponId]

    if runtimeSpec then
        runtimeSpec.SpreadAngle = 0
    end

    return OldDischarge(self, weaponId, p3, p4, p5)
end)

if CameraController.Recoil then
    local OldRecoil

    OldRecoil = hookfunction(CameraController.Recoil, function()
        return nil
    end)
end

if CameraController.ShakeImpulse then
    hookfunction(CameraController.ShakeImpulse, function()
        return nil
    end)
end

if CameraController.GetProceduralOffset then
    local OldGetProceduralOffset

    OldGetProceduralOffset = hookfunction(CameraController.GetProceduralOffset, function()
        return CFrame.identity
    end)
end
