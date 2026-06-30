-- By BriefBassoon117 | Discord

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local BulletController = require(
    ReplicatedStorage.Modules.Client.Controllers.BulletController
)

local function GetClosestTargetHead()
    local closestHead
    local closestDistance = math.huge

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local character = player.Character

            if character then
                local head = character:FindFirstChild("Head")
                local humanoid = character:FindFirstChildOfClass("Humanoid")

                if head
                    and humanoid
                    and humanoid.Health > 0
                    and not character:GetAttribute("Dead")
                then
                    local distance = (head.Position - Camera.CFrame.Position).Magnitude

                    if distance < closestDistance then
                        closestDistance = distance
                        closestHead = head
                    end
                end
            end
        end
    end

    return closestHead
end

local OldDischarge

OldDischarge = hookfunction(BulletController.Discharge, function(self, weaponId, p3, p4, p5)
    local head = GetClosestTargetHead()

    if head then
        local direction = (head.Position - p3).Unit

        p4 = direction

        if typeof(p5) == "CFrame" then
            p5 = CFrame.new(p3, p3 + direction)
        end
    end

    return OldDischarge(self, weaponId, p3, p4, p5)
end)
