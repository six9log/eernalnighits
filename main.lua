-- [[ SIX HUB - ETERNAL NIGHTS: REAL-TIME ESP ]]
-- Atalho Menu: HOME

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()
local Window = Library.CreateLib("Six Hub: Eternal Nights", "BloodTheme")
local RunService = game:GetService("RunService")

-- --- VARIÁVEIS GLOBAIS ---
_G.AnimatronicESP = false
_G.PlayerESP = false
_G.ItemESP = false
_G.WalkSpeed = 16
_G.FullBright = false
_G.Noclip = false

-- --- ABA 1: VISUAIS (ESP) ---
local Tab1 = Window:NewTab("Visuals")
local EspSection = Tab1:NewSection("Rastreadores em Tempo Real")

EspSection:NewToggle("ESP Animatronics (Vermelho)", "Veja os monstros instantaneamente", function(state)
    _G.AnimatronicESP = state
    if not state then ClearESP("Monster") end
end)

EspSection:NewToggle("ESP Aliados (Verde)", "Veja outros jogadores", function(state)
    _G.PlayerESP = state
    if not state then ClearESP("Player") end
end)

EspSection:NewToggle("ESP Itens (Amarelo)", "Mostra itens importantes", function(state)
    _G.ItemESP = state
    if not state then ClearESP("Item") end
end)

local LightSection = Tab1:NewSection("Mundo")
LightSection:NewToggle("FullBright (Luz Máxima)", "Remove a escuridão do mapa", function(state)
    _G.FullBright = state
    if state then
        game:GetService("Lighting").Ambient = Color3.fromRGB(255, 255, 255)
    else
        game:GetService("Lighting").Ambient = Color3.fromRGB(0, 0, 0)
    end
end)

-- --- ABA 2: MOVIMENTO ---
local Tab2 = Window:NewTab("Movimento")
local MoveSection = Tab2:NewSection("Controle de Personagem")

MoveSection:NewToggle("Noclip (Atravessar Paredes)", "Passe por portas e objetos", function(state)
    _G.Noclip = state
end)

MoveSection:NewSlider("Velocidade (Speed)", "Sua velocidade de caminhada", 150, 16, function(s)
    _G.WalkSpeed = s
end)

-- --- ABA 3: SETTINGS ---
local Tab3 = Window:NewTab("Settings")
Tab3:NewSection("Menu"):NewKeybind("Esconder/Abrir Menu", "Tecla HOME", Enum.KeyCode.Home, function()
    Library:ToggleUI()
end)

-- --- SISTEMA DE ESP (CRIAÇÃO) ---
function CreateESP(obj, typeName, color)
    if not obj or obj:FindFirstChild("SixTag") then return end

    local root = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Head") or obj
    if not root:IsA("BasePart") then return end

    -- Etiqueta de Texto (Criada uma vez só)
    local bill = Instance.new("BillboardGui", obj)
    bill.Name = "SixTag"
    bill.AlwaysOnTop = true
    bill.Size = UDim2.new(0, 100, 0, 40)
    bill.StudsOffset = Vector3.new(0, 2.5, 0)
    bill.Adornee = root
    
    local label = Instance.new("TextLabel", bill)
    label.Name = "NameLabel"
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(1, 0, 1, 0)
    label.TextColor3 = color
    label.TextStrokeTransparency = 0
    label.Font = Enum.Font.SourceSansBold
    label.TextSize = 14
    
    -- Marcação invisível
    local typeVal = Instance.new("StringValue", obj)
    typeVal.Name = "SixType"
    typeVal.Value = typeName

    -- Brilho através das paredes
    local highlight = Instance.new("Highlight", obj)
    highlight.Name = "SixESP"
    highlight.FillColor = color
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
end

function ClearESP(typeName)
    for _, v in pairs(workspace:GetDescendants()) do
        if v:FindFirstChild("SixType") and v.SixType.Value == typeName then
            if v:FindFirstChild("SixTag") then v.SixTag:Destroy() end
            if v:FindFirstChild("SixESP") then v.SixESP:Destroy() end
            v.SixType:Destroy()
        end
    end
end

-- --- 1. SCANNER LENTO (Evita Lag na hora de procurar coisas novas) ---
task.spawn(function()
    while task.wait(1) do
        local lp = game.Players.LocalPlayer.Character
        if not lp then continue end

        for _, v in pairs(workspace:GetDescendants()) do
            -- Procura Animatronics
            if _G.AnimatronicESP and v:IsA("Model") and v:FindFirstChild("Humanoid") and not game.Players:GetPlayerFromCharacter(v) then
                CreateESP(v, "Monster", Color3.fromRGB(255, 0, 0))
            
            -- Procura Players
            elseif _G.PlayerESP and v:IsA("Model") and game.Players:GetPlayerFromCharacter(v) and v ~= lp then
                CreateESP(v, "Player", Color3.fromRGB(0, 255, 0))
            
            -- Procura Itens (ClickDetectors, ProximityPrompts ou Tools)
            elseif _G.ItemESP and (v:IsA("Tool") or v:FindFirstChildOfClass("ProximityPrompt") or v:FindFirstChildOfClass("ClickDetector")) then
                local targetParent = v:IsA("Model") and v or v.Parent
                if targetParent then CreateESP(targetParent, "Item", Color3.fromRGB(255, 215, 0)) end
            end
        end
    end
end)

-- --- 2. RADAR EM TEMPO REAL (Atualiza distâncias a 60 FPS) ---
RunService.RenderStepped:Connect(function()
    local lp = game.Players.LocalPlayer.Character
    local lpRoot = lp and lp:FindFirstChild("HumanoidRootPart")

    if lpRoot then
        for _, v in pairs(workspace:GetDescendants()) do
            if v:FindFirstChild("SixTag") and v.SixTag:FindFirstChild("NameLabel") then
                local targetRoot = v:FindFirstChild("HumanoidRootPart") or v:FindFirstChild("Head") or v
                if targetRoot:IsA("BasePart") then
                    -- Cálculo exato e instantâneo da distância
                    local dist = math.floor((lpRoot.Position - targetRoot.Position).Magnitude)
                    v.SixTag.NameLabel.Text = v.Name .. " [" .. dist .. "m]"
                end
            end
        end
    end
end)

-- --- FÍSICA E MOVIMENTO ---
RunService.Stepped:Connect(function()
    local char = game.Players.LocalPlayer.Character
    if char then
        local hum = char:FindFirstChild("Humanoid")
        if hum then hum.WalkSpeed = _G.WalkSpeed end
        
        if _G.Noclip then
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end
    end
end)
