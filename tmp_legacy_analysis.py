from pathlib import Path
from analyzer.features import extract_file_features

root = Path(r'c:/Phong/chronos-ai')
dirs = ['domain/banking_core','domain/legacy_crypto','domain/math_matrix','tech/struct_alignment','tech/spaghetti_logic','tech/memory_unsafe']
metrics = ['code_lines','logical_loc','cyclomatic_complexity','function_count','avg_function_loc','raw_pointer_count','dynamic_allocation_count','precision_loss_count','estimated_padding_bytes','legacy_crypto_count','static_array_count','matrix_pattern_count','bitwise_operation_count','goto_count','malloc_count','free_count']

for d in dirs:
    files = []
    for p in (root / d).rglob('*'):
        if p.is_file() and p.suffix.lower() in {'.c','.h','.cpp','.hpp','.cob','.cbl','.cpy','.f','.f90','.for'}:
            files.append(p)
    rows = []
    for p in files:
        try:
            rec = extract_file_features(p)
            feat = rec['features']
            rows.append({m: feat.get(m, 0) for m in metrics})
        except Exception:
            pass
    if not rows:
        print(d, 'NO_FILES')
        continue
    print(f'\n## {d} count={len(rows)}')
    for m in metrics:
        vals = [r[m] for r in rows]
        avg = sum(vals)/len(vals)
        mx = max(vals)
        print(f'{m}: avg={avg:.1f} max={mx}')
