-- BlockSpin: Sticky Snappy Aimbot - Z ON (Aim In) | Z OFF (Un-Aim + Unlock)
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

local enabled = false
local currentTarget = nil
local highlights = {}
local tracerCenter = nil
local tracerBody = nil

local ESP_COLOR = Color3.fromRGB(255, 0, 0)
local TARGET_COLOR = Color3.fromRGB(0, 255, 0)

local SMOOTHNESS = 0.05   -- Snappy aim

local function createHighlight(character, color)
    if not character or highlights[character] then return end
    local hl = Instance.new("Highlight")
    hl.Adornee = character
    hl.FillColor = color
    hl.OutlineColor = color
    hl.FillTransparency = 0.5
    hl.OutlineTransparency = 0
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent = character
    highlights[character] = hl
end

local function removeHighlight(character)
    if highlights[character] then highlights[character]:Destroy() highlights[character] = nil end
end

local function isValidTarget(t)
    if not t or not t.head or not t.character then return false end
    local hum = t.character:FindFirstChild("Humanoid")
    if not hum or hum.Health <= 0 then return false end
    local vp = Camera:WorldToViewportPoint(t.head.Position)
    return vp.Z > 0
end

local function getClosestToMouse()
    local best, minDist = nil, math.huge
    local mPos = Vector2.new(Mouse.X, Mouse.Y)

    for _, plr in Players:GetPlayers() do
        if plr ~= LocalPlayer and plr.Character then
            local hum = plr.Character:FindFirstChild("Humanoid")
            if hum and hum.Health > 0 then
                local head = plr.Character:FindFirstChild("Head")
                if head then
                    local screen, onScreen = Camera:WorldToViewportPoint(head.Position)
                    if onScreen then
                        local dist = (Vector2.new(screen.X, screen.Y) - mPos).Magnitude
                        if dist < minDist then
                            minDist = dist
                            best = {head = head, character = plr.Character}
                        end
                    end
                end
            end
        end
    end
    return best
end

local function createTracers()
    if not tracerCenter then
        tracerCenter = Drawing.new("Line")
        tracerCenter.Thickness = 2
        tracerCenter.Color = Color3.fromRGB(0, 255, 0)
        tracerCenter.Transparency = 1
    end
    if not tracerBody then
        tracerBody = Drawing.new("Line")
        tracerBody.Thickness = 2
        tracerBody.Color = Color3.fromRGB(0, 200, 255)
        tracerBody.Transparency = 1
    end
end

local function isAiming()
    local char = LocalPlayer.Character
    if not char then return false end
    local tool = char:FindFirstChildOfClass("Tool")
    if not tool then return false end
    return tool:FindFirstChild("Aiming") or tool:FindFirstChild("ADS") or tool:FindFirstChild("Aim") 
        or tool:FindFirstChild("Zoom") or tool:FindFirstChild("Scope")
end

local function toggleQ()
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Q, false, game)
    task.wait(0.06)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Q, false, game)
end

local function equipGunIfAvailable()
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChild("Humanoid")
    if not hum or hum:FindFirstChildOfClass("Tool") then return end

    local bp = LocalPlayer:FindFirstChild("Backpack")
    if bp then
        for _, tool in ipairs(bp:GetChildren()) do
            if tool:IsA("Tool") then
                hum:EquipTool(tool)
                task.wait(0.1)
                break
            end
        end
    end
end

RunService.RenderStepped:Connect(function()
    if not enabled then
        currentTarget = nil
        if tracerCenter then tracerCenter.Visible = false end
        if tracerBody then tracerBody.Visible = false end
        return
    end

    if not isValidTarget(currentTarget) then
        currentTarget = getClosestToMouse()
    end

    -- Highlights
    for _, plr in Players:GetPlayers() do
        if plr ~= LocalPlayer and plr.Character then
            local isTarget = currentTarget and currentTarget.character == plr.Character
            createHighlight(plr.Character, isTarget and TARGET_COLOR or ESP_COLOR)
        end
    end

    for c in pairs(highlights) do
        if not c or not c.Parent or (c:FindFirstChild("Humanoid") and c.Humanoid.Health <= 0) then
            removeHighlight(c)
        end
    end

    if currentTarget and currentTarget.head then
        local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        
        local goal = CFrame.new(Camera.CFrame.Position, currentTarget.head.Position)
        Camera.CFrame = Camera.CFrame:Lerp(goal, SMOOTHNESS)

        createTracers()
        local h2d, onScr = Camera:WorldToViewportPoint(currentTarget.head.Position)
        local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)

        if onScr and root then
            tracerCenter.From = center
            tracerCenter.To = Vector2.new(h2d.X, h2d.Y)
            tracerCenter.Visible = true

            local b2d = Camera:WorldToViewportPoint(root.Position)
            tracerBody.From = Vector2.new(b2d.X, b2d.Y)
            tracerBody.To = Vector2.new(h2d.X, h2d.Y)
            tracerBody.Visible = true
        else
            tracerCenter.Visible = false
            tracerBody.Visible = false
        end

        -- Auto shoot
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
        task.wait(0.02)
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
    else
        if tracerCenter then tracerCenter.Visible = false end
        if tracerBody then tracerBody.Visible = false end
    end
end)

-- Z Toggle Logic
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.Z then
        enabled = not enabled

        if enabled then
            -- TURN ON
            equipGunIfAvailable()
            if not isAiming() then
                toggleQ()
            end
            print("✅ Aimlock ON + Aimed In")
        else
            -- TURN OFF + UN-AIM
            currentTarget = nil
            if tracerCenter then tracerCenter.Visible = false end
            if tracerBody then tracerBody.Visible = false end
            for c in pairs(highlights) do removeHighlight(c) end

            if isAiming() then
                toggleQ()
            end
            print("❌ Aimlock OFF + Un-Aimed")
        end
    end
end)

print("✅ Fresh Sticky Snappy Aimbot loaded on Xeno")
print("Press Z → ON + Aim In")
print("Press Z again → OFF + Un-Aim")