# demo/ - Before/After measurement cho IBM Bob 2.0 Hackathon

Bo script do luong doc lap voi pipeline chinh (`main.py`). Khong sua gi trong `analyzer/`;
chi tai su dung `analyzer.scanner` + `analyzer.features`.

## Pipeline (chay trong window)

```bash
# BEFORE da do san (7 gold sample goc, chua modernize) -> demo/before.json, demo/before.md

# 1. Bob modernize demo/samples/before/ -> demo/samples/after/

# 2. Do AFTER
python demo/measure.py --input demo/samples/after --label after --sources-only \
    --output demo/after.json --markdown demo/after.md

# 3. So sanh + xuat bieu do centerpiece
python demo/compare.py --before demo/before.json --after demo/after.json \
    --output demo/comparison.json --markdown demo/comparison.md \
    --chart demo/comparison.png
```

## Checklist - kiem tra TRUOC MOI LAN do before/after

- [ ] **`HAVE_PTHREADS` KHONG duoc define** khi compile ban "before" hay "after" cua bat ky
      file mau nao. Macro nay khong thuoc build system duoc mine ve; neu before/after define
      no khac nhau, hai ben se compile ra hai nhanh code khac nhau (`clib-settings.h`) va so
      sanh se sai lech ma khong bao loi. (chi tiet: `compile_check.md`)
- [ ] **`measure.py` phai chay voi `--sources-only`** cho CA before lan after. Thieu co nay,
      header (`commondefs.h`, `khmm.h`, ...) bi tinh la file nguon, doi so file do tu 7 len 16
      va lam sai lech moi con so tong hop.
- [ ] **Sau khi chay `compare.py`, kiem tra cot `matched_by`** trong `comparison.json`. File
      duoc ghep theo 3 muc uu tien: duong dan day du -> duong dan bo duoi (`.c` -> `.cpp`) ->
      ten file tran (chi khi ten do la duy nhat trong ca cay). Muc thu 3 tien loi khi Bob doi
      ten/doi duoi file, nhung neu 2 file khac thu muc trung ten thi co the ghep nham am tham -
      luon doi chieu bang ghep truoc khi tin so lieu.
- [ ] **`clib-package.c` va `clib-configure.c` KHONG tu chua.** Hai file nay can nguyen cay
      `chronos-legacy-dataset/c_financial_math/clib/` (`src/`, `src/common/`, `deps/`) kem cac
      co `-I` tuong ung - khong chi thu muc phang `demo/samples/before/`. Dua nguyen thu muc
      `clib/` cho Bob thay vi tach file roi. (chuoi header day du: `compile_check.md`)

## Tai lieu tham khao

| File | Vai tro |
| --- | --- |
| `gold_samples.json` | 7 file C duoc chon tu `tech/memory_unsafe`, kem risk score + ly do chon |
| `compile_check.md` | Ket qua build tren Windows + Linux, chuoi header day du, ly do nhom `clib-*` can nguyen thu muc |
| `measure.py` | Do metrics cho bat ky thu muc C/C++ nao -> JSON + Markdown |
| `compare.py` | 2 file JSON -> bang % giam + `comparison.png` |
| `before.json` / `before.md` | Ket qua do baseline |

**Risk formula phai giu nguyen giua before/after** (`RISK_FORMULA_VERSION` trong
`measure.py`); `compare.py` tu canh bao neu hai lan do dung version khac nhau.

