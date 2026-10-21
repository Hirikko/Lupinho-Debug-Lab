# Lupinho-Debug-Lab
Jogo debug para testar limites implementados no lupinho.

!!!!! AVISO !!!!!
NÃO USE ESTE REPO EM SEU LUPI.
Não sei o que pode acontecer,
não tenho um Lupi para testar e arriscar.
!!!!!!!!!!!!!!!!!

## Conteudo:
- game.lua
- palette-debug.lua

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

Paleta:
- Os primeiros 43 valores de Palette sao a paleta do Sonic, preservada na ordem e nos valores exatos fornecidos. -- não funcionou para sonic ter as cores corretas, todos os sprites estão de cor incorreta.
- Depois entram as cores unicas da paleta original do Debug, mantendo a ordem relativa em que aparecem nela.
