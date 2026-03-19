local addonName, MMB = ...
local spellID = 115151
local LSM = LibStub("LibSharedMedia-3.0")

MMB.maxCharges = 2
MMB.currentCharges = 0
MMB.cooldownStart = 0
MMB.cooldownDuration = 0
MMB.isActive = false

local function CheckSpec(frame)
    local _, playerClass = UnitClass("player")
    if playerClass == "MONK" then
        local spec = GetSpecialization()
        MMB.isActive = (spec == 2)
    else
        MMB.isActive = false
    end

    if MMB.isActive then
        frame:Show()
    else
        frame:Hide()
    end
end

function MMB.InitDB()
    _G.MonkMistBarDB = _G.MonkMistBarDB or {}
    local defaults = {
        offsetX = 0, offsetY = 0,
        width = 325, height = 10,
        texture = "Blizzard Target",
        barColor = {r = 0, g = 1.0, b = 0.596}, alpha = 1,
        anchorTo = "Manual",
        customAnchorName = nil,
        bgTexture = "Blizzard Target", 
        bgColor = {r = 0, g = 0, b = 0},
        bgAlpha = 0.5,
        showBorder = true,
        borderTexture = "Solid", borderSize = 1, 
        borderColor = {r = 0, g = 0, b = 0, a = 1},
        spacing = 1,
        autoWidthSettings = { ["Manual"] = false }, 
        userInteracted = { ["Manual"] = true }
    }
    for k, v in pairs(defaults) do 
        if _G.MonkMistBarDB[k] == nil then 
            _G.MonkMistBarDB[k] = v 
        elseif type(v) == "table" and type(_G.MonkMistBarDB[k]) == "table" then
            for subK, subV in pairs(v) do
                if _G.MonkMistBarDB[k][subK] == nil then _G.MonkMistBarDB[k][subK] = subV end
            end
        end
    end
end

local function GetAnchorFrame(key)
    if key == "Actionbar" then return _G["MainActionBar"]
    elseif key == "CooldownManager" then return _G["EssentialCooldownViewer"]
    elseif key == "Custom" and _G.MonkMistBarDB.customAnchorName then return _G[_G.MonkMistBarDB.customAnchorName]
    end
    return nil
end

function MMB.ApplySettings()
    if not _G.MonkMistBarDB or not MonkMistBarFrame or not MMB.isActive then return end
    local db, f = _G.MonkMistBarDB, MonkMistBarFrame
    local target = GetAnchorFrame(db.anchorTo)
    
    f:ClearAllPoints()
    f:SetParent(UIParent)
    
    if db.anchorTo ~= "Manual" and target and target:IsVisible() then
        f:SetPoint("BOTTOM", target, "TOP", db.offsetX or 0, db.offsetY or 0)
        local autoWidthActive = (db.userInteracted[db.anchorTo] == nil) or db.autoWidthSettings[db.anchorTo]
        local tWidth = target:GetWidth()
        f:SetWidth((autoWidthActive and tWidth > 20) and tWidth or db.width)
    else
        f:SetPoint("CENTER", UIParent, "CENTER", db.offsetX or 0, db.offsetY or 0)
        f:SetWidth(db.width or 200)
    end
    f:SetHeight(db.height or 20)
    f:SetAlpha(db.alpha or 1)

    local tex = LSM:Fetch("statusbar", db.texture or "Blizzard Target")
    local bgTex = LSM:Fetch("statusbar", db.bgTexture or "Blizzard Target")
    local borderTex = LSM:Fetch("border", db.borderTexture or "None")
    
    local spacing = db.spacing or 1 
    local mCharges = math.max(1, MMB.maxCharges)
    local barWidth = (f:GetWidth() - ((mCharges - 1) * spacing)) / mCharges
    local bSize = db.showBorder and (db.borderSize or 1) or 0

    for i = 1, 3 do
        local b = f.bars[i]
        if i <= mCharges then
            b:Show()
            b:SetSize(barWidth, f:GetHeight())
            b:ClearAllPoints()
            b:SetPoint("LEFT", f, "LEFT", (i-1) * (barWidth + spacing), 0)
            
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
            b.borderFrame:SetBackdrop({
                edgeFile = db.showBorder and borderTex or nil,
                edgeSize = bSize > 0 and bSize or 1,
            })
            local borC = db.borderColor or {r=0, g=0, b=0, a=1}
            b.borderFrame:SetBackdropBorderColor(borC.r, borC.g, borC.b, borC.a)
            b:SetFrameLevel(f:GetFrameLevel() + 1)
            b.borderFrame:SetFrameLevel(b:GetFrameLevel() + 2)
        else 
            b:Hide() 
        end
    end
end

local function UpdateChargeData()
    local chargeInfo = C_Spell.GetSpellCharges(spellID)
    if chargeInfo then
        local oldMax = MMB.maxCharges
        MMB.maxCharges = chargeInfo.maxCharges or 2
        MMB.currentCharges = chargeInfo.currentCharges or 0
        MMB.cooldownStart = chargeInfo.cooldownStartTime or 0
        MMB.cooldownDuration = chargeInfo.cooldownDuration or 0
        
        if oldMax ~= MMB.maxCharges then
            MMB.ApplySettings()
        end
    end
end

local f = CreateFrame("Frame", "MonkMistBarFrame", UIParent, "BackdropTemplate")
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("SPELL_UPDATE_CHARGES")
f:RegisterEvent("SPELL_UPDATE_COOLDOWN")
f:RegisterEvent("TRAIT_CONFIG_UPDATED")

f:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        MMB.InitDB()
        self.bars = {}
        for i = 1, 3 do 
            self.bars[i] = CreateFrame("StatusBar", nil, self, "BackdropTemplate")
            self.bars[i]:SetMinMaxValues(0, 1) 
        end
    elseif event == "PLAYER_ENTERING_WORLD" then
        CheckSpec(self)
        C_Timer.After(1, function()
            if MMB.isActive then
                UpdateChargeData()
                MMB.ApplySettings()
            end
        end)
    elseif event == "TRAIT_CONFIG_UPDATED" then
        CheckSpec(self)
        if MMB.isActive then
            UpdateChargeData()
            MMB.ApplySettings()
        end
    else
        if MMB.isActive then
            UpdateChargeData()
        end
    end
end)

f:SetScript("OnUpdate", function(self)
    if not MMB.isActive then return end

    for i = 1, MMB.maxCharges do
        local bar = self.bars[i]
        if not bar then break end
        if i <= MMB.currentCharges then 
            bar:SetValue(1)
        elseif i == MMB.currentCharges + 1 then
            if MMB.cooldownDuration > 0 then
                local progress = (GetTime() - MMB.cooldownStart) / MMB.cooldownDuration
                bar:SetValue(math.min(1, math.max(0, progress)))
            else
                bar:SetValue(0)
            end
        else 
            bar:SetValue(0) 
        end
    end
end)