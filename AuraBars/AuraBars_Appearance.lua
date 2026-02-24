local A = AuraBarsAddon
local S = A.state

-- Reposiciona o frame raiz usando as coordenadas salvas do perfil.
function A.ApplyRootPosition()
    if not S.buffRoot or not S.debuffRoot then
        return
    end

    S.buffRoot:ClearAllPoints()
    S.buffRoot:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", AuraBarsDB.buffX, AuraBarsDB.buffY)

    S.debuffRoot:ClearAllPoints()
    S.debuffRoot:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", AuraBarsDB.debuffX, AuraBarsDB.debuffY)
end

-- Mostra/oculta a âncora de arraste conforme estado de desbloqueio.
function A.UpdateMoveAnchorState()
    if S.buffRoot then
        S.buffRoot:Show()
    end

    if S.debuffRoot then
        S.debuffRoot:Show()
    end

    if S.buffMoveAnchor then
        S.buffMoveAnchor:EnableMouse(AuraBarsDB.unlocked)
        if AuraBarsDB.unlocked then
            S.buffMoveAnchor:RegisterForDrag("LeftButton")
            S.buffMoveAnchor:Show()
        else
            S.buffMoveAnchor:RegisterForDrag()
            S.buffMoveAnchor:Hide()
        end
    end

    if S.debuffMoveAnchor then
        S.debuffMoveAnchor:EnableMouse(AuraBarsDB.unlocked)
        if AuraBarsDB.unlocked then
            S.debuffMoveAnchor:RegisterForDrag("LeftButton")
            S.debuffMoveAnchor:Show()
        else
            S.debuffMoveAnchor:RegisterForDrag()
            S.debuffMoveAnchor:Hide()
        end
    end
end

-- Recalcula dimensões, posições, escala e interações de drag dos elementos.
function A.RefreshLayout()
    if not S.buffRoot or not S.debuffRoot or not S.buffsHeader or not S.debuffsHeader then
        return
    end

    S.buffRoot:SetSize(A.CONFIG.width, 1)
    S.buffRoot:SetScale(AuraBarsDB.scale)

    S.debuffRoot:SetSize(A.CONFIG.width, 1)
    S.debuffRoot:SetScale(AuraBarsDB.scale)

    S.buffsHeader:SetSize(A.CONFIG.width, (A.CONFIG.maxBuffs * A.CONFIG.height) + ((A.CONFIG.maxBuffs - 1) * A.CONFIG.spacing))
    S.buffsHeader:ClearAllPoints()
    S.buffsHeader:SetPoint("TOPLEFT", S.buffRoot, "TOPLEFT", 0, 0)

    S.debuffsHeader:SetSize(A.CONFIG.width, (A.CONFIG.maxDebuffs * A.CONFIG.height) + ((A.CONFIG.maxDebuffs - 1) * A.CONFIG.spacing))
    S.debuffsHeader:ClearAllPoints()
    S.debuffsHeader:SetPoint("TOPLEFT", S.debuffRoot, "TOPLEFT", 0, 0)

    for i = 1, #S.buffBars do
        local bar = S.buffBars[i]
        bar:ClearAllPoints()
        bar:SetPoint("TOPLEFT", S.buffsHeader, "TOPLEFT", 0, -((i - 1) * (A.CONFIG.height + A.CONFIG.spacing)))
    end

    for i = 1, #S.debuffBars do
        local bar = S.debuffBars[i]
        bar:ClearAllPoints()
        bar:SetPoint("TOPLEFT", S.debuffsHeader, "TOPLEFT", 0, -((i - 1) * (A.CONFIG.height + A.CONFIG.spacing)))
    end

    S.buffRoot:SetMovable(AuraBarsDB.unlocked)
    S.buffRoot:EnableMouse(AuraBarsDB.unlocked)
    S.buffRoot:RegisterForDrag("LeftButton")

    S.debuffRoot:SetMovable(AuraBarsDB.unlocked)
    S.debuffRoot:EnableMouse(AuraBarsDB.unlocked)
    S.debuffRoot:RegisterForDrag("LeftButton")

    A.ApplyRootPosition()
    A.UpdateMoveAnchorState()
end

-- Aplica a textura de barra atual em todas as barras criadas.
function A.ApplyBarTexture()
    local path = A.GetActiveBarTexturePath()

    for i = 1, #S.buffBars do
        S.buffBars[i].status:SetStatusBarTexture(path)
    end

    for i = 1, #S.debuffBars do
        S.debuffBars[i].status:SetStatusBarTexture(path)
    end
end

-- Aplica cor e espessura configuradas para borda de private aura em todas as barras.
function A.ApplyPrivateBorderStyle()
    local color = A.GetPrivateBorderColorByKey(AuraBarsDB.privateBorderColor)
    local edgeSize = AuraBarsDB.privateBorderThickness

    local function ApplyStyle(bar)
        if not bar or not bar.privateBorder then
            return
        end

        bar.privateBorder:SetBackdrop({
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            edgeSize = edgeSize,
            insets = { left = 2, right = 2, top = 2, bottom = 2 },
        })
        bar.privateBorder:SetBackdropBorderColor(color.r, color.g, color.b, color.a)
    end

    for i = 1, #S.buffBars do
        ApplyStyle(S.buffBars[i])
    end

    for i = 1, #S.debuffBars do
        ApplyStyle(S.debuffBars[i])
    end
end

-- Cria uma barra visual de aura (buff ou debuff) com interações e textos.
function A.CreateBar(parent, index, isDebuff)
    local bar = CreateFrame("Button", nil, parent, "BackdropTemplate")
    bar:SetSize(A.CONFIG.width, A.CONFIG.height)

    local yOffset = -((index - 1) * (A.CONFIG.height + A.CONFIG.spacing))
    bar:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, yOffset)

    bar.bg = bar:CreateTexture(nil, "BACKGROUND")
    bar.bg:SetAllPoints()
    bar.bg:SetColorTexture(0, 0, 0, 0.50)

    bar.status = CreateFrame("StatusBar", nil, bar)
    bar.status:SetAllPoints()
    bar.status:SetStatusBarTexture(A.GetActiveBarTexturePath())
    bar.status:SetMinMaxValues(0, 1)
    bar.status:SetValue(1)

    bar.icon = bar.status:CreateTexture(nil, "OVERLAY")
    bar.icon:SetSize(A.CONFIG.iconSize, A.CONFIG.iconSize)
    bar.icon:SetPoint("LEFT", bar, "LEFT", 0, 0)

    bar.nameText = bar.status:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    bar.nameText:SetPoint("LEFT", bar.icon, "RIGHT", 6, 0)
    bar.nameText:SetPoint("RIGHT", bar, "RIGHT", -42, 0)
    bar.nameText:SetJustifyH("LEFT")

    bar.timeText = bar.status:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    bar.timeText:SetPoint("RIGHT", bar, "RIGHT", -6, 0)
    bar.timeText:SetJustifyH("RIGHT")

    bar.privateBorder = CreateFrame("Frame", nil, bar, "BackdropTemplate")
    bar.privateBorder:SetAllPoints()
    bar.privateBorder:SetBackdrop({
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = AuraBarsDB.privateBorderThickness,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })

    local privateColor = A.GetPrivateBorderColorByKey(AuraBarsDB.privateBorderColor)
    bar.privateBorder:SetBackdropBorderColor(privateColor.r, privateColor.g, privateColor.b, privateColor.a)
    bar.privateBorder:Hide()

    bar.isDebuff = isDebuff
    bar:RegisterForClicks("RightButtonUp")
    bar:SetScript("OnClick", function(self, button)
        if button ~= "RightButton" then
            return
        end

        local auraData = self.auraData
        if not auraData or self.isDebuff then
            return
        end

        if auraData.isPassive then
            return
        end

        if C_UnitAuras and C_UnitAuras.CancelAuraByName and auraData.name then
            C_UnitAuras.CancelAuraByName("player", auraData.name)
            return
        end

        if CancelUnitBuff and auraData.name then
            CancelUnitBuff("player", auraData.name)
            return
        end

        if CancelSpellByName and auraData.name then
            CancelSpellByName(auraData.name)
        end
    end)

    bar:Hide()
    return bar
end

-- Garante que existam barras suficientes para os limites configurados.
function A.EnsureBars()
    for i = #S.buffBars + 1, A.CONFIG.maxBuffs do
        S.buffBars[i] = A.CreateBar(S.buffsHeader, i, false)
    end

    for i = #S.debuffBars + 1, A.CONFIG.maxDebuffs do
        S.debuffBars[i] = A.CreateBar(S.debuffsHeader, i, true)
    end
end

-- Cria frame raiz, cabeçalhos e âncora de arraste para o addon.
function A.CreateRoot()
    S.buffRoot = CreateFrame("Frame", "AuraBarsBuffRoot", UIParent, "BackdropTemplate")
    S.buffRoot:SetSize(A.CONFIG.width, 1)
    S.buffRoot:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", AuraBarsDB.buffX, AuraBarsDB.buffY)
    S.buffRoot:SetClampedToScreen(true)
    S.buffRoot:SetMovable(false)
    S.buffRoot:EnableMouse(false)
    S.buffRoot:RegisterForDrag("LeftButton")

    S.buffRoot:SetScript("OnDragStart", function(self)
        if AuraBarsDB and AuraBarsDB.unlocked then
            self:StartMoving()
        end
    end)

    S.buffRoot:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        -- '_' descarta os 3 primeiros retornos de GetPoint (point, relativeTo, relativePoint); usamos apenas x e y.
        local _, _, _, x, y = self:GetPoint(1)
        if x and y then
            AuraBarsDB.buffX = x
            AuraBarsDB.buffY = y
        end
    end)

    S.buffMoveAnchor = CreateFrame("Button", nil, S.buffRoot, "BackdropTemplate")
    S.buffMoveAnchor:SetSize(A.CONFIG.width, 20)
    S.buffMoveAnchor:SetPoint("BOTTOMLEFT", S.buffRoot, "TOPLEFT", 0, 6)
    S.buffMoveAnchor:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 12,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    S.buffMoveAnchor:SetBackdropColor(0.05, 0.5, 0.2, 0.8)
    S.buffMoveAnchor:SetBackdropBorderColor(0.2, 0.9, 0.5, 1)

    S.buffMoveAnchor.text = S.buffMoveAnchor:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    S.buffMoveAnchor.text:SetPoint("CENTER", S.buffMoveAnchor, "CENTER", 0, 0)
    S.buffMoveAnchor.text:SetText("AuraBars Buffs: clique e arraste")
    S.buffMoveAnchor:EnableMouse(true)
    S.buffMoveAnchor:RegisterForDrag("LeftButton")

    S.buffMoveAnchor:SetScript("OnDragStart", function()
        if AuraBarsDB and AuraBarsDB.unlocked then
            S.buffRoot:StartMoving()
        end
    end)

    S.buffMoveAnchor:SetScript("OnDragStop", function()
        S.buffRoot:StopMovingOrSizing()
        -- '_' descarta os 3 primeiros retornos de GetPoint (point, relativeTo, relativePoint); usamos apenas x e y.
        local _, _, _, x, y = S.buffRoot:GetPoint(1)
        if x and y then
            AuraBarsDB.buffX = x
            AuraBarsDB.buffY = y
        end
    end)

    S.buffMoveAnchor:Hide()

    S.buffsHeader = CreateFrame("Frame", nil, S.buffRoot)
    S.buffsHeader:SetSize(A.CONFIG.width, (A.CONFIG.maxBuffs * A.CONFIG.height) + ((A.CONFIG.maxBuffs - 1) * A.CONFIG.spacing))
    S.buffsHeader:SetPoint("TOPLEFT", S.buffRoot, "TOPLEFT", 0, 0)

    S.debuffRoot = CreateFrame("Frame", "AuraBarsDebuffRoot", UIParent, "BackdropTemplate")
    S.debuffRoot:SetSize(A.CONFIG.width, 1)
    S.debuffRoot:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", AuraBarsDB.debuffX, AuraBarsDB.debuffY)
    S.debuffRoot:SetClampedToScreen(true)
    S.debuffRoot:SetMovable(false)
    S.debuffRoot:EnableMouse(false)
    S.debuffRoot:RegisterForDrag("LeftButton")

    S.debuffRoot:SetScript("OnDragStart", function(self)
        if AuraBarsDB and AuraBarsDB.unlocked then
            self:StartMoving()
        end
    end)

    S.debuffRoot:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        -- '_' descarta os 3 primeiros retornos de GetPoint (point, relativeTo, relativePoint); usamos apenas x e y.
        local _, _, _, x, y = self:GetPoint(1)
        if x and y then
            AuraBarsDB.debuffX = x
            AuraBarsDB.debuffY = y
        end
    end)

    S.debuffMoveAnchor = CreateFrame("Button", nil, S.debuffRoot, "BackdropTemplate")
    S.debuffMoveAnchor:SetSize(A.CONFIG.width, 20)
    S.debuffMoveAnchor:SetPoint("BOTTOMLEFT", S.debuffRoot, "TOPLEFT", 0, 6)
    S.debuffMoveAnchor:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 12,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    S.debuffMoveAnchor:SetBackdropColor(0.5, 0.15, 0.15, 0.8)
    S.debuffMoveAnchor:SetBackdropBorderColor(0.95, 0.45, 0.45, 1)

    S.debuffMoveAnchor.text = S.debuffMoveAnchor:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    S.debuffMoveAnchor.text:SetPoint("CENTER", S.debuffMoveAnchor, "CENTER", 0, 0)
    S.debuffMoveAnchor.text:SetText("AuraBars Debuffs: clique e arraste")
    S.debuffMoveAnchor:EnableMouse(true)
    S.debuffMoveAnchor:RegisterForDrag("LeftButton")

    S.debuffMoveAnchor:SetScript("OnDragStart", function()
        if AuraBarsDB and AuraBarsDB.unlocked then
            S.debuffRoot:StartMoving()
        end
    end)

    S.debuffMoveAnchor:SetScript("OnDragStop", function()
        S.debuffRoot:StopMovingOrSizing()
        -- '_' descarta os 3 primeiros retornos de GetPoint (point, relativeTo, relativePoint); usamos apenas x e y.
        local _, _, _, x, y = S.debuffRoot:GetPoint(1)
        if x and y then
            AuraBarsDB.debuffX = x
            AuraBarsDB.debuffY = y
        end
    end)

    S.debuffMoveAnchor:Hide()

    S.debuffsHeader = CreateFrame("Frame", nil, S.debuffRoot)
    S.debuffsHeader:SetSize(A.CONFIG.width, (A.CONFIG.maxDebuffs * A.CONFIG.height) + ((A.CONFIG.maxDebuffs - 1) * A.CONFIG.spacing))
    S.debuffsHeader:SetPoint("TOPLEFT", S.debuffRoot, "TOPLEFT", 0, 0)
end

-- Cria botão no minimapa para abrir rapidamente o painel de opções.
function A.CreateMinimapButton()
    if S.minimapButton or not Minimap then
        return
    end

    local button = CreateFrame("Button", "AuraBarsMinimapButton", Minimap)
    button:SetSize(31, 31)
    button:SetFrameStrata("MEDIUM")
    button:SetPoint("TOPLEFT", Minimap, "TOPLEFT", 2, -2)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    local background = button:CreateTexture(nil, "BACKGROUND")
    background:SetTexture("Interface\\Minimap\\MiniMap-TrackingBackground")
    background:SetAllPoints()

    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetTexture("Interface\\Icons\\INV_Misc_PocketWatch_01")
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    icon:SetSize(18, 18)
    icon:SetPoint("CENTER", button, "CENTER", 0, 1)

    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetSize(53, 53)
    border:SetPoint("TOPLEFT")
    border:SetBlendMode("ADD")

    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("AuraBars")
        GameTooltip:AddLine("Clique para abrir as opções", 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)

    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    button:SetScript("OnClick", function()
        A.OpenOptionsPanel()
    end)

    S.minimapButton = button
end
