"""Núcleo mínimo do MVP. Sem IA, conectores ou dados reais."""
from dataclasses import dataclass, field
from datetime import datetime, timezone
from enum import Enum
from typing import Any
import uuid

class CaseState(str, Enum):
    INTAKE = "INTAKE"
    CONSENT_PENDING = "CONSENT_PENDING"
    DOCUMENT_COLLECTION = "DOCUMENT_COLLECTION"
    EXTRACTION_PENDING_REVIEW = "EXTRACTION_PENDING_REVIEW"
    SPECIALIST_ANALYSIS = "SPECIALIST_ANALYSIS"
    PENDENCIES = "PENDENCIES"
    PRELIMINARY_REPORT = "PRELIMINARY_REPORT"
    HUMAN_REVIEW = "HUMAN_REVIEW"
    APPROVED = "APPROVED"
    RETURNED_FOR_COMPLEMENT = "RETURNED_FOR_COMPLEMENT"
    CLOSED = "CLOSED"

class EvidenceStatus(str, Enum):
    CONFIRMED = "CONFIRMADO"
    PENDING = "PENDENTE_VALIDACAO"
    INCONCLUSIVE = "INCONCLUSIVO"

@dataclass
class AuditEvent:
    event_id: str
    case_id: str
    actor: str
    action: str
    details: dict[str, Any]
    timestamp: str

@dataclass
class CaseFile:
    case_id: str
    state: CaseState = CaseState.INTAKE
    synthetic: bool = True
    consent_recorded: bool = False
    documents: list[dict[str, Any]] = field(default_factory=list)
    facts: list[dict[str, Any]] = field(default_factory=list)
    pendencies: list[dict[str, Any]] = field(default_factory=list)
    audit: list[AuditEvent] = field(default_factory=list)
    human_approval: dict[str, Any] | None = None

class GovernanceError(PermissionError):
    pass

class Orion:
    """Orquestrador: coordena etapas, não profere conclusão jurídica."""
    ALLOWED_TRANSITIONS = {
        CaseState.INTAKE: {CaseState.CONSENT_PENDING},
        CaseState.CONSENT_PENDING: {CaseState.DOCUMENT_COLLECTION},
        CaseState.DOCUMENT_COLLECTION: {CaseState.EXTRACTION_PENDING_REVIEW},
        CaseState.EXTRACTION_PENDING_REVIEW: {CaseState.SPECIALIST_ANALYSIS, CaseState.RETURNED_FOR_COMPLEMENT},
        CaseState.SPECIALIST_ANALYSIS: {CaseState.PENDENCIES},
        CaseState.PENDENCIES: {CaseState.PRELIMINARY_REPORT, CaseState.RETURNED_FOR_COMPLEMENT},
        CaseState.PRELIMINARY_REPORT: {CaseState.HUMAN_REVIEW},
        CaseState.HUMAN_REVIEW: {CaseState.APPROVED, CaseState.RETURNED_FOR_COMPLEMENT},
        CaseState.RETURNED_FOR_COMPLEMENT: {CaseState.DOCUMENT_COLLECTION},
        CaseState.APPROVED: {CaseState.CLOSED},
        CaseState.CLOSED: set(),
    }

    def _audit(self, case: CaseFile, actor: str, action: str, **details):
        case.audit.append(AuditEvent(
            event_id=str(uuid.uuid4()), case_id=case.case_id, actor=actor,
            action=action, details=details,
            timestamp=datetime.now(timezone.utc).isoformat()
        ))

    def transition(self, case: CaseFile, target: CaseState, actor="ORION"):
        if target not in self.ALLOWED_TRANSITIONS[case.state]:
            raise GovernanceError(f"Transição não permitida: {case.state} -> {target}")
        if target == CaseState.DOCUMENT_COLLECTION and not case.consent_recorded:
            raise GovernanceError("Não iniciar coleta sem registro de autorização aplicável.")
        if target == CaseState.APPROVED:
            raise GovernanceError("Agentes não podem aprovar conclusões jurídicas.")
        case.state = target
        self._audit(case, actor, "STATE_TRANSITION", target=target.value)

    def record_consent(self, case: CaseFile, reference: str, recorded_by: str):
        if not reference.strip() or not recorded_by.strip():
            raise ValueError("Referência e responsável pelo registro são obrigatórios.")
        case.consent_recorded = True
        self._audit(case, recorded_by, "CONSENT_RECORDED", reference=reference)

    def add_document(self, case: CaseFile, document: dict[str, Any], actor="DOC360"):
        required = {"document_id", "document_type", "source", "version", "status"}
        if not required.issubset(document):
            raise ValueError(f"Documento sem campos: {sorted(required - set(document))}")
        if document["status"] == EvidenceStatus.CONFIRMED.value:
            raise GovernanceError("DOC360 não pode marcar documento como confirmado.")
        case.documents.append(dict(document))
        self._audit(case, actor, "DOCUMENT_INVENTORIED", document_id=document["document_id"])

    def add_fact(self, case: CaseFile, fact: dict[str, Any], actor: str):
        required = {"field", "value", "source_ref", "status"}
        if not required.issubset(fact):
            raise ValueError("Fato deve conter field, value, source_ref e status.")
        if fact["status"] == EvidenceStatus.CONFIRMED.value and actor not in {"HUMAN_REVIEWER", "AUTHORIZED_OPERATOR"}:
            raise GovernanceError("Somente pessoa autorizada pode confirmar informação.")
        case.facts.append(dict(fact))
        self._audit(case, actor, "FACT_RECORDED", field=fact["field"], status=fact["status"])

    def detect_pendencies(self, case: CaseFile):
        pending = []
        for fact in case.facts:
            if fact["status"] != EvidenceStatus.CONFIRMED.value:
                pending.append({"type": "FACT_VALIDATION", "field": fact["field"], "source_ref": fact["source_ref"]})
        for doc in case.documents:
            if doc["status"] == EvidenceStatus.INCONCLUSIVE.value:
                pending.append({"type": "DOCUMENT_REVIEW", "document_id": doc["document_id"]})
        case.pendencies = pending
        self._audit(case, "ORION", "PENDENCIES_DETECTED", count=len(pending))
        return pending

    def human_approve(self, case: CaseFile, reviewer_id: str, decision: str, note: str):
        if case.state != CaseState.HUMAN_REVIEW:
            raise GovernanceError("Aprovação só pode ocorrer na etapa de revisão humana.")
        if decision not in {"APPROVE", "RETURN"}:
            raise ValueError("Decisão deve ser APPROVE ou RETURN.")
        if not reviewer_id.strip() or not note.strip():
            raise ValueError("Revisor e justificativa são obrigatórios.")
        case.human_approval = {"reviewer_id": reviewer_id, "decision": decision, "note": note}
        self._audit(case, reviewer_id, "HUMAN_DECISION", decision=decision, note=note)
        case.state = CaseState.APPROVED if decision == "APPROVE" else CaseState.RETURNED_FOR_COMPLEMENT
        self._audit(case, "ORION", "STATE_TRANSITION", target=case.state.value)
