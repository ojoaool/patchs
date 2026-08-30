-- ╔══════════════════════════════════════════╗
-- ║           VANTA UI FRAMEWORK             ║
-- ║         dark · glassmorphism             ║
-- ╚══════════════════════════════════════════╝
--
-- Usage:
--   local lib = loadstring(...)()
--   local win = lib:init("MyHub", "v1.0", "rbxassetid://XXX", Enum.KeyCode.Insert, true)
--
--   local tab = win:Section("Combat", "rbxassetid://XXX")
--   local grp = tab:Group("Aimbot", "rbxassetid://XXX")
--
--   grp:Toggle("Enabled", false, function(v) end)
--   grp:ToggleInput("Auto Stat", "desc", 800, false, function(state, num) end)
--   grp:ToggleKeybind("Tp Behind", "desc", Enum.KeyCode.N, false, function(state) end)
--   grp:Slider("Smoothness", 0, 100, 35, function(v) end)
--   grp:Dropdown("Target", {"Head","Torso","HRP"}, "Head", function(v) end)
--   grp:MultiDropdown("Layers", {"Box","Name","HP"}, {"Box"}, function(t) end)
--   grp:Button("Fire", function() end)
--   grp:Label("Some text")
--   grp:Paragraph("Long description here...")
--   grp:TextField("Name", "Enter...", function(v) end)
--   grp:ColorDot("Color", Color3.fromRGB(80,140,255), function(c) end)
--   grp:Keybind("Hold Key", Enum.KeyCode.C, function(k) end)
--   grp:SectionLabel("Sub Section")
--
--   win:TempNotify("Title", "Message", "success", 4)   -- type: success/warn/error/info
--   win:Notify("Title", "Body", "OK", "rbxassetid://XXX", callback)
--   win:Notify2("Title", "Body", "Yes", "No", "rbxassetid://XXX", cb1, cb2)
--   win:Divider("SYSTEM")
--   win:ToggleVisible()

-- ─── filesystem compat (copiado do Linoria SaveManager) ───────────────────────
-- corrige exploiters onde isfolder/isfile/listfiles erram em vez de retornar false/{}
if copyfunction and isfolder then
    local isfolder_  = copyfunction(isfolder)
    local isfile_    = copyfunction(isfile)
    local listfiles_ = copyfunction(listfiles)
    local ok, err = pcall(function() return isfolder_(tostring(math.random(999999999, 999999999999))) end)
    if ok == false or (tostring(err):match("not") and tostring(err):match("found")) then
        getgenv().isfolder = function(folder)
            local s, data = pcall(function() return isfolder_(folder) end)
            if not s then return nil end
            return data
        end
        getgenv().isfile = function(file)
            local s, data = pcall(function() return isfile_(file) end)
            if not s then return nil end
            return data
        end
        getgenv().listfiles = function(folder)
            local s, data = pcall(function() return listfiles_(folder) end)
            if not s then return {} end
            return data
        end
    end
end

local lib = {}

local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local Debris            = game:GetService("Debris")
local RunService        = game:GetService("RunService")
local HttpService       = game:GetService("HttpService")

-- ─── tween helper ──────────────────────────────────────────────────────────
local function tw(obj, props, t, style, dir)
    TweenService:Create(
        obj,
        TweenInfo.new(t or 0.18, style or Enum.EasingStyle.Quart, dir or Enum.EasingDirection.Out),
        props
    ):Play()
end

local function slideOpen(panel)
    panel.AutomaticSize = Enum.AutomaticSize.None
    panel.Size = UDim2.new(panel.Size.X.Scale, panel.Size.X.Offset, 0, 0)
    panel.Visible = true
    local layout = panel:FindFirstChildWhichIsA("UIListLayout")
    local padding = panel:FindFirstChildWhichIsA("UIPadding")
    local padY = padding and (padding.PaddingTop.Offset + padding.PaddingBottom.Offset) or 0
    local targetH = (layout and layout.AbsoluteContentSize.Y or 0) + padY
    if targetH == 0 then
        task.wait()
        targetH = (layout and layout.AbsoluteContentSize.Y or 0) + padY
    end
    tw(panel, {Size = UDim2.new(panel.Size.X.Scale, panel.Size.X.Offset, 0, targetH)}, 0.2)
    task.delay(0.21, function() panel.AutomaticSize = Enum.AutomaticSize.Y end)
end

local function slideClose(panel)
    panel.AutomaticSize = Enum.AutomaticSize.None
    tw(panel, {Size = UDim2.new(panel.Size.X.Scale, panel.Size.X.Offset, 0, 0)}, 0.15)
    task.delay(0.16, function() panel.Visible = false end)
end

-- ─── safeClick: previne cliques acidentais durante scroll no mobile ────────
local SCROLL_THRESHOLD = 10 -- pixels de movimento que cancelam o tap
local function safeClick(btn, fn)
    local startPos = nil
    btn.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.Touch or
           i.UserInputType == Enum.UserInputType.MouseButton1 then
            startPos = i.Position
        end
    end)
    btn.InputEnded:Connect(function(i)
        if not startPos then return end
        if i.UserInputType == Enum.UserInputType.Touch or
           i.UserInputType == Enum.UserInputType.MouseButton1 then
            local delta = (Vector2.new(i.Position.X, i.Position.Y) - Vector2.new(startPos.X, startPos.Y)).Magnitude
            if delta < SCROLL_THRESHOLD then fn() end
            startPos = nil
        end
    end)
end

-- ─── instance shortcuts ────────────────────────────────────────────────────
local function applyProps(inst, props)
    for k, v in pairs(props or {}) do inst[k] = v end
    return inst
end

local function Frame(parent, props)
    local f = Instance.new("Frame")
    f.BorderSizePixel = 0
    applyProps(f, props)
    f.Parent = parent
    return f
end

local function Label(parent, props)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.BorderSizePixel = 0
    l.Font = Enum.Font.FredokaOne
    applyProps(l, props)
    l.Parent = parent
    return l
end

local function Button(parent, props)
    local b = Instance.new("TextButton")
    b.AutoButtonColor = false
    b.BorderSizePixel = 0
    b.Font = Enum.Font.FredokaOne
    applyProps(b, props)
    b.Parent = parent
    return b
end

local function Image(parent, props)
    local i = Instance.new("ImageLabel")
    i.BackgroundTransparency = 1
    i.BorderSizePixel = 0
    applyProps(i, props)
    i.Parent = parent
    return i
end

local function Corner(parent, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 8)
    c.Parent = parent
    return c
end

local function Stroke(parent, col, thick, trans)
    local s = Instance.new("UIStroke")
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Color = col or Color3.fromRGB(255,255,255)
    s.Thickness = thick or 1
    s.Transparency = trans or 0.92
    s.Parent = parent
    return s
end

local function ListLayout(parent, props)
    local l = Instance.new("UIListLayout")
    l.SortOrder = Enum.SortOrder.LayoutOrder
    applyProps(l, props)
    l.Parent = parent
    return l
end

local function Padding(parent, t, b, l, r)
    local p = Instance.new("UIPadding")
    p.PaddingTop    = UDim.new(0, t or 0)
    p.PaddingBottom = UDim.new(0, b or 0)
    p.PaddingLeft   = UDim.new(0, l or 0)
    p.PaddingRight  = UDim.new(0, r or 0)
    p.Parent = parent
    return p
end

-- ─── palette ───────────────────────────────────────────────────────────────
local C = {
    bg       = Color3.fromRGB(14,  14,  14),   -- #0e0e0e fundo da janela
    sidebar  = Color3.fromRGB(22,  22,  22),   -- #161616 sidebar
    surface  = Color3.fromRGB(18,  18,  18),   -- #121212 surface/modal
    element  = Color3.fromRGB(18,  18,  18),   -- #121212 elementos
    white    = Color3.fromRGB(255, 255, 255),  -- #ffffff branco puro
    hi       = Color3.fromRGB(224, 224, 224),  -- #e0e0e0 texto principal
    mid      = Color3.fromRGB(170, 170, 170),  -- #aaaaaa cinza médio
    low      = Color3.fromRGB(102, 102, 102),  -- #666666 texto inativo
    dim      = Color3.fromRGB(68,  68,  68),   -- #444444 descrição/placeholder
    border   = Color3.fromRGB(42,  42,  42),   -- #2a2a2a bordas sutis
    accent   = Color3.fromRGB(220,   220,  220),  -- branco accent
    accentBg = Color3.fromRGB(224,   224,  224),  -- branco claro hover
    onBg     = Color3.fromRGB(137,137,137),  -- Branco toggle ON
    offBg    = Color3.fromRGB(30,  30,  30),   -- #262626 toggle OFF
    knob     = Color3.fromRGB(15,  15,  15),   -- #0f0f0f
    toastBg  = Color3.fromRGB(10,  10,  10),   -- #0a0a0a
    success  = Color3.fromRGB(76,  175, 80),   -- #4caf50 verde
    warn     = Color3.fromRGB(255, 179, 0),    -- #ffb300 amarelo
    err      = Color3.fromRGB(244, 67,  54),   -- #f44336 vermelho
    info     = Color3.fromRGB(200, 200, 200),  -- #c8c8c8 cinza claro
}

-- ═══════════════════════════════════════════════════════════════════════════
function lib:init(title, subtitle, logoAsset, visibleKey, deletePrevious, logoSize)
    visibleKey = visibleKey or Enum.KeyCode.RightControl

    -- ── ScreenGui ──────────────────────────────────────────────────────────
    local hui = gethui()
    if hui:FindFirstChild("VantaUI") and deletePrevious then
        local old = hui.VantaUI
        local oldOuter = old:FindFirstChild("main")
        if oldOuter then
            tw(oldOuter, {Position = oldOuter.Position + UDim2.new(0,0,2,0)}, 0.4)
        end
        Debris:AddItem(old, 0.5)
    end

    local scrgui = Instance.new("ScreenGui")
    scrgui.Name           = "VantaUI"
    scrgui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    scrgui.ResetOnSpawn   = false
    scrgui.Parent         = hui

    -- ── main window  820 × 440 ─────────────────────────────────────────
    local main = Frame(scrgui, {
        Name                 = "main",
        AnchorPoint          = Vector2.new(0.5, 0.5),
        Position             = UDim2.new(0.5, 0, 2, 0),
        Size                 = UDim2.new(0, 820, 0, 500),
        BackgroundColor3     = Color3.fromRGB(15, 15, 15),
        BackgroundTransparency = 0.05,
        ClipsDescendants     = true,
        ZIndex               = 1,
    })
    Corner(main, 8)
    Stroke(main, Color3.fromRGB(255,255,255), 1, 0.82)

    -- ── acrylic blur (portado da MacLib) ─────────────────────────────────────
    local acrylicBlur = false
    local BlurTarget = main
    local camera = workspace.CurrentCamera
    local MTREL = "Glass"
    local binds = {}
    local wedgeguid = HttpService:GenerateGUID(true)

    local DepthOfField

    for _, v in pairs(game:GetService("Lighting"):GetChildren()) do
        if not v:IsA("DepthOfFieldEffect") and v:HasTag(".") then
            DepthOfField = Instance.new("DepthOfFieldEffect", game:GetService("Lighting"))
            DepthOfField.FarIntensity = 0
            DepthOfField.FocusDistance = 51.6
            DepthOfField.InFocusRadius = 50
            DepthOfField.NearIntensity = 1
            DepthOfField.Name = HttpService:GenerateGUID(true)
            DepthOfField:AddTag(".")
        elseif v:IsA("DepthOfFieldEffect") and v:HasTag(".") then
            DepthOfField = v
        end
    end

    if not DepthOfField then
        DepthOfField = Instance.new("DepthOfFieldEffect", game:GetService("Lighting"))
        DepthOfField.FarIntensity = 0
        DepthOfField.FocusDistance = 51.6
        DepthOfField.InFocusRadius = 50
        DepthOfField.NearIntensity = 1
        DepthOfField.Name = HttpService:GenerateGUID(true)
        DepthOfField:AddTag(".")
    end

    local blurFrame = Instance.new("Frame")
    blurFrame.Parent = BlurTarget
    blurFrame.Size = UDim2.new(0.97, 0, 0.97, 0)
    blurFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    blurFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    blurFrame.BackgroundTransparency = 1
    blurFrame.Name = HttpService:GenerateGUID(true)

    do
        local function IsNotNaN(x) return x == x end
        local continue = IsNotNaN(camera:ScreenPointToRay(0, 0).Origin.x)
        while not continue do
            RunService.RenderStepped:wait()
            continue = IsNotNaN(camera:ScreenPointToRay(0, 0).Origin.x)
        end
    end

    local blurParts = {}

    local DrawQuad do
        local acos, max, pi, sqrt = math.acos, math.max, math.pi, math.sqrt
        local sz = 0.2

        local function DrawTriangle(v1, v2, v3, p0, p1)
            local s1 = (v1 - v2).magnitude
            local s2 = (v2 - v3).magnitude
            local s3 = (v3 - v1).magnitude
            local smax = max(s1, s2, s3)
            local A, B, C
            if s1 == smax then A, B, C = v1, v2, v3
            elseif s2 == smax then A, B, C = v2, v3, v1
            elseif s3 == smax then A, B, C = v3, v1, v2 end

            local para = ((B-A).x*(C-A).x + (B-A).y*(C-A).y + (B-A).z*(C-A).z) / (A-B).magnitude
            local perp = sqrt((C-A).magnitude^2 - para*para)
            local dif_para = (A-B).magnitude - para

            local st = CFrame.new(B, A)
            local za = CFrame.Angles(pi/2, 0, 0)
            local cf0 = st
            local Top_Look = (cf0 * za).lookVector
            local Mid_Point = A + CFrame.new(A, B).lookVector * para
            local Needed_Look = CFrame.new(Mid_Point, C).lookVector
            local dot = Top_Look.x*Needed_Look.x + Top_Look.y*Needed_Look.y + Top_Look.z*Needed_Look.z
            local ac = CFrame.Angles(0, 0, acos(dot))
            cf0 = cf0 * ac
            if ((cf0 * za).lookVector - Needed_Look).magnitude > 0.01 then
                cf0 = cf0 * CFrame.Angles(0, 0, -2*acos(dot))
            end
            cf0 = cf0 * CFrame.new(0, perp/2, -(dif_para + para/2))
            local cf1 = st * ac * CFrame.Angles(0, pi, 0)
            if ((cf1 * za).lookVector - Needed_Look).magnitude > 0.01 then
                cf1 = cf1 * CFrame.Angles(0, 0, 2*acos(dot))
            end
            cf1 = cf1 * CFrame.new(0, perp/2, dif_para/2)

            if not p0 then
                p0 = Instance.new("Part")
                p0.FormFactor = "Custom"
                p0.TopSurface = 0
                p0.BottomSurface = 0
                p0.Anchored = true
                p0.CanCollide = false
                p0.CastShadow = false
                p0.Material = MTREL
                p0.Size = Vector3.new(sz, sz, sz)
                p0.Name = HttpService:GenerateGUID(true)
                local mesh = Instance.new("SpecialMesh", p0)
                mesh.MeshType = 2
                mesh.Name = wedgeguid
            end
            p0[wedgeguid].Scale = Vector3.new(0, perp/sz, para/sz)
            p0.CFrame = cf0

            if not p1 then p1 = p0:clone() end
            p1[wedgeguid].Scale = Vector3.new(0, perp/sz, dif_para/sz)
            p1.CFrame = cf1

            return p0, p1
        end

        function DrawQuad(v1, v2, v3, v4, parts)
            parts[1], parts[2] = DrawTriangle(v1, v2, v3, parts[1], parts[2])
            parts[3], parts[4] = DrawTriangle(v3, v2, v4, parts[3], parts[4])
        end
    end

    local blurParents = {}
    do
        local function add(child)
            if child:IsA("GuiObject") then
                blurParents[#blurParents + 1] = child
                add(child.Parent)
            end
        end
        add(blurFrame)
    end

    local function IsVisible(instance)
        while instance do
            if instance:IsA("GuiObject") then
                if not instance.Visible then return false end
            elseif instance:IsA("ScreenGui") then
                if not instance.Enabled then return false end
                break
            end
            instance = instance.Parent
        end
        return true
    end

    local function UpdateBlurOrientation(fetchProps)
        if not IsVisible(blurFrame) or not acrylicBlur then
            for _, pt in pairs(blurParts) do
                pt.Parent = nil
            end
            DepthOfField.Enabled = false
            return
        end
        DepthOfField.Enabled = true
        local properties = {
            Transparency = 0.98,
            BrickColor = BrickColor.new("Institutional white"),
        }
        local zIndex = 1 - 0.05 * blurFrame.ZIndex
        local tl, br = blurFrame.AbsolutePosition, blurFrame.AbsolutePosition + blurFrame.AbsoluteSize
        local tr, bl = Vector2.new(br.x, tl.y), Vector2.new(tl.x, br.y)
        do
            local rot = 0
            for _, v in ipairs(blurParents) do rot = rot + v.Rotation end
            if rot ~= 0 and rot % 180 ~= 0 then
                local mid = tl:lerp(br, 0.5)
                local s, c = math.sin(math.rad(rot)), math.cos(math.rad(rot))
                tl = Vector2.new(c*(tl.x-mid.x) - s*(tl.y-mid.y), s*(tl.x-mid.x) + c*(tl.y-mid.y)) + mid
                tr = Vector2.new(c*(tr.x-mid.x) - s*(tr.y-mid.y), s*(tr.x-mid.x) + c*(tr.y-mid.y)) + mid
                bl = Vector2.new(c*(bl.x-mid.x) - s*(bl.y-mid.y), s*(bl.x-mid.x) + c*(bl.y-mid.y)) + mid
                br = Vector2.new(c*(br.x-mid.x) - s*(br.y-mid.y), s*(br.x-mid.x) + c*(br.y-mid.y)) + mid
            end
        end
        DrawQuad(
            camera:ScreenPointToRay(tl.x, tl.y, zIndex).Origin,
            camera:ScreenPointToRay(tr.x, tr.y, zIndex).Origin,
            camera:ScreenPointToRay(bl.x, bl.y, zIndex).Origin,
            camera:ScreenPointToRay(br.x, br.y, zIndex).Origin,
            blurParts
        )
        if fetchProps then
            for _, pt in pairs(blurParts) do pt.Parent = camera end
            for propName, propValue in pairs(properties) do
                for _, pt in pairs(blurParts) do pt[propName] = propValue end
            end
        end
    end

    UpdateBlurOrientation(true)
    RunService.RenderStepped:Connect(UpdateBlurOrientation)
    -- ─────────────────────────────────────────────────────────────────────────



    -- ── sidebar full-height (56px) ────────────────────────────────────────
    local sidebar = Frame(main, {
        Name                 = "sidebar",
        Position             = UDim2.new(0,8,0,8),
        Size                 = UDim2.new(0,56,1,-16),
        BackgroundColor3     = C.sidebar,
        BackgroundTransparency = 0,
        ClipsDescendants     = true,
        ZIndex               = 3,
    })
    Corner(sidebar, 8)
    Stroke(sidebar, C.border, 1, 0)

    -- ── logo no topo da sidebar ───────────────────────────────────────────
    local logoBlock = Frame(sidebar, {
        Position             = UDim2.new(0,0,0,0),
        Size                 = UDim2.new(1,0,0,56),
        BackgroundTransparency = 1,
        ZIndex               = 4,
    })
    if logoAsset and logoAsset ~= "" then
        local lSize = logoSize and UDim2.new(0, logoSize, 0, logoSize) or UDim2.new(0.75, 0, 0.75, 0)
        -- bolinha atrás da logo com glow igual à pill
        local logoGlowDot = Frame(logoBlock, {
            AnchorPoint          = Vector2.new(0.5, 0.5),
            Position             = UDim2.new(0.5, 0, 0.5, 0),
            Size                 = UDim2.new(0, 8, 0, 8),
            BackgroundColor3     = C.accent,
            BackgroundTransparency = 0,
            ZIndex               = 3,
        })
        Corner(logoGlowDot, 99)
        local logoGlowShadow = Instance.new("UIShadow")
        logoGlowShadow.Color        = C.accent
        logoGlowShadow.BlurRadius   = UDim.new(0, 24)
        logoGlowShadow.Spread       = UDim2.fromOffset(6, 8)
        logoGlowShadow.Offset       = UDim2.fromOffset(0, 0)
        logoGlowShadow.Transparency = 0.05
        logoGlowShadow.ZIndex       = -1
        logoGlowShadow.Parent       = logoGlowDot

        local logoImg = Image(logoBlock, {
            AnchorPoint       = Vector2.new(0.5,0.5),
            Position          = UDim2.new(0.5,0,0.5,0),
            Size              = lSize,
            Image             = logoAsset,
            ImageColor3       = C.white,
            ImageTransparency = 0.1,
            ScaleType         = Enum.ScaleType.Fit,
            ZIndex            = 4,
        })
    else
        Label(logoBlock, {
            AnchorPoint    = Vector2.new(0.5,0.5),
            Position       = UDim2.new(0.5,0,0.5,0),
            Size           = UDim2.new(1,0,1,0),
            Text           = string.upper((title or "V"):sub(1,1)),
            TextColor3     = C.hi,
            TextSize       = 18,
            Font           = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Center,
            ZIndex         = 4,
        })
    end

    -- separador abaixo do logo
    Frame(sidebar, {
        Position             = UDim2.new(0,8,0,56),
        Size                 = UDim2.new(1,-16,0,1),
        BackgroundColor3     = C.border,
        BackgroundTransparency = 0,
        ZIndex               = 4,
    })


    -- ── scroll dos tab buttons ────────────────────────────────────────────
    local sidebarScroll = Instance.new("ScrollingFrame")
    sidebarScroll.Name                = "sidebarScroll"
    sidebarScroll.Position            = UDim2.new(0,0,0,118)
    sidebarScroll.Size                = UDim2.new(1,0,1,-118)
    sidebarScroll.BackgroundTransparency = 1
    sidebarScroll.BorderSizePixel     = 0
    sidebarScroll.ScrollBarThickness  = 0
    sidebarScroll.ScrollBarImageColor3 = C.dim
    sidebarScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    sidebarScroll.CanvasSize          = UDim2.new(0,0,0,0)
    sidebarScroll.ZIndex              = 3
    sidebarScroll.Parent              = sidebar
    ListLayout(sidebarScroll, {
        Padding                  = UDim.new(0,4),
        HorizontalAlignment      = Enum.HorizontalAlignment.Center,
    })
    Padding(sidebarScroll, 6,6,0,0)

    -- searchBox dummy (mantido pra não quebrar o filtro de tabs)
    local searchBox = Instance.new("TextBox")
    searchBox.Text    = ""
    searchBox.Parent  = sidebarScroll
    searchBox.Visible = false

    -- ── pill — barra vertical de 3px na borda esquerda da sidebar ────────
    local pill = Frame(sidebar, {
        Name                 = "pill",
        Position             = UDim2.new(0,0,0,118),
        Size                 = UDim2.new(0,4,0,14),
        BackgroundColor3     = C.accent,   -- branco
        BackgroundTransparency = 0,
        ZIndex               = 6,
    })
    Corner(pill, 2)

    -- ── pill fantasma — invisível, só pra carregar o UIShadow ────────────
    local pillGlow = Frame(sidebar, {
        Name                 = "pillGlow",
        Position             = UDim2.new(0,0,0,118),
        Size                 = UDim2.new(0,4,0,14),
        BackgroundColor3     = C.accent,
        BackgroundTransparency = 1,
        ZIndex               = 5,
    })
    Corner(pillGlow, 6)
    local pillShadow = Instance.new("UIShadow")
    pillShadow.Color        = C.accent
    pillShadow.BlurRadius   = UDim.new(0, 30)
    pillShadow.Spread       = UDim2.fromOffset(8, 10)
    pillShadow.Offset       = UDim2.fromOffset(0, 0)
    pillShadow.Transparency = 0
    pillShadow.ZIndex       = -1
    pillShadow.Parent       = pillGlow

    -- ── state ─────────────────────────────────────────────────────────────
    local sections     = {}
    local workareas    = {}
    local visible      = true
    local dbc          = false
    -- ── toast container (empilhamento estilo Linoria) ──────────────────────
    local toastContainer = Frame(nil, {
        Name             = "VantaToastContainer",
        AnchorPoint      = Vector2.new(0, 0),
        Position         = UDim2.new(0, 12, 0, 12),
        Size             = UDim2.new(0, 400, 1, -24),
        BackgroundTransparency = 1,
        ZIndex           = 50,
    })
    ListLayout(toastContainer, {
        FillDirection = Enum.FillDirection.Vertical,
        VerticalAlignment = Enum.VerticalAlignment.Top,
        Padding = UDim.new(0, 6),
    })
    toastContainer.Parent = scrgui

    -- ── mobile detection ──────────────────────────────────────────────────
    local forceMobile     = false  -- muda pra false em produção
    local _vp             = workspace.CurrentCamera.ViewportSize
    local useMobileSizing = forceMobile or (_vp.X < 1024 and _vp.Y < 768)
    local useMobilePrompt = forceMobile or UserInputService.TouchEnabled

    local W_DESK, H_DESK = 820, 460
    local W_MOB,  H_MOB  = 500, 275
    local W_open  = useMobileSizing and W_MOB  or W_DESK
    local H_open  = useMobileSizing and H_MOB  or H_DESK
    local W_seed  = useMobileSizing and 300     or 492
    local H_seed  = useMobileSizing and 165     or 264

    -- ── drag ──────────────────────────────────────────────────────────────
    local drag, dragStart, startPos
    main.InputBegan:Connect(function(i)
        if i.UserInputType ~= Enum.UserInputType.MouseButton1 and i.UserInputType ~= Enum.UserInputType.Touch then return end
        local relY = i.Position.Y - main.AbsolutePosition.Y
        local relX = i.Position.X - main.AbsolutePosition.X
        if useMobileSizing then
            if relY > 44 then return end
        else
            if relX > 72 then return end
        end
        drag = true; dragStart = i.Position; startPos = main.Position
        i.Changed:Connect(function()
            if i.UserInputState == Enum.UserInputState.End then drag = false end
        end)
    end)
    UserInputService.InputChanged:Connect(function(i)
        if drag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position - dragStart
            main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X,
                                           startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)

    -- animate in: grow + fade
    main.Size = UDim2.new(0, W_seed, 0, H_seed)
    main.BackgroundTransparency = 1
    main.Position = UDim2.new(0.5, 0, 0.5, 0)
    main.Visible = true
    tw(main, {Size = UDim2.new(0, W_open, 0, H_open), BackgroundTransparency = 0.05}, 0.55, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

    -- ═════════════════════════════════════════════════════════════════════
    local window = {}

    -- ── Config Registry (copiado do Feral) ───────────────────────────────
    local Registry = { Toggles = {}, Sliders = {}, Dropdowns = {}, Keybinds = {}, Boxes = {} }
    local ConfigFolder = "VantaUI/Configs"
    local HttpService  = game:GetService("HttpService")

    local function ensureFolder()
        if not isfolder("VantaUI") then makefolder("VantaUI") end
        if not isfolder(ConfigFolder) then makefolder(ConfigFolder) end
    end

    -- List: igual ao Linoria RefreshConfigList — faz makefolder antes do listfiles
    -- para forçar sincronização do filesystem no exploiter
    function window:ListConfigs()
        -- CheckFolderTree: recria as pastas pra forçar sync do filesystem (Linoria)
        local paths = { "VantaUI", ConfigFolder }
        for _, p in ipairs(paths) do
            if not isfolder(p) then makefolder(p) end
        end
        local files = listfiles(ConfigFolder)
        local names = {}
        for i = 1, #files do
            local f = files[i]
            if f:sub(-5) == ".json" then
                local pos = f:find(".json", 1, true)
                local start = pos
                local char = f:sub(pos, pos)
                while char ~= "/" and char ~= "\\" and char ~= "" do
                    pos = pos - 1
                    char = f:sub(pos, pos)
                end
                if char == "/" or char == "\\" then
                    table.insert(names, f:sub(pos + 1, start - 1))
                end
            end
        end
        return names
    end

    -- Save: copiado do Feral
    function window:SaveConfig(name)
        if not name or name == "" then return false, "No config name" end
        ensureFolder()
        local data = { Toggles = {}, Sliders = {}, Dropdowns = {}, Keybinds = {}, Boxes = {} }
        for id, obj in pairs(Registry.Toggles)   do local ok, v = pcall(obj.Get); if ok then data.Toggles[id]   = v end end
        for id, obj in pairs(Registry.Sliders)   do local ok, v = pcall(obj.Get); if ok then data.Sliders[id]   = v end end
        for id, obj in pairs(Registry.Dropdowns) do local ok, v = pcall(obj.Get); if ok then data.Dropdowns[id] = v end end
        for id, obj in pairs(Registry.Keybinds)  do local ok, v = pcall(obj.Get); if ok then data.Keybinds[id]  = v end end
        for id, obj in pairs(Registry.Boxes)     do local ok, v = pcall(obj.Get); if ok then data.Boxes[id]     = v end end
        local ok, err = pcall(function()
            writefile(ConfigFolder .. "/" .. name .. ".json", HttpService:JSONEncode(data))
        end)
        return ok, err
    end

    -- Load: copiado do Feral
    function window:LoadConfig(name)
        if not name or name == "" then return false, "No config name" end
        ensureFolder()
        local path = ConfigFolder .. "/" .. name .. ".json"
        if not isfile(path) then return false, "Config not found" end
        local raw = readfile(path)
        local ok, data = pcall(function() return HttpService:JSONDecode(raw) end)
        if not ok or type(data) ~= "table" then return false, "Invalid config data" end
        local apply = function(label, reg, saved)
            if not saved then return end
            for id, val in pairs(saved) do
                local obj = reg[id]
                if obj and obj.Set then
                    task.spawn(function()
                        local s, e = pcall(obj.Set, val)
                        if not s then warn("[Config]", label, "Set failed for id:", id, e) end
                    end)
                end
            end
        end
        task.spawn(function() apply("Toggle",   Registry.Toggles,   data.Toggles)   end)
        task.spawn(function() apply("Slider",   Registry.Sliders,   data.Sliders)   end)
        task.spawn(function() apply("Dropdown", Registry.Dropdowns, data.Dropdowns) end)
        task.spawn(function() apply("Keybind",  Registry.Keybinds,  data.Keybinds)  end)
        task.spawn(function() apply("Box",      Registry.Boxes,     data.Boxes)     end)
        return true
    end

    -- Delete: copiado do Feral
    function window:DeleteConfig(name)
        if not name or name == "" then return false, "No config name" end
        ensureFolder()
        local path = ConfigFolder .. "/" .. name .. ".json"
        if not isfile(path) then return false, "Config not found" end
        local ok, err = pcall(function() delfile(path) end)
        return ok, err
    end

    -- Autoload
    local autoloadFile = ConfigFolder .. "/autoload.txt"

    function window:SetAutoload(name)
        ensureFolder()
        pcall(function() writefile(autoloadFile, name) end)
    end

    function window:GetAutoload()
        if isfile(autoloadFile) then
            local ok, name = pcall(function() return readfile(autoloadFile) end)
            if ok and name and name ~= "" then return name end
        end
        return nil
    end

    function window:LoadAutoloadConfig()
        local name = self:GetAutoload()
        if not name then return end
        local ok, err = self:LoadConfig(name)
        if ok then
            self:TempNotify("Configs", 'Auto-loaded "' .. name .. '"', "success", 5)
        else
            self:TempNotify("Configs", "Auto-load failed: " .. tostring(err), "error", 5)
        end
    end

    -- ── ToggleVisible ─────────────────────────────────────────────────────
    -- ── MPrompt ───────────────────────────────────────────────────────────
    if useMobilePrompt then
        local MP_CIRCLE = 41
        local MP_OVERLAP = 20
        local MP_Y = 14

        local mWrap = Frame(scrgui, {
            Name                 = "MPrompt",
            AnchorPoint          = Vector2.new(0.5, 0),
            Position             = UDim2.new(0.5, 0, 0, MP_Y),
            Size                 = UDim2.new(0, 0, 0, 0),
            AutomaticSize        = Enum.AutomaticSize.XY,
            BackgroundTransparency = 1,
            ClipsDescendants     = false,
            ZIndex               = 60,
        })

        local mPill = Button(mWrap, {
            Name                 = "MPill",
            AnchorPoint          = Vector2.new(0, 0.5),
            Position             = UDim2.new(0, MP_CIRCLE - MP_OVERLAP, 0.5, 0),
            Size                 = UDim2.new(0, 0, 0, 0),
            AutomaticSize        = Enum.AutomaticSize.XY,
            BackgroundColor3     = C.sidebar,
            ClipsDescendants     = false,
            ZIndex               = 61,
        })
        Corner(mPill, 99)
        Padding(mPill, 6, 6, MP_OVERLAP + 8, 12)

        Label(mPill, {
            AnchorPoint      = Vector2.new(0, 0.5),
            Position         = UDim2.new(0, 0, 0.5, 0),
            Size             = UDim2.new(0, 0, 0, 0),
            AutomaticSize    = Enum.AutomaticSize.XY,
            Text             = "Show or hide " .. (title or "Hub"),
            TextColor3       = C.hi,
            TextSize         = 12,
            Font             = Enum.Font.GothamMedium,
            TextXAlignment   = Enum.TextXAlignment.Left,
            TextTruncate     = Enum.TextTruncate.None,
            ZIndex           = 62,
        })

        local mCircle = Frame(mWrap, {
            Name             = "MCircle",
            AnchorPoint      = Vector2.new(0, 0.5),
            Position         = UDim2.new(0, 0, 0.5, 0),
            Size             = UDim2.new(0, MP_CIRCLE, 0, MP_CIRCLE),
            BackgroundColor3 = C.sidebar,
            ZIndex           = 63,
        })
        Corner(mCircle, 99)
        Stroke(mCircle, C.accent, 2, 0)

        local mGlowDot = Frame(mCircle, {
            AnchorPoint          = Vector2.new(0.5, 0.5),
            Position             = UDim2.new(0.5, 0, 0.5, 0),
            Size                 = UDim2.new(0, 8, 0, 8),
            BackgroundColor3     = C.accent,
            BackgroundTransparency = 0,
            ZIndex               = 64,
        })
        Corner(mGlowDot, 99)
        local mGlowShadow = Instance.new("UIShadow")
        mGlowShadow.Color        = C.accent
        mGlowShadow.BlurRadius   = UDim.new(0, 24)
        mGlowShadow.Spread       = UDim2.fromOffset(6, 8)
        mGlowShadow.Offset       = UDim2.fromOffset(0, 0)
        mGlowShadow.Transparency = 0.05
        mGlowShadow.ZIndex       = -1
        mGlowShadow.Parent       = mGlowDot

        Image(mCircle, {
            AnchorPoint          = Vector2.new(0.5, 0.5),
            Position             = UDim2.new(0.5, 0, 0.5, 0),
            Size                 = UDim2.new(0, MP_CIRCLE * 0.88, 0, MP_CIRCLE * 0.88),
            Image                = logoAsset or "",
            ScaleType            = Enum.ScaleType.Fit,
            ZIndex               = 65,
        })

        local mCircleBtn = Button(mCircle, {
            Size                   = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            ZIndex                 = 66,
        })

        mPill.MouseEnter:Connect(function()
            tw(mPill, {BackgroundColor3 = C.offBg}, 0.12)
        end)
        mPill.MouseLeave:Connect(function()
            tw(mPill, {BackgroundColor3 = C.sidebar}, 0.12)
        end)
        mPill.MouseButton1Click:Connect(function() window:ToggleVisible() end)
        mCircleBtn.MouseButton1Click:Connect(function() window:ToggleVisible() end)
    end

    function window:ToggleVisible()
        if dbc then return end
        visible = not visible
        dbc = true
        if visible then
            main.Visible = true
            main.Size    = UDim2.new(0, W_seed, 0, H_seed)
            main.BackgroundTransparency = 1
            tw(main, {Size = UDim2.new(0, W_open, 0, H_open), BackgroundTransparency = 0.05}, 0.55, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
            task.delay(0.55, function() dbc = false end)
        else
            tw(main, {Size = UDim2.new(0, W_open * 0.95, 0, H_open * 0.95), BackgroundTransparency = 1}, 0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
            task.delay(0.28, function() main.Visible = false end)
            task.delay(0.25, function() dbc = false end)
        end
    end

    -- toggle via keybind
    local menuKey = visibleKey
    function window:SetMenuKey(kc) menuKey = kc end
    function window:GetMenuKey() return menuKey end

    if menuKey then
        UserInputService.InputBegan:Connect(function(i, gp)
            if not gp and i.KeyCode == menuKey then window:ToggleVisible() end
        end)
    end

    -- ── TempNotify (visual estilo Linoria) ───────────────────────────────
    function window:TempNotify(toastTitle, message, notifType, duration)
        duration = duration or 4

        -- cor da barra lateral baseada no tipo
        local accentCol = C.accent
        if notifType == "success" then accentCol = C.success
        elseif notifType == "warn"    then accentCol = C.warn
        elseif notifType == "error"   then accentCol = C.err
        end

        -- texto completo: "Título: mensagem"
        local fullText = (toastTitle or "") .. ": " .. (message or "")
        local ts = game:GetService("TextService")
        local textW = ts:GetTextSize(fullText, 14, Enum.Font.Gotham, Vector2.new(9999, 999)).X
        local textH = ts:GetTextSize(fullText, 14, Enum.Font.Gotham, Vector2.new(9999, 999)).Y
        local ySize = textH + 7
        local xSize = textW + 8 + 4  -- +8 padding texto, +4 margem barra

        -- NotifyOuter: começa X=0, ClipsDescendants corta durante expand
        local toast = Frame(toastContainer, {
            Name             = "VantaToast",
            Size             = UDim2.new(0, 0, 0, ySize),
            BackgroundColor3 = C.bg,
            ClipsDescendants = true,
            ZIndex           = 50,
        })

        -- NotifyInner: fundo escuro com borda
        local inner = Frame(toast, {
            Size             = UDim2.new(1, 0, 1, 0),
            BackgroundColor3 = C.surface,
            ZIndex           = 51,
        })
        Stroke(inner, C.border, 1, 0)

        -- InnerFrame: gradient sutil por cima (estilo Linoria)
        local innerFrame = Frame(inner, {
            BackgroundColor3 = C.white,
            BorderSizePixel  = 0,
            Position         = UDim2.new(0, 1, 0, 1),
            Size             = UDim2.new(1, -2, 1, -2),
            ZIndex           = 52,
        })
        local grad = Instance.new("UIGradient")
        grad.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 30, 30)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(22, 22, 22)),
        })
        grad.Rotation = -90
        grad.Parent = innerFrame

        -- Label do texto
        Label(innerFrame, {
            Position       = UDim2.new(0, 4, 0, 0),
            Size           = UDim2.new(1, -4, 1, 0),
            Text           = fullText,
            TextColor3     = C.hi,
            TextSize       = 14,
            Font           = Enum.Font.Gotham,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextWrapped    = true,
            ZIndex         = 53,
        })

        -- Barra lateral colorida (3px, igual ao Linoria)
        Frame(toast, {
            BackgroundColor3 = accentCol,
            BorderSizePixel  = 0,
            Position         = UDim2.new(0, -1, 0, -1),
            Size             = UDim2.new(0, 3, 1, 2),
            ZIndex           = 54,
        })

        -- entrada: expande X de 0 → xSize
        pcall(function()
            toast:TweenSize(
                UDim2.new(0, xSize, 0, ySize),
                Enum.EasingDirection.Out,
                Enum.EasingStyle.Quad,
                0.4,
                true
            )
        end)

        -- saída: recolhe X → 0
        task.delay(duration, function()
            if not toast.Parent then return end
            pcall(function()
                toast:TweenSize(
                    UDim2.new(0, 0, 0, ySize),
                    Enum.EasingDirection.Out,
                    Enum.EasingStyle.Quad,
                    0.3,
                    true
                )
            end)
            Debris:AddItem(toast, 0.35)
        end)
    end

    -- ── Notify (1-button modal) ───────────────────────────────────────────
    function window:Notify(t1, t2, btnTxt, iconAsset, callback)
        local overlay = Frame(main, {
            Size                 = UDim2.new(1,0,1,0),
            BackgroundColor3     = Color3.new(0,0,0),
            BackgroundTransparency = 0.45,
            ZIndex               = 10,
        })
        Corner(overlay, 14)

        local modal = Frame(overlay, {
            AnchorPoint          = Vector2.new(0.5,0.5),
            Position             = UDim2.new(0.5,0,0.5,0),
            Size                 = UDim2.new(0,280,0,0),
            AutomaticSize        = Enum.AutomaticSize.Y,
            BackgroundColor3     = C.surface,
            BackgroundTransparency = 0.05,
            ZIndex               = 11,
        })
        Corner(modal, 12)
        Stroke(modal, C.white, 1, 0.9)
        ListLayout(modal, {Padding = UDim.new(0,0)})
        Padding(modal, 16, 16, 16, 16)

        if iconAsset and iconAsset ~= "" then
            local iconWrap = Frame(modal, {
                Size               = UDim2.new(1,0,0,56),
                BackgroundTransparency = 1,
                ZIndex             = 12,
                LayoutOrder        = 0,
            })
            Image(iconWrap, {
                AnchorPoint  = Vector2.new(0.5,0.5),
                Position     = UDim2.new(0.5,0,0.5,0),
                Size         = UDim2.new(0,48,0,48),
                Image        = iconAsset,
                ImageColor3  = C.mid,
                ScaleType    = Enum.ScaleType.Fit,
                ZIndex       = 12,
            })
        end

        Label(modal, {
            Size           = UDim2.new(1,0,0,22),
            Text           = t1 or "",
            TextColor3     = C.hi,
            TextSize       = 13,
            Font           = Enum.Font.GothamMedium,
            TextXAlignment = Enum.TextXAlignment.Center,
            ZIndex         = 12,
            LayoutOrder    = 1,
        })
        Label(modal, {
            Size           = UDim2.new(1,0,0,0),
            AutomaticSize  = Enum.AutomaticSize.Y,
            Text           = t2 or "",
            TextColor3     = C.hi,
            TextSize       = 10,
            Font           = Enum.Font.Gotham,
            TextWrapped    = true,
            TextXAlignment = Enum.TextXAlignment.Center,
            ZIndex         = 12,
            LayoutOrder    = 2,
        })
        Frame(modal, {
            Size               = UDim2.new(1,0,0,8),
            BackgroundTransparency = 1,
            ZIndex             = 12,
            LayoutOrder        = 3,
        })
        local ok = Button(modal, {
            Size                 = UDim2.new(1,0,0,34),
            BackgroundColor3     = C.white,
            BackgroundTransparency = 0.1,
            Text                 = btnTxt or "OK",
            TextColor3           = C.bg,
            TextSize             = 12,
            Font                 = Enum.Font.GothamMedium,
            ZIndex               = 12,
            LayoutOrder          = 4,
        })
        Corner(ok, 7)
        ok.MouseButton1Click:Connect(function()
            overlay:Destroy()
            if callback then callback() end
        end)
    end

    -- ── Notify2 (2-button modal) ──────────────────────────────────────────
    function window:Notify2(t1, t2, b1txt, b2txt, iconAsset, cb1, cb2)
        local overlay = Frame(main, {
            Size                 = UDim2.new(1,0,1,0),
            BackgroundColor3     = Color3.new(0,0,0),
            BackgroundTransparency = 0.45,
            ZIndex               = 10,
        })
        Corner(overlay, 14)

        local modal = Frame(overlay, {
            AnchorPoint          = Vector2.new(0.5,0.5),
            Position             = UDim2.new(0.5,0,0.5,0),
            Size                 = UDim2.new(0,280,0,0),
            AutomaticSize        = Enum.AutomaticSize.Y,
            BackgroundColor3     = C.surface,
            BackgroundTransparency = 0.05,
            ZIndex               = 11,
        })
        Corner(modal, 12)
        Stroke(modal, C.white, 1, 0.9)
        ListLayout(modal, {Padding = UDim.new(0,0)})
        Padding(modal, 16, 16, 16, 16)

        if iconAsset and iconAsset ~= "" then
            local iconWrap = Frame(modal, {
                Size               = UDim2.new(1,0,0,56),
                BackgroundTransparency = 1,
                ZIndex             = 12,
                LayoutOrder        = 0,
            })
            Image(iconWrap, {
                AnchorPoint  = Vector2.new(0.5,0.5),
                Position     = UDim2.new(0.5,0,0.5,0),
                Size         = UDim2.new(0,48,0,48),
                Image        = iconAsset,
                ImageColor3  = C.mid,
                ScaleType    = Enum.ScaleType.Fit,
                ZIndex       = 12,
            })
        end

        Label(modal, {
            Size           = UDim2.new(1,0,0,22),
            Text           = t1 or "",
            TextColor3     = C.hi,
            TextSize       = 13,
            Font           = Enum.Font.GothamMedium,
            TextXAlignment = Enum.TextXAlignment.Center,
            ZIndex         = 12,
            LayoutOrder    = 1,
        })
        Label(modal, {
            Size           = UDim2.new(1,0,0,0),
            AutomaticSize  = Enum.AutomaticSize.Y,
            Text           = t2 or "",
            TextColor3     = C.hi,
            TextSize       = 10,
            Font           = Enum.Font.Gotham,
            TextWrapped    = true,
            TextXAlignment = Enum.TextXAlignment.Center,
            ZIndex         = 12,
            LayoutOrder    = 2,
        })
        Frame(modal, {
            Size               = UDim2.new(1,0,0,8),
            BackgroundTransparency = 1,
            ZIndex             = 12,
            LayoutOrder        = 3,
        })
        local btn1 = Button(modal, {
            Size                 = UDim2.new(1,0,0,34),
            BackgroundColor3     = C.white,
            BackgroundTransparency = 0.1,
            Text                 = b1txt or "Confirm",
            TextColor3           = C.bg,
            TextSize             = 12,
            Font                 = Enum.Font.GothamMedium,
            ZIndex               = 12,
            LayoutOrder          = 4,
        })
        Corner(btn1, 7)
        Frame(modal, {
            Size               = UDim2.new(1,0,0,6),
            BackgroundTransparency = 1,
            ZIndex             = 12,
            LayoutOrder        = 5,
        })
        local btn2 = Button(modal, {
            Size                 = UDim2.new(1,0,0,34),
            BackgroundColor3     = C.white,
            BackgroundTransparency = 0.97,
            Text                 = b2txt or "Cancel",
            TextColor3           = C.hi,
            TextSize             = 12,
            Font                 = Enum.Font.Gotham,
            ZIndex               = 12,
            LayoutOrder          = 6,
        })
        Corner(btn2, 7)
        Stroke(btn2, C.white, 1, 0.88)

        btn1.MouseButton1Click:Connect(function() overlay:Destroy(); if cb1 then cb1() end end)
        btn2.MouseButton1Click:Connect(function() overlay:Destroy(); if cb2 then cb2() end end)
    end

    -- ── Divider (sidebar section label) ───────────────────────────────────
    function window:Divider(name)
        local lbl = Label(sidebarScroll, {
            Size           = UDim2.new(1,0,0,22),
            Text           = string.upper(name or ""),
            TextColor3     = C.accent,
            TextSize       = 8,
            Font           = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex         = 3,
            LayoutOrder    = #sidebarScroll:GetChildren() + 1,
        })
        Padding(lbl, 0, 0, 14, 0)
    end

    -- ═════════════════════════════════════════════════════════════════════
    --  window:Section(name, iconAsset)
    -- ═════════════════════════════════════════════════════════════════════
    function window:Section(name, iconAsset)

        -- sidebar tab — 36x36px, centralizado, só ícone ou letra inicial
        local tabBtn = Button(sidebarScroll, {
            Name                 = "tab_" .. name,
            Size                 = UDim2.new(0,36,0,36),
            BackgroundColor3     = C.white,
            BackgroundTransparency = 1,
            Text                 = "",
            ZIndex               = 3,
            LayoutOrder          = #sidebarScroll:GetChildren() + 1,
        })
        Corner(tabBtn, 8)

        -- ícone centralizado
        local tabIcon = Image(tabBtn, {
            AnchorPoint       = Vector2.new(0.5,0.5),
            Position          = UDim2.new(0.5,0,0.5,0),
            Size              = UDim2.new(0,20,0,20),
            Image             = iconAsset or "",
            ImageColor3       = C.low,
            ImageTransparency = (iconAsset and iconAsset ~= "") and 0.3 or 1,
            ScaleType         = Enum.ScaleType.Fit,
            ZIndex            = 4,
        })

        -- letra inicial como fallback quando sem ícone
        local tabLabel = Label(tabBtn, {
            AnchorPoint    = Vector2.new(0.5,0.5),
            Position       = UDim2.new(0.5,0,0.5,0),
            Size           = UDim2.new(1,0,1,0),
            Text           = (not iconAsset or iconAsset == "") and name:sub(1,1):upper() or "",
            TextColor3     = C.low,
            TextSize       = 12,
            Font           = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Center,
            ZIndex         = 4,
        })

        -- workarea container (invisível, só posiciona as duas colunas)
        local workarea = Frame(main, {
            Name                 = "wa_" .. name,
            Position             = UDim2.new(0,72,0,0),
            Size                 = UDim2.new(1,-72,1,0),
            BackgroundTransparency = 1,
            BorderSizePixel      = 0,
            ZIndex               = 2,
            Visible              = false,
            ClipsDescendants     = false,
        })

        -- coluna esquerda
        local workareaL = Instance.new("ScrollingFrame")
        workareaL.Name                = "waL_" .. name
        workareaL.Position            = UDim2.new(0,0,0,0)
        workareaL.Size                = UDim2.new(0.5,-5,1,0)
        workareaL.BackgroundTransparency = 1
        workareaL.BorderSizePixel     = 0
        workareaL.ScrollBarThickness  = 3
        workareaL.ScrollBarImageColor3 = Color3.fromRGB(45,45,45)
        workareaL.ScrollBarImageTransparency = 1
        workareaL.AutomaticCanvasSize = Enum.AutomaticSize.Y
        workareaL.CanvasSize          = UDim2.new(0,0,0,0)
        workareaL.ZIndex              = 2
        workareaL.Parent              = workarea
        ListLayout(workareaL, {Padding = UDim.new(0,8)})
        Padding(workareaL, 12, 12, 8, 8)

        -- coluna direita
        local workareaR = Instance.new("ScrollingFrame")
        workareaR.Name                = "waR_" .. name
        workareaR.Position            = UDim2.new(0.5,5,0,0)
        workareaR.Size                = UDim2.new(0.5,-5,1,0)
        workareaR.BackgroundTransparency = 1
        workareaR.BorderSizePixel     = 0
        workareaR.ScrollBarThickness  = 3
        workareaR.ScrollBarImageColor3 = Color3.fromRGB(45,45,45)
        workareaR.ScrollBarImageTransparency = 1
        workareaR.AutomaticCanvasSize = Enum.AutomaticSize.Y
        workareaR.CanvasSize          = UDim2.new(0,0,0,0)
        workareaR.ZIndex              = 2
        workareaR.Parent              = workarea
        ListLayout(workareaR, {Padding = UDim.new(0,8)})
        Padding(workareaR, 12, 12, 8, 8)

        table.insert(sections, tabBtn)
        table.insert(workareas, workarea)

        -- ── sec object ───────────────────────────────────────────────────
        local sec = {}

        function sec:Select()
            for _, t in ipairs(sections) do
                tw(t, {BackgroundTransparency = 1, Size = UDim2.new(0, 36, 0, 36)}, 0.18)
                t.BackgroundColor3 = C.sidebar
                local stroke = t:FindFirstChildWhichIsA("UIStroke")
                if stroke then stroke:Destroy() end
                local grad = t:FindFirstChildWhichIsA("UIGradient")
                if grad then grad:Destroy() end
                local corner = t:FindFirstChildWhichIsA("UICorner")
                if corner then corner.CornerRadius = UDim.new(0, 8) end
                local l = t:FindFirstChildWhichIsA("TextLabel")
                if l then tw(l, {TextColor3 = C.low}, 0.18); l.Font = Enum.Font.Gotham end
                local ic = t:FindFirstChildWhichIsA("ImageLabel")
                if ic then tw(ic, {ImageColor3 = C.low, ImageTransparency = 0.5}, 0.18) end
            end

            -- pill viaja verticalmente até o centro do tab ativo
            local targetY = tabBtn.AbsolutePosition.Y - sidebar.AbsolutePosition.Y + (tabBtn.AbsoluteSize.Y - 14) / 2 + sidebarScroll.CanvasPosition.Y
            tw(pill,     {Position = UDim2.new(0, 0, 0, targetY), Size = UDim2.new(0, 4, 0, 14)}, 0.28, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
            tw(pillGlow, {Position = UDim2.new(0, 0, 0, targetY), Size = UDim2.new(0, 4, 0, 14)}, 0.28, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

            -- fundo roxo sólido no tab ativo (sem stroke, com gradiente e scale up)
            tw(tabBtn, {BackgroundColor3 = Color3.fromRGB(60, 60, 60), BackgroundTransparency = 0.15, Size = UDim2.new(0, 38, 0, 38)}, 0.18)

            -- corner mais suave no ativo
            local activeCorner = tabBtn:FindFirstChildWhichIsA("UICorner")
            if activeCorner then activeCorner.CornerRadius = UDim.new(0, 10) end

            -- gradiente de cima pra baixo: roxo vivo → roxo escuro
            local existingGrad = tabBtn:FindFirstChildWhichIsA("UIGradient")
            if existingGrad then existingGrad:Destroy() end
            local activeGrad = Instance.new("UIGradient")
            activeGrad.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0,   Color3.fromRGB(20, 80, 200)),
                ColorSequenceKeypoint.new(1,   Color3.fromRGB(4,  50, 140)),
            })
            activeGrad.Rotation = 90
            activeGrad.Parent   = tabBtn

            -- letra/ícone branco no tab ativo
            tw(tabLabel, {TextColor3 = C.white}, 0.18)
            tabLabel.Font = Enum.Font.GothamBold
            if iconAsset and iconAsset ~= "" then
                tw(tabIcon, {ImageColor3 = C.white, ImageTransparency = 0}, 0.18)
            end

            for _, w in ipairs(workareas) do w.Visible = false end

            -- workarea container: scale + fade
            local basePos  = UDim2.new(0, 72, 0, 0)
            local baseSize = UDim2.new(1, -72, 1, 0)
            local scaleOff = 8

            workarea.Position = UDim2.new(0, 72 + scaleOff, 0, scaleOff)
            workarea.Size     = UDim2.new(1, -72 - scaleOff*2, 1, -scaleOff*2)
            workarea.Visible  = true

            local overlay = Frame(main, {
                Position             = UDim2.new(0, 72, 0, 0),
                Size                 = UDim2.new(1, -72, 1, 0),
                BackgroundColor3     = C.bg,
                BackgroundTransparency = 0,
                ZIndex               = 50,
            })

            tw(workarea, {Position = basePos, Size = baseSize}, 0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
            tw(overlay,  {BackgroundTransparency = 1},          0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
            Debris:AddItem(overlay, 0.22)

            -- sincroniza scroll das colunas com o canvas
            for _, col in ipairs({workareaL, workareaR}) do
                local layout = col:FindFirstChildWhichIsA("UIListLayout")
                if layout then
                    col.CanvasSize = UDim2.fromOffset(0, layout.AbsoluteContentSize.Y)
                    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                        col.CanvasSize = UDim2.fromOffset(0, layout.AbsoluteContentSize.Y)
                    end)
                end
            end
        end

        safeClick(tabBtn, function() sec:Select() end)
        tabBtn.MouseEnter:Connect(function()
            if workarea.Visible then return end
            tw(tabBtn,   {BackgroundTransparency = 0.92}, 0.1)
            tw(tabLabel, {TextColor3 = C.hi},             0.1)
            if iconAsset and iconAsset ~= "" then
                tw(tabIcon, {ImageColor3 = C.mid, ImageTransparency = 0.2}, 0.1)
            end
        end)
        tabBtn.MouseLeave:Connect(function()
            if workarea.Visible then return end
            tw(tabBtn,   {BackgroundTransparency = 1},  0.1)
            tw(tabLabel, {TextColor3 = C.low},           0.1)
            if iconAsset and iconAsset ~= "" then
                tw(tabIcon, {ImageColor3 = C.low, ImageTransparency = 0.3}, 0.1)
            end
        end)

        if #sections == 1 then sec:Select() end

        -- search filter
        searchBox:GetPropertyChangedSignal("Text"):Connect(function()
            local q = string.upper(searchBox.Text)
            for _, t in ipairs(sections) do
                local l = t:FindFirstChildWhichIsA("TextLabel")
                local n = l and string.upper(l.Text) or ""
                t.Visible = (q == "" or string.find(n, q, 1, true) ~= nil)
            end
        end)

        -- ══════════════════════════════════════════════════════════════════
        --  sec:Group(groupName, iconAsset, side)
        --  side: "left" (padrão) ou "right"
        --  atalhos: sec:LeftGroup(name, icon) / sec:RightGroup(name, icon)
        -- ══════════════════════════════════════════════════════════════════
        function sec:Group(groupName, iconAsset, side)
            local col = (side == "right") and workareaR or workareaL

            -- wrapper externo: label acima + container abaixo
            local gboxOuter = Frame(col, {
                Name                 = "grp_" .. groupName,
                Size                 = UDim2.new(1,0,0,0),
                AutomaticSize        = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                ZIndex               = 3,
                LayoutOrder          = #col:GetChildren(),
            })
            ListLayout(gboxOuter, {Padding = UDim.new(0, 4)})

            -- label do grupo FORA e ACIMA do container
            Label(gboxOuter, {
                Size           = UDim2.new(1,0,0,16),
                Text           = string.upper(groupName or ""),
                TextColor3     = C.low,
                TextSize       = 9,
                Font           = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex         = 4,
                LayoutOrder    = 0,
            })

            -- container com cor e borda igual à sidebar
            local gbox = Frame(gboxOuter, {
                Size                 = UDim2.new(1,0,0,0),
                AutomaticSize        = Enum.AutomaticSize.Y,
                BackgroundColor3     = C.sidebar,
                BackgroundTransparency = 0,
                ClipsDescendants     = true,
                ZIndex               = 3,
                LayoutOrder          = 1,
            })
            Corner(gbox, 9)
            Stroke(gbox, C.border, 1, 0)

            -- body
            local body = Frame(gbox, {
                Name             = "body",
                Position         = UDim2.new(0,0,0,0),
                Size             = UDim2.new(1,0,0,0),
                AutomaticSize    = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                ZIndex           = 4,
            })
            ListLayout(body, {Padding = UDim.new(0, 5)})
            Padding(body, 8, 8, 10, 10)

            -- ── base row ─────────────────────────────────────────────────
            local function addDivider()
                local children = body:GetChildren()
                local hasItems = false
                for _, c in ipairs(children) do
                    if c:IsA("Frame") or c:IsA("TextLabel") or c:IsA("TextButton") then hasItems = true break end
                end
                if hasItems then
                    local divider = Instance.new("Frame")
                    divider.Size = UDim2.new(1, -16, 0, 1)
                    divider.Position = UDim2.new(0, 8, 0, 0)
                    divider.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    divider.BackgroundTransparency = 0.88
                    divider.BorderSizePixel = 0
                    divider.ZIndex = 5
                    divider.LayoutOrder = #body:GetChildren()
                    divider.Parent = body
                end
            end
            local function baseRow(lbl, h, desc)
                addDivider()
                -- se tiver descrição, altura maior e layout vertical
                local hasDesc = desc and desc ~= ""
                h = h or (hasDesc and 42 or 30)
                local row = Frame(body, {
                    Size             = UDim2.new(1,0,0,h),
                    AutomaticSize    = hasDesc and Enum.AutomaticSize.Y or Enum.AutomaticSize.None,
                    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                    BackgroundTransparency = 1,
                    ZIndex           = 5,
                    LayoutOrder      = #body:GetChildren(),
                })
                Corner(row, 6)
                row.MouseEnter:Connect(function()
                    tw(row, {BackgroundTransparency = 0.95}, 0.12)
                end)
                row.MouseLeave:Connect(function()
                    tw(row, {BackgroundTransparency = 1}, 0.12)
                end)

                -- container dos controles à direita (UIListLayout horizontal)
                local controlsFrame = Frame(row, {
                    AnchorPoint          = Vector2.new(1, 0.5),
                    Position             = UDim2.new(1, 0, 0.5, 0),
                    Size                 = UDim2.new(0, 0, 0, 20),
                    AutomaticSize        = Enum.AutomaticSize.X,
                    BackgroundTransparency = 1,
                    ZIndex               = 6,
                })
                local _ctl = Instance.new("UIListLayout")
                _ctl.FillDirection       = Enum.FillDirection.Horizontal
                _ctl.HorizontalAlignment = Enum.HorizontalAlignment.Right
                _ctl.VerticalAlignment   = Enum.VerticalAlignment.Center
                _ctl.SortOrder           = Enum.SortOrder.LayoutOrder
                _ctl.Padding             = UDim.new(0, 4)
                _ctl.Parent              = controlsFrame

                if hasDesc then
                    -- label principal
                    Label(row, {
                        Position       = UDim2.new(0,0,0,6),
                        Size           = UDim2.new(0.6,0,0,14),
                        Text           = lbl or "",
                        TextColor3     = C.hi,
                        TextSize       = 11,
                        Font           = Enum.Font.Gotham,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        ZIndex         = 6,
                    })
                    -- descrição secundária
                    Label(row, {
                        Position       = UDim2.new(0,0,0,22),
                        Size           = UDim2.new(0.75,0,0,0),
                        AutomaticSize  = Enum.AutomaticSize.Y,
                        Text           = desc,
                        TextColor3     = C.mid,
                        TextSize       = 11,
                        Font           = Enum.Font.Gotham,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        TextWrapped    = true,
                        ZIndex         = 6,
                    })
                else
                    Label(row, {
                        Position       = UDim2.new(0,0,0,0),
                        Size           = UDim2.new(0.55,0,1,0),
                        Text           = lbl or "",
                        TextColor3     = C.hi,
                        TextSize       = 11,
                        Font           = Enum.Font.Gotham,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        ZIndex         = 6,
                    })
                end
                return row, controlsFrame
            end

            local grp = {}

            -- ── Toggle ───────────────────────────────────────────────────
            function grp:Toggle(lbl, default, cb, keybind, desc, id)
                id = id or lbl
                local state   = default == true
                local key     = keybind or nil
                local waiting = false
                local row, controlsFrame = baseRow(lbl, nil, desc)

                -- pill container (30×16px oval)
                local pillBg = Button(controlsFrame, {
                    Size                 = UDim2.new(0, 36, 0, 19),
                    BackgroundColor3     = state and C.onBg or C.offBg,
                    BackgroundTransparency = 0,
                    Text                 = "",
                    ZIndex               = 7,
                    LayoutOrder          = 99,
                })
                Corner(pillBg, 99)

                -- knob (bolinha branca)
                local knobSize = 16
                local knobMargin = 3
                local knob = Frame(pillBg, {
                    AnchorPoint      = Vector2.new(0.5, 0.5),
                    Position         = state and UDim2.new(1, -(knobSize/2 + knobMargin), 0.5, 0) or UDim2.new(0, knobSize/2 + knobMargin, 0.5, 0),
                    Size             = UDim2.new(0, knobSize, 0, knobSize),
                    BackgroundColor3 = Color3.fromRGB(255,255,255),
                    ZIndex           = 8,
                })
                Corner(knob, 99)

                local o = {}
                local function flip()
                    state = not state
                    o.Value = state
                    tw(pillBg, {BackgroundColor3 = state and C.onBg or C.offBg}, 0.14)
                    tw(knob,   {Position = state and UDim2.new(1, -(knobSize/2 + knobMargin), 0.5, 0) or UDim2.new(0, knobSize/2 + knobMargin, 0.5, 0)}, 0.14)
                    if cb then cb(state) end
                end
                safeClick(pillBg, flip)

                -- keybind
                if keybind then
                    local keyName = tostring(key):gsub("Enum.KeyCode.","")
                    local kbLbl = Button(controlsFrame, {
                        Size                 = UDim2.new(0, 60, 0, 20),
                        Text                 = "[" .. keyName .. "]",
                        TextColor3           = C.hi,
                        TextSize             = 11,
                        Font                 = Enum.Font.Code,
                        TextXAlignment       = Enum.TextXAlignment.Center,
                        BackgroundTransparency = 1,
                        ZIndex               = 7,
                        LayoutOrder          = 1,
                    })
                    safeClick(kbLbl, function()
                        if waiting then return end
                        waiting = true; kbLbl.Text = "[...]"
                        local conn
                        conn = UserInputService.InputBegan:Connect(function(i, gp)
                            if gp then return end
                            if i.UserInputType ~= Enum.UserInputType.Keyboard then return end
                            key = i.KeyCode.Name
                            kbLbl.Text = "[" .. key .. "]"
                            waiting = false; conn:Disconnect()
                        end)
                    end)
                    UserInputService.InputBegan:Connect(function(i, gp)
                        if gp or waiting then return end
                        if not key or key == "Unknown" then return end
                        if i.UserInputType == Enum.UserInputType.Keyboard and i.KeyCode.Name == key then flip() end
                    end)
                end

                o.Value = state
                function o.Set(v) if state ~= (not not v) then flip() end end
                function o.Get() return state end
                function o:SetValue(v) o.Set(v) end
                if id then
                    Registry.Toggles[id] = {
                        Get = function() return state end,
                        Set = function(v) if state ~= (not not v) then flip() end end
                    }
                    if keybind then
                        Registry.Keybinds[id .. "_key"] = {
                            Get = function() return tostring(key) end,
                            Set = function(v)
                                if not v then return end
                                local s = tostring(v)
                                for _, kc in ipairs(Enum.KeyCode:GetEnumItems()) do
                                    if kc.Name == s or "Enum.KeyCode." .. kc.Name == s then
                                        key = kc; kbLbl.Text = "[" .. kc.Name .. "]"; return
                                    end
                                end
                            end
                        }
                    end
                end
                return o
            end

            -- ── ToggleInput ──────────────────────────────────────────────
            -- toggle + input numérico na mesma linha
            -- uso: grp:ToggleInput(lbl, desc, defaultNum, defaultBool, cb)
            -- cb(state, num)
            function grp:ToggleInput(lbl, desc, defaultNum, defaultBool, cb, id)
                id = id or lbl
                local state  = defaultBool == true
                local num    = defaultNum or 0
                local row, controlsFrame = baseRow(lbl, nil, desc)

                -- input numérico (LayoutOrder 1 = aparece primeiro, à esquerda da pill)
                local inputBgW = 46
                local inputBg = Frame(controlsFrame, {
                    Size                 = UDim2.new(0, inputBgW, 0, 20),
                    BackgroundColor3     = C.border,
                    BackgroundTransparency = 0,
                    ClipsDescendants     = true,
                    ZIndex               = 7,
                    LayoutOrder          = 1,
                })
                Corner(inputBg, 4)

                -- pill toggle (LayoutOrder 2 = aparece depois, à direita do input)
                local pillBg = Button(controlsFrame, {
                    Size                 = UDim2.new(0, 36, 0, 19),
                    BackgroundColor3     = state and C.onBg or C.offBg,
                    BackgroundTransparency = 0,
                    Text                 = "",
                    ZIndex               = 7,
                    LayoutOrder          = 2,
                })
                Corner(pillBg, 99)
                local knobSize = 13
                local knobMargin = 2
                local knob = Frame(pillBg, {
                    AnchorPoint      = Vector2.new(0.5, 0.5),
                    Position         = state and UDim2.new(1, -(knobSize/2 + knobMargin), 0.5, 0) or UDim2.new(0, knobSize/2 + knobMargin, 0.5, 0),
                    Size             = UDim2.new(0, knobSize, 0, knobSize),
                    BackgroundColor3 = Color3.fromRGB(255,255,255),
                    ZIndex           = 8,
                })
                Corner(knob, 99)

                -- Sombra elevada na bolinha do toggle
local knobGlow = Instance.new("UIShadow")
knobGlow.Color        = Color3.fromRGB(255, 255, 255)  -- ou a cor que você quiser (ex: C.accent)
knobGlow.BlurRadius   = UDim.new(0, 24)               -- blur alto
knobGlow.Spread       = UDim2.fromOffset(6, 8)        -- espalhamento
knobGlow.Offset       = UDim2.fromOffset(0, 0)        -- sem deslocamento (centralizado)
knobGlow.Transparency = 0.2                           -- bem sutil
knobGlow.ZIndex       = -1                            -- fica atrás da bolinha
knobGlow.Parent       = knob

                local o = {}
                local function flip()
                    state = not state
                    o.Value = state
                    tw(pillBg, {BackgroundColor3 = state and C.onBg or C.offBg}, 0.14)
                    tw(knob,   {Position = state and UDim2.new(1, -(knobSize/2 + knobMargin), 0.5, 0) or UDim2.new(0, knobSize/2 + knobMargin, 0.5, 0)}, 0.14)
                    if cb then cb(state, num) end
                end
                safeClick(pillBg, flip)

                local highlight = Frame(inputBg, {
                    Position             = UDim2.new(0,0,1,-2),
                    Size                 = UDim2.new(1,0,0,2),
                    BackgroundColor3     = C.accent,
                    BackgroundTransparency = 1,
                    ZIndex               = 9,
                })
                Corner(highlight, 2)

                local tb = Instance.new("TextBox")
                tb.Position              = UDim2.new(0,4,0,0)
                tb.Size                  = UDim2.new(1,-8,1,0)
                tb.BackgroundTransparency = 1
                tb.BorderSizePixel       = 0
                tb.Font                  = Enum.Font.GothamMedium
                tb.Text                  = tostring(num)
                tb.TextColor3            = C.hi
                tb.TextSize              = 10
                tb.ClearTextOnFocus      = false
                tb.TextXAlignment        = Enum.TextXAlignment.Left
                tb.ZIndex                = 8
                tb.Parent                = inputBg

                tb.Focused:Connect(function()
                    tw(highlight, {BackgroundTransparency = 0}, 0.15)
                end)
                tb.FocusLost:Connect(function()
                    tw(highlight, {BackgroundTransparency = 1}, 0.15)
                    local v = tonumber(tb.Text)
                    if v then
                        num = v
                    else
                        tb.Text = tostring(num)
                    end
                    if cb then cb(state, num) end
                end)

                o.Value = state
                function o.Set(s, n)
                    if s ~= nil and state ~= s then flip() end
                    if n ~= nil then num = n; tb.Text = tostring(n) end
                end
                function o.Get() return state, num end
                function o:SetValue(v) o.Set(v) end
                if id then
                    Registry.Toggles[id] = {
                        Get = function() return state end,
                        Set = function(v) if state ~= (not not v) then flip() end end
                    }
                end
                return o
            end

            -- ── ToggleKeybind ────────────────────────────────────────────
            -- toggle + keybind clicável na mesma linha
            -- uso: grp:ToggleKeybind(lbl, desc, defaultKey, defaultBool, cb)
            -- cb(state) ao flip; keybind também faz flip
            function grp:ToggleKeybind(lbl, desc, defaultKey, defaultBool, cb, id)
                id = id or lbl
                local state   = defaultBool == true
                local key     = defaultKey and defaultKey.Name or "Unknown"  -- string, igual ao Feral
                local waiting = false
                local row, controlsFrame = baseRow(lbl, nil, desc)

                -- badge do keybind (LayoutOrder 1 = à esquerda da pill)
                local keyName = key ~= "Unknown" and key or ""
                local kbfW = 36
                local kbf = Button(controlsFrame, {
                    Size                 = UDim2.new(0, kbfW, 0, 20),
                    BackgroundColor3     = C.white,
                    BackgroundTransparency = 0.94,
                    Text                 = "",
                    ZIndex               = 7,
                    LayoutOrder          = 1,
                })
                Corner(kbf, 4)
                Stroke(kbf, C.white, 1, 0.88)

                -- pill toggle (LayoutOrder 2 = à direita do badge)
                local pillBg = Button(controlsFrame, {
                    Size                 = UDim2.new(0, 36, 0, 19),
                    BackgroundColor3     = state and C.onBg or C.offBg,
                    BackgroundTransparency = 0,
                    Text                 = "",
                    ZIndex               = 7,
                    LayoutOrder          = 2,
                })
                Corner(pillBg, 99)
                local knobSize = 13
                local knobMargin = 2
                local knob = Frame(pillBg, {
                    AnchorPoint      = Vector2.new(0.5, 0.5),
                    Position         = state and UDim2.new(1, -(knobSize/2 + knobMargin), 0.5, 0) or UDim2.new(0, knobSize/2 + knobMargin, 0.5, 0),
                    Size             = UDim2.new(0, knobSize, 0, knobSize),
                    BackgroundColor3 = Color3.fromRGB(255,255,255),
                    ZIndex           = 8,
                })
                Corner(knob, 99)

                local o = {}
                local function flip()
                    state = not state
                    o.Value = state
                    tw(pillBg, {BackgroundColor3 = state and C.onBg or C.offBg}, 0.14)
                    tw(knob,   {Position = state and UDim2.new(1, -(knobSize/2 + knobMargin), 0.5, 0) or UDim2.new(0, knobSize/2 + knobMargin, 0.5, 0)}, 0.14)
                    if cb then cb(state) end
                end
                safeClick(pillBg, flip)

                local kbLbl = Label(kbf, {
                    Size           = UDim2.new(1,0,1,0),
                    Text           = keyName,
                    TextColor3     = C.hi,
                    TextSize       = 9,
                    Font           = Enum.Font.Code,
                    ZIndex         = 8,
                })

                -- captura: conexão temporária que se desconecta, igual ao Feral
                safeClick(kbf, function()
                    if waiting then return end
                    waiting      = true
                    kbLbl.Text   = "..."
                    local conn
                    conn = UserInputService.InputBegan:Connect(function(i, gp)
                        if gp then return end
                        if i.UserInputType ~= Enum.UserInputType.Keyboard then return end
                        key          = i.KeyCode.Name   -- string, igual ao Feral
                        kbLbl.Text   = key
                        waiting      = false
                        conn:Disconnect()               -- desconecta imediatamente
                    end)
                end)

                -- ação: permanente — só dispara se não está capturando E a tecla bate
                UserInputService.InputBegan:Connect(function(i, gp)
                    if gp then return end
                    if waiting then return end
                    if not key or key == "Unknown" then return end
                    if i.UserInputType == Enum.UserInputType.Keyboard and i.KeyCode.Name == key then
                        flip()
                    end
                end)

                o.Value = state
                function o.Set(v) if state ~= (not not v) then flip() end end
                function o.Get() return state end
                function o:SetValue(v) o.Set(v) end
                function o.SetKey(k)
                    key = type(k) == "string" and k or k.Name
                    kbLbl.Text = key
                end
                function o.GetKey() return key end
                if id then
                    Registry.Toggles[id] = {
                        Get = function() return state end,
                        Set = function(v) if state ~= (not not v) then flip() end end
                    }
                    -- keybind salva/carrega separado, igual ao Feral
                    Registry.Keybinds[id .. "_key"] = {
                        Get = function() return tostring(key) end,
                        Set = function(v)
                            if not v then return end
                            local s = tostring(v)
                            for _, kc in ipairs(Enum.KeyCode:GetEnumItems()) do
                                if kc.Name == s or "Enum.KeyCode." .. kc.Name == s then
                                    key = kc.Name
                                    kbLbl.Text = kc.Name
                                    return
                                end
                            end
                        end
                    }
                end
                return o
            end

            -- ── Slider ───────────────────────────────────────────────────
            function grp:Slider(lbl, min, max, default, cb, id)
                id = id or lbl
                min = min or 0; max = max or 100; default = default or min
                local val = default

                -- frame externo 44px
                local slFrame = Frame(body, {
                    Size                 = UDim2.new(1,0,0,44),
                    BackgroundTransparency = 1,
                    ZIndex               = 5,
                    LayoutOrder          = #body:GetChildren(),
                })

                -- linha superior: label à esquerda, valor à direita
                Label(slFrame, {
                    Position       = UDim2.new(0,0,0,4),
                    Size           = UDim2.new(0.7,0,0,16),
                    Text           = lbl or "",
                    TextColor3     = C.hi,
                    TextSize       = 11,
                    Font           = Enum.Font.Gotham,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex         = 6,
                })

                local valLbl = Label(slFrame, {
                    Position       = UDim2.new(0.7,0,0,4),
                    Size           = UDim2.new(0.3,0,0,16),
                    Text           = tostring(val),
                    TextColor3     = C.hi,
                    TextSize       = 11,
                    Font           = Enum.Font.GothamMedium,
                    TextXAlignment = Enum.TextXAlignment.Right,
                    ZIndex         = 6,
                })

                -- track com padding lateral (8px cada lado) pra knob não sair pela borda
                local trackBg = Frame(slFrame, {
                    Position             = UDim2.new(0,8,0,28),
                    Size                 = UDim2.new(1,-16,0,5),
                    BackgroundColor3     = Color3.fromRGB(50,50,50),
                    BackgroundTransparency = 0,
                    ZIndex               = 7,
                })
                Corner(trackBg, 2)

                local TRACK_W = 0 -- calculado em runtime via AbsoluteSize

                local p0 = (val-min)/(max-min)
                local fill = Frame(trackBg, {
                    Size             = UDim2.new(p0, 0, 1, 0),
                    BackgroundColor3 = C.accent,
                    BackgroundTransparency = 0,
                    ZIndex           = 8,
                })
                Corner(fill, 2)

                -- knob no fim do fill
                local knob = Frame(fill, {
                    AnchorPoint      = Vector2.new(1, 0.5),
                    Position         = UDim2.new(1, 0, 0.5, 0),
                    Size             = UDim2.new(0, 10, 0, 14),
                    BackgroundColor3 = Color3.fromRGB(255,255,255),
                    ZIndex           = 9,
                })
                Corner(knob, 5)

                local slBtn = Button(trackBg, {
                    Size                 = UDim2.new(1,0,0,20),
                    Position             = UDim2.new(0,0,0.5,-10),
                    BackgroundTransparency = 1,
                    Text                 = "",
                    ZIndex               = 10,
                })

                local sliding = false
                local moveConn, releaseConn

                local o = {}
                local function setVal(v)
                    val = math.clamp(v, min, max)
                    o.Value = val
                    local p = (val-min)/(max-min)
                    fill.Size = UDim2.new(p, 0, 1, 0)
                    valLbl.Text = tostring(val)
                    if cb then cb(val) end
                end

                local function onSlide(inputX)
                    local tw_ = trackBg.AbsoluteSize.X
                    local offset = math.clamp(inputX - trackBg.AbsolutePosition.X, 0, tw_)
                    local rv = math.floor((max - min) * (offset / tw_) + min)
                    setVal(rv)
                end

                slBtn.InputBegan:Connect(function(i)
                    if i.UserInputType ~= Enum.UserInputType.MouseButton1 and i.UserInputType ~= Enum.UserInputType.Touch then return end
                    sliding = true
                    onSlide(i.Position.X)
                    moveConn = UserInputService.InputChanged:Connect(function(i2)
                        if not sliding then return end
                        if i2.UserInputType == Enum.UserInputType.MouseMovement or i2.UserInputType == Enum.UserInputType.Touch then
                            onSlide(i2.Position.X)
                        end
                    end)
                    releaseConn = UserInputService.InputEnded:Connect(function(i2)
                        if i2.UserInputType == Enum.UserInputType.MouseButton1 or i2.UserInputType == Enum.UserInputType.Touch then
                            sliding = false
                            if moveConn then moveConn:Disconnect() end
                            if releaseConn then releaseConn:Disconnect() end
                        end
                    end)
                end)

                o.Value = val
                function o.Set(v) setVal(math.floor(v)) end
                function o.Get() return val end
                function o:SetValue(v) o.Set(v) end
                if id then
                    Registry.Sliders[id] = {
                        Get = function() return val end,
                        Set = function(v) setVal(tonumber(v) or val) end
                    }
                end
                return o
            end

            -- ── Dropdown ─────────────────────────────────────────────────
            function grp:Dropdown(lbl, options, default, cb, id)
                id = id or lbl
                local sel  = default or (options and options[1]) or ""
                local open = false
                local currentOptions = options

                -- row idêntico ao toggler — transparente, sem caixa própria
                local row = baseRow(lbl)

                -- caixinha sutil do trigger (valor + chevron)
                local triggerBox = Frame(row, {
                    AnchorPoint          = Vector2.new(1, 0.5),
                    Position             = UDim2.new(1, 0, 0.5, 0),
                    Size                 = UDim2.new(0, 110, 0, 22),
                    BackgroundColor3     = Color3.fromRGB(28, 28, 28),
                    BackgroundTransparency = 0,
                    ZIndex               = 7,
                })
                Corner(triggerBox, 6)
                Stroke(triggerBox, C.border, 1, 0)

                local valLbl = Label(triggerBox, {
                    Position       = UDim2.new(0, 8, 0, 0),
                    Size           = UDim2.new(1, -24, 1, 0),
                    Text           = sel,
                    TextColor3     = C.mid,
                    TextSize       = 11,
                    Font           = Enum.Font.GothamMedium,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex         = 8,
                })

                local chevron = Label(triggerBox, {
                    AnchorPoint    = Vector2.new(1, 0.5),
                    Position       = UDim2.new(1, -7, 0.5, 0),
                    Size           = UDim2.new(0, 12, 0, 12),
                    Text           = "v",
                    TextColor3     = C.dim,
                    TextSize       = 10,
                    Font           = Enum.Font.GothamBold,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    ZIndex         = 8,
                })

                -- botão invisível cobre o triggerBox
                local clickBtn = Button(triggerBox, {
                    Size                 = UDim2.new(1,0,1,0),
                    BackgroundTransparency = 1,
                    Text                 = "",
                    ZIndex               = 9,
                })

                -- popup flutuante parentado no scrgui — não é cortado pelo ClipsDescendants
                local panel = Frame(scrgui, {
                    Size                 = UDim2.new(0,0,0,0),
                    AnchorPoint          = Vector2.new(0, 0),
                    AutomaticSize        = Enum.AutomaticSize.None,
                    BackgroundColor3     = Color3.fromRGB(20,20,20),
                    BackgroundTransparency = 0,
                    ZIndex               = 50,
                    Visible              = false,
                    ClipsDescendants     = true,
                })
                Corner(panel, 8)
                Stroke(panel, Color3.fromRGB(42,42,42), 1, 0)

                local MAX_DROPDOWN_H = 200
                local scrollList = Instance.new("ScrollingFrame")
                scrollList.Size                  = UDim2.new(1, 0, 1, 0)
                scrollList.BackgroundTransparency = 1
                scrollList.BorderSizePixel        = 0
                scrollList.ScrollBarThickness     = 3
                scrollList.ScrollBarImageColor3   = Color3.fromRGB(80, 80, 80)
                scrollList.CanvasSize             = UDim2.new(0, 0, 0, 0)
                scrollList.AutomaticCanvasSize    = Enum.AutomaticSize.None
                scrollList.ClipsDescendants       = true
                scrollList.ZIndex                 = 51
                scrollList.Parent                 = panel

                local panelList = ListLayout(scrollList)
                Padding(scrollList, 4, 4, 0, 0)

                local function closePopup()
                    open = false
                    tw(chevron, {Rotation = 0}, 0.15)
                    -- fecha: escala de 1 -> 0 com Back.In, depois destroi
                    local scaleObj = panel:FindFirstChildWhichIsA("UIScale")
                    if scaleObj then
                        TweenService:Create(scaleObj,
                            TweenInfo.new(0.16, Enum.EasingStyle.Back, Enum.EasingDirection.In),
                            {Scale = 0}
                        ):Play()
                        task.delay(0.17, function()
                            panel.Visible = false
                            local s = panel:FindFirstChildWhichIsA("UIScale")
                            if s then s:Destroy() end
                        end)
                    else
                        panel.Visible = false
                    end
                end

                local function buildOptions(opts)
                    for _, ch in ipairs(scrollList:GetChildren()) do
                        if ch:IsA("TextButton") then ch:Destroy() end
                    end
                    for _, opt in ipairs(opts or {}) do
                        local isSel = opt == sel
                        local ob = Button(scrollList, {
                            Size                 = UDim2.new(1,0,0,28),
                            BackgroundColor3     = Color3.fromRGB(38,38,38),
                            BackgroundTransparency = isSel and 0.5 or 1,
                            Text                 = "",
                            ZIndex               = 51,
                        })
                        Corner(ob, 5)
                        Padding(ob, 0, 0, 10, 10)

                        Label(ob, {
                            Position       = UDim2.new(0, 0, 0, 0),
                            Size           = UDim2.new(0, 16, 1, 0),
                            Text           = isSel and "✓" or "",
                            TextColor3     = C.accent,
                            TextSize       = 10,
                            Font           = Enum.Font.GothamBold,
                            TextXAlignment = Enum.TextXAlignment.Center,
                            ZIndex         = 52,
                        })

                        local optLbl = Label(ob, {
                            Position       = UDim2.new(0, 16, 0, 0),
                            Size           = UDim2.new(1, -16, 1, 0),
                            Text           = opt,
                            TextColor3     = isSel and C.hi or C.mid,
                            TextSize       = 11,
                            Font           = isSel and Enum.Font.GothamMedium or Enum.Font.Gotham,
                            TextXAlignment = Enum.TextXAlignment.Left,
                            ZIndex         = 52,
                        })

                        ob.MouseEnter:Connect(function()
                            if opt ~= sel then
                                tw(ob,     {BackgroundTransparency = 0.7}, 0.1)
                                tw(optLbl, {TextColor3 = C.hi},            0.1)
                            end
                        end)
                        ob.MouseLeave:Connect(function()
                            if opt ~= sel then
                                tw(ob,     {BackgroundTransparency = 1},   0.1)
                                tw(optLbl, {TextColor3 = C.mid},           0.1)
                            end
                        end)
                        safeClick(ob, function()
                            sel = opt
                            valLbl.Text = opt
                            closePopup()
                            if o then o.Value = sel end
                            if cb then cb(opt) end
                        end)
                    end
                end

                buildOptions(currentOptions)

                -- fecha ao clicar fora
                UserInputService.InputBegan:Connect(function(i)
                    if not open then return end
                    if i.UserInputType ~= Enum.UserInputType.MouseButton1 and i.UserInputType ~= Enum.UserInputType.Touch then return end
                    local mp = i.Position
                    local pp = panel.AbsolutePosition
                    local ps = panel.AbsoluteSize
                    local inside = mp.X >= pp.X and mp.X <= pp.X + ps.X and mp.Y >= pp.Y and mp.Y <= pp.Y + ps.Y
                    local rp = row.AbsolutePosition
                    local rs = row.AbsoluteSize
                    local onRow = mp.X >= rp.X and mp.X <= rp.X + rs.X and mp.Y >= rp.Y and mp.Y <= rp.Y + rs.Y
                    if not inside and not onRow then
                        closePopup()
                    end
                end)

                safeClick(clickBtn, function()
                    open = not open
                    if open then
                        buildOptions(currentOptions)
                        -- calcula posição relativa ao main, alinhado ao triggerBox
                        local rowAbs  = triggerBox.AbsolutePosition
                        local relX = rowAbs.X
                        local relY = rowAbs.Y + triggerBox.AbsoluteSize.Y + 4

                        -- mede altura do conteúdo
                        task.wait()
                        local contentH = panelList.AbsoluteContentSize.Y + 8
                        local cappedH  = math.min(contentH, MAX_DROPDOWN_H)

                        -- largura dinâmica: mede o texto mais longo das opções
                        local maxTextW = 80
                        for _, opt in ipairs(currentOptions or {}) do
                            local approxW = #tostring(opt) * 7 + 40 -- ~7px por char + padding
                            if approxW > maxTextW then maxTextW = approxW end
                        end
                        local panelW = math.max(maxTextW, triggerBox.AbsoluteSize.X)

                        -- posiciona com AnchorPoint central (pop sai do meio)
                        panel.Size                = UDim2.new(0, panelW, 0, cappedH)
                        scrollList.Size           = UDim2.new(1, 0, 1, 0)
                        scrollList.CanvasSize     = UDim2.new(0, 0, 0, contentH)
                        -- centro do triggerBox horizontalmente, abaixo dele
                        panel.Position = UDim2.new(0, relX, 0, relY)
                        panel.Visible  = true

                        -- destroi UIScale antigo e cria um novo limpo
                        local oldScale = panel:FindFirstChildWhichIsA("UIScale")
                        if oldScale then oldScale:Destroy() end
                        local scaleObj = Instance.new("UIScale", panel)
                        scaleObj.Scale = 0

                        tw(chevron, {Rotation = 180}, 0.15)

                        -- POP real: escala de 0 a 1 com overshoot Back.Out
                        TweenService:Create(scaleObj,
                            TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
                            {Scale = 1}
                        ):Play()
                    else
                        closePopup()
                    end
                end)

                local o = {}
                o.Value = sel
                function o.Set(v) sel = v; o.Value = sel; valLbl.Text = tostring(v); if cb then cb(v) end end
                function o.Get() return sel end
                function o:SetValue(v) o.Set(v) end
                function o.GetNewList(newOpts)
                    currentOptions = newOpts
                    if open then closePopup() end
                    buildOptions(currentOptions)
                    local found = false
                    for _, v in ipairs(currentOptions or {}) do
                        if v == sel then found = true; break end
                    end
                    if not found then
                        sel = (currentOptions and currentOptions[1]) or ""
                        valLbl.Text = sel
                    end
                end
                if id then
                    Registry.Dropdowns[id] = {
                        Get = function() return sel end,
                        Set = function(v)
                            if not v then return end
                            local s = tostring(v)
                            local found = false
                            for _, opt in ipairs(currentOptions) do
                                if tostring(opt) == s then found = true; break end
                            end
                            if not found then return end
                            sel = s
                            valLbl.Text = s
                            if cb then cb(s) end
                        end
                    }
                end
                return o
            end

            -- ── MultiDropdown ─────────────────────────────────────────────
            function grp:MultiDropdown(lbl, options, defaults, cb, id)
                id = id or lbl
                local sel  = {}
                for _, v in ipairs(defaults or {}) do sel[v] = true end
                local open = false

                local function count()
                    local n = 0; for _, v in pairs(sel) do if v then n=n+1 end end; return n
                end
                local function labelTxt()
                    local n = count(); local tot = #(options or {})
                    if n == 0 then return "None" elseif n == tot then return "All"
                    else return n .. " selected" end
                end

                -- row idêntico ao Dropdown
                local row = baseRow(lbl)

                -- caixinha sutil do trigger (valor + chevron) — idêntico ao Dropdown
                local triggerBox = Frame(row, {
                    AnchorPoint          = Vector2.new(1, 0.5),
                    Position             = UDim2.new(1, 0, 0.5, 0),
                    Size                 = UDim2.new(0, 110, 0, 22),
                    BackgroundColor3     = Color3.fromRGB(28, 28, 28),
                    BackgroundTransparency = 0,
                    ZIndex               = 7,
                })
                Corner(triggerBox, 6)
                Stroke(triggerBox, C.border, 1, 0)

                local valLbl = Label(triggerBox, {
                    Position       = UDim2.new(0, 8, 0, 0),
                    Size           = UDim2.new(1, -24, 1, 0),
                    Text           = labelTxt(),
                    TextColor3     = C.mid,
                    TextSize       = 11,
                    Font           = Enum.Font.GothamMedium,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex         = 8,
                })

                local chevron = Label(triggerBox, {
                    AnchorPoint    = Vector2.new(1, 0.5),
                    Position       = UDim2.new(1, -7, 0.5, 0),
                    Size           = UDim2.new(0, 12, 0, 12),
                    Text           = "v",
                    TextColor3     = C.dim,
                    TextSize       = 10,
                    Font           = Enum.Font.GothamBold,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    ZIndex         = 8,
                })

                -- botão invisível cobre o triggerBox
                local clickBtn = Button(triggerBox, {
                    Size                 = UDim2.new(1,0,1,0),
                    BackgroundTransparency = 1,
                    Text                 = "",
                    ZIndex               = 9,
                })

                -- popup flutuante parentado no scrgui — não é cortado pelo ClipsDescendants
                local panel = Frame(scrgui, {
                    Size                 = UDim2.new(0,0,0,0),
                    AnchorPoint          = Vector2.new(0, 0),
                    AutomaticSize        = Enum.AutomaticSize.None,
                    BackgroundColor3     = Color3.fromRGB(20,20,20),
                    BackgroundTransparency = 0,
                    ZIndex               = 50,
                    Visible              = false,
                    ClipsDescendants     = true,
                })
                Corner(panel, 8)
                Stroke(panel, Color3.fromRGB(42,42,42), 1, 0)

                local MAX_DROPDOWN_H = 200
                local scrollList = Instance.new("ScrollingFrame")
                scrollList.Size                  = UDim2.new(1, 0, 1, 0)
                scrollList.BackgroundTransparency = 1
                scrollList.BorderSizePixel        = 0
                scrollList.ScrollBarThickness     = 3
                scrollList.ScrollBarImageColor3   = Color3.fromRGB(80, 80, 80)
                scrollList.CanvasSize             = UDim2.new(0, 0, 0, 0)
                scrollList.AutomaticCanvasSize    = Enum.AutomaticSize.None
                scrollList.ClipsDescendants       = true
                scrollList.ZIndex                 = 51
                scrollList.Parent                 = panel

                local panelList = ListLayout(scrollList)
                Padding(scrollList, 4, 4, 0, 0)

                local function closePopup()
                    open = false
                    tw(chevron, {Rotation = 0}, 0.15)
                    local scaleObj = panel:FindFirstChildWhichIsA("UIScale")
                    if scaleObj then
                        TweenService:Create(scaleObj,
                            TweenInfo.new(0.16, Enum.EasingStyle.Back, Enum.EasingDirection.In),
                            {Scale = 0}
                        ):Play()
                        task.delay(0.17, function()
                            panel.Visible = false
                            local s = panel:FindFirstChildWhichIsA("UIScale")
                            if s then s:Destroy() end
                        end)
                    else
                        panel.Visible = false
                    end
                end

                local function buildOptions(opts)
                    for _, ch in ipairs(scrollList:GetChildren()) do
                        if ch:IsA("TextButton") then ch:Destroy() end
                    end
                    for _, opt in ipairs(opts or {}) do
                        local on = sel[opt] == true
                        local ob = Button(scrollList, {
                            Size                 = UDim2.new(1,0,0,28),
                            BackgroundColor3     = Color3.fromRGB(38,38,38),
                            BackgroundTransparency = on and 0.5 or 1,
                            Text                 = "",
                            ZIndex               = 51,
                        })
                        Corner(ob, 5)
                        Padding(ob, 0, 0, 10, 10)

                        local tickLbl = Label(ob, {
                            Position       = UDim2.new(0, 0, 0, 0),
                            Size           = UDim2.new(0, 16, 1, 0),
                            Text           = on and "✓" or "",
                            TextColor3     = C.accent,
                            TextSize       = 10,
                            Font           = Enum.Font.GothamBold,
                            TextXAlignment = Enum.TextXAlignment.Center,
                            ZIndex         = 52,
                        })

                        local optLbl = Label(ob, {
                            Position       = UDim2.new(0, 16, 0, 0),
                            Size           = UDim2.new(1, -16, 1, 0),
                            Text           = opt,
                            TextColor3     = on and C.hi or C.mid,
                            TextSize       = 11,
                            Font           = on and Enum.Font.GothamMedium or Enum.Font.Gotham,
                            TextXAlignment = Enum.TextXAlignment.Left,
                            ZIndex         = 52,
                        })

                        ob.MouseEnter:Connect(function()
                            if not sel[opt] then
                                tw(ob,     {BackgroundTransparency = 0.7}, 0.1)
                                tw(optLbl, {TextColor3 = C.hi},            0.1)
                            end
                        end)
                        ob.MouseLeave:Connect(function()
                            if not sel[opt] then
                                tw(ob,     {BackgroundTransparency = 1},   0.1)
                                tw(optLbl, {TextColor3 = C.mid},           0.1)
                            end
                        end)
                        safeClick(ob, function()
                            if sel[opt] then sel[opt] = nil else sel[opt] = true end
                            local s = sel[opt]
                            tw(ob,     {BackgroundTransparency = s and 0.5 or 1}, 0.12)
                            tw(optLbl, {TextColor3 = s and C.hi or C.mid},        0.12)
                            tickLbl.Text = s and "✓" or ""
                            optLbl.Font  = s and Enum.Font.GothamMedium or Enum.Font.Gotham
                            valLbl.Text  = labelTxt()
                            if o then o.Value = sel end
                            if cb then cb(sel) end
                        end)
                    end
                end

                buildOptions(options)

                -- fecha ao clicar fora
                UserInputService.InputBegan:Connect(function(i)
                    if not open then return end
                    if i.UserInputType ~= Enum.UserInputType.MouseButton1 and i.UserInputType ~= Enum.UserInputType.Touch then return end
                    local mp = i.Position
                    local pp = panel.AbsolutePosition
                    local ps = panel.AbsoluteSize
                    local inside = mp.X >= pp.X and mp.X <= pp.X + ps.X and mp.Y >= pp.Y and mp.Y <= pp.Y + ps.Y
                    local rp = row.AbsolutePosition
                    local rs = row.AbsoluteSize
                    local onRow = mp.X >= rp.X and mp.X <= rp.X + rs.X and mp.Y >= rp.Y and mp.Y <= rp.Y + rs.Y
                    if not inside and not onRow then
                        closePopup()
                    end
                end)

                safeClick(clickBtn, function()
                    open = not open
                    if open then
                        buildOptions(options)
                        -- calcula posição relativa ao main, alinhado ao triggerBox
                        local rowAbs  = triggerBox.AbsolutePosition
                        local relX = rowAbs.X
                        local relY = rowAbs.Y + triggerBox.AbsoluteSize.Y + 4

                        -- mede altura do conteúdo
                        task.wait()
                        local contentH = panelList.AbsoluteContentSize.Y + 8
                        local cappedH  = math.min(contentH, MAX_DROPDOWN_H)

                        -- largura dinâmica: mede o texto mais longo das opções
                        local maxTextW = 80
                        for _, opt in ipairs(options or {}) do
                            local approxW = #tostring(opt) * 7 + 40
                            if approxW > maxTextW then maxTextW = approxW end
                        end
                        local panelW = math.max(maxTextW, triggerBox.AbsoluteSize.X)

                        -- posiciona com AnchorPoint central (pop sai do meio)
                        panel.Size                = UDim2.new(0, panelW, 0, cappedH)
                        scrollList.Size           = UDim2.new(1, 0, 1, 0)
                        scrollList.CanvasSize     = UDim2.new(0, 0, 0, contentH)
                        panel.Position = UDim2.new(0, relX, 0, relY)
                        panel.Visible  = true

                        -- destroi UIScale antigo e cria um novo limpo
                        local oldScale = panel:FindFirstChildWhichIsA("UIScale")
                        if oldScale then oldScale:Destroy() end
                        local scaleObj = Instance.new("UIScale", panel)
                        scaleObj.Scale = 0

                        tw(chevron, {Rotation = 180}, 0.15)

                        -- POP real: escala de 0 a 1 com overshoot Back.Out
                        TweenService:Create(scaleObj,
                            TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
                            {Scale = 1}
                        ):Play()
                    else
                        closePopup()
                    end
                end)

                local o = {}
                o.Value = sel
                function o.Get()
                    local out = {}
                    for k,v in pairs(sel) do if v then table.insert(out,k) end end
                    return out
                end
                function o.Set(tbl)
                    sel = {}; for _,v in ipairs(tbl) do sel[v] = true end
                    o.Value = sel
                    valLbl.Text = labelTxt()
                end
                function o:SetValue(v) o.Set(v) end
                if id then
                    -- copiado do Feral: Get retorna {k=bool}, Set itera tabela
                    Registry.Dropdowns[id] = {
                        Get = function()
                            local out = {}
                            for k, v in pairs(sel) do out[k] = not not v end
                            return out
                        end,
                        Set = function(v)
                            if type(v) ~= "table" then return end
                            local asList = {}
                            for k, val in pairs(v) do
                                if val then table.insert(asList, k) end
                            end
                            o.Set(asList)
                            if cb then pcall(cb, sel) end
                        end
                    }
                end
                return o
            end

            -- ── Button ───────────────────────────────────────────────────
            function grp:Button(lbl, cb)
                addDivider()
                local btn = Button(body, {
                    Size                 = UDim2.new(1, 0, 0, 36),
                    BackgroundColor3     = C.sidebar,
                    BackgroundTransparency = 0,
                    Text                 = "",
                    ZIndex               = 7,
                    LayoutOrder          = #body:GetChildren(),
                })
                Corner(btn, 8)

                -- texto à esquerda
                Label(btn, {
                    Position       = UDim2.new(0, 14, 0, 0),
                    Size           = UDim2.new(1, -40, 1, 0),
                    Text           = lbl,
                    TextColor3     = C.hi,
                    TextSize       = 12,
                    Font           = Enum.Font.GothamMedium,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex         = 8,
                })

                -- ícone à direita
                local icon = Instance.new("ImageLabel")
                icon.AnchorPoint          = Vector2.new(1, 0.5)
                icon.Position             = UDim2.new(1, -14, 0.5, 0)
                icon.Size                 = UDim2.new(0, 18, 0, 18)
                icon.BackgroundTransparency = 1
                icon.Image                = "rbxassetid://16513309462"
                icon.ZIndex               = 8
                icon.Parent               = btn

                btn.MouseEnter:Connect(function()
                    tw(btn, {BackgroundTransparency = 0.55}, 0.12)
                end)
                btn.MouseLeave:Connect(function()
                    tw(btn, {BackgroundTransparency = 0}, 0.12)
                end)
                safeClick(btn, function()
                    tw(btn, {BackgroundTransparency = 0.3}, 0.06)
                    task.delay(0.12, function()
                        tw(btn, {BackgroundTransparency = 0}, 0.1)
                    end)
                    if cb then coroutine.wrap(cb)() end
                end)
            end

            -- ── Label ────────────────────────────────────────────────────
            function grp:Label(text)
                addDivider()
                local lbl = Label(body, {
                    Size           = UDim2.new(1,0,0,26),
                    Text           = text or "",
                    TextColor3     = C.hi,
                    TextSize       = 10,
                    Font           = Enum.Font.Gotham,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    RichText       = true,
                    ZIndex         = 5,
                    LayoutOrder    = #body:GetChildren(),
                })
                local o = {}
                function o.Set(v) lbl.Text = v or "" end
                return o
            end

            -- ── Paragraph ────────────────────────────────────────────────
            function grp:Paragraph(text)
                addDivider()
                local lbl = Label(body, {
                    Size           = UDim2.new(1,0,0,0),
                    AutomaticSize  = Enum.AutomaticSize.Y,
                    Text           = text or "",
                    TextColor3     = C.hi,
                    TextSize       = 10,
                    Font           = Enum.Font.Gotham,
                    TextWrapped    = true,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    LineHeight     = 1.5,
                    ZIndex         = 5,
                    LayoutOrder    = #body:GetChildren(),
                })
                Padding(lbl, 2, 4, 0, 0)
            end

            -- ── TextField ────────────────────────────────────────────────
            function grp:TextField(lbl, placeholder, cb, id)
                addDivider()
                id = id or lbl
                local tfFrame = Frame(body, {
                    Size                 = UDim2.new(1,0,0,60),
                    BackgroundTransparency = 1,
                    ZIndex               = 5,
                    LayoutOrder          = #body:GetChildren(),
                })

                local bg1 = Frame(tfFrame, {
                    AnchorPoint          = Vector2.new(0.5,0.5),
                    Position             = UDim2.new(0.5,0,0.5,0),
                    Size                 = UDim2.new(1,-10,1,0),
                    BackgroundColor3     = C.sidebar,
                    BackgroundTransparency = 0,
                    ZIndex               = 6,
                })
                Corner(bg1, 4)

                Label(bg1, {
                    Position       = UDim2.new(0,10,0,0),
                    Size           = UDim2.new(1,-10,0.5,0),
                    Text           = lbl or "",
                    TextColor3     = C.hi,
                    TextSize       = 11,
                    Font           = Enum.Font.GothamMedium,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex         = 7,
                })

                local bg2 = Frame(bg1, {
                    AnchorPoint          = Vector2.new(1,0),
                    Position             = UDim2.new(1,-5,0,33),
                    Size                 = UDim2.new(1,-10,0,22),
                    BackgroundColor3     = C.border,
                    BackgroundTransparency = 0,
                    ClipsDescendants     = true,
                    ZIndex               = 7,
                })
                Corner(bg2, 4)

                local highlight = Frame(bg2, {
                    Position             = UDim2.new(0,0,1,-2),
                    Size                 = UDim2.new(1,0,0,4),
                    BackgroundColor3     = C.accent,
                    BackgroundTransparency = 1,
                    ZIndex               = 9,
                })
                Corner(highlight, 2)

                local tb = Instance.new("TextBox")
                tb.Position              = UDim2.new(0,5,0,0)
                tb.Size                  = UDim2.new(1,-10,1,0)
                tb.BackgroundTransparency = 1
                tb.BorderSizePixel       = 0
                tb.Font                  = Enum.Font.Gotham
                tb.PlaceholderText       = placeholder or "Type..."
                tb.PlaceholderColor3     = C.dim
                tb.Text                  = ""
                tb.TextColor3            = C.hi
                tb.TextSize              = 10
                tb.ClearTextOnFocus      = false
                tb.TextXAlignment        = Enum.TextXAlignment.Left
                tb.ZIndex                = 8
                tb.Parent                = bg2

                tb.Focused:Connect(function()
                    tw(highlight, {BackgroundTransparency = 0}, 0.15)
                end)
                tb.FocusLost:Connect(function()
                    tw(highlight, {BackgroundTransparency = 1}, 0.15)
                    if cb then cb(tb.Text) end
                end)

                local o = {}
                function o.Get() return tb.Text end
                function o.Set(v) tb.Text = tostring(v) end
                if id then
                    -- copiado do Feral: Set dispara callback depois de setar
                    Registry.Boxes[id] = {
                        Get = function() return tb.Text end,
                        Set = function(v)
                            tb.Text = tostring(v or "")
                            if tb.Text ~= "" and cb then pcall(cb, tb.Text) end
                        end
                    }
                end
                return o
            end

            -- ── ColorDot ─────────────────────────────────────────────────
            function grp:ColorDot(lbl, color, cb)
                local row = baseRow(lbl)
                color = color or Color3.fromRGB(80,140,255)

                local dot = Button(row, {
                    Position         = UDim2.new(1,-18,0.5,-8),
                    Size             = UDim2.new(0,16,0,16),
                    BackgroundColor3 = color,
                    Text             = "",
                    ZIndex           = 7,
                })
                Corner(dot, 8)
                Stroke(dot, C.white, 1, 0.85)
                safeClick(dot, function() if cb then cb(color) end end)

                local o = {}
                function o.Set(c) color = c; dot.BackgroundColor3 = c end
                function o.Get() return color end
                return o
            end

            -- ── Keybind ──────────────────────────────────────────────────
            function grp:Keybind(lbl, default, cb, id, onCapture)
                id = id or lbl
                local key     = default or Enum.KeyCode.Unknown
                local waiting = false
                local row     = baseRow(lbl)

                local kbf = Button(row, {
                    Position             = UDim2.new(1,-74,0.5,-10),
                    Size                 = UDim2.new(0,70,0,20),
                    BackgroundColor3     = C.white,
                    BackgroundTransparency = 0.94,
                    Text                 = "",
                    ZIndex               = 7,
                })
                Corner(kbf, 4)
                Stroke(kbf, C.white, 1, 0.88)

                local kbLbl = Label(kbf, {
                    Size           = UDim2.new(1,0,1,0),
                    Text           = tostring(key):gsub("Enum.KeyCode.",""),
                    TextColor3     = C.hi,
                    TextSize       = 9,
                    Font           = Enum.Font.Code,
                    ZIndex         = 8,
                })

                -- clique no badge: entra em modo de captura
                safeClick(kbf, function()
                    waiting = true
                    kbLbl.Text       = "..."
                    kbLbl.TextColor3 = C.hi
                    task.delay(10, function()
                        if waiting then
                            waiting = false
                            kbLbl.Text = tostring(key):gsub("Enum.KeyCode.","")
                        end
                    end)
                end)

                -- escuta global: captura nova tecla OU dispara o callback
                UserInputService.InputBegan:Connect(function(i, gp)
                    if gp then return end
                    if i.UserInputType ~= Enum.UserInputType.Keyboard then return end
                    if waiting then
                        -- modo captura: salva nova tecla
                        waiting          = false
                        key              = i.KeyCode
                        kbLbl.Text       = tostring(key):gsub("Enum.KeyCode.","")
                        kbLbl.TextColor3     = C.hi
                        if onCapture then onCapture(key) end
                    elseif i.KeyCode == key then
                        -- tecla correta pressionada: dispara callback
                        if cb then cb(key) end
                    end
                end)

                local o = {}
                function o.Get() return key end
                function o.Set(k) key=k; kbLbl.Text=tostring(k):gsub("Enum.KeyCode.","") end
                if id then
                    -- copiado do Feral: Get retorna tostring(key), Set itera KeyCode+UserInputType
                    Registry.Keybinds[id] = {
                        Get = function() return tostring(key) end,
                        Set = function(v)
                            if not v then return end
                            local s = tostring(v)
                            for _, kc in ipairs(Enum.KeyCode:GetEnumItems()) do
                                if kc.Name == s or "Enum.KeyCode." .. kc.Name == s then
                                    key = kc
                                    kbLbl.Text = kc.Name
                                    return
                                end
                            end
                            for _, uit in ipairs(Enum.UserInputType:GetEnumItems()) do
                                if uit.Name == s or "Enum.UserInputType." .. uit.Name == s then
                                    key = uit
                                    kbLbl.Text = uit.Name
                                    return
                                end
                            end
                        end
                    }
                end
                return o
            end

            -- ── SectionLabel (inside group) ───────────────────────────────
            function grp:SectionLabel(name)
                local secContainer = Frame(body, {
                    Size        = UDim2.new(1,0,0,28),
                    BackgroundTransparency = 1,
                    ZIndex      = 5,
                    LayoutOrder = #body:GetChildren(),
                })

                Label(secContainer, {
                    Size           = UDim2.new(1,0,0,18),
                    Position       = UDim2.new(0,0,0,4),
                    Text           = string.upper(name or ""),
                    TextColor3     = C.accent,
                    TextSize       = 9,
                    Font           = Enum.Font.GothamBold,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    ZIndex         = 6,
                })

                -- linha com gradient nas pontas
                local line = Frame(secContainer, {
                    Position         = UDim2.new(0,0,1,-2),
                    Size             = UDim2.new(1,0,0,1),
                    BackgroundColor3 = C.accent,
                    BackgroundTransparency = 0,
                    ZIndex           = 6,
                })
                local grad = Instance.new("UIGradient")
                grad.Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0,   1),
                    NumberSequenceKeypoint.new(0.2, 0),
                    NumberSequenceKeypoint.new(0.8, 0),
                    NumberSequenceKeypoint.new(1,   1),
                })
                grad.Parent = line
            end

            return grp
        end -- sec:Group

        function sec:LeftGroup(groupName, iconAsset)
            return sec:Group(groupName, iconAsset, "left")
        end

        function sec:RightGroup(groupName, iconAsset)
            return sec:Group(groupName, iconAsset, "right")
        end

        return sec
    end -- window:Section

    -- ═══════════════════════════════════════════════════════════════════════
    -- ── Tab de Configs (padrão Feral) ────────────────────────────────────
    -- • Delete direto sem modal, refresh imediato igual ao Feral
    -- ══════════════════════════════════════════════════════════════════════
    task.spawn(function()
        task.wait()
        local cfgTab = window:Section("Configs", "rbxassetid://139193436491732")
        local grp    = cfgTab:Group("Save / Load", "")

        -- nome atual da config (igual ao L_1595 do Feral)
        local currentName = "default"

        -- TextField: digitar nome manualmente (igual ao CreateBox do Feral)
        local nameField = grp:TextField("Name", "default", function(v)
            if v and v ~= "" then
                currentName = v
            end
        end)
        nameField.Set("default")

        -- Dropdown de configs (igual ao L_1600 do Feral)
        local ddConfigs = nil

        local function refreshDropdown()
            local ok, list = pcall(function()
                return window:ListConfigs()
            end)
            if not ok or type(list) ~= "table" then
                list = {}
            end
            if ddConfigs then
                ddConfigs.GetNewList(list)
            else
                ddConfigs = grp:Dropdown(
                    "Saved Configs",
                    list,
                    list[1] or "",
                    function(v)
                        if v and v ~= "" then
                            currentName = v
                            nameField.Set(v)
                        end
                    end
                )
            end
        end

        -- popula ao abrir
        refreshDropdown()

        grp:SectionLabel("Menu")

        grp:Keybind("Menu Keybind", window:GetMenuKey(), nil, "MenuKeybind", function(k)
            window:SetMenuKey(k)
        end)

        grp:SectionLabel("Actions")

        -- Save
        grp:Button("Save", function()
            local name = currentName ~= "" and currentName or "default"
            local ok, err = window:SaveConfig(name)
            if ok then
                window:TempNotify("Configs", 'Saved as "' .. name .. '"', "success", 5)
                refreshDropdown()
            else
                window:TempNotify("Configs", "Error saving: " .. tostring(err), "error", 5)
            end
        end)

        -- Load
        grp:Button("Load", function()
            local name = currentName ~= "" and currentName or "default"
            local ok, err = window:LoadConfig(name)
            if ok then
                window:TempNotify("Configs", 'Loaded "' .. name .. '"', "success", 5)
            else
                window:TempNotify("Configs", "Error loading: " .. tostring(err), "error", 5)
            end
        end)

        -- Delete
        grp:Button("Delete", function()
            local name = currentName
            if not name or name == "" then
                window:TempNotify("Configs", "No config selected.", "warn", 5)
                return
            end
            local ok, err = window:DeleteConfig(name)
            if ok then
                window:TempNotify("Configs", 'Deleted "' .. name .. '"', "success", 5)
                currentName = "default"
                nameField.Set("default")
                refreshDropdown()
            else
                window:TempNotify("Configs", "Error deleting: " .. tostring(err), "error", 5)
            end
        end)

        -- Refresh List
        grp:Button("Refresh List", function()
            refreshDropdown()
            window:TempNotify("Configs", "List refreshed.", "info", 3)
        end)

        grp:SectionLabel("Autoload")

        -- declarado antes do botão pra ser acessível no callback
        local autoloadLabel
        local autoloadName = window:GetAutoload()

        -- Set Autoload
        grp:Button("Set Autoload", function()
            local name = currentName
            if not name or name == "" then
                window:TempNotify("Configs", "No config selected.", "warn", 5)
                return
            end
            window:SetAutoload(name)
            if autoloadLabel then autoloadLabel.Set('Auto-load: "' .. name .. '"') end
            window:TempNotify("Configs", '"' .. name .. '" set as autoload.', "success", 5)
        end)

        -- label mostrando autoload atual
        autoloadLabel = grp:Label(autoloadName and ('Auto-load: "' .. autoloadName .. '"') or "Auto-load: none")

    end)

    task.defer(function()
        window:LoadAutoloadConfig()
    end)

    return window
end -- lib:init

return lib
