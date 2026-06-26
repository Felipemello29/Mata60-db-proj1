import re
import subprocess
import sys

def main():
    sys.stdout.reconfigure(encoding='utf-8')
    with open('delivery/final_script.sql', 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Find all SELECT queries. They usually start after a comment like "-- [RF"
    # or we can split the file by "-- [RF"
    blocks = re.split(r'-- \[RF', content)
    queries = []
    
    for i, block in enumerate(blocks[1:]): # skip the first part which is schema
        # The block starts with something like "1] Query 2: ..."
        # Let's extract the title
        title_line = block.split('\n')[0]
        title = f"[RF{title_line}"
        
        # Now find the SELECT statement. It ends with a semicolon.
        # It's a bit tricky to parse SQL with regex, but we can look for SELECT ... ;
        # We can also just find the first SELECT and the first ; after it.
        # But wait, there might be WITH clauses.
        # So we can just find the last SQL statement in this block before the next "-- [RF"
        # Let's clean up comments to easily find the query.
        lines = block.split('\n')[1:]
        query_lines = []
        for line in lines:
            if line.strip().startswith('--'):
                continue
            if line.strip() == '':
                continue
            query_lines.append(line)
        
        query = '\n'.join(query_lines).strip()
        # if the block has multiple statements, we want the last one which is usually the SELECT
        # But wait, the block is just the comments and then the SELECT query.
        if query:
            queries.append((title, query))
            
    # Now run each query
    print(f"Found {len(queries)} queries to test.")
    
    empty_queries = []
    
    for title, query in queries:
        print(f"Testing {title}...")
        # We can run it using docker exec
        # We want to see if it returns rows. We can wrap it in a COUNT(*).
        # Actually, psql -c "query" will print the rows and " (X rows)" at the end.
        
        try:
            result = subprocess.run(
                ['docker', 'exec', 'mata60-db', 'psql', '-U', 'postgres', '-d', 'mata60', '-c', query],
                capture_output=True, text=True, check=True
            )
            output = result.stdout
            
            # Find the " (X rows)" line
            match = re.search(r'\((\d+) row', output)
            if match:
                rows = int(match.group(1))
                if rows == 0:
                    print(f"  -> EMPTY! (0 rows)")
                    empty_queries.append(title)
                else:
                    print(f"  -> {rows} rows returned.")
            else:
                print(f"  -> Could not parse row count. Output snippet: {output[:100]}")
        except subprocess.CalledProcessError as e:
            print(f"  -> ERROR executing query: {e.stderr}")
            
    print("\n--- Summary ---")
    if empty_queries:
        print(f"{len(empty_queries)} queries returned EMPTY results:")
        for eq in empty_queries:
            print(f"  - {eq}")
    else:
        print("All queries returned values!")

if __name__ == "__main__":
    main()
