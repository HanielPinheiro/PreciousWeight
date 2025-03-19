# Fluxo da API

## Passo 1: Seleção e Verificação da Balança

Verifique o estado atual da balança na tabela scaleModel:

 - Estado_Balanca = 0 (vaga): A balança está disponível para uso.
 - Estado_Balanca = 1 (operante): A balança está em uso.
 - Estado_Balanca = 2 (inoperante): A balança não está funcional.

Ao alterar o estado da balança:

+ Atualize o campo Estado_Balanca na tabela scaleModel.
+ Crie um registro na tabela log_balanca com os seguintes valores:
  + data_log: Timestamp da mudança.
  + id_balanca: Identificação da balança.
  + estado_balanca: Estado anterior.
  + novo_estado_balanca: Novo estado.       
        

## Passo 2: Vinculação do Paciente à Balança

Ao associar um babyModel a uma balança:

- Verifique se a balança está operante (Estado_Balanca = 1).
- Atualize os registros necessários para vincular o babyModel.

Crie um registro na tabela log_paciente:

  - data_log: Timestamp do vínculo.
  - id_paciente: ID do babyModel.
  - id_balanca: ID da balança anteriormente usada (ou NULL se for a primeira vez).
  - novo_id_balanca: ID da nova balança vinculada.

## Passo 3: Registro de Pesagem

Após o babyModel ser vinculado a uma balança:

- Registre o weightModel na tabela weightModel com os seguintes valores:
  - data_peso: Data e hora da medição.
  - id_balanca: ID da balança usada.
  - id_paciente: ID do babyModel.
  - weightModel: Valor medido (em miligramas ou gramas, conforme resolução mínima da balança).