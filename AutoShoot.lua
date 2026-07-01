local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local LocalPlayer = Players.LocalPlayer

local GunController = require(
    ReplicatedStorage.Modules.Client.Controllers.GunController
)

local AUTO_SHOOT_SETTINGS = {
    Enabled = true,
    Enable360Mode = true,
    MaxDistance = 500,
    WallCheckParams = RaycastParams.new(),
}

AUTO_SHOOT_SETTINGS.WallCheckParams.FilterType = Enum.RaycastFilterType.Exclude
AUTO_SHOOT_SETTINGS.WallCheckParams.IgnoreWater = true

local MacroClickClock = 0

local function ResolvePassableInstance(instance)
    if not instance then
        return nil
    end

    local current = instance

    for _ = 1, 4 do
        if current
            and current:IsA("BasePart")
            and (
                CollectionService:HasTag(current, "Glass")
                or CollectionService:HasTag(current, "Glass_Fragile")
            )
        then
            return current
        end

        if not current then
            break
        end

        current = current.Parent
    end

    return nil
end

local function IsTargetVisible(character, muzzlePosition)
    if not character or not LocalPlayer.Character then
        return false
    end

    local sampleParts = {}

    for _, name in ipairs({
        "Head",
        "HumanoidRootPart",
        "Torso",
        "UpperTorso"
    }) do
        local part = character:FindFirstChild(name)

        if part then
            table.insert(sampleParts, part)
        end
    end

    if #sampleParts == 0 then
        return false
    end

    local exclude = {
        LocalPlayer.Character,
        workspace.CurrentCamera
    }

    local activeMap = workspace:FindFirstChild("ActiveMap")
        or workspace:FindFirstChild("Map")

    if activeMap then
        local touchables = activeMap:FindFirstChild("Touchables")
        local ignore = activeMap:FindFirstChild("Ignore")

        if touchables then
            table.insert(exclude, touchables)
        end

        if ignore then
            table.insert(exclude, ignore)
        end
    end

    local globalIgnore = workspace:FindFirstChild("Ignore")
    local cosmetic = workspace:FindFirstChild("_CosmeticProjectiles")

    if globalIgnore then
        table.insert(exclude, globalIgnore)
    end

    if cosmetic then
        table.insert(exclude, cosmetic)
    end

    AUTO_SHOOT_SETTINGS.WallCheckParams.FilterDescendantsInstances = exclude

    for _, part in ipairs(sampleParts) do
        local currentStart = muzzlePosition
        local direction = (part.Position - muzzlePosition).Unit
        local remaining = (part.Position - muzzlePosition).Magnitude

        for _ = 1, 4 do
            if remaining <= 0.05 then
                return true
            end

            local result = workspace:Raycast(
                currentStart,
                direction * remaining,
                AUTO_SHOOT_SETTINGS.WallCheckParams
            )

            if not result or result.Instance:IsDescendantOf(character) then
                return true
            end

            local passable = ResolvePassableInstance(result.Instance)

            if not passable then
                break
            end

            table.insert(
                AUTO_SHOOT_SETTINGS.WallCheckParams.FilterDescendantsInstances,
                passable
            )

            local travelled =
                (result.Position - currentStart).Magnitude + 0.02

            remaining = math.max(0, remaining - travelled)
            currentStart = result.Position + direction * 0.02
        end
    end

    return false
end

local OldUpdate

OldUpdate = hookfunction(GunController.Update, function(self, deltaTime, p3)
    if AUTO_SHOOT_SETTINGS.Enabled
        and self.Weapon
        and not self:_ShouldBlockWeaponInput()
    then
        local muzzle =
            self:GetMuzzleWorldPosition()
            or workspace.CurrentCamera.CFrame.Position

        local camera = workspace.CurrentCamera.CFrame

        local bestTarget
        local shortest = AUTO_SHOOT_SETTINGS.MaxDistance

        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                local character = player.Character
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                local root = character:FindFirstChild("HumanoidRootPart")

                if root and humanoid and humanoid.Health > 0 then
                    if not (
                        player.Team
                        and LocalPlayer.Team
                        and player.Team == LocalPlayer.Team
                    ) then
                        local vector = root.Position - muzzle
                        local distance = vector.Magnitude

                        if distance <= shortest then
                            local validAngle = true

                            if not AUTO_SHOOT_SETTINGS.Enable360Mode then
                                validAngle =
                                    camera.LookVector:Dot(vector.Unit) >= 0.707
                            end

                            if validAngle
                                and IsTargetVisible(character, muzzle)
                            then
                                shortest = distance
                                bestTarget = character
                            end
                        end
                    end
                end
            end
        end

        if bestTarget then
            if self.Weapon.FireMode == "auto" then
                if not self.FireHeld then
                    self:StartFiring()
                end
            else
                local now = os.clock()

                if now - MacroClickClock >= 0.03 then
                    if self.FireHeld then
                        self:StopFiring()
                    else
                        self:StartFiring()
                    end

                    MacroClickClock = now
                end
            end
        elseif self.FireHeld then
            self:StopFiring()
        end
    end

    return OldUpdate(self, deltaTime, p3)
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
