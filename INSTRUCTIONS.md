# Diretrizes e Instruções de Execução do Projeto PreviTEA

Este documento estabelece regras inegociáveis para o MVP do TEA Previdência 360.

## 1. Agentes de IA

- Nenhum agente emite parecer jurídico definitivo.
- Nenhum agente calcula RMI, tempo exato de contribuição ou direito adquirido.
- Toda saída analítica deve ser rotulada como Relatório Preliminar Não Conclusivo.
- Todo dado extraído ou inferido deve possuir source_id.
- Sem fonte suficiente, o dado deve ser marcado como INCONCLUSIVO.
- Nenhuma ação externa de escrita é permitida.
- Somente humano autorizado pode mudar PENDENTE_VALIDACAO para CONFIRMADO.

## 2. Desenvolvimento

- Entradas e saídas devem ser validadas contra JSON Schemas.
- O núcleo não deve depender de SDK proprietário de LLM.
- Skills devem ser documentadas em Markdown.
- Testes e synthetic_cases não podem conter dados pessoais reais.

## 3. Governança e Privacidade

- Documentos reais e dados sensíveis ficam fora do repositório.
- Aplicar minimização de dados.
- Auditoria deve registrar eventos relevantes.

## 4. Estados da Informação

- CONFIRMADO: validado por humano autorizado.
- PENDENTE_VALIDACAO: extraído ou declarado, aguardando validação humana.
- INCONCLUSIVO: evidência insuficiente, conflitante ou ilegível.
