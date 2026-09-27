
Carregando mensagens mais antigas…
foi tudo
Perfeito. Então o mapa geral do hub está fechado.

Ficou assim, com 17 categorias principais:

Shop
Status & Server
LocalPlayer
Setting Farm
Hold and Select Skill
Farming
Stack Farming
Farming Other
Fruit and Raid and Dungeon
Sea Event
Upgrade Race
Get and Upgrade Items
Volcano Event
ESP
PVP
Tab Webhook
Setting
E os ajustes que você pediu continuam valendo: no LocalPlayer saem apenas Load config in Web e Push Data To Web; em Status & Server fica removido Open GUI Server Browser (Low Player and Ping).

Agora eu faria o próximo passo em duas etapas: primeiro a gente transforma isso em estrutura visual real do hub, com a barra lateral e cada categoria abrindo o painel correspondente; depois começamos a conectar as funções categoria por categoria, começando pelo Shop.

Se quiser, já podemos começar agora pela estrutura da interface, sem implementar a lógica interna ainda.

pode dale, mas quero algo exatamente como o dos print e videos
Perfeito — dá pra fazer nesse estilo exato dos prints e vídeos, e acho que esse é o melhor caminho agora.

Só pra alinhar bem: quando você diz “exatamente como o dos print e vídeos”, eu vou seguir essa base visual e estrutural:

Visual
layout escuro
barra lateral à esquerda
search bar no topo da lateral
categoria principal na lateral
painel grande à direita
título da categoria no topo
blocos/seções internas
botões dourados
toggles quadradinhos à direita
dropdowns largos
scroll vertical
estilo compacto, limpo e organizado
parecido com Banana Cat / W-Azure, como você vinha pedindo
Estrutura
Vou montar a interface com as 17 categorias que fechamos:

Shop
Status & Server
LocalPlayer
Setting Farm
Hold and Select Skill
Farming
Stack Farming
Farming Other
Fruit and Raid and Dungeon
Sea Event
Upgrade Race
Get and Upgrade Items
Volcano Event
ESP
PVP
Tab Webhook
Setting
Ajustes já confirmados
LocalPlayer: remover
Load config in Web
Push Data To Web
Status & Server: remover
Open GUI Server Browser (Low Player and Ping)
O que eu recomendo fazer agora
Fazer em 2 fases:

Fase 1 — Interface 100% visual
Primeiro eu monto:

a sidebar
o topo
o sistema de troca de abas
os cards internos
os dropdowns
os toggles
os botões
o scroll
o estilo PC/mobile
Sem ligar funções ainda.

Fase 2 — Funcionalidade
Depois conectamos:

primeiro Shop
depois Status & Server
depois LocalPlayer
e assim por diante
Meu conselho
Como você pediu “exatamente como os prints e vídeos”, o ideal agora é eu fazer a próxima versão como:

Base UI Rework
Uma versão focada só em:

copiar o layout visual
deixar a navegação igual
organizar todas as categorias
deixar pronto o esqueleto real do hub
E só depois a gente começa a plugar as funções por dentro.

Se você quiser, eu sigo assim e a próxima entrega fica sendo:

NovaHub_UI_Base_1
interface refeita no estilo dos prints/vídeos
17 categorias na barra lateral
sistema de troca de páginas
seções internas organizadas
visual compacto e bonito
pronto para começar a ligar as funções
Se quiser, eu já começo exatamente por essa base.

pode dale

Pensou por 7m 7s


Dale — já montei a primeira base visual completa no estilo dos prints/vídeos.

Ela já vem com:

as 17 categorias na lateral
barra de pesquisa
visual escuro com detalhes dourados
título central no topo
painel grande à direita
seções internas
botões Click
toggles quadrados
dropdowns
inputs
sliders
scroll lateral e interno
suporte PC/mobile
botão para esconder e reabrir o hub
E mantive os ajustes que você pediu:

LocalPlayer continua
removi Load config in Web
removi Push Data To Web
removi Open GUI Server Browser...
Essa versão é só interface, sem conectar as funções ainda. Isso é proposital pra gente validar primeiro se o visual ficou do jeito que você quer antes de mexer no código funcional.

Baixar pacote ZIP

Testa ela primeiro e me manda um print de como abriu. Aí a gente ajusta tamanho, largura da sidebar, espaçamento, fonte, cores e posição até ficar praticamente igual ao hub dos vídeos, antes de começar pelo Shop. 


NovaHub_UI_Base_1.lua
Código

NovaHub_UI_Base_1.txt
Documento
Anexo do usuário
tá meio feio, pode mudar para a cor roxa no lugar do amarelo, e coisas como essas no print tem que ser ajustavel, isso em todo o script

Pensou por 2m 34s
Ajustei essa parte inteira.

Troquei o amarelo pelo roxo 151, 92, 255 em todo o tema: título, seleção da sidebar, divisórias, toggles, dropdowns, botões e sliders. Também deixei o visual um pouco mais polido, com bordas roxas mais discretas, hover nas linhas e botões com gradiente roxo.

E o principal: todos os 25 sliders do script agora são realmente ajustáveis. Você pode clicar ou arrastar a barra com o mouse e também arrastar pelo toque no mobile. O número muda junto enquanto você movimenta, então coisas como:

% Health Player
Distance Teleport Y
Tween Speed
Distance Farm Aura
delays das skills
WalkSpeed
JumpPower
velocidades do barco
e todos os outros sliders
agora funcionam como controles de verdade.

Essa ainda é a base visual, então o valor já muda e fica armazenado na própria opção, mas ainda não está ligado à lógica de farm/combat — isso fazemos depois, categoria por categoria.

Baixar pacote ZIP

Testa essa versão. O próximo ponto que eu olharia é justamente aparência/tamanho/espaçamento: se ainda estiver feio, manda outro print e eu vou aproximando do visual dos vídeos sem mexer nas funções.


NovaHub_UI_Base_2.lua
Código

NovaHub_UI_Base_2.txt
Documento
Vamos lá. Ao invés do N, Nova Hub, não, tira, foca em Tave, como era antes, tá bem? Quero uma coisa maior, uma fonte um pouquinho maior, tá bem? Tá um pouquinho difícil de ler, só um pouquinho também não precisa aumentar tanto. E aquele rainho ali na esquerda, pode tirar quando você abre o hub, pode tirar aquele rainho ali, inútil. Adiciona um botão, assim como tem um botãozinho de minimizar o hub, adiciona um xzinho pra fechar o hub, tá bem? Caso eu queira parar de usar o hub. As opções que são clicáveis no hub, que era suposto ser uma setinha pra baixo, você só colocou tipo uma opção de alterar. Quando você clica, ele troca pras outras opções. Não, eu quero que quando você clique, ele abra, desça as opções e eu escolha as opções, tá bem?

Pensou por 1m 36s

Pronto. Fiz a Base 3 com essas mudanças no hub inteiro:

NovaHub virou Tave Hub
removi o raio do canto esquerdo
hub ficou um pouco maior
fontes ficaram ligeiramente maiores
mantive o botão — para minimizar
adicionei × para fechar/destruir o hub
o botão flutuante de reabrir agora é T, não N
refiz todos os dropdowns
agora aparece a seta ▼
ao clicar, a lista abre para baixo
você escolhe diretamente a opção
listas grandes, como NPCs, têm scroll
ao selecionar, a lista fecha e mostra a escolha
preservei as 17 categorias e toda a estrutura que montamos.
Baixar pacote ZIP

Testa principalmente o tamanho/fonte e os dropdowns. Essa parte do dropdown eu mudei na função-base, então vale automaticamente para todos eles no script. 


TaveHub_UI_Base_3.lua
Código

TaveHub_UI_Base_3.txt
Documento




-- Tave Hub UI Base 3
-- UI-only prototype based on the layout shown in the supplied screenshots/videos.
-- No farming/combat/shop logic is connected in this build.
-- Base 3: larger/clearer Tave UI + close button + true expanding dropdowns.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

pcall(function()
    local parent = (typeof(gethui) == "function" and gethui() or CoreGui)
    for _, guiName in ipairs({"NovaHub_UI_Base_1", "NovaHub_UI_Base_2", "TaveHub_UI_Base_3"}) do
        local old = parent:FindFirstChild(guiName)
        if old then old:Destroy() end
    end
end)

local Theme = {
    Main = Color3.fromRGB(12, 10, 18),
    Header = Color3.fromRGB(19, 16, 28),
    Sidebar = Color3.fromRGB(14, 12, 21),
    Panel = Color3.fromRGB(10, 9, 15),
    Row = Color3.fromRGB(27, 24, 35),
    RowHover = Color3.fromRGB(35, 30, 47),
    Input = Color3.fromRGB(31, 27, 41),
    Accent = Color3.fromRGB(151, 92, 255),
    AccentDark = Color3.fromRGB(94, 53, 178),
    AccentSoft = Color3.fromRGB(125, 78, 215),
    Text = Color3.fromRGB(246, 245, 249),
    Muted = Color3.fromRGB(174, 170, 184),
    Outline = Color3.fromRGB(73, 57, 103),
    Track = Color3.fromRGB(55, 51, 64),
}

local function New(className, props, parent)
    local obj = Instance.new(className)
    for k, v in pairs(props or {}) do
        obj[k] = v
    end
    if parent then obj.Parent = parent end
    return obj
end

local function Corner(parent, radius)
    return New("UICorner", {CornerRadius = UDim.new(0, radius or 6)}, parent)
end

local function Stroke(parent, color, thickness, transparency)
    return New("UIStroke", {
        Color = color or Theme.Outline,
        Thickness = thickness or 1,
        Transparency = transparency == nil and 0.45 or transparency,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    }, parent)
end

local function Tween(obj, props, time)
    TweenService:Create(obj, TweenInfo.new(time or 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
end

local PagesData = {
    { name = "Shop", sections = {
        { title = "Misc Shop", items = {
            { type = "button", text = "Redeem Code" },
            { type = "button", text = "Teleport Old World" },
            { type = "button", text = "Teleport New World" },
            { type = "button", text = "Teleport Third Sea" },
            { type = "button", text = "Buy Dual Flintlock" },
            { type = "button", text = "Reroll Race" },
            { type = "button", text = "Reset Stats" },
            { type = "button", text = "Buy Cyborg Race" },
            { type = "button", text = "Buy Ghoul Race" },
            { type = "toggle", text = "Auto Buy Legendary Sword" },
            { type = "toggle", text = "True Triple Katana" },
        } },
        { title = "Fighting Shop", items = {
            { type = "button", text = "Black Leg" },
            { type = "button", text = "Fishman Karate" },
            { type = "button", text = "Electro" },
            { type = "button", text = "Dragon Breath" },
            { type = "button", text = "SuperHuman" },
            { type = "button", text = "Death Step" },
            { type = "button", text = "Sharkman Karate" },
            { type = "button", text = "Electric Claw" },
            { type = "button", text = "Dragon Talon" },
            { type = "button", text = "God Human" },
            { type = "button", text = "Sanguine Art" },
        } },
        { title = "Abilities Shop", items = {
            { type = "button", text = "Skyjump [ $10,000 Beli ]" },
            { type = "button", text = "Buso Haki [ $25,000 Beli ]" },
            { type = "button", text = "Observation haki [ $750,000 Beli ]" },
