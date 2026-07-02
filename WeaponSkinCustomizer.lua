-- By BriefBassoon117 | Discord
local CurrentCamera = workspace.CurrentCamera

local TARGET_MATERIAL = Enum.Material.ForceField
local TARGET_COLOR = Color3.fromRGB(255, 0, 128)
local TRANSPARENCY = 0.4

local function ApplySkin(model)
    task.wait(0.1)

    for _, obj in ipairs(model:GetDescendants()) do
        if obj:IsA("BasePart") then
            local surface = obj:FindFirstChildOfClass("SurfaceAppearance")
            if surface then
                surface:Destroy()
            end

            obj.Material = TARGET_MATERIAL
            obj.Color = TARGET_COLOR
            obj.Transparency = TRANSPARENCY

            if obj:GetAttribute("GsBaseT") then
                obj:SetAttribute("GsBaseT", TRANSPARENCY)
            end

        elseif obj:IsA("Decal") or obj:IsA("Texture") then
            obj.Transparency = 1
        end
    end
end

CurrentCamera.ChildAdded:Connect(function(child)
    if child:IsA("Model") then
        ApplySkin(child)
    end
end)

for _, child in ipairs(CurrentCamera:GetChildren()) do
    if child:IsA("Model") then
        ApplySkin(child)
    end
end
