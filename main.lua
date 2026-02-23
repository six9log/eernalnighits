-- [[ SIX HUB - ETERNAL NIGHTS: SUPREME LIGHT ]]
-- Atalho Menu: HOME

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()
local Window = Library.CreateLib("Six Hub: Eternal Nights", "BloodTheme")

-- --- CONTROLES DE PERFORMANCE ---
_G.AnimatronicESP = false
_G.PlayerESP = false
_G.ItemESP = false
_G.WalkSpeed = 16
_G.FullBright = false
_G.Noclip = false

-- Tabelas de Cache (Otimizadas)
local Cache = {
    Monsters = {},
    Players = {},
    Items = {}
}

-- --- ABA 1: VISUAIS ---
local Tab1 = Window:NewTab("Visuals")
local EspSection = Tab1:NewSection("Rastreadores Otimizados")

EspSection:NewToggle("ESP Animatronics", "Atualização inteligente", function(state)
    _G.AnimatronicESP = state
    if not state then ClearCache("Monsters") end
end)

EspSection:NewToggle("ESP Aliados", "Baixo consumo de CPU", function(state)
    _G.PlayerESP = state
    if not state then ClearCache("Players") end
end)

EspSection:NewToggle("ESP Itens (Filtro 5s)", "Verificação lenta para evitar lag", function(state)
    _G.ItemESP = state
    if not state then ClearCache("Items") end
end)

local LightSection = Tab1:NewSection("Mundo")
LightSection:NewToggle("FullBright", "Remove sombras", function(state)
    _G.FullBright = state
    -- Visão Clara Total (Ambient + Outdoor)
    game:GetService("Lighting").Ambient = state and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(0, 0, 0)
    game:GetService("Lighting").OutdoorAmbient = state and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(0, 0, 0)
end)

-- --- ABA 2: PERSONAGEM ---
local Tab2 = Window:NewTab("Movimento")
Tab2:NewSection("Atributos"):NewSlider("Velocidade", "Speed", 150, 16, function(s)
    _G.WalkSpeed = s
end)

Tab2:NewSection("Física"):NewToggle("Noclip", "Atravessar paredes", function(state)
    _G.Noclip = state
end)

-- --- FUNÇÕES DE SUPORTE (OTIMIZADAS PARA SEREM LEVES) ---
function ApplyESP(obj, color, group)
    if not obj or obj:FindFirstChild("SixTag") then return end
    
    local highlight = Instance.new("Highlight")
    highlight.Name = "SixESP"
    highlight.FillColor = color
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.FillTransparency = 0.5
    highlight.Parent = obj

    local bill = Instance.new("BillboardGui", obj)
    bill.Name = "SixTag"
    bill.AlwaysOnTop = true
    bill.Size = UDim2.new(0, 100, 0, 40)
    bill.StudsOffset = Vector3.new(0, 3, 0)
    
    local label = Instance.new("TextLabel", bill)
    label.Name = "DistLabel"
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(1, 0, 1, 0)
    label.TextColor3 = color
    label.TextStrokeTransparency = 0.8 -- Sombra leve para legibilidade
    label.Font = Enum.Font.SourceSansBold
    label.TextSize = 14
    label.Text = obj.Name

    table.insert(Cache[group], obj)
end

function ClearCache(group)
    for _, obj in pairs(Cache[group]) do
        if obj:FindFirstChild("SixESP") then obj.SixESP:Destroy() end
        if obj:FindFirstChild("SixTag") then obj.SixTag:Destroy() end
    end
    Cache[group] = {}
end

-- --- LOOPS DE VERIFICAÇÃO (SCANNERS) ---

-- Scanner de Itens: Super Lento (5 segundos) - Só roda se ligado
task.spawn(function()
    while true do
        if _G.ItemESP then
            for _, v in pairs(workspace:GetChildren()) do -- GetChildren é mais leve que Descendants aqui
                if v:IsA("Tool") or v:FindFirstChildOfClass("ProximityPrompt") or v:FindFirstChildOfClass("ClickDetector") then
                    ApplyESP(v, Color3.fromRGB(255, 215, 0), "Items")
                end
            end
        end
        task.wait(5)
    end
end)

-- Scanner de Personagens: Moderado (2 segundos)
task.spawn(function()
    while true do
        if _G.AnimatronicESP or _G.PlayerESP then
            local lp = game.Players.LocalPlayer
            for _, v in pairs(game.Players:GetPlayers()) do -- Scan direto na lista de players (muito mais leve)
                if v.Character and v ~= lp then
                    if _G.PlayerESP then ApplyESP(v.Character, Color3.fromRGB(0, 255, 0), "Players") end
                end
            end
            -- Scan de Monstros no Workspace
            for _, v in pairs(workspace:GetChildren()) do
                if v:IsA("Model") and v:FindFirstChild("Humanoid") and not game.Players:GetPlayerFromCharacter(v) then
                    if _G.AnimatronicESP then ApplyESP(v, Color3.fromRGB(255, 0, 0), "Monsters") end
                end
            end
        end
        task.wait(2)
    end
end)

-- --- LOOP DE DISTÂNCIA E FÍSICA (CENTRALIZADO E FLUIDO) ---
game:GetService("RunService").RenderStepped:Connect(function()
    local lp = game.Players.LocalPlayer
    local char = lp.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    
    if root then
        -- 1. Atualização de Distância (SÓ SE O ESP ESTIVER ON)
        for groupName, groupTable in pairs(Cache) do
            local isEnabled = (_G.AnimatronicESP and groupName == "Monsters") or (_G.PlayerESP and groupName == "Players") or (_G.ItemESP and groupName == "Items")
            
            for i, obj in pairs(groupTable) do
                if obj and obj.Parent and obj:FindFirstChild("SixTag") then
                    obj.SixESP.Enabled = isEnabled
                    obj.SixTag.Enabled = isEnabled
                    
                    if isEnabled then
                        local objPos = obj:IsA("Model") and (obj.PrimaryPart and obj.PrimaryPart.Position or obj:GetModelCFrame().Position) or obj.Position
                        local dist = math.floor((root.Position - objPos).Magnitude)
                        obj.SixTag.DistLabel.Text = obj.Name .. " [" .. dist .. "m]"
                    end
                else
                    table.remove(groupTable, i)
                end
            end
        end
        
        -- 2. Atributos do Player
        if char:FindFirstChild("Humanoid") then
            char.Humanoid.WalkSpeed = _G.WalkSpeed
        end
        
        -- 3. Noclip Otimizado (Não usa GetDescendants em loop infinito)
        if _G.Noclip then
            for _, part in pairs(char:GetChildren()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
            if char:FindFirstChild("UpperTorso") then char.UpperTorso.CanCollide = false end
            if char:FindFirstChild("LowerTorso") then char.LowerTorso.CanCollide = false end
        end
    end
end)

-- --- SETTINGS ---
local Tab3 = Window:NewTab("Settings")
Tab3:NewSection("Menu"):NewKeybind("Abrir/Fechar", "HOME", Enum.KeyCode.Home, function()
    Library:ToggleUI()
end)
