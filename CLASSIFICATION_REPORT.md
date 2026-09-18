# Báo cáo Phân loại Tập dữ liệu Mã nguồn Legacy (Chronos AI Dataset)

Báo cáo này tổng hợp kết quả phân loại các file mã nguồn legacy trong dự án theo đúng bảng tiêu chuẩn đường dẫn và đặc điểm lưu trữ.

## Bảng Tổng hợp Phân loại
| Tiêu chí | Đường dẫn thư mục | Đặc điểm mã nguồn lưu trữ | Số lượng file |
| :--- | :--- | :--- | :--- |
| **Domain Nghiệp vụ** | [`/domain/banking_core/`](file:///c:/Phong/chronos-ai/domain/banking_core) | Mã C/COBOL tính toán lãi suất, hạn mức tín dụng, sổ cái tài chính. | 174 |
| **Domain Nghiệp vụ** | [`/domain/legacy_crypto/`](file:///c:/Phong/chronos-ai/domain/legacy_crypto) | Các module băm dữ liệu cổ SHA-1, MD5, mã hóa RSA-1024 / DES. | 61 |
| **Domain Nghiệp vụ** | [`/domain/math_matrix/`](file:///c:/Phong/chronos-ai/domain/math_matrix) | Thuật toán ma trận, đại số tuyến tính, tính toán tài chính định lượng. | 45 |
| **Đặc tính Kỹ thuật** | [`/tech/struct_alignment/`](file:///c:/Phong/chronos-ai/tech/struct_alignment) | Code chứa C-struct căn chỉnh bộ nhớ 24-bytes thủ công. | 9 |
| **Đặc tính Kỹ thuật** | [`/tech/spaghetti_logic/`](file:///c:/Phong/chronos-ai/tech/spaghetti_logic) | Code rẽ nhánh phức tạp, vòng lặp lồng nhau, switch-case không break. | 9 |
| **Đặc tính Kỹ thuật** | [`/tech/memory_unsafe/`](file:///c:/Phong/chronos-ai/tech/memory_unsafe) | Code dùng con trỏ thô, cấp phát bộ nhớ động `malloc`/`free`. | 10 |

**Tổng số file đã được lập danh mục và phân loại:** 308 files.

## Cấu trúc Cây thư mục
```
chronos-ai/
├── domain/
│   ├── banking_core/          # 174 files (COBOL core banking + C interest/amortization)
│   ├── legacy_crypto/         # 61 files (SHA-1, MD5, RSA-1024, DES)
│   └── math_matrix/           # 45 files (BLAS matrix multiply, LAPACK decomposition, C matrix)
└── tech/
    ├── struct_alignment/      # 9 files (24-byte struct alignment, bitfields, manual padding)
    ├── spaghetti_logic/       # 9 files (3000+ gotos, 89 switch fallthroughs, COBOL GO TOs)
    └── memory_unsafe/         # 10 files (malloc/realloc/free, raw pointer arithmetic)
```