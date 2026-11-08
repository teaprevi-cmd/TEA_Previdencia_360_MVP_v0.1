# TEA Previdência 360 — MVP técnico v0.1

**Status:** protótipo de homologação com dados exclusivamente sintéticos.  
**Não utilizar com dados pessoais ou casos reais.**

## Objetivo
Estruturar um núcleo modular, auditável e independente de fornecedor para:
- controlar o ciclo de vida de um caso;
- inventariar documentos e registrar a origem dos dados;
- executar competências especializadas por contratos estáveis;
- detectar pendências;
- gerar relatório preliminar não conclusivo;
- bloquear aprovação jurídica e protocolo por agentes.

## Decisões arquiteturais
- Arquitetura híbrida e independente de fornecedor.
- Skills em Markdown; contratos em JSON Schema; testes automatizados.
- ORION como orquestrador; DOC360, CNIS360 e HISTÓRIA360 como especialistas temporários.
- Revisão humana obrigatória antes de qualquer conclusão jurídica.
- Dados sintéticos no MVP; nenhum conector externo ativo.

## Requisitos
Python 3.10+; biblioteca padrão apenas.

## Executar
```bash
python -m unittest discover -s tests -v
python -m tea360.cli
```

## Estrutura
- `agents/`: responsabilidades, instruções e permissões.
- `skills/`: cinco competências operacionais.
- `workflows/`: fluxo inicial e aprovação humana.
- `tools/`: interfaces abstratas; sem OCR, banco ou pesquisa externa ativos.
- `knowledge/`: estrutura para fontes oficiais versionadas.
- `governance/`: bloqueios, privacidade e auditoria.
- `schemas/`: contratos JSON.
- `tests/`: testes unitários, integração e segurança.
- `synthetic_cases/`: cenários fictícios de aceitação.

## Limites deliberados
1. Não calcula direito adquirido ou grau de deficiência.
2. Não decide enquadramento legal, carência, tempo reconhecido ou elegibilidade.
3. Não transforma OCR ou declaração em fato confirmado.
4. Não envia requerimentos, mensagens ou documentos a terceiros.
5. Não acessa sistemas externos nem armazena documentos pessoais.
6. Não substitui revisão por advogado ou profissional autorizado.

## Estados de informação
- `CONFIRMADO`: conferido por pessoa autorizada e com evidência registrada.
- `PENDENTE_VALIDACAO`: extraído/declarado, ainda não conferido.
- `INCONCLUSIVO`: evidência insuficiente, ilegível ou conflitante.

## Próximos marcos
Fundação → Competências → Validação sintética → Homologação jurídica e de segurança → autorização formal para eventual piloto real.
