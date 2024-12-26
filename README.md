# Balança Neonatal
## Descrição
Entendendo que o foco do projeto é aprimorar o produto para um modelo mais próximo do estado da arte - aquele pronto para o mercado - vamos aprimorar o fluxo do projeto de modo que o sistema de pesagem possa ser sincronizado a um aplicativo através de um microcontrolador com interface Wi-Fi (NodeMCU).

## Estrutura das branches:
- A branch main não receberá código, ela conterá informações gerais acerca das demais branches e do projeto.
- A branch NodeMCU tratará do código C/C++ do microcontrolador.
- A branch App tratará do código Flutter do aplicativo.
- A branch API tratará do código do Java das APIs.

## Desenvolvimento do software
- O design será feito em FIGMA. 
- O app será feito em Flutter. 
- Utilizar-se-á de APIS feita em Java para testar a sincronia entre App e MCU. 
- Por fim, a API passará para a nuvem na AWS, onde o sistema será avaliado. 
- A arquitetura do App é de MVC, e o desenvolvimento será orientado a componentes/módulos. 

## Desenvolvimento do hardware
- As células de carga serão as mesmas.
- A base da esturtura e o acabamento serão aperfeiçoados. 
- O Arduino será substituído pelo NodeMCU. 
- A central controladora desaparecerá.
- A tela de interface será o aplicativo.

## Sugestões de nome pro produto e pro app:
 - Precious Weight - Escolhi esse, podemos mudar depois.
 - Prem Balance
 - IncuBalance
 - Weight Premies
