# Báo cáo Phân loại Tập dữ liệu Mã nguồn Legacy (Chronos AI Dataset)

Báo cáo này tổng hợp việc phân loại mã nguồn legacy theo bộ tiêu chí mới được định nghĩa trong script phân loại: phân theo domain nghiệp vụ và đặc tính kỹ thuật. Số liệu dưới đây được đồng bộ với trạng thái hiện tại của workspace.

## Bộ tiêu chí phân loại mới

- Domain nghiệp vụ:
  - `/domain/banking_core/`
  - `/domain/legacy_crypto/`
  - `/domain/math_matrix/`
- Đặc tính kỹ thuật:
  - `/tech/struct_alignment/`
  - `/tech/spaghetti_logic/`
  - `/tech/memory_unsafe/`

## Bảng tổng hợp phân loại

| Tiêu chí              | Đường dẫn thư mục                                  | Đặc điểm mã nguồn lưu trữ                                                                    | Số lượng file |
| :-------------------- | :------------------------------------------------- | :------------------------------------------------------------------------------------------- | :------------ |
| **Domain Nghiệp vụ**  | [`/domain/banking_core/`](domain/banking_core)     | Mã C/COBOL về giao dịch ngân hàng, sổ cái, tính toán lãi suất, khấu hao, báo cáo tín dụng.   | 175           |
| **Domain Nghiệp vụ**  | [`/domain/legacy_crypto/`](domain/legacy_crypto)   | Thuật toán mật mã cổ điển: SHA-1, MD5, DES, RSA-1024 và các tiện ích liên quan.              | 114           |
| **Domain Nghiệp vụ**  | [`/domain/math_matrix/`](domain/math_matrix)       | BLAS/LAPACK, ma trận tuyến tính, thuật toán định lượng và tích hợp C/Fortran.                | 36            |
| **Đặc tính Kỹ thuật** | [`/tech/struct_alignment/`](tech/struct_alignment) | Cấu trúc C có căn chỉnh bộ nhớ thủ công, padding, bitfield và “24-byte alignment” tùy biến.  | 19            |
| **Đặc tính Kỹ thuật** | [`/tech/spaghetti_logic/`](tech/spaghetti_logic)   | Chuỗi điều khiển rối, nhánh lồng, fallthrough switch, goto/GO TO và vòng lặp phức tạp.       | 10            |
| **Đặc tính Kỹ thuật** | [`/tech/memory_unsafe/`](tech/memory_unsafe)       | Con trỏ thô, arithmetic pointer, cấp phát/giải phóng bộ nhớ bằng malloc/calloc/realloc/free. | 11            |

**Tổng số file đã được lập danh mục và phân loại:** 365 files.

## Cấu trúc cây thư mục

```text
chronos-ai/
├── domain/
│   ├── banking_core/          # 175 files (COBOL core banking + C financial logic)
│   ├── legacy_crypto/         # 114 files (SHA-1, MD5, DES, RSA và mã hóa cổ)
│   └── math_matrix/           # 36 files (BLAS/LAPACK + C quantitative math)
├── tech/
│   ├── struct_alignment/      # 19 files (manual memory alignment, padding, bitfields)
│   ├── spaghetti_logic/       # 10 files (nested branches, goto/fallthrough logic)
│   └── memory_unsafe/         # 11 files (raw pointers and manual memory management)
└── chronos-legacy-dataset/    # raw source collection used for classification
```

## Phân tích thực tế theo từng nhóm đặc điểm

Dựa trên số liệu thu thập từ các file mã legacy trong từng thư mục, các nhóm chỉ số mới cho thấy rõ xu hướng rủi ro và đặc tính kỹ thuật của từng nhóm dữ liệu.

### A. Phân tích theo Nhóm Chỉ Số Định Lượng (Quantitative Metrics)

- `tech/spaghetti_logic` là nhóm có mức độ phức tạp cao nhất: trung bình `cyclomatic_complexity = 806.2`, `goto_count = 348.4`, `avg_function_loc = 70.4`. Điều này cho thấy logic điều khiển rối, nhiều nhánh lồng và khó kiểm soát hơn hẳn so với các nhóm khác.
- `tech/struct_alignment` và `tech/memory_unsafe` có khối lượng mã lớn và hàm nhiều: `code_lines` trung bình lần lượt là `2201.2` và `1988.4`, `function_count` là `103.8` và `93.7`. Đây là dấu hiệu của code thuộc dạng low-level, cấu trúc phức tạp và khó bảo trì.
- `domain/math_matrix` có lượng mã lớn và chỉ số tính toán cao: `code_lines = 498.5`, `matrix_pattern_count = 0.9` trung bình, nhưng không có dấu hiệu crypto mạnh. Đây là nhóm mã chủ yếu phục vụ thuật toán số và đại số tuyến tính.
- `domain/legacy_crypto` có mức độ phức tạp vừa phải nhưng tập trung vào các thuật toán mật mã cổ: `legacy_crypto_count = 6.5` trung bình, `bitwise_operation_count = 20.2`. Đây là nhóm có tính chất chuyên biệt và tương đối dễ nhận diện bằng mẫu hàm mã hóa cổ.
- `domain/banking_core` có cấu trúc chủ yếu là nghiệp vụ, nên `logical_loc` thấp và `cyclomatic_complexity` thấp hơn nhiều so với nhóm kỹ thuật. Đây là nhóm code có tính “logic nghiệp vụ” hơn là “logic rối/tái cấu trúc”.

Kết luận: nhóm `tech/spaghetti_logic` và `tech/memory_unsafe` là hai nhóm có mức độ legacy khó duy trì nhất theo tiêu chí định lượng, trong khi `domain/legacy_crypto` và `domain/math_matrix` dễ nhận diện theo mục tiêu nghề nghiệp và thuật toán cụ thể.

### B. Phân tích theo Nhóm Chỉ Số An Toàn Bộ Nhớ & Con Trỏ (Memory Safety & Pointers)

- `tech/memory_unsafe` là nhóm nguy hiểm nhất về bộ nhớ: `raw_pointer_count = 809.0`, `dynamic_allocation_count = 15.4`, `malloc_count = 12.3`, `free_count = 24.0`. Đây là dấu hiệu rõ ràng của code phụ thuộc mạnh vào con trỏ thô và quản lý bộ nhớ thủ công.
- `tech/struct_alignment` cũng có nguy cơ cao tương tự: `raw_pointer_count = 874.1`, `estimated_padding_bytes = 14.6`, `dynamic_allocation_count = 11.7`. Một phần lý do là cấu trúc dữ liệu được khai báo với padding và căn chỉnh bộ nhớ thủ công, rất dễ dẫn đến lỗi tương thích nền tảng.
- `domain/math_matrix` có mức độ dùng con trỏ và cấp phát động trung bình thấp hơn, nhưng vẫn xuất hiện: `raw_pointer_count = 147.0`, `malloc_count = 1.5`. Đây là nhóm code số học mạnh nhưng ít nguy cơ leak hơn nhóm tech.
- `domain/legacy_crypto` có `raw_pointer_count = 46.9` và `dynamic_allocation_count = 0.0`, cho thấy phần lớn code crypto cổ là logic xử lý thuật toán hơn là thao tác bộ nhớ phức tạp.

Kết luận: rủi ro bộ nhớ tập trung chủ yếu ở `tech/memory_unsafe` và `tech/struct_alignment`; đây là hai nhóm cần được ưu tiên kiểm tra bảo mật và độ an toàn khi bảo trì hoặc chuyển đổi sang nền tảng mới.

### C. Phân tích theo Nhóm Chỉ Số Thuật Toán & An Ninh Mật Mã (Cryptography & Algorithms)

- `domain/legacy_crypto` là nhóm rõ ràng nhất về mặt thuật toán mật mã cổ: `legacy_crypto_count = 6.5` trung bình, tối đa `52`; trong đó có các hàm như SHA1_Init, MD5_Update, RSA_generate_key được phát hiện. Đây là địa điểm quan trọng nhất cho phân tích legacy crypto risk.
- `domain/math_matrix` mang đặc tính thuật toán số tuyến tính rõ rệt: `matrix_pattern_count = 0.9` trung bình, có nhiều trường hợp các cấu trúc ma trận và tensor xuất hiện trong các routine BLAS/LAPACK. Đây không phải nhóm crypto, mà là nhóm toán học số.
- `domain/banking_core` có đặc tính nghiệp vụ hơn là thuật toán mật mã; `legacy_crypto_count = 0.0`, `matrix_pattern_count = 0.0`. Nó phù hợp với nhóm logic tài chính hơn là nhóm kỹ thuật số hay mật mã.
- `tech/spaghetti_logic` và `tech/memory_unsafe` có `bitwise_operation_count` khá cao (`7.3` và `91.7`), nhưng không phải vì mục tiêu mật mã mà vì các thao tác dữ liệu thô và xử lý bit-level trong kiến trúc cũ.

Kết luận: nhóm `domain/legacy_crypto` có giá trị cao nhất cho phân loại thuật toán và an ninh mật mã; `domain/math_matrix` là nhóm thuật toán định lượng; còn `tech/*` vẫn là vùng có tính chất low-level và thao tác bit/nhánh nhiều hơn là “mật mã”.

## Kết luận tổng hợp cuối cùng

Ba nhóm chỉ số trên cho thấy rằng code legacy không thể chỉ được phân loại bằng đường dẫn thư mục đơn thuần; cần đánh giá đồng thời:

- Khía cạnh nghiệp vụ và chức năng (domain classification)
- Khía cạnh kỹ thuật và độ nguy hiểm của code (tech classification)
- Khía cạnh số liệu và nguy cơ bảo trì/an ninh (quantitative + memory + algorithm assessment)

Theo dữ liệu thực tế phân tích được:

1. `tech/spaghetti_logic` là nhóm có rủi ro về cấu trúc điều khiển và độ phức tạp cực cao.
2. `tech/memory_unsafe` và `tech/struct_alignment` là nhóm nguy cơ bộ nhớ và căn chỉnh dữ liệu lớn nhất.
3. `domain/legacy_crypto` là nhóm rõ nhất về thuật toán mật mã cổ và rủi ro an ninh.
4. `domain/math_matrix` là nhóm thuật toán số, mạnh về xử lý ma trận và đại số tuyến tính hơn là mật mã.
5. `domain/banking_core` là nguồn dữ liệu chủ yếu thuộc nghiệp vụ ngân hàng, có độ phức tạp thấp hơn nhưng rất quan trọng về logic hệ thống tài chính.

Như vậy, báo cáo đã chuyển từ mô tả phân loại tĩnh sang phân tích legacy hiện trạng theo chỉ số kỹ thuật và rủi ro thực tế của từng nhóm mã nguồn.
