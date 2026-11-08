from .core import Orion, CaseFile, CaseState

def main():
    case = CaseFile(case_id="DEMO-SYNTHETIC-001")
    orion = Orion()
    orion.transition(case, CaseState.CONSENT_PENDING)
    orion.record_consent(case, "CONSENTIMENTO-FICTICIO-001", "OPERADOR-DEMO")
    orion.transition(case, CaseState.DOCUMENT_COLLECTION)
    print("TEA Previdência 360 MVP v0.1")
    print(f"Caso sintético: {case.case_id}")
    print(f"Estado atual: {case.state.value}")
    print(f"Eventos de auditoria: {len(case.audit)}")
    print("Nenhum dado real foi utilizado.")

if __name__ == "__main__":
    main()
