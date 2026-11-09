#!/usr/bin/env bash
set -euo pipefail

echo "Criando arquivos do PreviTEA..."

mkdir -p schemas tools docs/ux/prototype synthetic_cases/CASE-0001/documents governance/audit_logs tests

if [ -f .gitignore ]; then
  cp .gitignore .gitignore.bak
fi

cat > .gitignore <<'GITIGNORE_EOF'
# Python
__pycache__/
*.py[cod]
*.egg-info/
.venv/
venv/

# Dados sensíveis / originais
originals_private/
raw/
incoming/
*_privado/
*.pdf

# Exceções para artefatos sintéticos permitidos
!synthetic_cases/**/*.redacted.pdf
!synthetic_cases/**/*.json

# Logs e segredos
governance/audit_logs/*.log
*.env
*.local.json
tools/sanitization_entities.local.json

# Backups
*.bak
GITIGNORE_EOF

cat > INSTRUCTIONS.md <<'MD_EOF'
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
MD_EOF

cat > BASE_CONHECIMENTO.md <<'MD_EOF'
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
MD_EOF

cat > schemas/DocumentSchema.json <<'JSON_EOF'
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "schemas/DocumentSchema.json",
  "title": "PreviTEA DocumentSchema",
  "type": "object",
  "additionalProperties": false,
  "required": [
    "schema_version",
    "document_id",
    "case_id",
    "document_type",
    "information_state",
    "source",
    "privacy",
    "extracted_fields"
  ],
  "properties": {
    "schema_version": {
      "type": "string",
      "const": "0.1.0"
    },
    "document_id": {
      "type": "string",
      "pattern": "^DOC-[A-Za-z0-9_-]+$"
    },
    "case_id": {
      "type": "string",
      "pattern": "^CASE-[A-Za-z0-9_-]+$"
    },
    "document_type": {
      "enum": [
        "medical_report",
        "neuropsychological_report",
        "psychiatric_report",
        "identity_document",
        "driver_license",
        "education_diploma",
        "social_security_simulation",
        "cnis_extract",
        "employment_record",
        "other"
      ]
    },
    "information_state": {
      "enum": [
        "CONFIRMADO",
        "PENDENTE_VALIDACAO",
        "INCONCLUSIVO"
      ]
    },
    "issued_date": {
      "type": ["string", "null"],
      "format": "date"
    },
    "issuer": {
      "type": ["object", "null"],
      "additionalProperties": false,
      "properties": {
        "role": {
          "type": ["string", "null"]
        },
        "council_type": {
          "type": ["string", "null"]
        },
        "council_number": {
          "type": ["string", "null"]
        },
        "municipality": {
          "type": ["string", "null"]
        },
        "uf": {
          "type": ["string", "null"]
        }
      }
    },
    "source": {
      "type": "object",
      "additionalProperties": false,
      "required": [
        "original_sha256"
      ],
      "properties": {
        "original_file_name": {
          "type": ["string", "null"]
        },
        "original_sha256": {
          "type": "string",
          "pattern": "^[a-f0-9]{64}$"
        },
        "redacted_file": {
          "type": ["string", "null"]
        },
        "redaction": {
          "type": "object"
        }
      }
    },
    "privacy": {
      "type": "object",
      "additionalProperties": false,
      "required": [
        "raw_text_to_llm"
      ],
      "properties": {
        "contains_personal_data": {
          "type": "boolean"
        },
        "contains_sensitive_health_data": {
          "type": ["boolean", "null"]
        },
        "raw_text_to_llm": {
          "const": false
        },
        "retention": {
          "enum": [
            "manifest_only",
            "redacted_only",
            "restricted_access"
          ]
        }
      }
    },
    "extracted_fields": {
      "type": "object"
    },
    "provenance": {
      "type": "array",
      "items": {
        "type": "object",
        "additionalProperties": false,
        "required": [
          "field",
          "source_id"
        ],
        "properties": {
          "field": {
            "type": "string"
          },
          "source_id": {
            "type": "string"
          },
          "page": {
            "type": ["integer", "null"]
          },
          "confidence": {
            "type": ["number", "null"],
            "minimum": 0,
            "maximum": 1
          }
        }
      }
    },
    "created_at": {
      "type": "string",
      "format": "date-time"
    }
  }
}
JSON_EOF

cat > schemas/TeaClinicalReportSchema.json <<'JSON_EOF'
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "schemas/TeaClinicalReportSchema.json",
  "title": "PreviTEA TEA Clinical Report Schema",
  "type": "object",
  "allOf": [
    {
      "$ref": "DocumentSchema.json"
    }
  ],
  "properties": {
    "document_type": {
      "enum": [
        "medical_report",
        "neuropsychological_report",
        "psychiatric_report"
      ]
    },
    "extracted_fields": {
      "type": "object",
      "additionalProperties": false,
      "required": [
        "diagnostic_hypotheses",
        "functional_impact"
      ],
      "properties": {
        "diagnostic_hypotheses": {
          "type": "array",
          "items": {
            "type": "object",
            "additionalProperties": false,
            "required": [
              "label",
              "status"
            ],
            "properties": {
              "code_system": {
                "enum": [
                  "CID-10",
                  "CID-11",
                  "DSM-5-TR",
                  "outro"
                ]
              },
              "code": {
                "type": ["string", "null"]
              },
              "label": {
                "type": "string"
              },
              "support_level": {
                "enum": [
                  "1",
                  "2",
                  "3",
                  "nao_se_aplica",
                  null
                ]
              },
              "presentation": {
                "type": ["string", "null"]
              },
              "status": {
                "enum": [
                  "confirmado",
                  "sugestivo",
                  "pendente_validacao",
                  "inconclusivo"
                ]
              }
            }
          }
        },
        "functional_impact": {
          "type": "object",
          "additionalProperties": false,
          "properties": {
            "social_interaction": {
              "enum": [
                "baixo",
                "leve",
                "moderado",
                "grave",
                "nao_informado"
              ]
            },
            "professional_context": {
              "enum": [
                "baixo",
                "leve",
                "moderado",
                "grave",
                "nao_informado"
              ]
            },
            "affective_relationships": {
              "enum": [
                "baixo",
                "leve",
                "moderado",
                "grave",
                "nao_informado"
              ]
            },
            "daily_life": {
              "enum": [
                "baixo",
                "leve",
                "moderado",
                "grave",
                "nao_informado"
              ]
            },
            "sensory_sensitivities": {
              "type": "boolean"
            },
            "need_for_predictability": {
              "type": "boolean"
            },
            "literal_communication": {
              "type": "boolean"
            }
          }
        },
        "cognitive_profile": {
          "type": "object",
          "additionalProperties": false,
          "properties": {
            "overall_intellectual_functioning": {
              "enum": [
                "abaixo_da_media",
                "media",
                "media_superior",
                "superior",
                "muito_superior",
                "nao_informado"
              ]
            },
            "working_memory": {
              "enum": [
                "abaixo_da_media",
                "media",
                "media_superior",
                "superior",
                "muito_superior",
                "nao_informado"
              ]
            },
            "processing_speed": {
              "enum": [
                "abaixo_da_media",
                "media",
                "media_superior",
                "superior",
                "muito_superior",
                "nao_informado"
              ]
            },
            "attention": {
              "enum": [
                "abaixo_da_media",
                "media",
                "media_superior",
                "superior",
                "muito_superior",
                "nao_informado"
              ]
            },
            "executive_functioning": {
              "enum": [
                "prejudicado",
                "preservado_em_teste_estruturado",
                "misto",
                "nao_informado"
              ]
            }
          }
        },
        "raw_text": {
          "const": null
        }
      }
    }
  }
}
JSON_EOF

cat > tools/sanitize_case.py <<'PY_EOF'
#!/usr/bin/env python3
"""
tools/sanitize_case.py

Sanitiza PDFs e gera um synthetic_case compatível com o PreviTEA/TEA360.

Este script:
- NÃO envia dados para LLM;
- NÃO armazena texto bruto;
- gera manifesto auditável;
- tenta redagir automaticamente PDFs com camada de texto;
- marca revisão manual quando necessário.

Dependência opcional:
- PyMuPDF (fitz) para redação automática.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import secrets
from datetime import datetime, timezone
from pathlib import Path

SCHEMA_VERSION = "0.1.0"

DEFAULT_REGEXES = {
    "cpf": r"\b(?:\d{3}\.?\d{3}\.?\d{3}-?\d{2})\b",
    "cnpj": r"\b(?:\d{2}\.?\d{3}\.?\d{3}/?\d{4}-?\d{2})\b",
    "rg_like": r"\b\d{1,2}\.?\d{3}\.?\d{3}(?:-\d)?\b",
    "cnh_like": r"\b\d{10,12}\b",
    "date_br": r"\b\d{2}/\d{2}/\d{4}\b",
    "datetime_br": r"\b\d{2}/\d{2}/\d{4}\s+\d{2}:\d{2}(?::\d{2})?\b",
    "phone_br": r"\b(?:\+?55\s?)?(?:\(?\d{2}\)?\s?)?(?:9?\d{4}[-\s]?\d{4})\b",
    "email": r"\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b",
    "cep": r"\b\d{5}-?\d{3}\b",
}


def utc_now():
    return datetime.now(timezone.utc).isoformat()


def relpath(path):
    try:
        return path.relative_to(Path.cwd()).as_posix()
    except Exception:
        return str(path)


def sha256_file(path):
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(8192), b""):
            h.update(chunk)
    return h.hexdigest()


def load_extra_patterns(path):
    if not path:
        return {}
    data = json.loads(path.read_text(encoding="utf-8"))
    return {k: re.compile(v) for k, v in data.items()}


def compile_patterns(extra):
    patterns = {k: re.compile(v) for k, v in DEFAULT_REGEXES.items()}
    patterns.update(extra)
    return patterns


def generate_synthetic_identity(case_id):
    return {
        "subject_id": f"SUBJ-{case_id}-001",
        "display_name": f"Segurado Sintético {case_id}",
        "birth_date": None,
        "age_band": "nao_informada",
        "document_numbers": "todos_removidos_ou_sinteticos",
        "notes": "Identidade gerada para testes; não corresponde a pessoa real.",
    }


def redact_pdf(pdf_path, output_pdf, patterns):
    try:
        import fitz
    except Exception:
        return {
            "automatic_redaction": False,
            "manual_redaction_required": True,
            "reason": (
                "PyMuPDF não instalado. Instale com 'pip install pymupdf' "
                "dentro de um ambiente virtual ou faça redação manual."
            ),
            "redacted_fields": [],
        }

    doc = fitz.open(pdf_path)
    redacted_fields = []

    for page in doc:
        text_dict = page.get_text("dict")

        for block in text_dict.get("blocks", []):
            if block.get("type", 0) != 0:
                continue

            for line in block.get("lines", []):
                for span in line.get("spans", []):
                    text = span.get("text", "")
                    matched_fields = []

                    for field, regex in patterns.items():
                        if regex.search(text):
                            matched_fields.append(field)

                    if matched_fields:
                        rect = fitz.Rect(span["bbox"])
                        page.add_redact_annot(rect, text="[DADO_REMOVIDO]")
                        for field in matched_fields:
                            redacted_fields.append(
                                {
                                    "page": page.number + 1,
                                    "field": field,
                                }
                            )

        page.apply_redactions()

    doc.save(output_pdf, deflate=True, garbage=4)
    doc.close()

    return {
        "automatic_redaction": True,
        "manual_redaction_required": len(redacted_fields) == 0,
        "redacted_fields": redacted_fields,
        "output_pdf": relpath(output_pdf),
    }


def build_document_record(
    pdf_path,
    case_id,
    out_dir,
    patterns,
    redact,
    sensitive_health,
):
    doc_id = f"DOC-{secrets.token_hex(6)}"
    original_hash = sha256_file(pdf_path)

    doc_dir = out_dir / case_id / "documents"
    doc_dir.mkdir(parents=True, exist_ok=True)

    redacted_path = doc_dir / f"{doc_id}.redacted.pdf"

    if redact:
        redaction = redact_pdf(pdf_path, redacted_path, patterns)
    else:
        redaction = {
            "automatic_redaction": False,
            "manual_redaction_required": True,
            "reason": "Redação automática desativada. Não versione PDF original.",
            "redacted_fields": [],
        }

    record = {
        "schema_version": SCHEMA_VERSION,
        "document_id": doc_id,
        "case_id": case_id,
        "document_type": "pending_classification",
        "information_state": "PENDENTE_VALIDACAO",
        "source": {
            "original_file_name": None,
            "original_sha256": original_hash,
            "redacted_file": relpath(redacted_path) if redacted_path.exists() else None,
            "redaction": redaction,
        },
        "privacy": {
            "contains_personal_data": True,
            "contains_sensitive_health_data": True if sensitive_health else None,
            "raw_text_to_llm": False,
            "retention": "manifest_only",
        },
        "extracted_fields": {},
        "provenance": [],
        "created_at": utc_now(),
    }

    return record


def main():
    parser = argparse.ArgumentParser(
        description="Sanitiza PDFs e gera synthetic_case PreviTEA."
    )
    parser.add_argument(
        "--pdf",
        action="append",
        required=True,
        help="Caminho do PDF original. Pode usar várias vezes.",
    )
    parser.add_argument("--case-id", required=True)
    parser.add_argument("--output", default="synthetic_cases")
    parser.add_argument(
        "--entities",
        help="JSON com regex extras para redação.",
    )
    parser.add_argument(
        "--no-redact",
        action="store_true",
        help="Não tenta redação automática.",
    )
    parser.add_argument(
        "--sensitive-health",
        action="store_true",
        help="Marca os documentos como contendo dados sensíveis de saúde.",
    )

    args = parser.parse_args()

    out_dir = Path(args.output)
    case_dir = out_dir / args.case_id
    case_dir.mkdir(parents=True, exist_ok=True)

    extra_path = Path(args.entities) if args.entities else None
    patterns = compile_patterns(load_extra_patterns(extra_path))

    docs = []
    for pdf in args.pdf:
        p = Path(pdf)
        docs.append(
            build_document_record(
                p,
                args.case_id,
                out_dir,
                patterns,
                redact=not args.no_redact,
                sensitive_health=args.sensitive_health,
            )
        )

    synthetic_case = {
        "schema_version": SCHEMA_VERSION,
        "case_id": args.case_id,
        "environment": "MODO_SINTETICO",
        "information_state": "PENDENTE_VALIDACAO",
        "subject": generate_synthetic_identity(args.case_id),
        "guardrails": {
            "legal_conclusion": "blocked",
            "rmi_calculation": "blocked",
            "external_protocol": "blocked",
            "human_approval_required": True,
        },
        "documents": docs,
        "created_at": utc_now(),
    }

    case_path = case_dir / "case.json"
    case_path.write_text(
        json.dumps(synthetic_case, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )

    print(f"Manifesto gerado: {relpath(case_path)}")

    if any(
        d["source"]["redaction"].get("manual_redaction_required")
        for d in docs
    ):
        print("Atenção: revisão manual de redação é necessária antes de prosseguir.")


if __name__ == "__main__":
    main()
PY_EOF

chmod +x tools/sanitize_case.py

cat > tools/sanitization_entities.example.json <<'JSON_EOF'
{
  "nome_real": "\\bNOME_REAL\\b",
  "sobrenome_real": "\\bSOBRENOME_REAL\\b",
  "nome_profissional": "\\bPROFISSIONAL_REAL\\b",
  "endereco_real": "\\bENDERECO_REAL\\b",
  "documento_real": "\\bDOCUMENTO_REAL\\b"
}
JSON_EOF

cat > docs/ux/prototype/index.html <<'HTML_EOF'
<!doctype html>
<html lang="pt-BR">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>PreviTEA — Caso CASE-0001</title>
  <style>
    :root {
      --bg: #f6f4ef;
      --surface: #fffdf8;
      --text: #222222;
      --muted: #5b5b5b;
      --border: #d8d3c8;
      --accent: #31618a;
      --accent-soft: #eaf1f7;
      --warning-bg: #faf3e0;
      --warning-border: #d8b65e;
      --warning-text: #6a5300;
      --focus: #1d4e89;
    }

    * {
      box-sizing: border-box;
    }

    body {
      margin: 0;
      background: var(--bg);
      color: var(--text);
      font-family: "Atkinson Hyperlegible", "Lexend", "Segoe UI", Arial, sans-serif;
      font-size: 18px;
      line-height: 1.6;
    }

    .container {
      max-width: 860px;
      margin: 0 auto;
      padding: 24px;
    }

    h1 {
      font-size: 1.7rem;
      margin: 0 0 8px 0;
    }

    .subtitle {
      color: var(--muted);
      margin: 0;
    }

    .progress {
      display: flex;
      flex-wrap: wrap;
      gap: 8px;
      padding: 0;
      list-style: none;
      margin: 20px 0;
    }

    .progress li {
      border: 1px solid var(--border);
      background: var(--surface);
      border-radius: 999px;
      padding: 8px 12px;
      color: var(--muted);
      font-size: 0.95rem;
    }

    .progress li.active {
      background: var(--accent-soft);
      border-color: var(--accent);
      color: var(--text);
      font-weight: 600;
    }

    .card {
      background: var(--surface);
      border: 1px solid var(--border);
      border-radius: 14px;
      padding: 20px;
      margin-bottom: 16px;
    }

    .meta {
      color: var(--muted);
      font-size: 0.95rem;
      margin: 4px 0;
    }

    .status {
      display: inline-block;
      border-radius: 999px;
      padding: 6px 10px;
      border: 1px solid var(--warning-border);
      background: var(--warning-bg);
      color: var(--warning-text);
      font-size: 0.92rem;
      font-weight: 600;
      margin: 8px 0;
    }

    .actions {
      display: flex;
      flex-wrap: wrap;
      gap: 10px;
      margin-top: 16px;
    }

    button {
      appearance: none;
      border: 1px solid var(--border);
      background: var(--surface);
      color: var(--text);
      border-radius: 10px;
      padding: 11px 14px;
      font-size: 1rem;
      cursor: pointer;
    }

    button.primary {
      background: var(--accent);
      border-color: var(--accent);
      color: #ffffff;
    }

    button:focus-visible {
      outline: 3px solid var(--focus);
      outline-offset: 2px;
    }

    .notice {
      border: 1px solid var(--warning-border);
      background: var(--warning-bg);
      color: var(--warning-text);
      border-radius: 12px;
      padding: 14px 16px;
      margin-bottom: 16px;
    }
  </style>
</head>
<body>
  <main class="container">
    <header>
      <h1>PreviTEA — Caso CASE-0001</h1>
      <p class="subtitle">
        Ambiente de homologação com dados sintéticos. Nenhum direito está sendo calculado.
      </p>
    </header>

    <ol class="progress" aria-label="Progresso do caso">
      <li>Início</li>
      <li>Consentimento</li>
      <li>Documentos</li>
      <li class="active">Triagem</li>
      <li>Pendências</li>
      <li>Revisão humana</li>
      <li>Relatório</li>
    </ol>

    <div class="notice">
      Os documentos abaixo estão em estado PENDENTE_VALIDACAO.
      A aprovação final deve ser feita por profissional autorizado.
    </div>

    <section aria-label="Documentos do caso">
      <article class="card">
        <h2>Avaliação sintética</h2>
        <p class="meta">Tipo: neuropsychological_report</p>
        <p class="meta">Origem: DOC-0001</p>
        <span class="status">PENDENTE_VALIDACAO</span>
        <p>
          Estrutura recebida com hipóteses diagnósticas e impacto funcional.
          Texto bruto não será exibido nem enviado para análise automática.
        </p>
        <div class="actions">
          <button type="button">Revisar campos</button>
          <button type="button">Ver metadados</button>
        </div>
      </article>
    </section>

    <section aria-label="Ações do caso">
      <div class="actions">
        <button type="button">Salvar e sair</button>
        <button type="button">Voltar</button>
        <button type="button" class="primary">Continuar para pendências</button>
      </div>
    </section>
  </main>
</body>
</html>
HTML_EOF

cat > synthetic_cases/CASE-0001/case.json <<'JSON_EOF'
{
  "schema_version": "0.1.0",
  "case_id": "CASE-0001",
  "environment": "MODO_SINTETICO",
  "information_state": "PENDENTE_VALIDACAO",
  "subject": {
    "subject_id": "SUBJ-CASE-0001-001",
    "display_name": "Segurado Sintético CASE-0001",
    "birth_date": null,
    "age_band": "nao_informada",
    "document_numbers": "nao_informados"
  },
  "guardrails": {
    "legal_conclusion": "blocked",
    "rmi_calculation": "blocked",
    "external_protocol": "blocked",
    "human_approval_required": true
  },
  "documents": [
    {
      "document_id": "DOC-0001",
      "document_type": "neuropsychological_report",
      "information_state": "PENDENTE_VALIDACAO",
      "structured_file": "documents/DOC-0001.json"
    }
  ],
  "created_at": "2026-11-09T00:00:00Z"
}
JSON_EOF

cat > synthetic_cases/CASE-0001/documents/DOC-0001.json <<'JSON_EOF'
{
  "schema_version": "0.1.0",
  "document_id": "DOC-0001",
  "case_id": "CASE-0001",
  "document_type": "neuropsychological_report",
  "information_state": "PENDENTE_VALIDACAO",
  "issued_date": null,
  "issuer": {
    "role": "neuropsychologist",
    "council_type": null,
    "council_number": null,
    "municipality": null,
    "uf": null
  },
  "source": {
    "original_file_name": null,
    "original_sha256": "0000000000000000000000000000000000000000000000000000000000000000",
    "redacted_file": null,
    "redaction": {
      "automatic_redaction": false,
      "manual_redaction_required": true
    }
  },
  "privacy": {
    "contains_personal_data": false,
    "contains_sensitive_health_data": true,
    "raw_text_to_llm": false,
    "retention": "manifest_only"
  },
  "extracted_fields": {
    "diagnostic_hypotheses": [
      {
        "code_system": "CID-10",
        "code": "F84.0",
        "label": "Transtorno do Espectro Autista",
        "support_level": "1",
        "presentation": null,
        "status": "sugestivo"
      },
      {
        "code_system": "CID-10",
        "code": "F90.2",
        "label": "Transtorno do Déficit de Atenção/Hiperatividade",
        "support_level": null,
        "presentation": "combinada",
        "status": "sugestivo"
      },
      {
        "code_system": "outro",
        "code": null,
        "label": "Altas Habilidades/Superdotação",
        "support_level": null,
        "presentation": null,
        "status": "sugestivo"
      }
    ],
    "functional_impact": {
      "social_interaction": "moderado",
      "professional_context": "moderado",
      "affective_relationships": "moderado",
      "daily_life": "leve",
      "sensory_sensitivities": true,
      "need_for_predictability": true,
      "literal_communication": true
    },
    "cognitive_profile": {
      "overall_intellectual_functioning": "superior",
      "working_memory": "muito_superior",
      "processing_speed": "media",
      "attention": "media_superior",
      "executive_functioning": "preservado_em_teste_estruturado"
    }
  },
  "provenance": [
    {
      "field": "extracted_fields.diagnostic_hypotheses[0]",
      "source_id": "DOC-0001",
      "page": null,
      "confidence": null
    }
  ],
  "created_at": "2026-11-09T00:00:00Z"
}
JSON_EOF

cat > tests/test_no_pii_regex.py <<'PY_EOF'
import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

TARGETS = [
    "synthetic_cases",
    "docs/ux",
    "INSTRUCTIONS.md",
    "BASE_CONHECIMENTO.md",
]

EXTENSIONS = {".md", ".json", ".html"}

PATTERNS = [
    re.compile(r"(?<!\d)(?:\d{3}\.?\d{3}\.?\d{3}-?\d{2})(?!\d)"),
    re.compile(r"\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b"),
    re.compile(
        r"(?<!\d)(?:\+?55\s?)?(?:\(\d{2}\)|\d{2})\s?9?\d{4}[-\s]\d{4}(?!\d)"
    ),
]


class TestNoPII(unittest.TestCase):
    def assert_no_pii(self, text, path):
        for pattern in PATTERNS:
            match = pattern.search(text)
            if match:
                self.fail(f"Possible PII in {path}: {match.group(0)}")

    def test_targets(self):
        files = []

        for target in TARGETS:
            p = ROOT / target
            if p.is_file():
                files.append(p)
            elif p.is_dir():
                for f in p.rglob("*"):
                    if f.is_file() and f.suffix in EXTENSIONS:
                        files.append(f)

        self.assertTrue(files, "No files found to scan")

        for f in files:
            text = f.read_text(encoding="utf-8", errors="ignore")
            self.assert_no_pii(text, f.relative_to(ROOT))


if __name__ == "__main__":
    unittest.main()
PY_EOF

touch governance/audit_logs/.gitkeep

echo "Validando JSON..."
python3 -m json.tool schemas/DocumentSchema.json > /dev/null
python3 -m json.tool schemas/TeaClinicalReportSchema.json > /dev/null
python3 -m json.tool synthetic_cases/CASE-0001/case.json > /dev/null
python3 -m json.tool synthetic_cases/CASE-0001/documents/DOC-0001.json > /dev/null
python3 -m json.tool tools/sanitization_entities.example.json > /dev/null

echo "Testando script de sanitização..."
python3 tools/sanitize_case.py --help > /dev/null

echo "Executando teste anti-PII..."
python3 tests/test_no_pii_regex.py

echo "Arquivos criados com sucesso."
