import json
from pathlib import Path
from datetime import datetime

def run_orion(case_id):
    case_path = Path(f"synthetic_cases/{case_id}/case.json")
    if not case_path.exists():
        return {"error": f"Caso {case_id} não encontrado."}
    
    case_data = json.loads(case_path.read_text())
    
    report = {
        "case_id": case_id,
        "status": "Relatório Preliminar Não Conclusivo",
        "generated_at": datetime.now().isoformat(),
        "findings": [],
        "guardrails_triggered": True
    }
    
    for doc in case_data.get("documents", []):
        doc_file = doc.get("structured_file", "").split("/")[-1]
        doc_path = Path(f"synthetic_cases/{case_id}/documents/{doc_file}")
        
        if doc_path.exists():
            doc_data = json.loads(doc_path.read_text())
            fields = doc_data.get("extracted_fields", {})
            
            if "diagnostic_hypotheses" in fields:
                for hyp in fields["diagnostic_hypotheses"]:
                    report["findings"].append(
                        f"📄 Documento {doc['document_id']}: Hipótese de {hyp['label']} (Status: {hyp['status']})"
                    )
            
            if "functional_impact" in fields:
                impact = fields["functional_impact"]
                if impact.get("need_for_predictability"):
                    report["findings"].append("⚠️ Perfil funcional indica necessidade de previsibilidade e rotina.")
                if impact.get("sensory_sensitivities"):
                    report["findings"].append("⚠️ Perfil funcional indica hipersensibilidade sensorial.")

            if "pending_periods" in fields:
                report["findings"].append(f"📊 Documento {doc['document_id']}: Tempo de contribuição inventariado ({fields.get('total_time_contribution_years')} anos e {fields.get('total_time_contribution_months')} meses).")
                for pend in fields["pending_periods"]:
                    report["findings"].append(f"🚨 PENDÊNCIA NO CNIS ({pend['start_date']} a {pend['end_date']}): {pend['reason']}. Requer documentação complementar.")
                    
    report["conclusion"] = "🛡️ ANÁLISE INCONCLUSIVA PARA FINS JURÍDICOS. REQUER REVISÃO HUMANA."
    return report
