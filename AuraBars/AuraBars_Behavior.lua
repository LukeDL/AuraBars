local A = AuraBarsAddon
local S = A.state
local AuraBars = A.eventFrame

-- Converte segundos para texto compacto (h/m/s).
local function FormatTime(seconds)
    if not seconds or seconds <= 0 then
        return "0s"
    end

    if seconds >= 3600 then
        return string.format("%dh", math.floor(seconds / 3600))
    elseif seconds >= 60 then
        return string.format("%dm", math.floor(seconds / 60))
    elseif seconds >= 10 then
        return string.format("%ds", math.floor(seconds))
    end

    return string.format("%.1fs", seconds)
end

-- Oculta e desativa atualização dos frames padrão de auras da Blizzard.
local function HideBlizzardAuraFrames()
    if BuffFrame then
        BuffFrame:UnregisterAllEvents()
        BuffFrame:Hide()
        BuffFrame:HookScript("OnShow", BuffFrame.Hide)
    end

    if TemporaryEnchantFrame then
        TemporaryEnchantFrame:UnregisterAllEvents()
        TemporaryEnchantFrame:Hide()
        TemporaryEnchantFrame:HookScript("OnShow", TemporaryEnchantFrame.Hide)
    end
end

-- Sanitiza payload de aura para tipos seguros e consistentes.
local function SanitizeAuraData(auraData)
    if not auraData then
        return nil
    end

    local auraName = auraData.name and tostring(auraData.name) or "Aura"
    local auraIcon = tonumber(auraData.icon) or auraData.icon
    local auraDuration = tonumber(auraData.duration) or 0
    local auraExpirationTime = tonumber(auraData.expirationTime) or 0
    local auraDispel = auraData.dispelName and tostring(auraData.dispelName) or nil
    local auraPassive = auraData.isPassive and true or false
    local auraPrivate = false

    local okPrivate, privateValue = pcall(function()
        return auraData.isPrivateAura or auraData.isPrivate
    end)

    if okPrivate and privateValue then
        auraPrivate = true
    end

    return {
        name = auraName,
        icon = auraIcon,
        duration = auraDuration,
        expirationTime = auraExpirationTime,
        dispelName = auraDispel,
        isPassive = auraPassive,
        isPrivate = auraPrivate,
    }
end

-- Calcula duração e tempo restante com proteção contra valores secretos/tainted.
local function GetSafeTiming(durationValue, expirationValue, now)
    local ok, duration, expiration, isTimed, remaining = pcall(function()
        local durationNumber = tonumber(durationValue) or 0
        local expirationNumber = tonumber(expirationValue) or 0
        local isTimedValue = durationNumber > 0
        local remainingValue = 0

        if isTimedValue and expirationNumber > 0 then
            remainingValue = math.max(expirationNumber - now, 0)
        end

        return durationNumber, expirationNumber, isTimedValue, remainingValue
    end)

    if not ok then
        return 0, 0, false, 0
    end

    return duration, expiration, isTimed, remaining
end

-- Coleta auras do jogador por filtro e limita ao total configurado.
local function CollectAuras(filter, maxCount)
    local auras = {}

    for index = 1, 255 do
        local rawAuraData = C_UnitAuras.GetAuraDataByIndex("player", index, filter)
        if not rawAuraData then
            break
        end

        local auraData = SanitizeAuraData(rawAuraData)
        auras[#auras + 1] = auraData
    end

    while #auras > maxCount do
        table.remove(auras)
    end

    return auras
end

-- Atualiza uma barra individual com dados de aura e estilo visual.
local function UpdateSingleBar(bar, auraData, now)
    if not bar then
        return
    end

    if not auraData then
        bar.auraData = nil
        bar:Hide()
        return
    end

    local duration, expiration, isTimed, remaining = GetSafeTiming(auraData.duration, auraData.expirationTime, now)

    bar.auraData = {
        name = auraData.name,
        icon = auraData.icon,
        duration = duration,
        expirationTime = expiration,
        dispelName = auraData.dispelName,
        isPassive = auraData.isPassive and true or false,
        isPrivate = auraData.isPrivate and true or false,
    }

    bar.icon:SetTexture(auraData.icon)
    bar.nameText:SetText(auraData.name or "Aura")

    if isTimed then
        bar.status:SetMinMaxValues(0, duration)
        bar.status:SetValue(remaining)
        bar.timeText:SetText(FormatTime(remaining))
    else
        bar.status:SetMinMaxValues(0, 1)
        bar.status:SetValue(1)
        bar.timeText:SetText("∞")
    end

    if bar.isDebuff then
        local debuffType = auraData.dispelName
        local color = debuffType and DebuffTypeColor[debuffType] or nil
        if color then
            bar.status:SetStatusBarColor(color.r, color.g, color.b, 0.9)
        else
            bar.status:SetStatusBarColor(A.COLORS.debuff[1], A.COLORS.debuff[2], A.COLORS.debuff[3], 0.9)
        end
    else
        if isTimed then
            bar.status:SetStatusBarColor(A.COLORS.buff[1], A.COLORS.buff[2], A.COLORS.buff[3], 0.9)
        else
            bar.status:SetStatusBarColor(A.COLORS.noDuration[1], A.COLORS.noDuration[2], A.COLORS.noDuration[3], 0.9)
        end
    end

    if bar.privateBorder then
        if auraData.isPrivate then
            bar.privateBorder:Show()
        else
            bar.privateBorder:Hide()
        end
    end

    bar:Show()
end

-- Atualiza todas as barras visíveis com o snapshot atual de buffs/debuffs.
function A.UpdateBars()
    if not S.buffRoot or not S.debuffRoot or not S.buffsHeader or not S.debuffsHeader then
        return
    end

    A.EnsureBars()

    local now = GetTime()
    local buffs = CollectAuras("HELPFUL", A.CONFIG.maxBuffs)
    local debuffs = CollectAuras("HARMFUL", A.CONFIG.maxDebuffs)

    for i = 1, A.CONFIG.maxBuffs do
        local bar = S.buffBars[i]
        if bar then
            UpdateSingleBar(bar, buffs[i], now)
        end
    end

    for i = 1, A.CONFIG.maxDebuffs do
        local bar = S.debuffBars[i]
        if bar then
            UpdateSingleBar(bar, debuffs[i], now)
        end
    end
end

-- Atualiza apenas os timers das barras já exibidas para reduzir custo.
local function RefreshTimersOnly()
    if not S.buffRoot and not S.debuffRoot then
        return
    end

    local now = GetTime()

    for i = 1, #S.buffBars do
        local bar = S.buffBars[i]
        local auraData = bar.auraData
        -- '_' descarta duration e expiration retornados por GetSafeTiming; aqui só usamos isTimed e remaining.
        local _, _, isTimed, remaining = GetSafeTiming(auraData and auraData.duration, auraData and auraData.expirationTime, now)
        if bar:IsShown() and auraData and isTimed then
            bar.status:SetValue(remaining)
            bar.timeText:SetText(FormatTime(remaining))
        end
    end

    for i = 1, #S.debuffBars do
        local bar = S.debuffBars[i]
        local auraData = bar.auraData
        -- '_' descarta duration e expiration retornados por GetSafeTiming; aqui só usamos isTimed e remaining.
        local _, _, isTimed, remaining = GetSafeTiming(auraData and auraData.duration, auraData and auraData.expirationTime, now)
        if bar:IsShown() and auraData and isTimed then
            bar.status:SetValue(remaining)
            bar.timeText:SetText(FormatTime(remaining))
        end
    end
end

-- Registra o comando de chat do addon para abrir as opções.
local function SetupSlashCommands()
    SLASH_AURABAR1 = "/aurabar"

    SlashCmdList.AURABAR = function()
        A.OpenOptionsPanel()
    end
end

-- Dispatcher principal dos eventos do addon.
AuraBars:SetScript("OnEvent", function(_, event, unit)
    if event == "PLAYER_LOGIN" then
        A.EnsureDB()
        A.ApplyDBToConfig()
        HideBlizzardAuraFrames()
        A.CreateRoot()
        A.EnsureBars()
        A.ApplyBarTexture()
        A.ApplyPrivateBorderStyle()
        A.RefreshLayout()
        SetupSlashCommands()
        A.CreateOptionsPanel()
        A.UpdateBars()
    elseif event == "PLAYER_ENTERING_WORLD" then
        A.UpdateBars()
    elseif event == "UNIT_AURA" and unit == "player" then
        A.UpdateBars()
    end
end)

-- Tick periódico para manter o timer visual das barras sincronizado.
AuraBars:SetScript("OnUpdate", function(_, elapsed)
    S.elapsedSinceUpdate = S.elapsedSinceUpdate + elapsed
    if S.elapsedSinceUpdate >= A.CONFIG.updateRate then
        S.elapsedSinceUpdate = 0
        RefreshTimersOnly()
    end
end)

AuraBars:RegisterEvent("PLAYER_LOGIN")
AuraBars:RegisterEvent("PLAYER_ENTERING_WORLD")
AuraBars:RegisterUnitEvent("UNIT_AURA", "player")
