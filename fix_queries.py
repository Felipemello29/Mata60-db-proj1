import re
import os

files = [
    r"C:\Users\ffeli\OneDrive\Área de Trabalho\banco de dados\schema\advanced_queries.sql",
    r"C:\Users\ffeli\OneDrive\Área de Trabalho\banco de dados\schema\intermediate_queries.sql",
    r"C:\Users\ffeli\OneDrive\Área de Trabalho\banco de dados\delivery\final_script.sql"
]

def fix_aliases(text):
    # Fix aliases explicitly matching `as lower_case` or `AS lower_case`
    def replacer(match):
        return f"AS {match.group(1).upper()}"
    return re.sub(r"(?i)\bas\s+([a-z_]+)\b", replacer, text)

# Fix Q7 specifically
q7_old = """SELECT proj.DS_NOME_PROJETO, COUNT(DISTINCT a.ID_ATIVIDADE) as total_atividades
FROM TB_PROJETO_EXTENSAO proj
JOIN TB_ATIVIDADE a ON proj.ID_PROJETO = a.ID_PROJ_VINCULADO
JOIN RL_ALOCACAO_INSTRUTOR alloc ON a.ID_ATIVIDADE = alloc.ID_ATIVIDADE
WHERE alloc.ID_INSTRUTOR = proj.ID_INSTR_COORDENADOR
AND proj.ID_PROJETO IN (
    SELECT ID_PROJ_VINCULADO
    FROM TB_ATIVIDADE
    GROUP BY ID_PROJ_VINCULADO
    HAVING COUNT(*) > 5
)
GROUP BY proj.DS_NOME_PROJETO;"""

q7_new = """SELECT proj.DS_NOME_PROJETO, (SELECT COUNT(*) FROM TB_ATIVIDADE WHERE ID_PROJ_VINCULADO = proj.ID_PROJETO) AS TOTAL_ATIVIDADES
FROM TB_PROJETO_EXTENSAO proj
WHERE EXISTS (
    SELECT 1 FROM TB_ATIVIDADE a
    JOIN RL_ALOCACAO_INSTRUTOR alloc ON a.ID_ATIVIDADE = alloc.ID_ATIVIDADE
    WHERE a.ID_PROJ_VINCULADO = proj.ID_PROJETO
    AND alloc.ID_INSTRUTOR = proj.ID_INSTR_COORDENADOR
)
AND proj.ID_PROJETO IN (
    SELECT ID_PROJ_VINCULADO
    FROM TB_ATIVIDADE
    GROUP BY ID_PROJ_VINCULADO
    HAVING COUNT(*) > 5
);"""

for file in files:
    if os.path.exists(file):
        with open(file, "r", encoding="utf-8") as f:
            content = f.read()
        
        if "COUNT(DISTINCT a.ID_ATIVIDADE) as total_atividades" in content:
            content = content.replace(q7_old, q7_new)
        
        content = fix_aliases(content)
        
        with open(file, "w", encoding="utf-8") as f:
            f.write(content)
        print(f"Fixed {file}")
