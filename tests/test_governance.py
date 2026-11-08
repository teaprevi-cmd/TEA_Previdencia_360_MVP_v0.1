import unittest
from tea360.core import *

class GovernanceTests(unittest.TestCase):
    def setUp(self):
        self.case = CaseFile("TEST-SYNTH", synthetic=True)
        self.o = Orion()

    def test_collection_blocked_without_authorization(self):
        self.o.transition(self.case, CaseState.CONSENT_PENDING)
        with self.assertRaises(GovernanceError):
            self.o.transition(self.case, CaseState.DOCUMENT_COLLECTION)

    def test_agent_cannot_confirm_fact(self):
        with self.assertRaises(GovernanceError):
            self.o.add_fact(self.case, {"field":"date","value":"2020-01-01","source_ref":"D1","status":"CONFIRMADO"}, "DOC360")

    def test_doc_agent_cannot_mark_document_confirmed(self):
        with self.assertRaises(GovernanceError):
            self.o.add_document(self.case, {"document_id":"D1","document_type":"CNIS","source":"synthetic","version":1,"status":"CONFIRMADO"})

    def test_agent_cannot_approve(self):
        with self.assertRaises(GovernanceError):
            self.o.transition(self.case, CaseState.APPROVED)

    def test_audit_created(self):
        self.o.transition(self.case, CaseState.CONSENT_PENDING)
        self.assertEqual(self.case.audit[-1].action, "STATE_TRANSITION")

    def test_pending_fact_detected(self):
        self.o.add_fact(self.case, {"field":"employer","value":"Empresa fictícia","source_ref":"D1","status":"PENDENTE_VALIDACAO"}, "CNIS360")
        self.assertEqual(len(self.o.detect_pendencies(self.case)), 1)

    def test_human_approval_required(self):
        self.case.state = CaseState.HUMAN_REVIEW
        self.o.human_approve(self.case, "REVISOR-FICTICIO", "APPROVE", "Revisão sintética")
        self.assertEqual(self.case.state, CaseState.APPROVED)

if __name__ == "__main__":
    unittest.main()
