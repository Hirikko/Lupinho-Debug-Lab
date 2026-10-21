# Lupinho-Debug-Lab
Jogo debug para testar limites implementados no lupinho.

!!!!! AVISO !!!!!
NÃO USE ESTE REPO EM SEU LUPI.
Não sei o que pode acontecer,
não tenho um Lupi para testar e arriscar.
!!!!!!!!!!!!!!!!!

Conteudo:
- game.lua
- palette-debug.lua

Instalacao:
1. Coloque game.lua e palette-debug.lua na raiz do pacote do jogo.
2. copie vários sprites para a pasta sprites, vários png para o teste dos sprites.
3. em lupi-codec, você vai usar lua run.lua pasta-jogo/ pasta-release/
4. o conteúdo de releases, você compacta .zip e renomeia para .lupi

Paleta:
- Os primeiros 43 valores de Palette sao a paleta do Sonic, preservada na ordem e nos valores exatos fornecidos. -- não funcionou para sonic ter as cores corretas, todos os sprites estão de cor incorreta.
- Depois entram as cores unicas da paleta original do Debug, mantendo a ordem relativa em que aparecem nela.
