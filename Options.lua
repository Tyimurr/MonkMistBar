local addonName, MMB = ...
local LSM = LibStub("LibSharedMedia-3.0")
local lsfdd = LibStub("LibSFDropDown-1.5")
local categoryObj
local optionFrames = {}

-- 1. FRAME PICKER LOGIC
local function IsBlocked(n)
    if not n then return true end
    local list = {"TimerTracker", "GlobalFX", "MotionSickness", "ContainerFrame", "UIWidget", "UIParent", "WorldFrame", "MainMenuBar", "GhostFrame", "MonkMistBarPicker", "MonkMistBarFrame"}
    for _, b in ipairs(list) do if n:find(b) then return true end end
    return false
end

local function ScanForFrameUnderMouse()
    local candidates = {}
    local function DeepScan(f, depth)
        if not f or depth > 8 then return end
        local success, name = pcall(function()
            if f:IsForbidden() or f.isNamePlate then return nil end
            local n = f:GetName()
            if n and f:IsVisible() and MouseIsOver(f) then
                if not IsBlocked(n) and not n:find("^1") then return n end
            end
        end)
        if success and name then table.insert(candidates, {name = name, level = f:GetFrameLevel() or 0}) end
        local ok, children = pcall(function() return {f:GetChildren()} end)
        if ok and children then for _, child in ipairs(children) do DeepScan(child, depth + 1) end end
    end
    DeepScan(UIParent, 0)
    table.sort(candidates, function(a, b) return a.level > b.level end)
    return #candidates > 0 and candidates[1].name or nil
end

local function StartFramePicker(callback)
    if SettingsPanel then SettingsPanel:Hide() end
    if MonkMistBarOptions then MonkMistBarOptions:Hide() end
    local picker = CreateFrame("Button", "MonkMistBarPicker", UIParent)
    picker:SetAllPoints(); picker:SetFrameStrata("TOOLTIP"); picker:EnableMouse(true); SetCursor("CAST_CURSOR")
    picker:SetScript("OnClick", function(self)
        local found = ScanForFrameUnderMouse()
        if found then _G.MonkMistBarDB.customAnchorName = found; _G.MonkMistBarDB.anchorTo = "Custom" end
        ResetCursor(); self:Hide()
        if categoryObj then Settings.OpenToCategory(categoryObj.ID) end
        if callback then callback() end
    end)
    picker:Show()
end

-- 2. UI HELPERS
local function SetDDText(dd, text)
    if not dd then return end
    if dd.SetText then dd:SetText(text) end
    if dd.Text then dd.Text:SetText(text) end
end

local function RefreshOptionsUI()
    for dbKey, frame in pairs(optionFrames) do
        local val = _G.MonkMistBarDB[dbKey]
        if val ~= nil and frame.slider then
            local isAlpha = (dbKey:find("Alpha") or dbKey == "alpha")
            local displayVal = isAlpha and (val * 100) or val
            frame.slider:SetValue(displayVal)
            if frame.eb then frame.eb:SetText(tostring(math.floor(displayVal))) end
        end
    end
end

local function UpdateWidthSliderState(autoCB, widthSlider)
    local isAuto = autoCB:GetChecked() and _G.MonkMistBarDB.anchorTo ~= "Manual"
    widthSlider.slider:SetEnabled(not isAuto)
    widthSlider:SetAlpha(isAuto and 0.4 or 1.0)
    widthSlider.eb:SetEnabled(not isAuto)
end

local function CreateSection(panel, text, anchor, y)
    local sec = CreateFrame("Frame", nil, panel)
    sec:SetSize(580, 30); sec:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, y or -25)
    local t = sec:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    t:SetPoint("BOTTOMLEFT", sec, "BOTTOMLEFT", 5, 7); t:SetText(text)
    local line = sec:CreateTexture(nil, "ARTWORK")
    line:SetColorTexture(1, 1, 1, 0.2); line:SetPoint("TOPLEFT", t, "BOTTOMLEFT", -5, -2); line:SetPoint("TOPRIGHT", sec, "BOTTOMRIGHT", 0, -2); line:SetHeight(1)
    return sec
end

local function AddSlider(panel, label, min, max, dbKey, anchor, x, y, customWidth)
    local frame = CreateFrame("Frame", nil, panel, "MMB_SliderTemplate")
    frame:SetSize(customWidth or 580, 45); frame:SetPoint("TOPLEFT", anchor, (x == 0) and "BOTTOMLEFT" or "TOPLEFT", x or 0, y or -30)
    frame.slider.label:SetText(label); frame.slider:SetMinMaxValues(min, max); frame.box.val:Hide()
    local eb = CreateFrame("EditBox", nil, frame.box)
    eb:SetAllPoints(); eb:SetFontObject("GameFontHighlightSmall"); eb:SetJustifyH("CENTER"); eb:SetAutoFocus(false)
    frame.eb = eb
    local isAlpha = (dbKey:find("Alpha") or dbKey == "alpha")
    eb:SetScript("OnEnterPressed", function(self)
        local n = tonumber(self:GetText())
        if n then n = math.max(min, math.min(max, n)); frame.slider:SetValue(n); _G.MonkMistBarDB[dbKey] = isAlpha and (n/100) or n; MMB.ApplySettings() end
        self:ClearFocus()
    end)
    frame.slider:SetScript("OnValueChanged", function(self, value)
        local v = math.floor(value); eb:SetText(tostring(v)); _G.MonkMistBarDB[dbKey] = isAlpha and (v/100) or v; MMB.ApplySettings()
    end)
    optionFrames[dbKey] = frame
    return frame
end

local function CreateColorButton(panel, labelText, dbKey, anchor, x, y)
    local label = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    label:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", x or 0, y or -20); label:SetText(labelText)
    local btn = CreateFrame("Button", nil, panel, "MMB_BoxTemplate")
    btn:SetSize(22, 18); btn:SetPoint("LEFT", label, "RIGHT", 10, 0)
    btn.tex = btn:CreateTexture(nil, "ARTWORK"); btn.tex:SetAllPoints(); btn.tex:SetPoint("TOPLEFT", 1, -1); btn.tex:SetPoint("BOTTOMRIGHT", -1, 1)
    btn:SetScript("OnShow", function(self) 
        local c = _G.MonkMistBarDB[dbKey] or {r=1, g=1, b=1}
        self.tex:SetColorTexture(c.r or 1, c.g or 1, c.b or 1, 1) 
    end)
    btn:SetScript("OnClick", function()
        ColorPickerFrame:SetupColorPickerAndShow({
            swatchFunc = function() 
                local r, g, b = ColorPickerFrame:GetColorRGB()
                _G.MonkMistBarDB[dbKey].r, _G.MonkMistBarDB[dbKey].g, _G.MonkMistBarDB[dbKey].b = r, g, b
                btn.tex:SetColorTexture(r, g, b); MMB.ApplySettings() 
            end,
            r = _G.MonkMistBarDB[dbKey].r or 1, g = _G.MonkMistBarDB[dbKey].g or 1, b = _G.MonkMistBarDB[dbKey].b or 1
        })
    end)
    return label
end

-- 3. OPTIONS PANEL CREATION
local function CreateOptionsPanel()
    local panel = CreateFrame("Frame", "MonkMistBarOptions", UIParent)
    local scrollFrame = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 8, -8); scrollFrame:SetPoint("BOTTOMRIGHT", -28, 8)
    local scrollChild = CreateFrame("Frame"); scrollChild:SetSize(580, 1100); scrollFrame:SetScrollChild(scrollChild)
    local title = scrollChild:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 10, -10); title:SetText("MonkMistBar")

    local anchorDD, autoCB, texDD, bgTexDD, borDD, showBorCB, wS

    local function UpdateAutoWidthState()
        local db = _G.MonkMistBarDB
        local isManual = (db.anchorTo == "Manual")
        
        if isManual then
            autoCB:SetChecked(false)
            autoCB:Disable()
            autoCB:SetAlpha(0.5)
            autoCB.Text:SetTextColor(0.5, 0.5, 0.5)
        else
            autoCB:Enable()
            autoCB:SetAlpha(1.0)
            autoCB.Text:SetTextColor(1, 0.82, 0)
            local state = db.autoWidthSettings[db.anchorTo]
            if state == nil then state = true end 
            autoCB:SetChecked(state)
        end
        UpdateWidthSliderState(autoCB, wS)
    end

    local resetBtn = CreateFrame("Button", nil, scrollChild, "UIPanelButtonTemplate")
    resetBtn:SetSize(160, 22); resetBtn:SetPoint("TOPRIGHT", scrollChild, "TOPRIGHT", -10, -10)
    resetBtn:SetText("Reset to Default")
    resetBtn:SetScript("OnClick", function()
        _G.MonkMistBarDB = nil
        MMB.InitDB()
        MMB.ApplySettings()
        local db = _G.MonkMistBarDB
        SetDDText(anchorDD, db.anchorTo)
        SetDDText(texDD, "Bar: "..db.texture)
        SetDDText(bgTexDD, "Background: "..db.bgTexture)
        SetDDText(borDD, "Border: "..db.borderTexture)
        
        UpdateAutoWidthState()
        showBorCB:SetChecked(db.showBorder)
        RefreshOptionsUI()
    end)

    -- SECTION: POSITION
    local secPos = CreateSection(scrollChild, "Position & Anchoring", title, -15)
    anchorDD = lsfdd:CreateModernButton(scrollChild, 240, 26)
    anchorDD:SetPoint("TOPLEFT", secPos, "BOTTOMLEFT", 0, -15)
    autoCB = CreateFrame("CheckButton", nil, scrollChild, "MMB_CheckButtonTemplate")
    autoCB:SetPoint("TOPLEFT", anchorDD, "BOTTOMLEFT", 0, -10); autoCB.Text:SetText("Adjust width automatically to anchor")

    wS = AddSlider(scrollChild, "Width (Manual)", 50, 600, "width", autoCB, 0, -35, 280)

    anchorDD:ddSetInitFunc(function(self)
        self:ddAddButton({ text = "Manual", checked = function() return _G.MonkMistBarDB.anchorTo == "Manual" end, func = function() _G.MonkMistBarDB.anchorTo = "Manual"; SetDDText(anchorDD, "Manual"); UpdateAutoWidthState(); MMB.ApplySettings() end })
        local presets = {"Actionbar", "CooldownManager"}
        for _, name in ipairs(presets) do
            self:ddAddButton({ text = name, checked = function() return _G.MonkMistBarDB.anchorTo == name end, func = function() _G.MonkMistBarDB.anchorTo = name; SetDDText(anchorDD, name); UpdateAutoWidthState(); MMB.ApplySettings() end })
        end
        if _G.MonkMistBarDB.customAnchorName then
            self:ddAddButton({ text = "Focus: " .. _G.MonkMistBarDB.customAnchorName, checked = function() return _G.MonkMistBarDB.anchorTo == "Custom" end, func = function() _G.MonkMistBarDB.anchorTo = "Custom"; SetDDText(anchorDD, "Focus: " .. _G.MonkMistBarDB.customAnchorName); UpdateAutoWidthState(); MMB.ApplySettings() end })
        end
        self:ddAddButton({ text = "|cff00ff98Select Frame (Picker)...|r", notCheckable = true, func = function() StartFramePicker(function() _G.MonkMistBarDB.anchorTo = "Custom"; SetDDText(anchorDD, "Focus: " .. (_G.MonkMistBarDB.customAnchorName or "Custom")); UpdateAutoWidthState(); MMB.ApplySettings() end) end })
    end)

    autoCB:SetScript("OnClick", function(self) _G.MonkMistBarDB.autoWidthSettings[_G.MonkMistBarDB.anchorTo] = self:GetChecked(); _G.MonkMistBarDB.userInteracted[_G.MonkMistBarDB.anchorTo] = true; UpdateWidthSliderState(self, wS); MMB.ApplySettings() end)

    local hS = AddSlider(scrollChild, "Height", 4, 100, "height", wS, 300, 0, 280)
    local xS = AddSlider(scrollChild, "X-Offset", -500, 500, "offsetX", wS, 0, -45, 280)
    local yS = AddSlider(scrollChild, "Y-Offset", -500, 500, "offsetY", xS, 300, 0, 280)
    local spaceS = AddSlider(scrollChild, "Spacing", 0, 20, "spacing", yS, -300, -45, 280)

    -- SECTION: APPEARANCE
    local secLook = CreateSection(scrollChild, "Appearance & Colors", spaceS, -45)
    texDD = lsfdd:CreateMediaStatusbarModernButton(scrollChild, 240, 26)
    texDD:SetPoint("TOPLEFT", secLook, "BOTTOMLEFT", 0, -30)
    texDD:ddSetInitFunc(function(self)
        for _, name in ipairs(LSM:List("statusbar")) do
            self:ddAddButton({ text = name, icon = LSM:Fetch("statusbar", name), iconSize = {140, 18}, func = function() _G.MonkMistBarDB.texture = name; SetDDText(texDD, "Bar: "..name); MMB.ApplySettings() end, checked = function() return _G.MonkMistBarDB.texture == name end })
        end
    end)
    local barCol = CreateColorButton(scrollChild, "Bar Color:", "barColor", texDD, 0, -25)
    local alphaS = AddSlider(scrollChild, "Total Alpha", 0, 100, "alpha", barCol, 0, -40, 240)

    bgTexDD = lsfdd:CreateMediaStatusbarModernButton(scrollChild, 240, 26)
    bgTexDD:SetPoint("TOPLEFT", secLook, "BOTTOMLEFT", 300, -30)
    bgTexDD:ddSetInitFunc(function(self)
        for _, name in ipairs(LSM:List("statusbar")) do
            self:ddAddButton({ text = name, icon = LSM:Fetch("statusbar", name), iconSize = {140, 18}, func = function() _G.MonkMistBarDB.bgTexture = name; SetDDText(bgTexDD, "Background: "..name); MMB.ApplySettings() end, checked = function() return _G.MonkMistBarDB.bgTexture == name end })
        end
    end)
    local bgCol = CreateColorButton(scrollChild, "Background Color:", "bgColor", bgTexDD, 0, -25)
    local bgAlphaS = AddSlider(scrollChild, "Background Alpha", 0, 100, "bgAlpha", bgCol, 0, -40, 240)

    -- SECTION: BORDER
    local secBorder = CreateSection(scrollChild, "Border", alphaS, -45)
    showBorCB = CreateFrame("CheckButton", nil, scrollChild, "MMB_CheckButtonTemplate")
    showBorCB:SetPoint("TOPLEFT", secBorder, "BOTTOMLEFT", 0, -10); showBorCB.Text:SetText("Show Border")
    showBorCB:SetScript("OnClick", function(self) _G.MonkMistBarDB.showBorder = self:GetChecked(); MMB.ApplySettings() end)

    borDD = lsfdd:CreateMediaBorderModernButton(scrollChild, 240, 26)
    borDD:SetPoint("TOPLEFT", showBorCB, "BOTTOMLEFT", 0, -20)
    borDD:ddSetInitFunc(function(self)
        for _, name in ipairs(LSM:List("border")) do
            self:ddAddButton({ text = name, func = function() _G.MonkMistBarDB.borderTexture = name; SetDDText(borDD, "Border: "..name); MMB.ApplySettings() end, checked = function() return _G.MonkMistBarDB.borderTexture == name end })
        end
    end)
    
    local borSizeS = AddSlider(scrollChild, "Border Thickness", 0, 10, "borderSize", borDD, 300, 18, 240)
    local borColBtn = CreateColorButton(scrollChild, "Border Color:", "borderColor", borDD, 0, -38)

    -- SECTION: ABOUT & SUPPORT
    local function AddCopyBox(label, value, iconPath, anchor, yOffset)
        local container = CreateFrame("Frame", nil, scrollChild)
        container:SetSize(560, 30)
        container:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, yOffset)

        if iconPath then
            local icon = container:CreateTexture(nil, "ARTWORK")
            icon:SetSize(22, 22)
            icon:SetPoint("LEFT", container, "LEFT", 10, 0)
            icon:SetTexture(iconPath)
        end

        local lbl = container:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        lbl:SetPoint("LEFT", container, "LEFT", 40, 0)
        lbl:SetText(label)

        local box = CreateFrame("Frame", nil, container, "MMB_BoxTemplate")
        box:SetSize(350, 22)
        box:SetPoint("LEFT", container, "LEFT", 150, 0)

        local eb = CreateFrame("EditBox", nil, box)
        eb:SetSize(340, 20)
        eb:SetPoint("CENTER", box, "CENTER", 0, 0)
        eb:SetFontObject("GameFontHighlightSmall")
        eb:SetAutoFocus(false)
        eb:SetText(value)
        eb:SetCursorPosition(0)
        
        eb:SetScript("OnTextChanged", function(self, userInput) if userInput then self:SetText(value) end end)
        eb:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
        container:SetScript("OnShow", function() eb:SetText(value) end)
        
        return container
    end

    local secAbout = CreateSection(scrollChild, "About & Support", borDD, -80)
    local mediaPath = "Interface\\AddOns\\MonkMistBar\\Media\\"
    
    local dBox = AddCopyBox("Discord:", "Tyimur", mediaPath.."discord.tga", secAbout, -15)
    local gBox = AddCopyBox("Github:", "https://github.com/Tyimurr/MonkMistBar", mediaPath.."github.tga", dBox, -10)
    local wBox = AddCopyBox("Wago:", "https://addons.wago.io/addons/monkmistbar", mediaPath.."wago.tga", gBox, -10)
    local cBox = AddCopyBox("CurseForge:", "https://www.curseforge.com/wow/addons/monkmistbar", mediaPath.."curse.tga", wBox, -10)

    -- FOOTER INFO
    local footerContainer = CreateFrame("Frame", nil, scrollChild)
    footerContainer:SetSize(550, 100)
    footerContainer:SetPoint("TOPLEFT", cBox, "BOTTOMLEFT", 10, -40)

    local footerTitle = footerContainer:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    footerTitle:SetPoint("TOPLEFT", 0, 0)
    footerTitle:SetText("|cff00ff98MonkMistBar|r")

    local footerText = footerContainer:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    footerText:SetPoint("TOPLEFT", footerTitle, "BOTTOMLEFT", 0, -10)
    footerText:SetWidth(500)
    footerText:SetJustifyH("LEFT")
    footerText:SetSpacing(3)
    
    footerText:SetText(
        "Author: |cff00ff98Tyimur|r\n" ..
        "|cff888888Version: 1.1.1|r\n\n" ..
        "A huge thanks to |cff00ff98Spazhealer|r for the idea of this display. It has become a permanent part of my UI.\n\n" ..
        "Special thanks to |cff00ff98baremetalxd|r: I discovered your Twitch streams when I first started playing Mistweaver. You were a true idol and the reason I fell in love with this class. Thank you for the inspiration!"
    )

    panel:SetScript("OnShow", function()
        local db = _G.MonkMistBarDB
        local cur = db.anchorTo
        SetDDText(anchorDD, (cur == "Custom" and "Focus: "..(db.customAnchorName or "")) or cur)
        SetDDText(texDD, "Bar: ".. (db.texture or "None"))
        SetDDText(bgTexDD, "Background: ".. (db.bgTexture or "None"))
        SetDDText(borDD, "Border: ".. (db.borderTexture or "None"))
        
        UpdateAutoWidthState() 
        showBorCB:SetChecked(db.showBorder)
        RefreshOptionsUI()
    end)

    return panel
end

-- 4. REGISTRATION & SLASH COMMANDS
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function()
    categoryObj = Settings.RegisterCanvasLayoutCategory(CreateOptionsPanel(), "MonkMistBar")
    Settings.RegisterAddOnCategory(categoryObj)
end)

SLASH_MONKMISTBAR1 = "/mmb"
SlashCmdList["MONKMISTBAR"] = function() if categoryObj then Settings.OpenToCategory(categoryObj.ID) end end