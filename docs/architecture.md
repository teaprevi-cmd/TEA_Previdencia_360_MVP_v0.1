# Arquitetura v0.1
O núcleo é uma aplicação Python simples, com regras de fluxo explícitas. Agentes e Skills são contratos independentes do fornecedor de modelo. Adaptadores externos serão injetados atrás de interfaces, nunca embutidos na lógica jurídica.
Fluxo: ORION → especialista/Skill → saída estruturada → validação → auditoria → revisão humana.
