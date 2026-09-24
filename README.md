# 🛠️ Field AI Assistant (Trợ lý Giám sát Hiện trường AI)

> Ứng dụng di động & web hỗ trợ kỹ sư và thanh tra hiện trường tạo biên bản kiểm tra sự cố bằng **giọng nói**, tự động trích xuất thông tin có cấu trúc chuẩn bằng **Gemini AI**, hoạt động bền bỉ trong điều kiện **Offline-First** và tự động đồng bộ khi có kết nối Internet.

---

## 🌟 Tính Năng Nổi Bật

- 🎙️ **Thu âm & Trích xuất Giọng nói Thông minh**:
  - Ghi âm trực tiếp tại hiện trường với hiệu ứng sóng âm thanh tương tác theo thời gian thực (`WaveRecordButton`).
  - Hỗ trợ nhập liệu giọng nói hoặc văn bản ghi chú nhanh.
- 🤖 **Trích xuất JSON Chuẩn bằng Gemini AI**:
  - Tự động điền các trường: Tiêu đề, Vị trí cụ thể, Danh mục sự cố (Điện, Cơ khí, Xây dựng, An toàn, HVAC...), Mức độ ưu tiên (Thấp, Trung bình, Cao, Khẩn cấp), Mô tả hiện trạng và Biện pháp khắc phục đề xuất.
  - Tích hợp bộ giải thuật **Smart NLP Fallback** cho phép trải nghiệm ngay cả khi chưa nhập API Key hoặc khi mất mạng.
- 💾 **Kiến trúc Offline-First Độc lập**:
  - Lưu trữ cơ sở dữ liệu nội bộ SQLite (`sqflite`) trên thiết bị di động, tự động chuyển đổi sang `shared_preferences` trên nền tảng Web.
  - Quản lý trạng thái phiếu: `pending_sync` (Chờ đồng bộ) và `synced` (Đã đồng bộ).
- 🔄 **Tự động Đồng bộ (Auto-Sync)**:
  - Lắng nghe sự kiện kết nối mạng (`ConnectivityService`) và kích hoạt đồng bộ nền ngay khi khôi phục Internet.
- 🛡️ **Giao diện Chuyên dụng cho Hiện trường**:
  - Industrial Dark Mode với độ tương phản cao, tối ưu hiển thị dưới ánh sáng mạnh ngoài trời.
  - **Swipe-To-Submit**: Nút vuốt ngang xác nhận chống chạm nhầm khi công nhân/kỹ sư đeo găng tay bảo hộ.

---

## 🏗️ Cấu Trúc Dự Án (Clean Architecture)

```
field_ai_assistant/
├── android/                                    # Cấu hình Android native (RECORD_AUDIO, INTERNET)
├── web/                                        # Cấu hình Web demo & vercel.json deploy SPA
├── assets/
│   ├── icons/                                  # Icon ứng dụng
│   └── prompts/
│       └── system_extraction_prompt.txt        # Prompt trích xuất JSON cho Gemini AI
├── lib/
│   ├── app.dart                                # Cấu hình MaterialApp, Industrial Dark Theme, Routes
│   ├── main.dart                               # Entry point, khởi tạo native services, Local DB
│   │
│   ├── core/                                   # Thành phần dùng chung toàn hệ thống
│   │   ├── constants/                          # Biến hằng số, API endpoints, App colors
│   │   │   ├── app_colors.dart
│   │   │   ├── api_endpoints.dart
│   │   │   └── app_constants.dart
│   │   ├── errors/                             # Failure & Exception classes
│   │   │   ├── exceptions.dart
│   │   │   └── failures.dart
│   │   ├── network/                            # HTTP client wrapper
│   │   │   └── api_client.dart
│   │   ├── services/                           # Hardware/Native services
│   │   │   ├── audio_recorder_service.dart     # Ghi âm giọng nói & real-time amplitude wave
│   │   │   └── connectivity_service.dart       # Lắng nghe trạng thái Online/Offline
│   │   └── utils/                              # Formatters, debouncer, dialog helpers
│   │       ├── date_formatter.dart
│   │       ├── debouncer.dart
│   │       └── dialog_helper.dart
│   │
│   └── features/
│       └── inspection/                         # Feature cốt lõi: Tiếp nhận & Kiểm tra hiện trường
│           ├── data/
│           │   ├── datasources/
│           │   │   ├── inspection_remote_ds.dart   # Gọi Gemini API + Smart NLP Fallback
│           │   │   └── inspection_local_ds.dart    # Lưu SQFlite / SharedPreferences khi offline
│           │   ├── models/                         # DTO, fromJson, toJson, toMap, fromMap
│           │   │   └── inspection_ticket_model.dart
│           │   └── repositories/
│           │       └── inspection_repository_impl.dart # Điều phối logic Online vs Offline
│           ├── domain/
│           │   ├── entities/                       # Business entity thuần túy
│           │   │   └── inspection_ticket.dart
│           │   └── repositories/                   # Abstract repository interface
│           │       └── i_inspection_repository.dart
│           └── presentation/
│               ├── controllers/                    # State management (ChangeNotifier)
│               │   └── inspection_controller.dart
│               ├── views/
│               │   ├── main_shell_screen.dart      # Navigation Shell: Dashboard, Voice Station, History
│               │   ├── voice_capture_screen.dart   # Màn hình thu âm Equalizer & kịch bản mẫu
│               │   ├── ticket_review_screen.dart   # Màn hình duyệt biên bản & phát lại âm thanh
│               │   └── ticket_history_screen.dart  # Danh sách biên bản (Lọc trạng thái, Sync)
│               └── widgets/
│                   ├── wave_record_button.dart     # Nút thu âm Equalizer 24 thanh âm
│                   ├── priority_badge_chip.dart    # Huy hiệu & chip chọn mức độ ưu tiên
│                   └── swipe_to_submit_btn.dart    # Nút vuốt chống bấm nhầm công nghiệp
│
├── AI_WORKLOG.md                               # Nhật ký chi tiết làm việc với AI
├── README.md                                   # Tài liệu hướng dẫn dự án
└── pubspec.yaml                                # Cấu hình dependencies & assets
```

---

## 🚀 Hướng Dẫn Cài Đặt & Chạy Ứng Dụng

### 1. Yêu cầu Môi trường
- Flutter SDK: `>= 3.13.0` (Đã kiểm thử tối ưu trên Flutter `3.47.5`)
- Dart SDK: `>= 3.13.4`

### 2. Cài đặt Thư viện
```bash
flutter pub get
```

### 3. Chạy Ứng Dụng
- **Chạy trên thiết bị di động (Android / iOS)**:
  ```bash
  flutter run
  ```
- **Chạy trên trình duyệt Web (Chrome)**:
  ```bash
  flutter run -d chrome
  ```
- **Chạy trên macOS**:
  ```bash
  flutter run -d macos
  ```

---

## 🔑 Cấu hình Google Gemini API Key

Bạn có thể cấu hình API Key bằng 2 cách tiện lợi:
1. **Trực tiếp trên giao diện ứng dụng**: Nhấn vào biểu tượng ⚙️ (Cài đặt) ở góc trên bên phải màn hình chính và nhập khóa API Key của bạn (`AIzaSy...`).
2. **Offline/Test Mode**: Ứng dụng tích hợp sẵn cơ chế phân tích thông minh dự phòng, sẵn sàng hoạt động ngay cả khi không có kết nối internet hoặc chưa thiết lập API key.

---

## 📦 Hướng Dẫn Build Triển Khai (Production Build)

### Build Android APK:
```bash
flutter build apk --release
```

### Build Web Demo (Deploy Vercel / Firebase Hosting):
```bash
flutter build web --release
```
*Ghi chú*: Thư mục `web/vercel.json` đã được thiết lập sẵn quy tắc rewrite để hỗ trợ Single Page Application (SPA).

---

## 🧪 Kiểm Thử (Testing)

Chạy kiểm thử chất lượng mã nguồn:
```bash
flutter analyze
flutter test
```
