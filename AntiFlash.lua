-- By BriefBassoon117 | Discord
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FlashbangController = require(
    ReplicatedStorage.Modules.Client.Controllers.FlashbangController
)

local function DeployAntiFlash()
    for _, upvalue in ipairs(debug.getupvalues(FlashbangController.Start)) do
        if typeof(upvalue) == "function" then
            for index, privateFunc in ipairs(debug.getupvalues(upvalue)) do
                if typeof(privateFunc) == "function"
                    and debug.info(privateFunc, "n") == "computeIntensity"
                then
                    local OriginalComputeIntensity = privateFunc

                    debug.setupvalue(upvalue, index, function(detonationPos)
                        OriginalComputeIntensity(detonationPos)
                        return 0
                    end)

                    return true
                end
            end
        end
    end

    return false
end

DeployAntiFlash()
