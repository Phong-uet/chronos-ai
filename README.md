# Chronos AI

Dự án phân tích và gom cụm mã nguồn legacy C/C++ để phát hiện mẫu, rủi ro và chọn gold samples cho benchmark.

## Tính năng

- Quét mã nguồn C/C++ trong thư mục đầu vào
- Trích xuất đặc trưng code và độ phức tạp
- Phân cụm dựa trên feature vector
- Đánh giá rủi ro và cảnh báo lỗi nguy hiểm
- Chọn các mẫu gold tiêu biểu cho đánh giá
- Xuất báo cáo và file JSON/CSV

## Cài đặt

```bash
pip install -r requirements.txt
```

## Chạy nhanh

```bash
python main.py --input ./source-code --output ./output --gold-dir ./chronos-gold-samples
```

## Thư mục đầu ra

- `output/`: báo cáo, features, clustering data
- `chronos-gold-samples/`: các file gold mẫu được chọn

## Ghi chú

Dự án phù hợp để phân tích code legacy, tìm mẫu lập trình và chuẩn bị dataset benchmark cho các nhiệm vụ đánh giá hoặc so sánh.
