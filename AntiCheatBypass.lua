-- By BriefBassoon117 | Discord
local ReplicatedStorage = game:GetService("ReplicatedStorage")

if not hookfunction or not debug.getupvalues then
    return
end

local TARGET_NAME = "IntegrityController"

for _, module in ipairs(ReplicatedStorage:GetDescendants()) do
    if module:IsA("ModuleScript") and module.Name == TARGET_NAME then
        local success, controller = pcall(require, module)

        if success
            and type(controller) == "table"
            and type(controller.Start) == "function"
        then
            for _, upvalue in ipairs(debug.getupvalues(controller.Start)) do
                if type(upvalue) == "function"
                    and debug.info(upvalue, "n") == "send"
                then
                    hookfunction(upvalue, function()
                        task.wait(999999999)
                    end)

                    return
                end
            end
        end
    end
end
