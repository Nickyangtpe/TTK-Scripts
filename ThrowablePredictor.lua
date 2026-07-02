-- By BriefBassoon117 | Discord
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local Visuals = {
    Points = {},
    TargetDot = nil,
    MaxPoints = 60,
    Container = nil,
}

function Visuals:Init()
    if self.Container and self.Container.Parent then
        return
    end

    local folder = Instance.new("Folder")
    folder.Name = "ThrowablePredictor_ESP"
    folder.Parent = Workspace
    self.Container = folder

    local dot = Instance.new("Part")
    dot.Anchored = true
    dot.CanCollide = false
    dot.CanTouch = false
    dot.CanQuery = false
    dot.Size = Vector3.new(0.6, 0.6, 0.6)
    dot.Color = Color3.fromRGB(255, 0, 0)
    dot.Material = Enum.Material.Neon
    dot.Shape = Enum.PartType.Ball
    dot.Parent = folder
    self.TargetDot = dot

    local dotHighlight = Instance.new("Highlight")
    dotHighlight.FillColor = Color3.fromRGB(255, 0, 0)
    dotHighlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    dotHighlight.FillTransparency = 0.2
    dotHighlight.OutlineTransparency = 0
    dotHighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    dotHighlight.Adornee = dot
    dotHighlight.Parent = dot

    for i = 1, self.MaxPoints do
        local p = Instance.new("Part")
        p.Anchored = true
        p.CanCollide = false
        p.CanTouch = false
        p.CanQuery = false
        p.Size = Vector3.new(0.15, 0.15, 0.15)
        p.Color = Color3.fromRGB(0, 255, 255)
        p.Material = Enum.Material.Neon
        p.Shape = Enum.PartType.Ball
        p.Parent = folder

        local hl = Instance.new("Highlight")
        hl.FillColor = Color3.fromRGB(0, 255, 255)
        hl.FillTransparency = 0.3
        hl.OutlineTransparency = 1
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Adornee = p
        hl.Parent = p

        table.insert(self.Points, p)
    end
end

function Visuals:Clear()
    if not self.Container then
        return
    end

    for _, p in ipairs(self.Points) do
        p.Transparency = 1
    end

    if self.TargetDot then
        self.TargetDot.Transparency = 1
    end
end

function Visuals:Render(positions, hitPos)
    self:Init()

    for i = 1, self.MaxPoints do
        local pos = positions[i]

        if pos then
            self.Points[i].Position = pos
            self.Points[i].Transparency = 0
        else
            self.Points[i].Transparency = 1
        end
    end

    if hitPos then
        self.TargetDot.Position = hitPos
        self.TargetDot.Transparency = 0
    else
        self.TargetDot.Transparency = 1
    end
end

local PredictionSystem = {
    TargetController = nil,
    RealProjectile = nil,
    IsAiming = false,
}

local GRAVITY = Workspace.Gravity
local realPositions = {}

local BOUNCE_ELASTICITY = 0.45
local FRICTION_COEFF = 0.85
local MIN_BOUNCE_VEL = 3

function PredictionSystem:CalculateInitialPhysics(entry)
    local cfg = entry and entry.Projectile
    if not cfg then
        return
    end

    local camCF = Camera.CFrame
    local spawnCF =
        camCF * CFrame.new(0, -0.6, -(cfg.SpawnDistance or 2))

    local velocity =
        camCF.LookVector * (cfg.ThrowSpeed or 55)
        + Vector3.new(0, 1, 0) * (cfg.UpSpeed or 18)

    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")

    if hrp then
        velocity += hrp.AssemblyLinearVelocity
    end

    return spawnCF.Position, velocity
end

function PredictionSystem:PredictPreThrow(entry)
    local startPos, velocity = self:CalculateInitialPhysics(entry)
    if not startPos then
        Visuals:Clear()
        return
    end

    local positions = {}
    local currentPos = startPos
    local currentVelocity = velocity
    local hitPos

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {
        LocalPlayer.Character,
        self.Container,
    }
    params.IgnoreWater = true

    for i = 1, Visuals.MaxPoints do
        table.insert(positions, currentPos)

        local accel = Vector3.new(0, -GRAVITY, 0)
        local displacement =
            currentVelocity * 0.04 + 0.5 * accel * 0.04 * 0.04

        local nextPos = currentPos + displacement
        local nextVel = currentVelocity + accel * 0.04

        local result =
            Workspace:Raycast(currentPos, displacement, params)

        if result then
            local normal = result.Normal
            currentPos = result.Position + normal * 0.05

            local normalVel = currentVelocity:Dot(normal) * normal
            local tangentVel = currentVelocity - normalVel

            if normalVel.Magnitude > MIN_BOUNCE_VEL then
                currentVelocity =
                    tangentVel * FRICTION_COEFF
                    - normalVel * BOUNCE_ELASTICITY
            else
                currentVelocity = tangentVel * FRICTION_COEFF

                if normal.Y > 0.7 then
                    currentVelocity += Vector3.new(0, -GRAVITY * 0.1, 0)
                end
            end

            if currentVelocity.Magnitude < 0.2 then
                hitPos = result.Position
                break
            end
        else
            currentPos = nextPos
            currentVelocity = nextVel
        end

        hitPos = currentPos
    end

    Visuals:Render(positions, hitPos)
end

function PredictionSystem:TrackRealProjectile()
    if not self.RealProjectile or not self.RealProjectile.Parent then
        self.RealProjectile = nil
        Visuals:Clear()
        return
    end

    local pos = self.RealProjectile:GetPivot().Position

    table.insert(realPositions, pos)

    if #realPositions > Visuals.MaxPoints then
        table.remove(realPositions, 1)
    end

    local hitPos = pos
    local part =
        self.RealProjectile.PrimaryPart
        or self.RealProjectile:FindFirstChildWhichIsA("BasePart")

    if part then
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = {
            LocalPlayer.Character,
            self.RealProjectile,
            self.Container,
        }

        local vel = part.AssemblyLinearVelocity
        local dir =
            vel.Magnitude > 0.5 and vel.Unit * 10 or Vector3.new(0, -10, 0)

        local result = Workspace:Raycast(pos, dir, params)

        if result then
            hitPos = result.Position
        end
    end

    Visuals:Render(realPositions, hitPos)
end

local function SetupHooks()
    local Controller

    for _, v in ipairs(getgc(true)) do
        if typeof(v) == "table"
            and rawget(v, "ActivatePress")
            and rawget(v, "_LaunchProjectile")
        then
            Controller = v
            break
        end
    end

    if not Controller then
        return false
    end

    PredictionSystem.TargetController = Controller

    local oldDown = Controller._OnAimDown
    Controller._OnAimDown = function(self, ...)
        PredictionSystem.IsAiming = true
        table.clear(realPositions)
        return oldDown(self, ...)
    end

    local oldFinish = Controller._FinishThrow
    Controller._FinishThrow = function(self, ...)
        PredictionSystem.IsAiming = false
        return oldFinish(self, ...)
    end

    local oldUnequip = Controller.Unequip
    Controller.Unequip = function(self, ...)
        PredictionSystem.IsAiming = false
        PredictionSystem.RealProjectile = nil
        Visuals:Clear()
        return oldUnequip(self, ...)
    end

    local oldSpawn = Controller._SpawnThrownModel
    Controller._SpawnThrownModel = function(self, ...)
        local model = oldSpawn(self, ...)
        if model then
            PredictionSystem.RealProjectile = model
            table.clear(realPositions)
        end
        return model
    end

    return true
end

RunService.RenderStepped:Connect(function()
    if PredictionSystem.RealProjectile then
        PredictionSystem:TrackRealProjectile()
    elseif PredictionSystem.IsAiming and PredictionSystem.TargetController then
        local entry = PredictionSystem.TargetController._entry
        if entry then
            PredictionSystem:PredictPreThrow(entry)
        end
    else
        Visuals:Clear()
    end
end)

task.spawn(function()
    while not SetupHooks() do
        task.wait(0.5)
    end
end)
