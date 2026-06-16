import os
import re

def update_arguicao():
    path = r"C:\Users\ffeli\OneDrive\Área de Trabalho\banco de dados\docs\arguicao_oral_qa.md"
    if not os.path.exists(path): return
    with open(path, "r", encoding="utf-8") as f: content = f.read()
    
    if "Questões Adicionais sobre a Validação" not in content:
        content += "\n\n## 5. Questões Adicionais sobre a Validação e Correções (Pós-Revisão Analítica)\n\n"
        content += "**Pergunta 1:** Durante a revisão do script consolidado, foi apontado um erro na coluna DH_OPERACAO das tabelas de auditoria. Qual foi a correção e o motivo?\n"
        content += "**Resposta Esperada:** A coluna `DH_OPERACAO` (Data/Hora) foi renomeada para `DT_OPERACAO`. Apesar de conter um `TIMESTAMP` (que registra hora), o Documento de Arquitetura MAD1 exigia estritamente o uso da sigla `DT_` para essa coluna de auditoria. A adequação visa respeitar as restrições normativas do documento do cliente.\n\n"
        content += "**Pergunta 2:** O relatório mencionou que a nomeação das Triggers (ex: `TG_A_IUD_TB_ATIVIDADE`) estava fora do padrão. Como isso foi resolvido?\n"
        content += "**Resposta Esperada:** O padrão exigia `TG_[A/B]_[I/U/D]_NomeTabela`, ou seja, apenas uma letra para o tipo de operação. O script foi corrigido desmembrando as triggers aglutinadas em três triggers separadas (ex: `TG_A_I_TB_ATIVIDADE`, `TG_A_U_TB_ATIVIDADE` e `TG_A_D_TB_ATIVIDADE`). Isso não só adere ao padrão de forma rigorosa como facilita manutenções futuras isoladas por operação.\n\n"
        content += "**Pergunta 3:** No que diz respeito às chaves estrangeiras (FK), qual foi a falha de nomenclatura corrigida?\n"
        content += "**Resposta Esperada:** A regra definia `FK_TabelaPai_TabelaFilha_Nome`. As constraints estavam usando apenas o nome genérico. Elas foram renomeadas para refletir a semântica completa exigida (ex: `FK_TB_PROJETO_EXTENSAO_TB_ATIVIDADE_PROJ`).\n\n"
        with open(path, "w", encoding="utf-8") as f: f.write(content)

def update_relatorio():
    path = r"C:\Users\ffeli\OneDrive\Área de Trabalho\banco de dados\docs\relatorio_marco2.md"
    if not os.path.exists(path): return
    with open(path, "r", encoding="utf-8") as f: content = f.read()
    content = content.replace("Todas contêm TP_OPERACAO, DH_OPERACAO (timestamp)", "Todas contêm TP_OPERACAO, DT_OPERACAO (timestamp)")
    content = content.replace("capturam os dados via triggers TG_A_IUD_ com AFTER", "capturam os dados via triggers individuais (TG_A_I_, TG_A_U_ e TG_A_D_) com AFTER")
    with open(path, "w", encoding="utf-8") as f: f.write(content)

def update_referencia():
    path = r"C:\Users\ffeli\OneDrive\Área de Trabalho\banco de dados\docs\referencia_banco_dados_marco2.md"
    if not os.path.exists(path): return
    with open(path, "r", encoding="utf-8") as f: content = f.read()
    old_text = "Identifica o gargalo quando as chaves `ID_INSTRUTOR` e `ID_INSTR_COORDENADOR` coincidem por meio de JOIN, tudo associado a uma Subquery de volume de atividades (>5)."
    new_text = "Utiliza uma sub-query no SELECT para contabilizar corretamente o total de atividades do projeto pai, e utiliza EXISTS para certificar que o coordenador de fato ministra aulas nele. Tudo associado a uma Subquery de restrição de volume (>5 atividades no projeto)."
    content = content.replace(old_text, new_text)
    with open(path, "w", encoding="utf-8") as f: f.write(content)

def update_technical_report():
    path = r"C:\Users\ffeli\OneDrive\Área de Trabalho\banco de dados\delivery\technical_report.md"
    if not os.path.exists(path): return
    with open(path, "r", encoding="utf-8") as f: content = f.read()
    content = content.replace("CONSTRAINT FK_ATIVIDADE_PROJETO FOREIGN KEY", "CONSTRAINT FK_TB_PROJETO_EXTENSAO_TB_ATIVIDADE_PROJ FOREIGN KEY")
    content = content.replace("DH_OPERACAO (timestamp)", "DT_OPERACAO (timestamp)")
    content = content.replace("triggers TG_A_IUD_", "triggers TG_A_I_, TG_A_U_ e TG_A_D_")
    with open(path, "w", encoding="utf-8") as f: f.write(content)

update_arguicao()
update_relatorio()
update_referencia()
update_technical_report()
print("Documentation updated successfully.")
