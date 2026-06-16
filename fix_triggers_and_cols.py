import re

files = [
    r"C:\Users\ffeli\OneDrive\Área de Trabalho\banco de dados\schema\audit_triggers.sql",
    r"C:\Users\ffeli\OneDrive\Área de Trabalho\banco de dados\delivery\final_script.sql"
]

def fix_triggers(text):
    # Regex to find:
    # CREATE TRIGGER TG_A_IUD_(\w+)
    # AFTER INSERT OR UPDATE OR DELETE ON (\w+)
    # FOR EACH ROW EXECUTE FUNCTION (\w+)\(\);
    
    pattern = re.compile(
        r"CREATE TRIGGER TG_A_IUD_(\w+)\s+"
        r"AFTER INSERT OR UPDATE OR DELETE ON (\w+)\s+"
        r"FOR EACH ROW EXECUTE FUNCTION (\w+)\(\);"
    )
    
    def replacer(match):
        trigger_name_base = match.group(1)
        table_name = match.group(2)
        function_name = match.group(3)
        
        replacement = (
            f"CREATE TRIGGER TG_A_I_{trigger_name_base}\n"
            f"AFTER INSERT ON {table_name}\n"
            f"FOR EACH ROW EXECUTE FUNCTION {function_name}();\n\n"
            f"CREATE TRIGGER TG_A_U_{trigger_name_base}\n"
            f"AFTER UPDATE ON {table_name}\n"
            f"FOR EACH ROW EXECUTE FUNCTION {function_name}();\n\n"
            f"CREATE TRIGGER TG_A_D_{trigger_name_base}\n"
            f"AFTER DELETE ON {table_name}\n"
            f"FOR EACH ROW EXECUTE FUNCTION {function_name}();"
        )
        return replacement
    
    return pattern.sub(replacer, text)

for file in files:
    try:
        with open(file, "r", encoding="utf-8") as f:
            content = f.read()
            
        # Replace DH_OPERACAO to DT_OPERACAO in table definitions
        content = content.replace("DH_OPERACAO TIMESTAMP", "DT_OPERACAO TIMESTAMP")
        
        # Also replace TP_OPERACAO just in case we need it? No, just DH_OPERACAO
        
        content = fix_triggers(content)
        
        with open(file, "w", encoding="utf-8") as f:
            f.write(content)
            
        print(f"Fixed {file}")
    except Exception as e:
        print(f"Error processing {file}: {e}")

