-- [[ SHOP EXPLOIT TESTER ]] --
local Remote = game:GetService("ReplicatedStorage"):WaitForChild("BuyThis")

-- Tente rodar isso com o console aberto (F9) para ver erros
local ItemsToTest = {
    "Sword", "Potion", "Armor", "Vip", -- Chutes de nomes comuns
    1, 2, 3, 100 -- Chutes de IDs
}

for _, item in pairs(ItemsToTest) do
    print("Tentando comprar: ", item)
    Remote:FireServer(item)
    task.wait(0.2)
end