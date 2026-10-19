-- Консольная команда sppms_status.

SPPMS = SPPMS or {}

local function say(msg)
    Console.print("[sppms] "..msg)
end

Console.new{
    "sppms_status",
    {
        "Prints whether SPP: Modded Survivors loaded in full and which supported "
        .."survivors it found.",
    },
    function(_)
        local boot = SPPMS.Boot
        if not boot then
            say("no boot report - main.lua did not reach the end of loading")
            return
        end
        say(string.format("modules %d/%d, missing: %s", boot.loaded, boot.total, boot.missing))

        for _, key in ipairs(boot.expected) do
            if type(SPPMS[key]) == "string" then
                say(key..": "..SPPMS[key])
            end
        end
    end
}

SPPMS.Debug = true
