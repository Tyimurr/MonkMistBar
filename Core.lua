local addonName, MMB = ...
local spellID = 115151
local LSM = LibStub("LibSharedMedia-3.0")

local curMax = 2
local currentCharges = 2
local lastStart, lastDuration = 0, 0
local isMWActive = false
local MainFrame

local function IsSafeNumber(value)
    return value ~= nil and type(value) == "number" and not issecretvalue(value)
end

local function UpdateChargeData()
    local info = C_Spell.GetSpellCharges(spellID)
    if info then
        
        if IsSafeNumber(info.currentCharges) then
            currentCharges = info.currentCharges
        end
        
        if IsSafeNumber(info.maxCharges) then
            curMax = info.maxCharges
        end

        if IsSafeNumber(info.cooldownDuration) and info.cooldownDuration > 0 then
            lastDuration = info.cooldownDuration
            lastStart = info.cooldownStartTime or 0
        end
        
        MMB.maxCharges = curMax
        MMB.currentCharges = currentCharges
    end
end

local function CheckSpec(frame)
    local _, playerClass = UnitClass("player")
    if playerClass == "MONK" then
        local spec = GetSpecialization()
        isMWActive = (spec == 2)
    else
        isMWActive = false
    end
    MMB.isActive = isMWActive
    if frame then
        if isMWActive then frame:Show() else frame:Hide() end
    end
end

function MMB.InitDB()
    _G.MonkMistBarDB = _G.MonkMistBarDB or {}
    local defaults = {
        offsetX = 0, offsetY = 0, width = 325, height = 10,
        texture = "Blizzard Target", barColor = {r = 0, g = 1.0, b = 0.596}, alpha = 1,
        anchorTo = "Manual", customAnchorName = nil, bgTexture = "Blizzard Target", 
        bgColor = {r = 0, g = 0, b = 0}, bgAlpha = 0.5, showBorder = true,
        borderTexture = "Solid", borderSize = 1, borderColor = {r = 0, g = 0, b = 0, a = 1},
        spacing = 1, autoWidthSettings = { ["Manual"] = false }, userInteracted = { ["Manual"] = true }
    }
    for k, v in pairs(defaults) do 
        if _G.MonkMistBarDB[k] == nil then _G.MonkMistBarDB[k] = v end
    end
end

local function GetAnchorFrame(key)
    if key == "Actionbar" then return _G["MainActionBar"]
    elseif key == "CooldownManager" then return _G["EssentialCooldownViewer"]
    elseif key == "Custom" and _G.MonkMistBarDB.customAnchorName then return _G[_G.MonkMistBarDB.customAnchorName] end
    return nil
end

function MMB.ApplySettings()
    if not _G.MonkMistBarDB or not MainFrame or not isMWActive then return end
    local db, f = _G.MonkMistBarDB, MainFrame
    local target = GetAnchorFrame(db.anchorTo)
    f:ClearAllPoints()
    f:SetParent(UIParent)
    if db.anchorTo ~= "Manual" and target and target:IsVisible() then
        f:SetPoint("BOTTOM", target, "TOP", db.offsetX or 0, db.offsetY or 0)
        local autoWidthActive = (db.userInteracted[db.anchorTo] == nil) or db.autoWidthSettings[db.anchorTo]
        f:SetWidth((autoWidthActive and target:GetWidth() > 20) and target:GetWidth() or db.width)
    else
        f:SetPoint("CENTER", UIParent, "CENTER", db.offsetX or 0, db.offsetY or 0)
        f:SetWidth(db.width or 200)
    end
    f:SetHeight(db.height or 20)
    f:SetAlpha(db.alpha or 1)
    
    local tex = LSM:Fetch("statusbar", db.texture or "Blizzard Target")
    local bgTex = LSM:Fetch("statusbar", db.bgTexture or "Blizzard Target")
    local borderTex = LSM:Fetch("border", db.borderTexture or "None")
    local mCharges = math.max(1, curMax)
    local barWidth = (f:GetWidth() - ((mCharges - 1) * db.spacing)) / mCharges
    local bSize = db.showBorder and (db.borderSize or 1) or 0

    for i = 1, 3 do
        local b = f.bars[i]
        if i <= mCharges then
            b:Show()
            b:SetSize(barWidth, f:GetHeight())
            b:ClearAllPoints()
            b:SetPoint("LEFT", f, "LEFT", (i-1) * (barWidth + db.spacing), 0)
            if not b.bg then b.bg = b:CreateTexture(nil, "BACKGROUND"); b.bg:SetAllPoints(b) end
            b.bg:SetTexture(bgTex)
            local bgC = db.bgColor or {r=0, g=0, b=0}
            b.bg:SetVertexColor(bgC.r, bgC.g, bgC.b, db.bgAlpha or 0.5)
            b:SetStatusBarTexture(tex)
            local barC = db.barColor or {r = 0, g = 1.0, b = 0.596}
            b:SetStatusBarColor(barC.r, barC.g, barC.b)
            local barTex = b:GetStatusBarTexture()
            barTex:ClearAllPoints()
            barTex:SetPoint("TOPLEFT", b, "TOPLEFT", bSize, -bSize)
            barTex:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", -bSize, bSize)
            if not b.borderFrame then b.borderFrame = CreateFrame("Frame", nil, b, "BackdropTemplate"); b.borderFrame:SetAllPoints(b) end
            b.borderFrame:SetBackdrop({ edgeFile = db.showBorder and borderTex or nil, edgeSize = bSize > 0 and bSize or 1 })
            local borC = db.borderColor or {r=0, g=0, b=0, a=1}
            b.borderFrame:SetBackdropBorderColor(borC.r, borC.g, borC.b, borC.a)
            b:SetFrameLevel(f:GetFrameLevel() + 1)
            b.borderFrame:SetFrameLevel(b:GetFrameLevel() + 2)
        else b:Hide() end
    end
end

MainFrame = CreateFrame("Frame", "MonkMistBarFrame", UIParent, "BackdropTemplate")
MainFrame:RegisterEvent("ADDON_LOADED")
MainFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
MainFrame:RegisterEvent("SPELL_UPDATE_CHARGES")
MainFrame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
MainFrame:RegisterEvent("TRAIT_CONFIG_UPDATED")
MainFrame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")

MainFrame:SetScript("OnEvent", function(self, event, arg1, arg2, arg3)
    if event == "ADDON_LOADED" and arg1 == addonName then
        MMB.InitDB()
        self.bars = {}
        for i = 1, 3 do self.bars[i] = CreateFrame("StatusBar", nil, self, "BackdropTemplate"); self.bars[i]:SetMinMaxValues(0, 1) end
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" and arg3 == spellID then
        if currentCharges > 0 then currentCharges = currentCharges - 1 end
    elseif event == "PLAYER_ENTERING_WORLD" or event == "TRAIT_CONFIG_UPDATED" then
        CheckSpec(self)
        C_Timer.After(0.5, function() if isMWActive then UpdateChargeData(); MMB.ApplySettings() end end)
    else
        if isMWActive then UpdateChargeData() end
    end
end)

MainFrame:SetScript("OnUpdate", function(self)
    if not isMWActive then return end
    local now = GetTime()
    
    for i = 1, 3 do
        local bar = self.bars[i]
        if bar and i <= curMax then
            if i <= currentCharges then
                bar:SetValue(1)
            elseif i == (currentCharges + 1) and lastDuration > 0.1 then
                local progress = (now - lastStart) / lastDuration
                bar:SetValue(progress > 1 and 1 or (progress < 0 and 0 or progress))
            else
                bar:SetValue(0)
            end
        end
    end
end)