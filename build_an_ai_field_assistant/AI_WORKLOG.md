# AI_WORKLOG.md — Nhật ký Làm việc & Phát triển Dự án cùng AI

## 1. Thông tin Tổng quan Dự án
- **Tên dự án**: Field AI Assistant (Trợ lý Giám sát Hiện trường AI)
- **Mục tiêu**: Xây dựng ứng dụng di động & web cho kỹ sư / cán bộ giám sát tại công trường, nhà máy, xí nghiệp; cho phép ghi âm mô tả sự cố bằng giọng nói, sử dụng **Gemini AI** trích xuất tự động thành phiếu biên bản kiểm tra chuẩn hóa JSON, lưu trữ dữ liệu ngoại tuyến (Offline-first) và tự động đồng bộ khi có kết nối mạng.
- **Nền tảng mục tiêu**: Flutter (Android, iOS, Web Demo cho Vercel/Firebase, Desktop).
- **Kiến trúc ứng dụng**: Clean Architecture (Domain, Data, Presentation) kết hợp State Management phản ứng nhanh (`ChangeNotifier` / `ListenableBuilder`).

---

## 2. Cấu trúc Thư mục Dự án Đã Thiết lập
```
field_ai_assistant/
├── android/                                    # Cấu hình Android native (Permissions: RECORD_AUDIO, INTERNET)
├── web/                                        # Cấu hình Web demo & vercel.json deploy SPA
├── assets/
│   ├── icons/                                  # Thư mục icon ứng dụng
│   └── prompts/
│       └── system_extraction_prompt.txt        # File prompt trích xuất JSON cho Gemini AI
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
│               ├── controllers/                    # State management
│               │   └── inspection_controller.dart
│               ├── views/
│               │   ├── voice_capture_screen.dart   # Màn hình ghi âm chính & chọn kịch bản mẫu
│               │   ├── ticket_review_screen.dart   # Màn hình review form AI tự điền
│               │   └── ticket_history_screen.dart  # Danh sách phiếu (Đã gửi / Chờ sync)
│               └── widgets/
│                   ├── wave_record_button.dart     # Nút thu âm có hiệu ứng sóng âm
│                   ├── priority_badge_chip.dart    # Chip hiển thị & chọn độ ưu tiên
│                   └── swipe_to_submit_btn.dart    # Nút vuốt để gửi phiếu (chống bấm nhầm)
│
├── AI_WORKLOG.md                               # Nhật ký làm việc với AI
├── README.md                                   # Tài liệu hướng dẫn dự án
└── pubspec.yaml                                # Cấu hình dependencies & assets
```

---

## 3. Các Bước Thực hiện Chi tiết cùng AI

### Bước 1: Khảo sát & Quản lý Dependencies (`pubspec.yaml`)
- Tích hợp các thư viện chuyên dụng, tương thích cao với Flutter 3.47 / Dart 3.13:
  - `record: ^7.1.1`: Thu âm giọng nói native đa nền tảng, trích xuất biên độ âm thanh thời gian thực.
  - `connectivity_plus: ^7.3.1`: Giám sát mạng Internet đa luồng.
  - `sqflite: ^2.4.4` & `shared_preferences: ^2.5.5`: Hệ thống lưu trữ kép (SQLite cho thiết bị di động, SharedPreferences dự phòng cho Web).
  - `http: ^1.6.0`, `uuid: ^4.6.0`, `intl: ^0.20.3`, `google_fonts: ^8.2.1`.
- Cấu hình assets trong `pubspec.yaml` trỏ tới `assets/icons/` và `assets/prompts/`.

### Bước 2: Cấu hình Quyền Native & Web Demo
- **Android (`AndroidManifest.xml`)**:
  - `android.permission.RECORD_AUDIO`: Thu âm qua microphone.
  - `android.permission.INTERNET`: Gọi API Gemini và đồng bộ máy chủ.
  - `android.permission.ACCESS_NETWORK_STATE`: Giám sát kết nối mạng.
  - `android.permission.MODIFY_AUDIO_SETTINGS`.
  - Khai báo `<uses-feature android:name="android.hardware.microphone" android:required="false" />`.
- **Web Demo**:
  - Bổ sung `web/vercel.json` phục vụ Single Page Application (SPA rewrite routing).
  - Tối ưu `web/index.html` với viewport di động, theme color `#0F172A`, thẻ meta PWA.

### Bước 3: Kỹ nghệ Prompt Trích xuất JSON (`system_extraction_prompt.txt`)
- Soạn thảo prompt chi tiết cho Gemini Flash:
  - Yêu cầu định dạng JSON đơn nhất, cấu trúc chặt chẽ (`title`, `description`, `location`, `category`, `priority`, `suggested_action`, `inspector_name`, `confidence_score`).
  - Phân loại 6 danh mục: `electrical`, `mechanical`, `civil`, `safety`, `hvac`, `general`.
  - Chuẩn hóa 4 cấp độ ưu tiên: `low`, `medium`, `high`, `critical`.
  - Kèm các tình huống thực tế (Few-shot Examples) bằng tiếng Việt chuyên ngành cơ điện / nhà xưởng cán thép / tủ điện chập cháy.

### Bước 4: Xây dựng Lớp Core (Nền tảng & Hạ tầng)
- `AppColors`: Bảng màu Industrial Dark Mode sang trọng, độ tương phản cao cho môi trường hiện trường ngoài trời.
- `ApiClient`: Wrapper HTTP Client có timeout, chuẩn hóa mã lỗi, xử lý phản hồi từ Google Gemini.
- `AudioRecorderService`: Quản lý lifecycle thu âm, stream biên độ âm thanh (`amplitudeStream`) phục vụ hiệu ứng sóng động.
- `ConnectivityService`: Theo dõi kết nối mạng và kích hoạt sự kiện tự động đồng bộ khi có kết nối trở lại.

### Bước 5: Xây dựng Lớp Domain & Data (Clean Architecture)
- `InspectionTicket`: Thực thể thuần túy của nghiệp vụ.
- `InspectionTicketModel`: Xử lý chuyển đổi linh hoạt (`fromJson`, `toJson`, `fromAiExtraction`, `toMap`, `fromMap`).
- `InspectionRemoteDataSource`: Gọi trực tiếp Gemini API; đặc biệt **tích hợp bộ lọc Heuristic NLP thông minh dự phòng** giúp ứng dụng hoạt động mượt mà ngay cả khi chưa có API Key hoặc mất mạng.
- `InspectionLocalDataSource`: Quản lý SQLite Database bảng `inspection_tickets`, có cơ chế fallback sang SharedPreferences trên môi trường Web.
- `InspectionRepositoryImpl`: Điều phối thông minh giữa Online & Offline:
  - Khi online: Đẩy phiếu lên máy chủ, đánh dấu `synced`.
  - Khi offline: Lưu trữ an toàn cục bộ, đánh dấu `pending_sync`.
  - Khi mạng phục hồi: Tự động quét các phiếu đang chờ và đồng bộ nền.

### Bước 6: Xây dựng Giao diện & Trải nghiệm Người dùng (Presentation)
- `InspectionController`: Quản lý toàn bộ luồng trạng thái từ ghi âm, phân tích AI, chỉnh sửa phiếu, lọc danh sách đến đồng bộ.
- `WaveRecordButton`: Nút bấm ghi âm có hiệu ứng sóng xung kích lan tỏa theo nhịp biên độ giọng nói.
- `PriorityBadgeChip`: Hiển thị huy hiệu mức độ ưu tiên theo màu chuẩn và cho phép chọn trực quan.
- `SwipeToSubmitButton`: Nút trượt xác nhận lấy cảm hứng từ các thiết bị công nghiệp, chống thao tác vô tình chạm phải khi kỹ sư đeo găng tay.
- `VoiceCaptureScreen`: Màn hình ghi âm chính với thanh trạng thái mạng, cấu hình API Key, kịch bản mẫu thử nghiệm tức thì.
- `TicketReviewScreen`: Form duyệt và chỉnh sửa thông tin do AI tự động điền.
- `TicketHistoryScreen`: Quản lý danh sách phiếu với các tab lọc (Tất cả, Chờ đồng bộ, Đã sync) và nút đồng bộ một chạm.

---

## 4. Kết quả Kiểm thử & Chất lượng Mã nguồn
- Kiểm tra cú pháp và quy chuẩn Flutter Lints:
  ```bash
  flutter analyze
  # Kết quả: No issues found!
  ```
- Kiểm thử đơn vị (Unit Test) thành công:
  ```bash
  flutter test
  # Kết quả: All tests passed!
  ```

---

## 5. Hướng dẫn Phát triển & Mở rộng Tương lai
1. **Camera Inspection**: Bổ sung tính năng chụp ảnh hiện trường và gửi ảnh kèm âm thanh vào mô hình Multimodal của Gemini để tăng độ chính xác vị trí lỗi.
2. **Offline Speech-to-Text**: Tích hợp mô hình Whisper tflite cục bộ trên thiết bị cho các khu vực hoàn toàn không có sóng di động.
3. **Background Sync Worker**: Tích hợp WorkManager trên Android để tự động đồng bộ dữ liệu ngay cả khi ứng dụng đã đóng.
