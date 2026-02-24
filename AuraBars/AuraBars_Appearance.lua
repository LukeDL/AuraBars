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
    if not S.buffMoveAnchor or not S.debuffMoveAnchor then
        return
    end

    if AuraBarsDB.unlocked then
        S.buffMoveAnchor:Show()
        S.debuffMoveAnchor:Show()
    else
        S.buffMoveAnchor:Hide()
        S.debuffMoveAnchor:Hide()
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

-- Helper para criar labels no painel de opções com âncora e texto.
function A.CreateLabel(parent, text, anchor, x, y)
    local label = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    label:SetPoint(anchor, parent, anchor, x, y)
    label:SetText(text)
    return label
end

-- Abre o painel de opções em APIs novas ou legadas do WoW.
function A.OpenOptionsPanel()
    if Settings and Settings.OpenToCategory and S.optionsCategory then
        Settings.OpenToCategory(S.optionsCategory.ID)
        return
    end

    if InterfaceOptionsFrame_OpenToCategory then
        InterfaceOptionsFrame_OpenToCategory("AuraBars")
        InterfaceOptionsFrame_OpenToCategory("AuraBars")
    end
end

-- Monta e registra o painel de opções do addon na interface do jogo.
function A.CreateOptionsPanel()
    local panel = CreateFrame("Frame", "AuraBarsOptionsPanel")
    panel.name = "AuraBars"

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("AuraBars")

    local subtitle = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    subtitle:SetText("Configurações das barras de buffs/debuffs")

    local lockCheck = CreateFrame("CheckButton", "AuraBarsOptionsLockCheck", panel, "InterfaceOptionsCheckButtonTemplate")
    lockCheck:SetPoint("TOPLEFT", subtitle, "BOTTOMLEFT", 0, -16)
    lockCheck.Text:SetText("Travar frame (desmarque para arrastar)")
    lockCheck:SetScript("OnClick", function(self)
        A.SetUnlocked(not self:GetChecked())
    end)

    A.CreateLabel(panel, "Escala", "TOPLEFT", 16, -110)
    local scaleSlider = CreateFrame("Slider", "AuraBarsOptionsScaleSlider", panel, "OptionsSliderTemplate")
    scaleSlider:SetPoint("TOPLEFT", 16, -130)
    scaleSlider:SetWidth(260)
    scaleSlider:SetMinMaxValues(0.5, 2.0)
    scaleSlider:SetValueStep(0.05)
    scaleSlider.Low:SetText("0.5")
    scaleSlider.High:SetText("2.0")
    scaleSlider.Text:SetText("Escala")

    local scaleValue = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    scaleValue:SetPoint("LEFT", scaleSlider, "RIGHT", 12, 0)
    scaleSlider:SetScript("OnValueChanged", function(_, value)
        A.SetScale(value)
        scaleValue:SetText(string.format("%.2f", AuraBarsDB.scale))
    end)

    A.CreateLabel(panel, "Barras de Buff", "TOPLEFT", 16, -190)
    local buffSlider = CreateFrame("Slider", "AuraBarsOptionsBuffSlider", panel, "OptionsSliderTemplate")
    buffSlider:SetPoint("TOPLEFT", 16, -210)
    buffSlider:SetWidth(260)
    buffSlider:SetMinMaxValues(1, 40)
    buffSlider:SetValueStep(1)
    buffSlider.Low:SetText("1")
    buffSlider.High:SetText("40")
    buffSlider.Text:SetText("Quantidade de Buffs")

    local buffValue = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    buffValue:SetPoint("LEFT", buffSlider, "RIGHT", 12, 0)
    buffSlider:SetScript("OnValueChanged", function(_, value)
        A.SetMaxBuffs(value)
        buffValue:SetText(tostring(AuraBarsDB.maxBuffs))
    end)

    A.CreateLabel(panel, "Barras de Debuff", "TOPLEFT", 16, -270)
    local debuffSlider = CreateFrame("Slider", "AuraBarsOptionsDebuffSlider", panel, "OptionsSliderTemplate")
    debuffSlider:SetPoint("TOPLEFT", 16, -290)
    debuffSlider:SetWidth(260)
    debuffSlider:SetMinMaxValues(1, 40)
    debuffSlider:SetValueStep(1)
    debuffSlider.Low:SetText("1")
    debuffSlider.High:SetText("40")
    debuffSlider.Text:SetText("Quantidade de Debuffs")

    local debuffValue = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    debuffValue:SetPoint("LEFT", debuffSlider, "RIGHT", 12, 0)
    debuffSlider:SetScript("OnValueChanged", function(_, value)
        A.SetMaxDebuffs(value)
        debuffValue:SetText(tostring(AuraBarsDB.maxDebuffs))
    end)

    local textureLabel = A.CreateLabel(panel, "Textura da barra", "TOPLEFT", 16, -350)
    textureLabel:SetText("Textura da barra")

    local textureDropdown = CreateFrame("Frame", "AuraBarsOptionsTextureDropdown", panel, "UIDropDownMenuTemplate")
    textureDropdown:SetPoint("TOPLEFT", 0, -366)

    UIDropDownMenu_SetWidth(textureDropdown, 220)
    UIDropDownMenu_Initialize(textureDropdown, function(_, level)
        if level ~= 1 then
            return
        end

        for i = 1, #A.BAR_TEXTURES do
            local texture = A.BAR_TEXTURES[i]
            local info = UIDropDownMenu_CreateInfo()
            info.text = texture.label .. " (" .. texture.key .. ")"
            info.checked = AuraBarsDB.texture == texture.key
            info.func = function()
                A.SetTexture(texture.key)
                UIDropDownMenu_SetSelectedValue(textureDropdown, texture.key)
                UIDropDownMenu_SetText(textureDropdown, texture.label)
            end
            info.value = texture.key
            UIDropDownMenu_AddButton(info, level)
        end
    end)

    local privateColorLabel = A.CreateLabel(panel, "Cor da borda (Private Aura)", "TOPLEFT", 16, -430)
    privateColorLabel:SetText("Cor da borda (Private Aura)")

    local privateColorDropdown = CreateFrame("Frame", "AuraBarsOptionsPrivateBorderColorDropdown", panel, "UIDropDownMenuTemplate")
    privateColorDropdown:SetPoint("TOPLEFT", 0, -446)

    UIDropDownMenu_SetWidth(privateColorDropdown, 220)
    UIDropDownMenu_Initialize(privateColorDropdown, function(_, level)
        if level ~= 1 then
            return
        end

        for i = 1, #A.PRIVATE_BORDER_COLORS do
            local color = A.PRIVATE_BORDER_COLORS[i]
            local info = UIDropDownMenu_CreateInfo()
            info.text = color.label .. " (" .. color.key .. ")"
            info.checked = AuraBarsDB.privateBorderColor == color.key
            info.func = function()
                A.SetPrivateBorderColor(color.key)
                UIDropDownMenu_SetSelectedValue(privateColorDropdown, color.key)
                UIDropDownMenu_SetText(privateColorDropdown, color.label)
            end
            info.value = color.key
            UIDropDownMenu_AddButton(info, level)
        end
    end)

    A.CreateLabel(panel, "Espessura da borda", "TOPLEFT", 16, -508)
    local privateThicknessSlider = CreateFrame("Slider", "AuraBarsOptionsPrivateBorderThicknessSlider", panel, "OptionsSliderTemplate")
    privateThicknessSlider:SetPoint("TOPLEFT", 16, -528)
    privateThicknessSlider:SetWidth(260)
    privateThicknessSlider:SetMinMaxValues(4, 24)
    privateThicknessSlider:SetValueStep(1)
    privateThicknessSlider.Low:SetText("4")
    privateThicknessSlider.High:SetText("24")
    privateThicknessSlider.Text:SetText("Espessura")

    local privateThicknessValue = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    privateThicknessValue:SetPoint("LEFT", privateThicknessSlider, "RIGHT", 12, 0)
    privateThicknessSlider:SetScript("OnValueChanged", function(_, value)
        A.SetPrivateBorderThickness(value)
        privateThicknessValue:SetText(tostring(AuraBarsDB.privateBorderThickness))
    end)

    local resetButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    resetButton:SetPoint("TOPLEFT", 16, -580)
    resetButton:SetSize(120, 24)
    resetButton:SetText("Restaurar")
    resetButton:SetScript("OnClick", function()
        A.ResetSettings()
        panel:Refresh()
    end)

    -- Recarrega valores atuais do perfil para controles da interface.
    function panel:Refresh()
        lockCheck:SetChecked(not AuraBarsDB.unlocked)
        scaleSlider:SetValue(AuraBarsDB.scale)
        buffSlider:SetValue(AuraBarsDB.maxBuffs)
        debuffSlider:SetValue(AuraBarsDB.maxDebuffs)
        scaleValue:SetText(string.format("%.2f", AuraBarsDB.scale))
        buffValue:SetText(tostring(AuraBarsDB.maxBuffs))
        debuffValue:SetText(tostring(AuraBarsDB.maxDebuffs))

        local activeTexture = A.GetTextureByKey(AuraBarsDB.texture)
        UIDropDownMenu_SetSelectedValue(textureDropdown, activeTexture.key)
        UIDropDownMenu_SetText(textureDropdown, activeTexture.label)

        local activePrivateColor = A.GetPrivateBorderColorByKey(AuraBarsDB.privateBorderColor)
        UIDropDownMenu_SetSelectedValue(privateColorDropdown, activePrivateColor.key)
        UIDropDownMenu_SetText(privateColorDropdown, activePrivateColor.label)
        privateThicknessSlider:SetValue(AuraBarsDB.privateBorderThickness)
        privateThicknessValue:SetText(tostring(AuraBarsDB.privateBorderThickness))
    end

    panel:SetScript("OnShow", function(self)
        self:Refresh()
    end)

    if Settings and Settings.RegisterCanvasLayoutCategory then
        local category = Settings.RegisterCanvasLayoutCategory(panel, "AuraBars")
        category.ID = "AuraBars"
        Settings.RegisterAddOnCategory(category)
        S.optionsCategory = category
    elseif InterfaceOptions_AddCategory then
        InterfaceOptions_AddCategory(panel)
        S.optionsCategory = panel
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
