-- [[ SIX HUB - ETERNAL NIGHTS: ULTRALITE EDITION ]]
-- Atalho: HOME

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()
local Window = Library.CreateLib("Six Hub: Eternal Nights", "BloodTheme")

-- --- CONFIGS ---
_G.AnimatronicESP = false
_G.PlayerESP = false
_G.ItemESP = false
_G.Noclip = false
_G.WalkSpeed = 16

local Cache = {Monsters = {}, Players = {}, Items = {}}

-- --- INTERFACE ---
local Tab1 = Window:NewTab("Visuals")
local Sec1 = Tab1:NewSection("Rastreadores (Event-Based)")

Sec1:NewToggle("ESP Animatronics", "Luz vermelha", function(s) _G.AnimatronicESP = s end)
Sec1:NewToggle("ESP Aliados", "Luz verde", function(s) _G.PlayerESP = s end)
Sec1:NewToggle("ESP Itens", "Luz amarela", function(s) _G.ItemESP = s end)

local Tab2 = Window:NewTab("Movimento")
Tab2:NewSection("Personagem"):NewSlider("Velocidade", "Speed", 100, 16, function(s) _G.WalkSpeed = s end)
Tab2:NewToggle("Noclip", "Atravessar paredes", function(s) _G.Noclip = s end)

-- --- FUNÇÃO DE CRIAÇÃO (SÓ RODA 1 VEZ POR OBJETO) ---
local function ApplyESP(obj, color, group)
    if not obj or obj:FindFirstChild("SixESP") then return end
    
    local highlight = Instance.new("Highlight")
    highlight.Name = "SixESP"
    highlight.FillColor = color
    highlight.OutlineColor = Color3.new(1,1,1)
    highlight.FillTransparency = 0.5
    highlight.Parent = obj

    local bill = Instance.new("BillboardGui", obj)
    bill.Name = "SixTag"
    bill.AlwaysOnTop = true
    bill.Size = UDim2.new(0, 80, 0, 30)
    bill.StudsOffset = Vector3.new(0, 3, 0)
    
    local label = Instance.new("TextLabel", bill)
    label.Name = "Label"
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(1, 0, 1, 0)
    label.TextColor3 = color
    label.Font = Enum.Font.SourceSansBold
    label.TextSize = 14
    label.Text = obj.Name

    table.insert(Cache[group], obj)
end

-- --- MONITOR DE NOVOS OBJETOS (MUITO LEVE) ---
local function Check(v)
    if v:IsA("Model") and v:FindFirstChild("Humanoid") then
        task.wait(0.5) -- Espera carregar o nome real
        if game.Players:GetPlayerFromCharacter(v) then
            if v ~= game.Players.LocalPlayer.Character then ApplyESP(v, Color3.new(0,1,0), "Players") end
        else
            ApplyESP(v, Color3.new(1,0,0), "Monsters")
        end
    elseif v:IsA("ProximityPrompt") or v:IsA("ClickDetector") then
        ApplyESP(v.Parent, Color3.new(1,1,0), "Items")
    end
end

workspace.DescendantAdded:Connect(Check)
for _, v in pairs(workspace:GetDescendants()) do task.spawn(Check, v) end

-- --- LOOP DE ATUALIZAÇÃO (FLUIDO E LEVE) ---
task.spawn(function()
    while true do
        local lp = game.Players.LocalPlayer.Character
        local root = lp and lp:FindFirstChild("HumanoidRootPart")
        
        if root then
            -- Speed
            if lp:FindFirstChild("Humanoid") then lp.Humanoid.WalkSpeed = _G.WalkSpeed end
            
            -- Distâncias (Apenas no que já está no Cache)
            for group, list in pairs(Cache) do
                local enabled = (group == "Monsters" and _G.AnimatronicESP) or (group == "Players" and _G.PlayerESP) or (group == "Items" and _G.ItemESP)
                
                for i, obj in pairs(list) do
                    if obj and obj.Parent and obj:FindFirstChild("SixTag") then
                        obj.SixESP.Enabled = enabled
                        obj.SixTag.Enabled = enabled
                        
                        if enabled then
                            local dist = math.floor((root.Position - (obj:IsA("Model") and obj:GetModelCFrame().Position or obj.Position)).Magnitude)
                            obj.SixTag.Label.Text = obj.Name .. " [" .. dist .. "m]"
                        end
                    else
                        table.remove(list, i)
                    end
                end
            end
        end
        task.wait(0.1) -- 10 Atualizações por segundo (Suave e sem lag)
    end
end)

-- --- NOCLIP OTIMIZADO ---
game:GetService("RunService").Stepped:Connect(function()
    if _G.Noclip and game.Players.LocalPlayer.Character then
        for _, v in pairs(game.Players.LocalPlayer.Character:GetDescendants()) do
            if v:IsA("BasePart") then v.CanCollide = false end
        end
    end
end)

Window:NewTab("Settings"):NewSection("Menu"):NewKeybind("Abrir/Fechar", "HOME", Enum.KeyCode.Home, function() Library:ToggleUI() end)
