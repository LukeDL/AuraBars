local addonName = ...

AuraBarsAddon = AuraBarsAddon or {}
local A = AuraBarsAddon

A.addonName = addonName
A.eventFrame = A.eventFrame or CreateFrame("Frame", "AuraBarsEventFrame")
A.state = A.state or {
    buffRoot = nil,
    debuffRoot = nil,
    buffsHeader = nil,
    debuffsHeader = nil,
    buffMoveAnchor = nil,
    debuffMoveAnchor = nil,
    minimapButton = nil,
    optionsCategory = nil,
    buffBars = {},
    debuffBars = {},
    elapsedSinceUpdate = 0,
    textureDropdown = nil,
    texturePreview = nil,
}

A.CONFIG = {
    width = 220,
    height = 18,
    spacing = 4,
    iconSize = 18,
    maxBuffs = 10,
    maxDebuffs = 10,
    updateRate = 0.1,
}

A.DEFAULTS = {
    buffX = -24,
    buffY = -220,
    debuffX = -24,
    debuffY = -470,
    scale = 1,
    maxBuffs = 10,
    maxDebuffs = 10,
    unlocked = false,
    texture = "builtin:default",
    privateBorderColor = "gold",
    privateBorderThickness = 12,
}

A.COLORS = {
    buff = { 0.10, 0.65, 0.25 },
    debuff = { 0.75, 0.20, 0.20 },
    noDuration = { 0.35, 0.35, 0.35 },
}

A.BAR_TEXTURES = {
    { key = "default", label = "Default", path = "Interface\\TARGETINGFRAME\\UI-StatusBar" },
    { key = "flat", label = "Flat", path = "Interface\\Buttons\\WHITE8X8" },
    { key = "banto", label = "BantoBar", path = "Interface\\RAIDFRAME\\Raid-Bar-Hp-Fill" },
    { key = "ui", label = "UI-StatusBar", path = "Interface\\TARGETINGFRAME\\UI-StatusBar" },
}

A.sharedMedia = nil
A.textureRegistry = {}
A.textureByKey = {}

A.PRIVATE_BORDER_COLORS = {
    { key = "gold", label = "Dourado", r = 0.95, g = 0.82, b = 0.12, a = 1 },
    { key = "cyan", label = "Ciano", r = 0.20, g = 0.85, b = 0.95, a = 1 },
    { key = "purple", label = "Roxo", r = 0.78, g = 0.45, b = 0.95, a = 1 },
    { key = "red", label = "Vermelho", r = 0.95, g = 0.35, b = 0.35, a = 1 },
}

-- Escreve mensagens do addon no chat com prefixo padrão.
function A.Msg(text)
    print("|cff33ff99AuraBars|r: " .. text)
end

-- Restringe um valor dentro de um intervalo mínimo e máximo.
function A.Clamp(value, minValue, maxValue)
    if value < minValue then
        return minValue
    end
    if value > maxValue then
        return maxValue
    end
    return value
end

-- Procura uma textura pelo identificador e retorna fallback se não encontrar.
function A.GetTextureByKey(textureKey)
    if #A.textureRegistry == 0 then
        A.RebuildTextureRegistry()
    end

    if A.textureByKey[textureKey] then
        return A.textureByKey[textureKey]
    end

    return A.textureRegistry[1]
end

-- Inicializa integração opcional com LibSharedMedia-3.0 quando disponível.
function A.InitSharedMedia()
    if A.sharedMedia then
        return A.sharedMedia
    end

    if not LibStub then
        return nil
    end

    local lib = LibStub("LibSharedMedia-3.0", true)
    if lib then
        A.sharedMedia = lib
    end

    return A.sharedMedia
end

-- Reconstrói o catálogo de texturas combinando built-ins e SharedMedia.
function A.RebuildTextureRegistry()
    A.textureRegistry = {}
    A.textureByKey = {}

    for i = 1, #A.BAR_TEXTURES do
        local builtIn = A.BAR_TEXTURES[i]
        local entry = {
            key = "builtin:" .. builtIn.key,
            label = builtIn.label,
            path = builtIn.path,
            source = "Built-in",
        }
        A.textureRegistry[#A.textureRegistry + 1] = entry
        A.textureByKey[entry.key] = entry
    end

    local lsm = A.InitSharedMedia()
    if lsm and lsm.List and lsm.Fetch then
        local lsmList = lsm:List("statusbar") or {}
        for i = 1, #lsmList do
            local mediaName = lsmList[i]
            local mediaPath = lsm:Fetch("statusbar", mediaName, true)
            if mediaPath then
                local entry = {
                    key = "lsm:" .. mediaName,
                    label = mediaName,
                    path = mediaPath,
                    source = "SharedMedia",
                }
                A.textureRegistry[#A.textureRegistry + 1] = entry
                A.textureByKey[entry.key] = entry
            end
        end
    end

    return A.textureRegistry
end

-- Procura uma cor de borda de private aura pelo identificador e retorna fallback.
function A.GetPrivateBorderColorByKey(colorKey)
    for i = 1, #A.PRIVATE_BORDER_COLORS do
        if A.PRIVATE_BORDER_COLORS[i].key == colorKey then
            return A.PRIVATE_BORDER_COLORS[i]
        end
    end

    return A.PRIVATE_BORDER_COLORS[1]
end

-- Retorna o caminho da textura atualmente selecionada no perfil.
function A.GetActiveBarTexturePath()
    local texture = A.GetTextureByKey(AuraBarsDB and AuraBarsDB.texture or A.DEFAULTS.texture)
    return texture.path
end

-- Inicializa e valida as configurações persistidas em AuraBarsDB.
function A.EnsureDB()
    AuraBarsDB = AuraBarsDB or {}

    A.RebuildTextureRegistry()

    if AuraBarsDB.buffX == nil then
        if AuraBarsDB.x ~= nil then
            AuraBarsDB.buffX = AuraBarsDB.x
        else
            AuraBarsDB.buffX = A.DEFAULTS.buffX
        end
    end

    if AuraBarsDB.buffY == nil then
        if AuraBarsDB.y ~= nil then
            AuraBarsDB.buffY = AuraBarsDB.y
        else
            AuraBarsDB.buffY = A.DEFAULTS.buffY
        end
    end

    if AuraBarsDB.debuffX == nil then AuraBarsDB.debuffX = A.DEFAULTS.debuffX end
    if AuraBarsDB.debuffY == nil then AuraBarsDB.debuffY = A.DEFAULTS.debuffY end
    if AuraBarsDB.scale == nil then AuraBarsDB.scale = A.DEFAULTS.scale end
    if AuraBarsDB.maxBuffs == nil then AuraBarsDB.maxBuffs = A.DEFAULTS.maxBuffs end
    if AuraBarsDB.maxDebuffs == nil then AuraBarsDB.maxDebuffs = A.DEFAULTS.maxDebuffs end
    if AuraBarsDB.unlocked == nil then AuraBarsDB.unlocked = A.DEFAULTS.unlocked end
    if AuraBarsDB.texture == nil then AuraBarsDB.texture = A.DEFAULTS.texture end
    if AuraBarsDB.privateBorderColor == nil then AuraBarsDB.privateBorderColor = A.DEFAULTS.privateBorderColor end
    if AuraBarsDB.privateBorderThickness == nil then AuraBarsDB.privateBorderThickness = A.DEFAULTS.privateBorderThickness end

    AuraBarsDB.scale = A.Clamp(AuraBarsDB.scale, 0.5, 2.0)
    AuraBarsDB.maxBuffs = A.Clamp(math.floor(AuraBarsDB.maxBuffs), 1, 40)
    AuraBarsDB.maxDebuffs = A.Clamp(math.floor(AuraBarsDB.maxDebuffs), 1, 40)
    if AuraBarsDB.texture and not string.find(AuraBarsDB.texture, ":", 1, true) then
        AuraBarsDB.texture = "builtin:" .. AuraBarsDB.texture
    end

    AuraBarsDB.texture = A.GetTextureByKey(AuraBarsDB.texture).key
    AuraBarsDB.privateBorderColor = A.GetPrivateBorderColorByKey(AuraBarsDB.privateBorderColor).key
    AuraBarsDB.privateBorderThickness = A.Clamp(math.floor(AuraBarsDB.privateBorderThickness), 4, 24)
end

-- Aplica valores persistidos no bloco de configuração de runtime.
function A.ApplyDBToConfig()
    A.CONFIG.maxBuffs = AuraBarsDB.maxBuffs
    A.CONFIG.maxDebuffs = AuraBarsDB.maxDebuffs
end

-- Atualiza o estado de lock e requisita refresh visual do layout.
function A.SetUnlocked(unlocked)
    AuraBarsDB.unlocked = unlocked and true or false
    if A.RefreshLayout then
        A.RefreshLayout()
    end
end

-- Define a escala do addon e atualiza layout quando disponível.
function A.SetScale(scale)
    AuraBarsDB.scale = A.Clamp(scale, 0.5, 2.0)
    if A.RefreshLayout then
        A.RefreshLayout()
    end
end

-- Define textura ativa e força atualização visual das barras.
function A.SetTexture(textureKey)
    AuraBarsDB.texture = A.GetTextureByKey(textureKey).key
    if A.ApplyBarTexture then
        A.ApplyBarTexture()
    end
    if A.UpdateBars then
        A.UpdateBars()
    end
end

-- Define a cor da borda de private aura e reaplica estilo nas barras.
function A.SetPrivateBorderColor(colorKey)
    AuraBarsDB.privateBorderColor = A.GetPrivateBorderColorByKey(colorKey).key
    if A.ApplyPrivateBorderStyle then
        A.ApplyPrivateBorderStyle()
    end
end

-- Define a espessura da borda de private aura e reaplica estilo nas barras.
function A.SetPrivateBorderThickness(thickness)
    AuraBarsDB.privateBorderThickness = A.Clamp(math.floor(thickness), 4, 24)
    if A.ApplyPrivateBorderStyle then
        A.ApplyPrivateBorderStyle()
    end
end

-- Ajusta a quantidade máxima de buffs e reaplica layout/render.
function A.SetMaxBuffs(maxBuffs)
    AuraBarsDB.maxBuffs = A.Clamp(math.floor(maxBuffs), 1, 40)
    A.ApplyDBToConfig()
    if A.EnsureBars then A.EnsureBars() end
    if A.RefreshLayout then A.RefreshLayout() end
    if A.UpdateBars then A.UpdateBars() end
end

-- Ajusta a quantidade máxima de debuffs e reaplica layout/render.
function A.SetMaxDebuffs(maxDebuffs)
    AuraBarsDB.maxDebuffs = A.Clamp(math.floor(maxDebuffs), 1, 40)
    A.ApplyDBToConfig()
    if A.EnsureBars then A.EnsureBars() end
    if A.RefreshLayout then A.RefreshLayout() end
    if A.UpdateBars then A.UpdateBars() end
end

-- Restaura todas as preferências para os valores padrão do addon.
function A.ResetSettings()
    AuraBarsDB.buffX = A.DEFAULTS.buffX
    AuraBarsDB.buffY = A.DEFAULTS.buffY
    AuraBarsDB.debuffX = A.DEFAULTS.debuffX
    AuraBarsDB.debuffY = A.DEFAULTS.debuffY
    AuraBarsDB.scale = A.DEFAULTS.scale
    AuraBarsDB.maxBuffs = A.DEFAULTS.maxBuffs
    AuraBarsDB.maxDebuffs = A.DEFAULTS.maxDebuffs
    AuraBarsDB.unlocked = A.DEFAULTS.unlocked
    AuraBarsDB.texture = A.DEFAULTS.texture
    AuraBarsDB.privateBorderColor = A.DEFAULTS.privateBorderColor
    AuraBarsDB.privateBorderThickness = A.DEFAULTS.privateBorderThickness

    A.ApplyDBToConfig()

    if A.EnsureBars then A.EnsureBars() end
    if A.ApplyBarTexture then A.ApplyBarTexture() end
    if A.ApplyPrivateBorderStyle then A.ApplyPrivateBorderStyle() end
    if A.RefreshLayout then A.RefreshLayout() end
    if A.UpdateBars then A.UpdateBars() end
end
