-- Общее для файлов выживших: регистрация таблиц, поиск состояний и объектов мода, первый шаг объекта, какой объект сейчас шагает, поздняя регистрация на старте забега, неуязвимость.

SPPMS = SPPMS or {}

local Util = {}

Util.NS = "SPPModdedSurvivors"

function Util.register(namespace, T, SKILLS)
    local found = {}
    for key, identifiers in pairs(SKILLS) do
        if T[key] == nil then
            error("no table T."..key.." for "..namespace.." skills", 2)
        end
        local list = {}
        for i, identifier in ipairs(identifiers) do
            local skill = Skill.find(identifier, namespace)
            if not skill then
                error("skill "..namespace.."-"..identifier.." not found", 2)
            end
            list[i] = skill
        end
        SPPMS.api.register(list, T[key])
        found[key] = list
    end
    return found
end

function Util.find(class, identifier, namespace)
    local found = class.find(identifier, namespace)
    if not found then
        error(namespace.."-"..identifier.." not found", 2)
    end
    return found
end

function Util.in_state(actor, state)
    return tonumber(actor.actor_state_current_id) == state.value
end

function Util.constant(name)
    local value = gm.constants[name]
    if value == nil then error("vanilla asset "..name.." not found", 2) end
    return value
end

function Util.bool(v)
    return v == true or (type(v) == "number" and v > 0.5)
end

local first_step_count = 0

function Util.on_first_step(object, fn)
    first_step_count = first_step_count + 1
    local key = "sppms_seen"..first_step_count
    Callback.add(object.on_step, Callback.Priority.BEFORE, function(inst)
        if not Instance.exists(inst) then return end
        local data = Instance.get_data(inst, nil, Util.NS)
        if data[key] then return end
        data[key] = true
        fn(inst)
    end)
end

function Util.stepping(object)
    local current = nil
    Callback.add(object.on_step, Callback.Priority.BEFORE, function(inst) current = inst end)
    Callback.add(object.on_step, Callback.Priority.AFTER, function() current = nil end)
    return function() return current end
end

function Util.late(branch, setup)
    SPPMS[branch] = "waiting"
    Callback.add(Callback.ON_GAME_START, Callback.Priority.AFTER, function()
        local state = SPPMS[branch]
        if state ~= "waiting" and state ~= "absent" then return end
        local ok, found = pcall(setup)
        if not ok then
            SPPMS[branch] = "failed"
            log.warning("SPPModdedSurvivors: "..branch.." failed to register -> "..tostring(found))
            return
        end
        SPPMS[branch] = found and "ready" or "absent"
    end)
end

function Util.grant_invuln(actor, seconds)
    actor.invincible = math.max(tonumber(actor.invincible) or 0, math.floor(seconds * 60))
end

SPPMS.Util = Util
