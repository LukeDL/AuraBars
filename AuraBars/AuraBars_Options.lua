local A = AuraBarsAddon
local S = A.state

local TEXTURE_PICKER_VISIBLE_ROWS = 15
local TEXTURE_PICKER_ROW_HEIGHT = 20

-- Cria raiz rolável para o painel de opções para evitar overflow em listas maiores.
local function CreateScrollableOptionsRoot(panel)
    local scrollFrame = CreateFrame("ScrollFrame", "AuraBarsOptionsScrollFrame", panel, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", panel, "TOPLEFT", 8, -42)
    scrollFrame:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -28, 8)

    local content = CreateFrame("Frame", "AuraBarsOptionsScrollContent", scrollFrame)
    content:SetSize(1, 1040)
    scrollFrame:SetScrollChild(content)

    return content
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
        local categoryID = S.optionsCategory.ID
        if type(categoryID) == "number" then
            Settings.OpenToCategory(categoryID)
            return
        end
    end

    if InterfaceOptionsFrame_OpenToCategory then
        InterfaceOptionsFrame_OpenToCategory("AuraBars")
        InterfaceOptionsFrame_OpenToCategory("AuraBars")
    end
end

-- Recarrega o dropdown de textura e o preview com base no catálogo atual.
function A.RefreshTextureDropdownUI()
    local picker = S.texturePicker

    if not picker then
        return
    end

    local textures = A.RebuildTextureRegistry()
    picker.textures = textures

    local maxOffset = math.max(#textures - TEXTURE_PICKER_VISIBLE_ROWS, 0)
    local offset = picker.offset or 0
    picker.offset = math.max(0, math.min(offset, maxOffset))

    local scrollBar = picker.scrollBar
    if scrollBar then
        scrollBar:SetMinMaxValues(0, maxOffset)
        scrollBar:SetValueStep(1)
        scrollBar:SetValue(picker.offset)
        scrollBar:Show()
        if maxOffset == 0 then
            scrollBar:Hide()
        end
    end

    local activeTexture = A.GetTextureByKey(AuraBarsDB.texture)
    if picker.selectedText then
        picker.selectedText:SetText("Selecionada: " .. activeTexture.label)
    end

    for rowIndex = 1, TEXTURE_PICKER_VISIBLE_ROWS do
        local textureIndex = picker.offset + rowIndex
        local row = picker.rows and picker.rows[rowIndex]
        local texture = textures[textureIndex]

        if row then
            if texture then
                row.texture = texture
                row.swatch:SetTexture(texture.path)
                row.text:SetText(texture.label)
                row.check:SetText(texture.key == AuraBarsDB.texture and "✓" or "")
                row:Show()
            else
                row.texture = nil
                row:Hide()
            end
        end
    end
end

-- Monta e registra o painel de opções do addon na interface do jogo.
function A.CreateOptionsPanel()
    local panel = CreateFrame("Frame", "AuraBarsOptionsPanel")
    panel.name = "AuraBars"

    local content = CreateScrollableOptionsRoot(panel)

    local title = content:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", content, "TOPLEFT", 8, -8)
    title:SetText("AuraBars")

    local subtitle = content:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    subtitle:SetText("Configurações das barras de buffs/debuffs")

    local lockCheck = CreateFrame("CheckButton", "AuraBarsOptionsLockCheck", content, "InterfaceOptionsCheckButtonTemplate")
    lockCheck:SetPoint("TOPLEFT", subtitle, "BOTTOMLEFT", 0, -16)
    lockCheck.Text:SetText("Travar frame (desmarque para arrastar)")
    lockCheck:SetScript("OnClick", function(self)
        A.SetUnlocked(not self:GetChecked())
    end)

    A.CreateLabel(content, "Escala", "TOPLEFT", 16, -110)
    local scaleSlider = CreateFrame("Slider", "AuraBarsOptionsScaleSlider", content, "OptionsSliderTemplate")
    scaleSlider:SetPoint("TOPLEFT", 16, -130)
    scaleSlider:SetWidth(260)
    scaleSlider:SetMinMaxValues(0.5, 2.0)
    scaleSlider:SetValueStep(0.05)
    scaleSlider.Low:SetText("0.5")
    scaleSlider.High:SetText("2.0")
    scaleSlider.Text:SetText("Escala")

    local scaleValue = content:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    scaleValue:SetPoint("LEFT", scaleSlider, "RIGHT", 12, 0)
    scaleSlider:SetScript("OnValueChanged", function(_, value)
        A.SetScale(value)
        scaleValue:SetText(string.format("%.2f", AuraBarsDB.scale))
    end)

    A.CreateLabel(content, "Barras de Buff", "TOPLEFT", 16, -190)
    local buffSlider = CreateFrame("Slider", "AuraBarsOptionsBuffSlider", content, "OptionsSliderTemplate")
    buffSlider:SetPoint("TOPLEFT", 16, -210)
    buffSlider:SetWidth(260)
    buffSlider:SetMinMaxValues(1, 40)
    buffSlider:SetValueStep(1)
    buffSlider.Low:SetText("1")
    buffSlider.High:SetText("40")
    buffSlider.Text:SetText("Quantidade de Buffs")

    local buffValue = content:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    buffValue:SetPoint("LEFT", buffSlider, "RIGHT", 12, 0)
    buffSlider:SetScript("OnValueChanged", function(_, value)
        A.SetMaxBuffs(value)
        buffValue:SetText(tostring(AuraBarsDB.maxBuffs))
    end)

    A.CreateLabel(content, "Barras de Debuff", "TOPLEFT", 16, -270)
    local debuffSlider = CreateFrame("Slider", "AuraBarsOptionsDebuffSlider", content, "OptionsSliderTemplate")
    debuffSlider:SetPoint("TOPLEFT", 16, -290)
    debuffSlider:SetWidth(260)
    debuffSlider:SetMinMaxValues(1, 40)
    debuffSlider:SetValueStep(1)
    debuffSlider.Low:SetText("1")
    debuffSlider.High:SetText("40")
    debuffSlider.Text:SetText("Quantidade de Debuffs")

    local debuffValue = content:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    debuffValue:SetPoint("LEFT", debuffSlider, "RIGHT", 12, 0)
    debuffSlider:SetScript("OnValueChanged", function(_, value)
        A.SetMaxDebuffs(value)
        debuffValue:SetText(tostring(AuraBarsDB.maxDebuffs))
    end)

    local textureLabel = A.CreateLabel(content, "Textura da barra", "TOPLEFT", 16, -350)
    textureLabel:SetText("Textura da barra")

    local texturePicker = CreateFrame("Frame", "AuraBarsOptionsTexturePicker", content, "BackdropTemplate")
    texturePicker:SetPoint("TOPLEFT", 16, -372)
    texturePicker:SetSize(260, (TEXTURE_PICKER_VISIBLE_ROWS * TEXTURE_PICKER_ROW_HEIGHT) + 8)
    texturePicker:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 12,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    texturePicker:SetBackdropColor(0.05, 0.05, 0.05, 0.8)
    texturePicker:SetBackdropBorderColor(0.35, 0.35, 0.35, 1)
    texturePicker:EnableMouseWheel(true)

    local pickerScrollFrame = CreateFrame("ScrollFrame", "AuraBarsTexturePickerScrollFrame", texturePicker, "UIPanelScrollFrameTemplate")
    pickerScrollFrame:SetPoint("TOPLEFT", texturePicker, "TOPLEFT", 4, -4)
    pickerScrollFrame:SetPoint("BOTTOMRIGHT", texturePicker, "BOTTOMRIGHT", -26, 4)

    local pickerContent = CreateFrame("Frame", nil, pickerScrollFrame)
    pickerContent:SetSize(230, TEXTURE_PICKER_VISIBLE_ROWS * TEXTURE_PICKER_ROW_HEIGHT)
    pickerScrollFrame:SetScrollChild(pickerContent)

    local pickerScrollBar = _G[pickerScrollFrame:GetName() .. "ScrollBar"]
    pickerScrollBar:SetMinMaxValues(0, 0)
    pickerScrollBar:SetValueStep(1)

    texturePicker.rows = {}
    texturePicker.scrollBar = pickerScrollBar
    texturePicker.offset = 0

    local function SetTexturePickerOffset(value)
        local textures = texturePicker.textures or {}
        local maxOffset = math.max(#textures - TEXTURE_PICKER_VISIBLE_ROWS, 0)
        local nextOffset = math.floor(value or 0)
        nextOffset = math.max(0, math.min(nextOffset, maxOffset))

        if nextOffset == texturePicker.offset then
            return
        end

        texturePicker.offset = nextOffset
        A.RefreshTextureDropdownUI()
    end

    pickerScrollBar:SetScript("OnValueChanged", function(_, value)
        SetTexturePickerOffset(value)
    end)

    texturePicker:SetScript("OnMouseWheel", function(_, delta)
        local normalizedDelta = 0
        if delta > 0 then
            normalizedDelta = 1
        elseif delta < 0 then
            normalizedDelta = -1
        end

        SetTexturePickerOffset(texturePicker.offset - normalizedDelta)
        pickerScrollBar:SetValue(texturePicker.offset)
    end)

    for rowIndex = 1, TEXTURE_PICKER_VISIBLE_ROWS do
        local row = CreateFrame("Button", nil, pickerContent, "BackdropTemplate")
        row:SetPoint("TOPLEFT", pickerContent, "TOPLEFT", 0, -((rowIndex - 1) * TEXTURE_PICKER_ROW_HEIGHT))
        row:SetSize(230, TEXTURE_PICKER_ROW_HEIGHT)
        row:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
        })
        row:SetBackdropColor(1, 1, 1, 0.03)

        row.swatch = row:CreateTexture(nil, "ARTWORK")
        row.swatch:SetSize(120, 12)
        row.swatch:SetPoint("LEFT", row, "LEFT", 4, 0)

        row.text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.text:SetPoint("LEFT", row.swatch, "RIGHT", 8, 0)
        row.text:SetPoint("RIGHT", row, "RIGHT", -20, 0)
        row.text:SetJustifyH("LEFT")

        row.check = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        row.check:SetPoint("RIGHT", row, "RIGHT", -6, 0)

        row:SetScript("OnEnter", function(self)
            self:SetBackdropColor(1, 1, 1, 0.10)
        end)

        row:SetScript("OnLeave", function(self)
            self:SetBackdropColor(1, 1, 1, 0.03)
        end)

        row:SetScript("OnClick", function(self)
            if not self.texture then
                return
            end

            A.SetTexture(self.texture.key)
            A.RefreshTextureDropdownUI()
        end)

        texturePicker.rows[rowIndex] = row
    end

    texturePicker.selectedText = content:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    texturePicker.selectedText:SetPoint("TOPLEFT", texturePicker, "BOTTOMLEFT", 2, -6)
    texturePicker.selectedText:SetText("Selecionada: -")

    S.texturePicker = texturePicker

    local privateColorLabel = A.CreateLabel(content, "Cor da borda (Private Aura)", "TOPLEFT", 16, -710)
    privateColorLabel:SetText("Cor da borda (Private Aura)")

    local privateColorDropdown = CreateFrame("Frame", "AuraBarsOptionsPrivateBorderColorDropdown", content, "UIDropDownMenuTemplate")
    privateColorDropdown:SetPoint("TOPLEFT", 0, -726)

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

    A.CreateLabel(content, "Espessura da borda", "TOPLEFT", 16, -788)
    local privateThicknessSlider = CreateFrame("Slider", "AuraBarsOptionsPrivateBorderThicknessSlider", content, "OptionsSliderTemplate")
    privateThicknessSlider:SetPoint("TOPLEFT", 16, -808)
    privateThicknessSlider:SetWidth(260)
    privateThicknessSlider:SetMinMaxValues(4, 24)
    privateThicknessSlider:SetValueStep(1)
    privateThicknessSlider.Low:SetText("4")
    privateThicknessSlider.High:SetText("24")
    privateThicknessSlider.Text:SetText("Espessura")

    local privateThicknessValue = content:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    privateThicknessValue:SetPoint("LEFT", privateThicknessSlider, "RIGHT", 12, 0)
    privateThicknessSlider:SetScript("OnValueChanged", function(_, value)
        A.SetPrivateBorderThickness(value)
        privateThicknessValue:SetText(tostring(AuraBarsDB.privateBorderThickness))
    end)

    local resetButton = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    resetButton:SetPoint("TOPLEFT", 16, -860)
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

        A.RefreshTextureDropdownUI()

        local activePrivateColor = A.GetPrivateBorderColorByKey(AuraBarsDB.privateBorderColor)
        UIDropDownMenu_SetSelectedValue(privateColorDropdown, activePrivateColor.key)
        UIDropDownMenu_SetText(privateColorDropdown, activePrivateColor.label)
        privateThicknessSlider:SetValue(AuraBarsDB.privateBorderThickness)
        privateThicknessValue:SetText(tostring(AuraBarsDB.privateBorderThickness))
    end

    panel:SetScript("OnShow", function(self)
        A.RefreshTextureDropdownUI()
        self:Refresh()
    end)

    if Settings and Settings.RegisterCanvasLayoutCategory then
        local category = Settings.RegisterCanvasLayoutCategory(panel, "AuraBars")
        Settings.RegisterAddOnCategory(category)
        S.optionsCategory = category
    elseif InterfaceOptions_AddCategory then
        InterfaceOptions_AddCategory(panel)
        S.optionsCategory = panel
    end
end
