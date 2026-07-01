local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GunController = require(
    ReplicatedStorage.Modules.Client.Controllers.GunController
)
local TargetAcquisition = require(
    ReplicatedStorage.Modules.Client.Combat.TargetAcquisition
)

local AUTO_SHOOT_SETTINGS = {
    Enabled = true,
    MaxDistance = 350,
    FieldOfView = 2.2,
}

local OldUpdate

OldUpdate = hookfunction(GunController.Update, function(self, deltaTime, cameraCFrame, p3)
    if AUTO_SHOOT_SETTINGS.Enabled
        and self.Weapon
        and not self:_ShouldBlockWeaponInput()
    then
        local hasTarget = TargetAcquisition.HasHostileTarget(
            AUTO_SHOOT_SETTINGS.MaxDistance,
            AUTO_SHOOT_SETTINGS.FieldOfView
        )

        if hasTarget then
            if not self.FireHeld then
                self:StartFiring()
            end

            if self.Weapon.FireMode == "auto" then
                self.FireHeld = true
            end
        elseif self.FireHeld then
            self:StopFiring()
        end
    end

    return OldUpdate(self, deltaTime, cameraCFrame, p3)
end)

local OldUnequip

OldUnequip = hookfunction(GunController.Unequip, function(self)
    if self.FireHeld then
        self:StopFiring()
    end

    return OldUnequip(self)
end)

local OldResetInputState

OldResetInputState = hookfunction(GunController.ResetInputState, function(self)
    if self.FireHeld then
        self:StopFiring()
    end

    return OldResetInputState(self)
end)
