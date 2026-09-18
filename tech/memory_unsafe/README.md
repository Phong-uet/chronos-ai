# Đặc tính Kỹ thuật: Memory Unsafe & Raw Pointers

**Đường dẫn thư mục**: `/tech/memory_unsafe/`

## Tiêu chuẩn mã nguồn (Theo yêu cầu)
> Code dùng con trỏ thô, cấp phát bộ nhớ động `malloc`/`free`.

### Chi tiết tiêu chí
Mã nguồn sử dụng nhiều con trỏ thô (raw pointers), số học con trỏ (pointer arithmetic), và cấp phát/thu hồi bộ nhớ thủ công qua malloc, calloc, realloc, free.

## Thống kê
- **Tổng số file phân loại**: 10 files

## Danh sách file mẫu tiêu biểu
| Tên File | Phân loại / Đặc điểm | Kích thước (bytes) |
| :--- | :--- | :--- |
| `stb.h` | 112 malloc/realloc calls, 102 free calls, manual block allocators | 430,675 |
| `stb_image.h` | 11 malloc, 14 free calls, raw pointer buffer walking | 290,998 |
| `sds.c` | Raw pointer tricks (s[-1] header offset), malloc/realloc/free | 43,279 |
| `clib-package.c` | Dynamic struct management: 10 mallocs, 53 frees, raw pointers | 41,099 |
| `clib-configure.c` | 5 mallocs, 21 frees with manual memory lifecycle | 16,839 |
| `khmm.c` | 2D dynamic matrix allocation (double **), 12 mallocs, 43 frees | 11,248 |
| `kopen.c` | Low-level buffer allocation: 12 mallocs, 11 frees | 9,494 |
| `skpf10.c` | Raw pointer interface array allocation: 14 mallocs, 18 frees | 8,817 |
| `skpfa.c` | Raw pointer interface array allocation: 14 mallocs, 18 frees | 8,540 |
| `sktrd.c` | Raw pointer matrix transforms: 12 mallocs, 12 frees | 12,293 |
