# Đặc tính Kỹ thuật: Spaghetti Control Flow

**Đường dẫn thư mục**: `/tech/spaghetti_logic/`

## Tiêu chuẩn mã nguồn (Theo yêu cầu)
> Code rẽ nhánh phức tạp, vòng lặp lồng nhau, switch-case không break.

### Chi tiết tiêu chí
Mã nguồn có độ phức tạp chu trình cao (Cyclomatic Complexity), rẽ nhánh phức tạp, vòng lặp lồng sâu, switch-case fallthrough không có break, hoặc lạm dụng lệnh nhảy goto / GO TO.

## Thống kê
- **Tổng số file phân loại**: 9 files

## Danh sách file mẫu tiêu biểu
| Tên File | Phân loại / Đặc điểm | Kích thước (bytes) |
| :--- | :--- | :--- |
| `cmark_scanners.c` | Complex state machine: 3,069 goto jumps, 50 switch fallthroughs | 194,218 |
| `gumbo_tokenizer.c` | Dense tokenizer: 89 switch-case fallthroughs without break | 119,807 |
| `cmark_node.c` | Nested control flow: 20 switch fallthroughs | 17,859 |
| `openssl_tasn_dec.c` | ASN.1 decoder engine: 47 gotos, 10 switch fallthroughs | 41,119 |
| `openssl_bn_mul.c` | Multiprecision multiplication: 19 gotos, deeply nested loops | 34,607 |
| `MERCHANT.cob` | COBOL spaghetti: 40 GO TO statements | 23,109 |
| `PAYROLL.cob` | COBOL spaghetti: 28 GO TO statements, nested PERFORM | 25,927 |
| `DISPUTE.cob` | COBOL spaghetti: 19 GO TO statements, 33 PERFORM loops | 25,336 |
| `BATCHPROC.CBL` | COBOL batch processor: 19 GO TO statements, complex branching | 21,020 |
