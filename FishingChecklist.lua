local addonName, FBStorage = ...
local FBI = FBStorage

local FL = LibStub("LibFishing-1.0")
local LW = LibStub("LibWindow-1.1")

local CHECKLIST_CMD = "checklist"
local WINDOW_TITLE = "Fishing Checklist"
local WINDOW_SUBTITLE = "Track repeatable fishing tasks, treasures, and utility unlocks."

local ROW_HEIGHT = 22
local ROW_SPACING = 4
local WINDOW_WIDTH = 420

local function IsQuestDone(task)
    if not task.questIDs then
        return false
    end
    for _, questID in ipairs(task.questIDs) do
        if C_QuestLog.IsQuestFlaggedCompleted(questID) then
            return true
        end
    end
    return false
end

local function IsQuestDoneOnAccount(task)
    if not task.questIDs or not C_QuestLog.IsQuestFlaggedCompletedOnAccount then
        return false
    end
    for _, questID in ipairs(task.questIDs) do
        if C_QuestLog.IsQuestFlaggedCompletedOnAccount(questID) then
            return true
        end
    end
    return false
end

local function IsAchievementDone(task)
    if not task.achievementID then
        return false
    end
    local _, _, _, completed = GetAchievementInfo(task.achievementID)
    return completed
end

local function IsToyOwned(task)
    return task.toyID and PlayerHasToy(task.toyID)
end

local function IsItemOwned(task)
    return task.itemID and GetItemCount(task.itemID, true) > 0
end

local function IsDarkmoonActive()
    local dayOfWeek = tonumber(date("%w"))
    local dayOfMonth = tonumber(date("%e"))
    local firstSundayOfMonth = ((dayOfMonth - (dayOfWeek + 1)) % 7) + 1
    local daysSinceFirstSunday = dayOfMonth - firstSundayOfMonth
    return daysSinceFirstSunday >= 0 and daysSinceFirstSunday <= 6
end

local function IsSunday()
    return tonumber(date("%w")) == 0
end

local function GetCurrentFishingSkill()
    local rank = FL:GetCurrentSkill()
    return rank or 0
end

local function IsMountCollectedByName(name)
    if not name or not C_MountJournal or not C_MountJournal.GetMountIDs then
        return false
    end
    for _, mountID in ipairs(C_MountJournal.GetMountIDs()) do
        local mountName, _, _, _, _, _, _, _, _, _, isCollected = C_MountJournal.GetMountInfoByID(mountID)
        if mountName == name then
            return isCollected and true or false
        end
    end
    return false
end

local function GetTaskStatus(task)
    if task.check then
        return task.check(task)
    end

    if task.repeatable then
        local active = true
        if task.activeCheck then
            active = task.activeCheck(task)
        end
        if not active then
            return "inactive", task.inactiveText or "Inactive"
        end
        return "available", task.availableText or "Available"
    end

    if task.questIDs then
        if IsQuestDone(task) then
            return "done", "Completed"
        end
        if task.accountWide and IsQuestDoneOnAccount(task) then
            return "done", "Done on account"
        end
        return "available", "Available"
    end

    if task.achievementID then
        if IsAchievementDone(task) then
            return "done", "Completed"
        end
        return "available", "Incomplete"
    end

    if task.toyID then
        if IsToyOwned(task) then
            return "done", "Owned"
        end
        return "missing", "Missing"
    end

    if task.itemID then
        if IsItemOwned(task) then
            return "done", "Owned"
        end
        return "missing", "Missing"
    end

    if task.mountName then
        if IsMountCollectedByName(task.mountName) then
            return "done", "Collected"
        end
        return "available", "Missing"
    end

    if task.skillGoal then
        local current = GetCurrentFishingSkill()
        if current >= task.skillGoal then
            return "done", string.format("%d / %d", current, task.skillGoal)
        end
        return "available", string.format("%d / %d", current, task.skillGoal)
    end

    return "info", task.statusText or "Info"
end

local function StatusColor(status)
    if status == "done" then
        return 0.35, 0.85, 0.45
    elseif status == "available" then
        return 0.95, 0.82, 0.28
    elseif status == "inactive" then
        return 0.65, 0.65, 0.65
    elseif status == "missing" then
        return 0.90, 0.45, 0.45
    end
    return 0.75, 0.82, 0.92
end

local Tasks = {
    {
        category = "Events",
        entries = {
            {
                name = "Stranglethorn Fishing Extravaganza",
                repeatable = true,
                activeCheck = IsSunday,
                repeatLabel = "Weekly event",
                availableText = "Sunday",
                inactiveText = "Not Sunday",
                note = "Tournament event anchor row. The Booty Bay fishing contest runs on Sundays.",
            },
            {
                name = "Master Angler Tournament Turn-In",
                questIDs = { 8193 },
                repeatable = true,
                activeCheck = IsSunday,
                repeatLabel = "Weekly event",
                availableText = "Event up",
                inactiveText = "Event down",
                note = "Turn in 40 Speckled Tastyfish during the Stranglethorn Fishing Extravaganza.",
            },
            {
                name = "Rare Fish Turn-In: Keefer's Angelfish",
                questIDs = { 8225 },
                repeatable = true,
                activeCheck = IsSunday,
                repeatLabel = "Weekly event",
                availableText = "Event up",
                inactiveText = "Event down",
                note = "Stranglethorn Fishing Extravaganza rare fish turn-in.",
            },
            {
                name = "Rare Fish Turn-In: Brownell's Blue Striped Racer",
                questIDs = { 8224 },
                repeatable = true,
                activeCheck = IsSunday,
                repeatLabel = "Weekly event",
                availableText = "Event up",
                inactiveText = "Event down",
                note = "Stranglethorn Fishing Extravaganza rare fish turn-in.",
            },
            {
                name = "Rare Fish Turn-In: Dezian Queenfish",
                questIDs = { 8221 },
                repeatable = true,
                activeCheck = IsSunday,
                repeatLabel = "Weekly event",
                availableText = "Event up",
                inactiveText = "Event down",
                note = "Stranglethorn Fishing Extravaganza rare fish turn-in.",
            },
            {
                name = "Darkmoon Faire Fishing Quest",
                questIDs = { 29513 },
                repeatable = true,
                activeCheck = IsDarkmoonActive,
                repeatLabel = "Monthly",
                availableText = "Faire up",
                inactiveText = "Faire down",
                note = "Spoilin' for Salty Sea Dogs. This uses the Darkmoon profession-fishing quest ID inferred from the profession quest sequence.",
            },
        },
    },
    {
        category = "Midnight",
        entries = {
            {
                name = "Bait and Tackle",
                questIDs = { 90795 },
                repeatLabel = "One-time treasure",
                note = "Midnight treasure in Zul'Aman. RareScanner data ties this treasure to quest 90795.",
            },
            {
                name = "Treasures of Zul'Aman",
                achievementID = 62125,
                repeatLabel = "Achievement",
                note = "Midnight treasure achievement bucket used by RareScanner for Zul'Aman treasures.",
            },
            {
                name = "Midnight Fishing Skill 100",
                skillGoal = 100,
                repeatLabel = "Progress goal",
                note = "First useful Midnight fishing milestone.",
            },
            {
                name = "Midnight Fishing Skill 200",
                skillGoal = 200,
                repeatLabel = "Progress goal",
                note = "Late-progress Midnight fishing milestone before the 300 cap.",
            },
            {
                name = "Midnight Fishing Skill 300",
                skillGoal = 300,
                repeatLabel = "Progress goal",
                note = "Midnight max-skill target.",
            },
        },
    },
    {
        category = "Collectibles",
        entries = {
            {
                name = "Nether-Swept Drake",
                mountName = "Nether-Warped Drake",
                repeatLabel = "Mount",
                note = "Verified Midnight fishing mount. Warcraft Wiki lists Nether-Swept Drake as a fished item from the Voidstorm that teaches the Nether-Warped Drake mount.",
            },
        },
    },
    {
        category = "Achievements",
        entries = {
            {
                name = "Master Angler of Azeroth",
                achievementID = 306,
                repeatLabel = "Achievement",
                note = "Win the Booty Bay fishing contest.",
            },
            {
                name = "Accomplished Angler",
                achievementID = 1516,
                repeatLabel = "Achievement",
                note = "Broad fishing progression meta-achievement.",
            },
            {
                name = "The Coin Master",
                achievementID = 2096,
                repeatLabel = "Achievement",
                note = "Collect all coins from the Dalaran fountain.",
            },
            {
                name = "Turtles All the Way Down",
                achievementID = 3218,
                repeatLabel = "Achievement",
                note = "Catch the Sea Turtle mount while fishing.",
            },
        },
    },
    {
        category = "Utility",
        entries = {
            {
                name = "Reusable Oversized Bobber",
                toyID = 202207,
                repeatLabel = "Toy",
                note = "Large reusable fishing bobber toy.",
            },
            {
                name = "Trawler Totem",
                toyID = 152556,
                repeatLabel = "Toy",
                note = "Water-walking fishing utility toy.",
            },
            {
                name = "Anglers Fishing Raft",
                toyID = 85500,
                repeatLabel = "Toy",
                note = "Classic fishing raft utility toy.",
            },
            {
                name = "Sharpened Tuskarr Spear",
                itemID = 88535,
                repeatLabel = "Item",
                note = "Utility fishing item already supported by FishingBuddy's item planner.",
            },
            {
                name = "Weather-Beaten Fishing Hat",
                itemID = 33820,
                repeatLabel = "Item",
                note = "Classic fishing hat with a fishing skill bonus.",
            },
            {
                name = "Captain Rumsey's Lager",
                itemID = 34832,
                repeatLabel = "Consumable",
                note = "Fishing skill buff consumable already used by FishingBuddy.",
            },
        },
    },
}

local function BuildDetailText(task)
    local lines = { task.name }
    if task.repeatLabel then
        tinsert(lines, task.repeatLabel)
    end
    if task.note then
        tinsert(lines, task.note)
    end
    if task.questIDs then
        tinsert(lines, "Quest ID: "..table.concat(task.questIDs, ", "))
    end
    if task.achievementID then
        tinsert(lines, "Achievement ID: "..task.achievementID)
    end
    if task.toyID then
        tinsert(lines, "Toy ID: "..task.toyID)
    end
    if task.itemID then
        tinsert(lines, "Item ID: "..task.itemID)
    end
    if task.mountName then
        tinsert(lines, "Mount: "..task.mountName)
    end
    if task.skillGoal then
        tinsert(lines, "Skill goal: "..task.skillGoal)
    end
    return table.concat(lines, "\n")
end

local ChecklistFrame
local rowPool = {}

local function AcquireRow(parent)
    local row = tremove(rowPool)
    if row then
        row:SetParent(parent)
        row:Show()
        return row
    end

    row = CreateFrame("Button", nil, parent)
    row:SetHeight(ROW_HEIGHT)
    row:SetWidth(WINDOW_WIDTH - 24)

    row.background = row:CreateTexture(nil, "BACKGROUND")
    row.background:SetAllPoints()
    row.background:SetTexture("Interface\\Buttons\\WHITE8X8")

    row.leftText = row:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    row.leftText:SetPoint("LEFT", 6, 0)
    row.leftText:SetJustifyH("LEFT")
    row.leftText:SetWidth(220)

    row.middleText = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    row.middleText:SetPoint("LEFT", row.leftText, "RIGHT", 8, 0)
    row.middleText:SetJustifyH("LEFT")
    row.middleText:SetWidth(110)

    row.rightText = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    row.rightText:SetPoint("RIGHT", -6, 0)
    row.rightText:SetJustifyH("RIGHT")
    row.rightText:SetWidth(78)

    row.highlight = row:CreateTexture(nil, "HIGHLIGHT")
    row.highlight:SetAllPoints()
    row.highlight:SetTexture("Interface\\Buttons\\WHITE8X8")
    row.highlight:SetVertexColor(1, 1, 1, 0.08)

    return row
end

local function ReleaseRows()
    if not ChecklistFrame or not ChecklistFrame.rows then
        return
    end
    for _, row in ipairs(ChecklistFrame.rows) do
        row:Hide()
        row:ClearAllPoints()
        row:SetScript("OnClick", nil)
        tinsert(rowPool, row)
    end
    wipe(ChecklistFrame.rows)
end

local function UpdateChecklist()
    if not ChecklistFrame then
        return
    end

    ReleaseRows()

    local anchor = ChecklistFrame.subtitle
    local contentHeight = 56
    for _, group in ipairs(Tasks) do
        local header = AcquireRow(ChecklistFrame)
        header:SetPoint("TOPLEFT", 12, -contentHeight)
        header.background:SetVertexColor(0.12, 0.18, 0.25, 0.95)
        header.leftText:SetText(group.category)
        header.leftText:SetTextColor(0.96, 0.93, 0.78)
        header.middleText:SetText("")
        header.rightText:SetText("")
        header:SetScript("OnClick", nil)
        tinsert(ChecklistFrame.rows, header)
        contentHeight = contentHeight + ROW_HEIGHT + ROW_SPACING
        anchor = header

        for _, task in ipairs(group.entries) do
            local row = AcquireRow(ChecklistFrame)
            local status, statusText = GetTaskStatus(task)
            local r, g, b = StatusColor(status)
            row:SetPoint("TOPLEFT", 12, -contentHeight)
            row.background:SetVertexColor(0.04, 0.06, 0.10, 0.82)
            row.leftText:SetText(task.name)
            row.leftText:SetTextColor(0.92, 0.92, 0.92)
            row.middleText:SetText(task.repeatLabel or "")
            row.middleText:SetTextColor(0.70, 0.78, 0.88)
            row.rightText:SetText(statusText)
            row.rightText:SetTextColor(r, g, b)
            row:SetScript("OnClick", function()
                ChecklistFrame.detailText:SetText(BuildDetailText(task))
            end)
            tinsert(ChecklistFrame.rows, row)
            contentHeight = contentHeight + ROW_HEIGHT + ROW_SPACING
            anchor = row
        end
    end

    ChecklistFrame:SetHeight(contentHeight + 74)
end

local function ToggleChecklist()
    if not ChecklistFrame then
        return
    end
    if ChecklistFrame:IsShown() then
        ChecklistFrame:Hide()
        FishingBuddy_Player["ChecklistVisible"] = false
    else
        UpdateChecklist()
        ChecklistFrame:Show()
        FishingBuddy_Player["ChecklistVisible"] = true
    end
end

local function CreateChecklistWindow()
    if ChecklistFrame then
        return
    end

    ChecklistFrame = CreateFrame("Frame", "FishingChecklistFrame", UIParent, "BackdropTemplate")
    ChecklistFrame:SetSize(WINDOW_WIDTH, 320)
    ChecklistFrame:SetFrameStrata("MEDIUM")
    ChecklistFrame:SetClampedToScreen(true)
    ChecklistFrame:EnableMouse(true)
    ChecklistFrame.rows = {}

    ChecklistFrame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 12,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    ChecklistFrame:SetBackdropColor(0.03, 0.05, 0.08, 0.94)
    ChecklistFrame:SetBackdropBorderColor(0.28, 0.38, 0.48, 0.9)

    ChecklistFrame.titleBar = CreateFrame("Frame", nil, ChecklistFrame)
    ChecklistFrame.titleBar:SetPoint("TOPLEFT", 4, -4)
    ChecklistFrame.titleBar:SetPoint("TOPRIGHT", -4, -4)
    ChecklistFrame.titleBar:SetHeight(26)
    ChecklistFrame.titleBar:EnableMouse(true)
    ChecklistFrame.titleBar:RegisterForDrag("LeftButton")
    ChecklistFrame.titleBar:SetScript("OnDragStart", function()
        ChecklistFrame:StartMoving()
    end)
    ChecklistFrame.titleBar:SetScript("OnDragStop", function()
        ChecklistFrame:StopMovingOrSizing()
        if ChecklistFrame.SavePosition then
            ChecklistFrame:SavePosition()
        end
    end)

    ChecklistFrame.header = ChecklistFrame.titleBar:CreateTexture(nil, "BACKGROUND")
    ChecklistFrame.header:SetAllPoints()
    ChecklistFrame.header:SetTexture("Interface\\Buttons\\WHITE8X8")
    ChecklistFrame.header:SetVertexColor(0.10, 0.16, 0.22, 0.96)

    ChecklistFrame.title = ChecklistFrame.titleBar:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    ChecklistFrame.title:SetPoint("LEFT", 8, 0)
    ChecklistFrame.title:SetText(WINDOW_TITLE)

    local closeButton = CreateFrame("Button", nil, ChecklistFrame.titleBar, "UIPanelCloseButton")
    closeButton:SetPoint("RIGHT", 2, 0)
    closeButton:SetScript("OnClick", function()
        ChecklistFrame:Hide()
        FishingBuddy_Player["ChecklistVisible"] = false
    end)

    ChecklistFrame.subtitle = ChecklistFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    ChecklistFrame.subtitle:SetPoint("TOPLEFT", ChecklistFrame.titleBar, "BOTTOMLEFT", 8, -8)
    ChecklistFrame.subtitle:SetWidth(WINDOW_WIDTH - 24)
    ChecklistFrame.subtitle:SetJustifyH("LEFT")
    ChecklistFrame.subtitle:SetText(WINDOW_SUBTITLE)

    ChecklistFrame.detailText = ChecklistFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    ChecklistFrame.detailText:SetPoint("BOTTOMLEFT", 12, 12)
    ChecklistFrame.detailText:SetPoint("BOTTOMRIGHT", -12, 12)
    ChecklistFrame.detailText:SetJustifyH("LEFT")
    ChecklistFrame.detailText:SetJustifyV("TOP")
    ChecklistFrame.detailText:SetText("Click a row to see details.")

    LW:Embed(ChecklistFrame)
    FishingBuddy_Player["ChecklistLocation"] = FishingBuddy_Player["ChecklistLocation"] or {}
    ChecklistFrame:RegisterConfig(FishingBuddy_Player["ChecklistLocation"])
    ChecklistFrame:RestorePosition()
    ChecklistFrame:MakeDraggable()

    local location = FishingBuddy_Player["ChecklistLocation"]
    if location and location.point == nil then
        ChecklistFrame:ClearAllPoints()
        ChecklistFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 120, -220)
        ChecklistFrame:SavePosition()
    end

    ChecklistFrame:SetMovable(true)
    ChecklistFrame:Hide()
end

local ChecklistEvents = {}

ChecklistEvents["VARIABLES_LOADED"] = function()
    FishingBuddy_Player["ChecklistVisible"] = FishingBuddy_Player["ChecklistVisible"] or false
    CreateChecklistWindow()
    UpdateChecklist()
    if FishingBuddy_Player["ChecklistVisible"] then
        ChecklistFrame:Show()
    end
end

ChecklistEvents["BAG_UPDATE_DELAYED"] = function()
    if ChecklistFrame and ChecklistFrame:IsShown() then
        UpdateChecklist()
    end
end

ChecklistEvents["QUEST_TURNED_IN"] = function()
    if ChecklistFrame and ChecklistFrame:IsShown() then
        UpdateChecklist()
    end
end

ChecklistEvents["PLAYER_ENTERING_WORLD"] = function()
    if ChecklistFrame and ChecklistFrame:IsShown() then
        UpdateChecklist()
    end
end

FBI.Commands[CHECKLIST_CMD] = {
    help = "|c#GREEN#/fb checklist|r#BRSPCS#Toggle the Fishing Checklist window.",
    func = function()
        ToggleChecklist()
        return true
    end,
}

FBI:RegisterHandlers(ChecklistEvents)
