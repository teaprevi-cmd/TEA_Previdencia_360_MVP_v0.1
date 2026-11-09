# Base do Conhecimento: TEA Previdência 360

## 1. Definições e Conceitos-Chave

- TEA Previdência 360: núcleo técnico, modular e auditável do ecossistema PreviTEA.
- MVP v0.1: protótipo de homologação com dados sintéticos.
- Estados da informação: CONFIRMADO, PENDENTE_VALIDACAO e INCONCLUSIVO.
- Relatório preliminar: saída não conclusiva, sempre sujeita à revisão humana.

## 2. Marco Legal e Normativo

- LGPD: minimização, segurança e proibição de exposição indevida de dados sensíveis.
- Ética profissional: o sistema não substitui advogado ou responsável técnico.
- Regras previdenciárias: o sistema pode organizar informações, mas não decide direito.
- EC 103/2019: referência para simulações e análise estrutural, sem conclusão automática.

## 3. Atores e Stakeholders

- Segurado sintético: persona de teste.
- Advogado ou responsável técnico: único que confirma dados jurídicos.
- Agentes digitais: ORION, DOC360, CNIS360 e HISTÓRIA360.
- INSS: entidade externa, sem acesso ativo no MVP.
- OAB e ANPD: referências de conformidade ética e privacidade.

## 4. Processos e Fluxos Operacionais

- Ingestão documental.
- Triagem estruturada.
- Extração controlada de campos.
- Classificação de pendências.
- Relatório preliminar não conclusivo.
- Aprovação humana obrigatória.

## 5. Dados, Indicadores e Evidências

- Todo dado deve ter proveniência.
- Documentos são representados por metadados e campos estruturados.
- Texto bruto de documentos sensíveis não deve ser exposto a agentes.
- Casos sintéticos servem para teste de fluxo, validação de schemas e segurança.

## 6. Boas Práticas

- Vendor-agnosticism no núcleo.
- Contratos rígidos com JSON Schema.
- Human-in-the-loop obrigatório.
- Interface previsível e neuroinclusiva.
- Auditoria e rastreabilidade.

## 7. Riscos, Barreiras e Lições Aprendidas

- Risco de reidentificação se dados reais forem versionados.
- Risco de alucinação jurídica se agentes decidirem direito.
- Risco de UX inadequada para pessoas neurodivergentes.
- Risco de vazamento de dados de saúde.
- Necessidade de comunicação literal, previsível e sem sobrecarga sensorial.

## 8. Lacunas, Inconsistências e Pontos Truncados

- Documentos reais do caso-piloto não devem ser commitados.
- CaseSchema e ReportSchema ainda precisam ser implementados.
- OCR e conectores externos permanecem desativados no MVP.
- A validação jurídica final depende de humano autorizado.
