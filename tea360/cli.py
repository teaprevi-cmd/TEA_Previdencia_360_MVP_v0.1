import sys
import json
from pathlib import Path
from datetime import datetime
from tea360.orion import run_orion

def main():
    print("="*60)
    print(" 🏛️  PreviTEA - CLI de Revisão Humana (MVP v0.1)")
    print(" 🔒 Ambiente: MODO_SINTETICO | LGPD Compliance: ATIVO")
    print("="*60)
    
    cases_dir = Path("synthetic_cases")
    pending_cases = []
    
    for case_file in cases_dir.glob("*/case.json"):
        data = json.loads(case_file.read_text())
        if data.get("information_state") == "PENDENTE_VALIDACAO":
            pending_cases.append(data)
            
    if not pending_cases:
        print("\n✅ Nenhum caso pendente de validação no momento.")
        return
        
    print(f"\n⚠️  Você tem {len(pending_cases)} caso(s) aguardando validação:\n")
    for i, case in enumerate(pending_cases):
        print(f"  [{i+1}] {case['case_id']} - {case['subject']['display_name']}")
        
    choice = input("\nDigite o número do caso para analisar (ou 's' para sair): ").strip()
    if choice.lower() == 's':
        return
        
    try:
        idx = int(choice) - 1
        selected_case = pending_cases[idx]
    except (ValueError, IndexError):
        print("Opção inválida.")
        return
        
    print(f"\n🤖 ORION processando {selected_case['case_id']}...")
    report = run_orion(selected_case['case_id'])
    
    print("\n" + "="*60)
    print(" 📑 RELATÓRIO PRELIMINAR NÃO CONCLUSIVO")
    print("="*60)
    for finding in report.get('findings', []):
        print(f"  • {finding}")
    print(f"\n{report.get('conclusion', '')}")
    print("="*60)
    
    action = input("\nComo Advogado/Responsável, o que deseja fazer?\n  [1] Confirmar e Aprovar (Muda para CONFIRMADO)\n  [2] Manter Pendente\nEscolha: ").strip()
    
    if action == '1':
        case_path = Path(f"synthetic_cases/{selected_case['case_id']}/case.json")
        data = json.loads(case_path.read_text())
        data['information_state'] = 'CONFIRMADO'
        case_path.write_text(json.dumps(data, indent=2, ensure_ascii=False))
        
        log_entry = f"{datetime.now().isoformat()} | USER: Advogado | ACTION: APPROVE | CASE: {selected_case['case_id']}\n"
        log_dir = Path("governance/audit_logs")
        log_dir.mkdir(parents=True, exist_ok=True)
        with open(log_dir / "approvals.log", "a") as f:
            f.write(log_entry)
            
        print("\n✅ Caso confirmado com sucesso! Log de auditoria gerado.")
    else:
        print("\n⏸️  Caso mantido em PENDENTE_VALIDACAO.")

if __name__ == "__main__":
    main()
