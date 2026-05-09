local Players = game:GetService("Players")
local GroupService = game:GetService("GroupService")
local player = Players.LocalPlayer
local gui = Instance.new("ScreenGui")
gui.ResetOnSpawn = false
gui.Parent = player.PlayerGui

local TARGET_GROUP = 13104082

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 420, 0, 500)
frame.Position = UDim2.new(0, 10, 0.5, -250)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
frame.BackgroundTransparency = 0.3
frame.BorderSizePixel = 0
frame.Parent = gui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 36)
title.Position = UDim2.new(0, 0, 0, 0)
title.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
title.BackgroundTransparency = 0
title.TextColor3 = Color3.new(1,1,1)
title.TextScaled = true
title.Font = Enum.Font.GothamBold
title.Text = "🔍 Anim Scanner | 0 found"
title.Parent = frame

local countLabel = Instance.new("TextLabel")
countLabel.Size = UDim2.new(1, 0, 0, 28)
countLabel.Position = UDim2.new(0, 0, 0, 36)
countLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
countLabel.BackgroundTransparency = 0
countLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
countLabel.TextScaled = true
countLabel.Font = Enum.Font.Gotham
countLabel.Text = "Scanning..."
countLabel.Parent = frame

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, 0, 1, -64)
scroll.Position = UDim2.new(0, 0, 0, 64)
scroll.BackgroundTransparency = 1
scroll.ScrollBarThickness = 6
scroll.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.Parent = frame

local layout = Instance.new("UIListLayout")
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Padding = UDim.new(0, 2)
layout.Parent = scroll

local foundAnims = {}
local animCount = 0
local MarketplaceService = game:GetService("MarketplaceService")

local function addAnimEntry(id, source)
    if foundAnims[id] then return end

    -- Check owner của anim có phải group 13104082 không
    local numId = id:match("%d+")
    if not numId then return end

    task.spawn(function()
        local ok, info = pcall(function()
            return MarketplaceService:GetProductInfo(tonumber(numId))
        end)
        if not ok or not info then return end

        local creatorId = info.Creator and info.Creator.Id
        local creatorType = info.Creator and info.Creator.CreatorType

        -- Chỉ nhận anim của group 13104082
        if creatorType ~= "Group" or creatorId ~= TARGET_GROUP then return end
        if foundAnims[id] then return end
        foundAnims[id] = true
        animCount += 1

        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, -8, 0, 52)
        row.BackgroundColor3 = animCount % 2 == 0
            and Color3.fromRGB(30, 30, 30)
            or  Color3.fromRGB(38, 38, 38)
        row.BackgroundTransparency = 0
        row.BorderSizePixel = 0
        row.LayoutOrder = animCount
        row.Parent = scroll

        local idLabel = Instance.new("TextLabel")
        idLabel.Size = UDim2.new(1, -8, 0, 26)
        idLabel.Position = UDim2.new(0, 6, 0, 2)
        idLabel.BackgroundTransparency = 1
        idLabel.TextColor3 = Color3.fromRGB(100, 220, 255)
        idLabel.TextScaled = true
        idLabel.Font = Enum.Font.GothamBold
        idLabel.TextXAlignment = Enum.TextXAlignment.Left
        idLabel.Text = "ID: " .. numId .. " | " .. (info.Name or "?")
        idLabel.Parent = row

        local srcLabel = Instance.new("TextLabel")
        srcLabel.Size = UDim2.new(1, -8, 0, 20)
        srcLabel.Position = UDim2.new(0, 6, 0, 28)
        srcLabel.BackgroundTransparency = 1
        srcLabel.TextColor3 = Color3.fromRGB(160, 160, 160)
        srcLabel.TextScaled = true
        srcLabel.Font = Enum.Font.Gotham
        srcLabel.TextXAlignment = Enum.TextXAlignment.Left
        srcLabel.Text = "📍 " .. source
        srcLabel.Parent = row

        scroll.CanvasSize = UDim2.new(0, 0, 0, animCount * 54)
        scroll.CanvasPosition = Vector2.new(0, math.max(0, animCount * 54 - scroll.AbsoluteSize.Y))
        title.Text = "🔍 Group " .. TARGET_GROUP .. " | " .. animCount .. " found"
    end)
end

local function scanInstance(obj, depth)
    if depth > 8 then return end

    if obj:IsA("Animator") then
        local ok, tracks = pcall(function()
            return obj:GetPlayingAnimationTracks()
        end)
        if ok then
            for _, track in ipairs(tracks) do
                local id = track.Animation and track.Animation.AnimationId or ""
                if id ~= "" then
                    local parent = obj.Parent and obj.Parent.Parent
                    local sourceName = parent and parent.Name or obj.Parent.Name
                    addAnimEntry(id, sourceName .. " (playing)")
                end
            end
        end
    end

    if obj:IsA("Animation") then
        local id = obj.AnimationId
        if id ~= "" then
            addAnimEntry(id, obj.Parent and obj.Parent.Name or "Unknown")
        end
    end

    for _, child in ipairs(obj:GetChildren()) do
        scanInstance(child, depth + 1)
    end
end

local function doScan()
    countLabel.Text = "Scanning... (checking group owner)"
    scanInstance(game.Workspace, 0)
    countLabel.Text = "Scan xong | " .. animCount .. " anim của group " .. TARGET_GROUP
end

task.spawn(doScan)

task.spawn(function()
    while true do
        task.wait(5)
        doScan()
    end
end)
