# Đặc tính Kỹ thuật: Struct Alignment & Memory Packing

**Đường dẫn thư mục**: `/tech/struct_alignment/`

## Tiêu chuẩn mã nguồn (Theo yêu cầu)
> Code chứa C-struct căn chỉnh bộ nhớ 24-bytes thủ công.

### Chi tiết tiêu chí
Các cấu trúc dữ liệu C-struct được thiết kế căn chỉnh bộ nhớ thủ công: logic alignment 24-byte struct, struct header 24 bytes (3 con trỏ/kích thước 8 bytes), bitfields n_args:24, padding bytes thủ công.

## Thống kê
- **Tổng số file phân loại**: 9 files

## Danh sách file mẫu tiêu biểu
| Tên File | Phân loại / Đặc điểm | Kích thước (bytes) |
| :--- | :--- | :--- |
| `deprecated_stb.h` | 24-byte struct alignment logic (malloc_base, line 2910) | 430,675 |
| `klib_kexpr.c` | Bitfield packed 24-byte operator struct (n_args:24, ke1_s) | 17,522 |
| `klib_kstring.h` | 24-byte struct header layout (size_t l, m; char *s) | 7,322 |
| `klib_kvec.h` | 24-byte dynamic vector header (size_t n, m; type *a) | 2,970 |
| `des_des_old.h` | Manual struct padding for 8/24-byte alignment (DES_LONG pad[2]) | 21,983 |
| `ec_ec_curve.c` | Manual 24-byte coordinate buffer packing for elliptic curve data | 114,148 |
| `stb_stb_truetype.h` | Manual struct packing & padding (stbtt_pack_context, stbtt_vertex) | 204,271 |
| `prerelease_stb_lib.h` | Manual multiple of 16/24 padding in struct header | 110,088 |
| `caveview_cave_render.c` | Manual cache alignment struct padding (int padding[13]) | 30,470 |
