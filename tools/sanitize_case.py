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
