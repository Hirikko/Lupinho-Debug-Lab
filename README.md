# Lupinho-Debug-Lab
Jogo debug para testar limites implementados no lupinho.

!!!!! AVISO !!!!!
NÃO USE ESTE REPO EM SEU LUPI.
Não sei o que pode acontecer,
não tenho um Lupi para testar e arriscar.
!!!!!!!!!!!!!!!!!

## Debug Lab (Jogo de Testes)

O jogo de debug foi modularizado (pasta `testes/`) e conta com novos recursos de validação e otimização de hardware.

### 1. Telemetria no Console (L1 + R1)
Em qualquer tela do jogo, segure **L1 + R1** (teclas G + H no teclado) para ativar/desativar o envio de telemetria via `ui.stat` direto para o console do navegador.
Por padrão, ele envia uma linha formatada a cada **2 segundos**:
`[info] [Telemetry] FPS: 60.0 | Uptime: 45.2s | FrameTime: 16.66ms | Frames: 2700 | LuaMem: 142KB`

### 2. Teste de Cores (RGB Hex)
O NPC de **CORES** agora exibe, além do índice e nome, o código Hexadecimal `#RRGGBB` calculado a partir da paleta BGR555 do Lupi, permitindo validar a cor externamente. A navegação também suporta mouse wheel, e o texto se adapta (inverte a cor) em fundos escuros ou claros.

### 3. Controles Visuais
Todos os controles do jogo (no teste de CONTROLE e no teste de SOM) agora seguem o padrão visual do controle SNES (Vinik), com cores corretas e feedback visual de "flash" ao pressionar os botões.

### 4. Novas APIs de Sistema
- **`ui.stat(n)`**: Retorna métricas do sistema em tempo real (FPS, CPU, Memória do Lua, etc.).
- **`ui.peektext()`**: Permite ver o próximo caractere do buffer de teclado sem consumi-lo.
- **Backspace**: Suporte nativo para apagar caracteres no teste READTEXT.

---

## Conteúdo:
```text
├── game.lua
├── jogador.lua
├── music
│   ├── actstart.fur
│   ├── bgm
│   │   ├── chefe.fur
│   │   ├── fim.fur
│   │   ├── greenhill.fur
│   │   ├── invenc.fur
│   │   ├── junglezn.fur
│   │   ├── labyrinthzn.fur
│   │   ├── marblezn-unused.fur
│   │   ├── salabonus.fur
│   │   ├── scrapbrainzn.fur
│   │   ├── skybasezn.fur
│   │   └── skysanct-unused.fur
│   ├── chefe.fur
│   ├── esmeraldacaos.fur
│   ├── fim.fur
│   ├── fx
│   │   ├── actstart.fur
│   │   ├── breathe.fur
│   │   ├── bumper.fur
│   │   ├── chaosemeraldget.fur
│   │   ├── chaosemeraldscircle.fur
│   │   ├── chaosemeraldscircle-onlyhigh.fur
│   │   ├── chaosemeraldscircle-onlylow.fur
│   │   ├── collapse.fur
│   │   ├── defeated.fur
│   │   ├── dooropenclose.fur
│   │   ├── electricity.fur
│   │   ├── electricityloop.fur
│   │   ├── esmeraldacaos.fur
│   │   ├── explosion1.fur
│   │   ├── explosion2.fur
│   │   ├── extralifeget.fur
│   │   ├── fall.fur
│   │   ├── firestream.fur
│   │   ├── glassbreak.fur
│   │   ├── goalpostfliploop.fur
│   │   ├── goalpostland.fur
│   │   ├── hit.fur
│   │   ├── hurt.fur
│   │   ├── jump.fur
│   │   ├── logointro.fur
│   │   ├── passou.fur
│   │   ├── perdeu.fur
│   │   ├── ramp.fur
│   │   ├── ringget.fur
│   │   ├── ringgetmulti.fur
│   │   ├── roll.fur
│   │   ├── sega.fur
│   │   ├── shot1.fur
│   │   ├── shot2.fur
│   │   ├── shot3.fur
│   │   ├── shot4.fur
│   │   ├── skid.fur
│   │   ├── spear.fur
│   │   ├── spring.fur
│   │   ├── switch.fur
│   │   ├── title.fur
│   │   ├── warp.fur
│   │   ├── watersplash1.fur
│   │   └── watersplash2.fur
│   ├── greenhill.fur
│   ├── invencivel.fur
│   ├── junglezone.fur
│   ├── labyrinthzone.fur
│   ├── marblezone.fur
│   ├── menu.fur
│   ├── passou.fur
│   ├── perdeu.fur
│   ├── salabonus.fur
│   ├── scrapbrainzone.fur
│   ├── skybasezone.fur
│   ├── skysanct.fur
│   ├── title.fur
│   ├── w1.fur
│   └── w2.fur
├── npcs.lua
├── palette-debug.lua
├── README.md
├── testes
│   ├── audio.lua
│   ├── controles.lua
│   ├── cores.lua
│   ├── estresse.lua
│   ├── lista.lua
│   ├── mouse.lua
│   ├── readtext.lua
│   └── sistema.lua
└── utils.lua
```
    
### Tela de Seleção de testes
<img width="1184" height="689" alt="image" src="https://github.com/user-attachments/assets/d86e29aa-26f2-486e-8b13-c39a869399d0" />

### Sala de seleção de testes
<img width="1422" height="823" alt="image" src="https://github.com/user-attachments/assets/626c70a4-d49b-4f2a-8209-91b292612792" />

### Controle
<img width="1444" height="828" alt="image" src="https://github.com/user-attachments/assets/f036ee66-ad96-4ded-aadd-9f90945fe613" />

### Tela de crash do limite de instruções lua
<img width="1181" height="706" alt="image" src="https://github.com/user-attachments/assets/a86a244a-d12a-45f6-a751-39a18405061b" />

## Instalacao:
Funciona no mesmo fluxo de um jogo lupi comum.

1. Coloque game.lua e palette-debug.lua na raiz do pacote do jogo.
2. copie vários sprites para a pasta sprites, vários png para o teste dos sprites.
3. em lupi-codec, você vai usar lua run.lua pasta-jogo/ pasta-release/
4. o conteúdo de releases, você compacta .zip e renomeia para .lupi

---

### Verificando o intervalo da Telemetria (2 segundos)
Para garantir que a alteração para 2 segundos ficou no lugar certo, verifique se a variável no topo do seu `game.lua` está assim:

```lua
local telemetry = {
  enabled = false,
  last_time = 0,
  interval = 2.0, -- <-- Aqui está o intervalo de 2 segundos
  combo_held = false
}
