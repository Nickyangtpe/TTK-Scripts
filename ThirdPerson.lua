-- By BriefBassoon117 | Discord
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local CurrentCamera = workspace.CurrentCamera

local CAMERA_OFFSET = Vector3.new(2.5, 2, 11)
local WALL_PADDING = 0.4

local CameraController = require(
    ReplicatedStorage.Modules.Client.Controllers.CameraController
)

local function GetActiveController()
    return CameraController._active or rawget(CameraController, "_active")
end

local RaycastParams = RaycastParams.new()
RaycastParams.FilterType = Enum.RaycastFilterType.Exclude
RaycastParams.IgnoreWater = true

local function UpdateRaycastFilter()
    local ignore = {}

    if LocalPlayer.Character then
        table.insert(ignore, LocalPlayer.Character)
    end

    if CurrentCamera then
        table.insert(ignore, CurrentCamera)
    end

    for _, name in ipairs({
        "MercPOV",
        "MercPlayers",
        "Ignore"
    }) do
        local instance = workspace:FindFirstChild(name)

        if instance then
            table.insert(ignore, instance)
        end
    end

    RaycastParams.FilterDescendantsInstances = ignore
end

local OldNewIndex

OldNewIndex = hookmetamethod(game, "__newindex", function(self, key, value)
    if self == CurrentCamera
        and key == "CFrame"
        and typeof(value) == "CFrame"
    then
        local controller = GetActiveController()

        if controller
            and controller.enabled
            and LocalPlayer.Character
        then
            local root =
                LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

            if root then
                local origin = value.Position
                local target =
                    value * CFrame.new(CAMERA_OFFSET)

                UpdateRaycastFilter()

                local result = workspace:Raycast(
                    origin,
                    target.Position - origin,
                    RaycastParams
                )

                if result then
                    local position =
                        result.Position + result.Normal * WALL_PADDING

                    return OldNewIndex(
                        self,
                        key,
                        target.Rotation + position
                    )
                end

                return OldNewIndex(self, key, target)
            end
        end
    end

    return OldNewIndex(self, key, value)
end)

RunService.RenderStepped:Connect(function()
    local character = LocalPlayer.Character

    if not character then
        return
    end

    for _, object in ipairs(character:GetDescendants()) do
        if object:IsA("BasePart")
            and object.Name ~= "HumanoidRootPart"
        then
            object.LocalTransparencyModifier = 0
        end
    end
end)
