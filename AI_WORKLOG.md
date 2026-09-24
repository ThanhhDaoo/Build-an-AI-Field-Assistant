# AI_WORKLOG.md — Nhật Ký Làm Việc & Báo Cáo Tiến Độ Dự Án Cùng AI

---

## 1. Thông Tin Tổng Quan Dự Án
- **Tên dự án**: Field AI Assistant (Trợ lý Giám sát & Báo cáo Hiện trường AI)
- **Mục tiêu**: Xây dựng ứng dụng di động & web cho kỹ sư / cán bộ giám sát tại công trường, nhà máy, xí nghiệp; cho phép ghi âm mô tả sự cố bằng giọng nói, sử dụng **Gemini AI Multimodal** trích xuất tự động thành phiếu biên bản kiểm tra chuẩn hóa JSON, lưu trữ dữ liệu ngoại tuyến (Offline-first) và tự động đồng bộ khi có kết nối mạng.
- **Nền tảng mục tiêu**: Flutter (Android, iOS, Web Demo cho Vercel/Firebase, Desktop).
- **Kiến trúc ứng dụng**: Clean Architecture (Domain, Data, Presentation) kết hợp Service Locator (`get_it`), Reactive State Management (`ChangeNotifier` / `flutter_bloc`), và Thiết kế Chuẩn Công Nghiệp (Industrial Dark Theme).

---

## 2. Bảng Theo Dõi Tiến Độ Toàn Bộ Các Giai Đoạn (Project Milestones)

| Giai đoạn | Tên Giai Đoạn & Hạng Mục Cốt Lõi | Trạng Thái | Commit Tham Chiếu |
| :---: | :--- | :---: | :---: |
| **Giai đoạn 1** | **Thiết lập nền tảng, Cấu hình thiết bị & Tái thiết kế UI Middle Mobile** | **ĐÃ HOÀN THÀNH** | `b1f1189` |
| **Giai đoạn 2** | **Xử lý Phần cứng, Audio Pipeline & Bóc băng Giọng nói (Speech-to-Text)** | **ĐÃ HOÀN THÀNH** | `4e55f6e`, `893de9b`, `90520ff` |
| **Giai đoạn 3** | **AI Service & Bóc tách Dữ liệu Hiện trường (Structured Output & Multi-tier Fallback)** | **ĐÃ HOÀN THÀNH** | `0d81571` |
| **Giai đoạn 4** | **Offline-First, Lưu trữ Cục bộ SQLite & Cơ chế Tự động Đồng bộ (Sync Queue)** | *KẾ HOẠCH TIẾP THEO* | `Sắp thực hiện` |
| **Giai đoạn 5** | **Camera Inspection, Multimodal Visual Analysis & Xuất Báo cáo PDF** | *TƯƠNG LAI* | `Dự kiến` |

---

## 3. Chi Tiết Thực Hiện Các Giai Đoạn Đã Hoàn Thành

### [x] Giai Đoạn 1: Thiết Lập Nền Tảng, Cấu Hình Thiết Bị & Giao Diện Hiện Trường
- **1.1. Cấu hình đa nền tảng & dependencies**:
  - Hỗ trợ đồng thời Android và Web (`web/vercel.json`, cấu hình SPA routing).
  - Tích hợp bộ thư viện cốt lõi: `record: ^7.1.1`, `audioplayers: ^6.1.0`, `speech_to_text: ^7.5.0`, `google_generative_ai: ^0.4.6`, `sqflite: ^2.4.4`, `shared_preferences: ^2.5.5`, `connectivity_plus: ^7.3.1`, `get_it: ^8.0.3`, `uuid: ^4.6.0`, `intl: ^0.20.3`, `google_fonts: ^8.2.1`.
- **1.2. Chuẩn hóa phân quyền native**:
  - Khai báo đầy đủ quyền trong `android/app/src/main/AndroidManifest.xml`: `RECORD_AUDIO`, `INTERNET`, `ACCESS_NETWORK_STATE`, `MODIFY_AUDIO_SETTINGS`.
  - Khai báo `<uses-feature android:name="android.hardware.microphone" android:required="false" />` tương thích đa thiết bị.
- **1.3. Kiến trúc Clean Architecture & Dependency Injection**:
  - Phân tầng nghiêm ngặt: `core/`, `features/inspection/data/`, `features/inspection/domain/`, `features/inspection/presentation/`.
  - Tập trung đăng ký dịch vụ tại `lib/core/di/injection_container.dart` bằng `GetIt`, sẵn sàng cho mock testing độc lập.
- **1.4. Phát triển AudioPlayerService**:
  - Tạo `lib/core/services/audio_player_service.dart` quản lý playback âm thanh hiện trường, stream tiến trình thời gian thực, stream trạng thái phát/tạm dừng.
- **1.5. Tái thiết kế toàn diện UI theo góc nhìn Middle Mobile Developer**:
  - Loại bỏ hoàn toàn giao diện màu mè mang tính "chatbot AI demo". Chuyển sang phong cách **Industrial Dark Theme** (`AppColors`): nền `#0B1120`, card bề mặt `#151E32`, màu viền và phân cách sắc nét `#1E293B`, màu chủ đạo `#10B981` (Emerald).
  - Xây dựng thanh điều hướng `MainShellScreen` gồm 3 phân hệ:
    1. **Tổng quan (Dashboard)**: Thống kê KPI sự cố, tìm kiếm nhanh, danh sách sự cố gần nhất.
    2. **Thu âm (Voice Logging Station)**: Bàn điều khiển ghi âm trực quan với đo lường decibel.
    3. **Biên bản (Records Manager)**: Lọc trạng thái (Tất cả / Chờ sync / Đã sync) và đồng bộ tức thì.
  - Các widget chuyên dụng: `SwipeToSubmitButton` (nút trượt chống chạm nhầm khi mang găng tay bảo hộ), `PriorityBadgeChip` (nhận diện độ khẩn cấp).

---

### [x] Giai Đoạn 2: Xử Lý Phần Cứng, Audio Pipeline & Bóc Băng Giọng Nói (STT)
- **2.1. Nâng cấp AudioRecorderService (`lib/core/services/audio_recorder_service.dart`)**:
  - Xử lý các thao tác phần cứng: bắt đầu (`startRecording`), dừng (`stopRecording`), hủy bỏ an toàn (`cancelRecording`).
  - Hỗ trợ lưu 2 định dạng âm thanh:
    - `.m4a` (AAC LC 128kbps - mặc định, dung lượng nhỏ, chất lượng thoại rõ nét).
    - `.wav` (PCM 16-bit không nén).
  - Tự động tạo thư mục an toàn `app_recordings/` bên trong `getApplicationDocumentsDirectory()` để tránh tình trạng hệ điều hành tự ý quét xóa cache.
  - Tự động xóa sạch file rác khi hủy ghi âm (`cancelRecording`), ngăn rò rỉ dung lượng bộ nhớ thiết bị.
- **2.2. Xử lý cấp quyền Microphone & Dialog hướng dẫn chuyên nghiệp**:
  - Tích hợp `permission_handler: ^11.4.0`. Bắt lỗi `MicrophonePermissionException` có phân biệt cờ `isPermanentlyDenied`.
  - Thiết kế `MicrophonePermissionDialog` chuẩn Dark Mode có nút chuyển hướng người dùng trực tiếp vào **Cài đặt ứng dụng (App Settings)** khi bị từ chối vĩnh viễn.
- **2.3. Tích hợp bộ nhận diện giọng nói Speech-to-Text (`SpeechToTextService`)**:
  - Viết `lib/core/services/speech_to_text_service.dart` sử dụng engine native thiết bị, ưu tiên nhận dạng tiếng Việt (`vi_VN`).
  - Bổ sung intent `<intent><action android:name="android.speech.RecognitionService" /></intent>` vào `AndroidManifest.xml` hỗ trợ đầy đủ Android 11+ (API 30, 34, 37).
  - Cung cấp Stream `wordsStream` truyền dữ liệu lời nói thời gian thực lên giao diện.
- **2.4. Trải nghiệm người dùng đồng bộ âm thanh & văn bản**:
  - Hiển thị Card bóc băng giọng nói trực tiếp (Live STT Card) ngay trong lúc thu âm trên màn hình `VoiceCaptureScreen`.
  - Tích hợp các Chip kịch bản thử nghiệm sự cố nhanh (Bơm thủy lực quá nhiệt, Rò rỉ van khí nén, Chập tủ điện hạ thế) cho phép kiểm thử nhanh ngay cả trên máy ảo không có micro vật lý.
  - Đặt Card **"Văn bản bóc băng giọng nói (Transcript)"** ở vị trí ưu tiên hàng đầu ngay dưới trình phát âm thanh tại `TicketReviewScreen` để kỹ sư đối chiếu và xác nhận thông tin.
- **2.5. Tối ưu hệ thống Build Gradle**:
  - Khắc phục cảnh báo biên dịch `warning: [options] source/target value 8 is obsolete and will be removed in a future release` bằng cờ cấu hình `-Xlint:-options` trong `android/build.gradle.kts`.

---

### [x] Giai Đoạn 3: AI Service & Bóc Tách Dữ Liệu Hiện Trường (Structured Output)
- **3.1. Thiết kế Prompt Trích xuất Chuẩn hóa (`assets/prompts/system_extraction_prompt.txt`)**:
  - Loại bỏ hoàn toàn các khối bao bọc markdown ````json ```` để trình phân tích chuỗi không bao giờ gặp lỗi `FormatException`.
  - Định nghĩa chuẩn JSON Schema đơn nhất bao gồm 9 trường kỹ thuật bắt buộc:
    ```json
    {
      "title": "Tiêu đề ngắn gọn sự cố",
      "description": "Mô tả chi tiết hiện trạng kỹ thuật",
      "location": "Vị trí / Phân xưởng / Khu vực xảy ra sự cố",
      "category": "electrical | mechanical | civil | safety | hvac | general",
      "priority": "low | medium | high | critical",
      "suggested_action": "Hành động khắc phục hoặc bảo trì đề xuất",
      "inspector_name": "Tên kỹ sư / cán bộ giám sát",
      "confidence_score": 0.95,
      "raw_transcript": "Toàn văn lời nói bóc băng"
    }
    ```
  - Bổ sung bộ từ điển nhận dạng lỗi hiện trường công nghiệp Việt Nam: van xả DN50, puly/puri, bạc đạn, rơ-le nhiệt, aptomat, sụt áp, nứt dầm, lún móng, tháp giải nhiệt chiller, rò rỉ khí nén...
- **3.2. Viết hàm `extractTicketFromAudio(File audioFile)` trong `InspectionRemoteDataSource`**:
  - Tự động nhận diện MIME type của file âm thanh: `audio/mp4` (.m4a), `audio/wav` (.wav), `audio/mp3`, `audio/aac`.
  - Gửi trực tiếp tệp âm thanh nhị phân lên **Gemini 1.5 Flash (Multimodal)** thông qua SDK `google_generative_ai` kèm `systemInstruction` và cờ `responseMimeType: 'application/json'`.
  - Bộ tiền xử lý phòng thủ `_cleanJson`: tự động cắt chuỗi từ dấu `{` đầu tiên đến dấu `}` cuối cùng, gạt bỏ mọi ký tự rác nếu mô hình vô tình trả thêm lời chào.
  - Phân tích và kiểm thực dữ liệu an toàn bằng `InspectionTicketModel.fromJson()`:
    - Tự sinh UUID ngẫu nhiên nếu AI không trả ID.
    - Tự gắn mốc thời gian hiện tại (`DateTime.now()`).
    - Tự động chuẩn hóa chữ thường (lowercase) cho `category` và `priority`.
    - Bảo lưu đường dẫn file ghi âm `audioPath` và `rawTranscript` để phục vụ nghe lại và đồng bộ.
- **3.3. Bộ Fallback Bẫy Lỗi Đa Tầng (Multi-tier Fallback Engine)**:
  - **Tầng 1 (Lỗi Mạng/Kết Nối)**: Bẫy `SocketException`, `TimeoutException`, `HttpException` khi mất sóng 4G/Wifi ngoài công trường.
  - **Tầng 2 (Lỗi Dữ Liệu/Schema)**: Bẫy `FormatException`, `TypeError` khi chuỗi JSON từ AI bị lỗi cấu trúc.
  - **Tầng 3 (Lỗi API/Quota/Key)**: Bẫy `GenerativeAIException`, HTTP 400/403/429 khi hết hạn mức gọi API hoặc chưa cấu hình API Key.
  - **Tầng 4 (Smart NLP Heuristic Fallback)**: Tự động phân tích ngữ nghĩa tiếng Việt cục bộ (Local NLP Regex & Keyword Matching) dựa trên transcript hoặc tên tệp để trích xuất đầy đủ tiêu đề, vị trí, phân loại kỹ thuật và mức độ ưu tiên, **đảm bảo ứng dụng hoạt động thông suốt 100%, tuyệt đối không bao giờ crash**.
- **3.4. Kiểm thử Đơn vị & Xác thực Hệ thống (Unit Testing & Verification)**:
  - Xây dựng bộ test chuyên sâu `test/ai_extraction_service_test.dart` gồm 7 test case:
    1. Trích xuất thành công JSON từ phản hồi giả lập của Gemini.
    2. Tự động làm sạch chuỗi khi có markdown block ````json ```` hoặc văn bản thừa.
    3. Trích xuất thành công dữ liệu từ file nhị phân âm thanh thật (`real_test_record.m4a`).
    4. Kích hoạt bộ fallback Heuristic khi mất kết nối mạng (`SocketException`).
    5. Kích hoạt bộ fallback Heuristic khi phản hồi JSON bị lỗi cấu trúc (`FormatException`).
    6. Kích hoạt bộ fallback Heuristic khi gặp ngoại lệ API (`GenerativeAIException`).
    7. Tự động nhận diện chính xác MIME type (`audio/mp4` và `audio/wav`).
  - Toàn bộ **16/16 test case** trong toàn dự án đều đạt **PASS 100%**.
  - Kiểm tra tĩnh `flutter analyze`: **0 issues found**.
  - Build và kiểm thử trực tiếp trên Android Emulator `emulator-5554`: tốc độ build debug chỉ **3.2 giây**, luồng thao tác từ Ghi âm -> Live STT -> Trích xuất AI -> Duyệt biên bản -> Gửi thành công vận hành trơn tru.

---

## 4. Cấu Trúc Cây Thư Mục Dự Án (Project Structure)

```
build_an_ai_field_assistant/
├── android/                                    # Cấu hình Android native (Permissions, Speech recognition intent, Gradle)
├── web/                                        # Cấu hình Web demo & vercel.json deploy SPA
├── assets/
│   ├── icons/                                  # Assets icon ứng dụng
│   └── prompts/
│       └── system_extraction_prompt.txt        # Prompt JSON Schema thuần túy cho Gemini Multimodal
├── lib/
│   ├── app.dart                                # MaterialApp, Industrial Dark Theme, Routes
│   ├── main.dart                               # Entry point, khởi tạo native services & local database
│   │
│   ├── core/                                   # Nền tảng hạ tầng dùng chung
│   │   ├── constants/
│   │   │   ├── app_colors.dart                 # Bảng màu Dark Mode công nghiệp (Emerald, Slate, Amber, Rose)
│   │   │   ├── api_endpoints.dart
│   │   │   └── app_constants.dart
│   │   ├── errors/
│   │   │   ├── exceptions.dart                 # MicrophonePermissionException, ServerException, AiServiceException
│   │   │   └── failures.dart
│   │   ├── network/
│   │   │   └── api_client.dart
│   │   ├── services/
│   │   │   ├── audio_recorder_service.dart     # Ghi âm (.m4a/.wav), amplitude stream, dọn dẹp file rác
│   │   │   ├── audio_player_service.dart       # Trình phát lại âm thanh hiện trường
│   │   │   ├── speech_to_text_service.dart     # Nhận diện & bóc băng giọng nói tiếng Việt thời gian thực
│   │   │   └── connectivity_service.dart       # Giám sát trạng thái kết nối mạng Internet
│   │   ├── di/
│   │   │   └── injection_container.dart        # Service Locator (GetIt) tiêm phụ thuộc toàn dự án
│   │   └── utils/
│   │       ├── date_formatter.dart
│   │       └── dialog_helper.dart
│   │
│   └── features/
│       └── inspection/                         # Nghiệp vụ cốt lõi: Giám sát & Quản lý Biên bản Hiện trường
│           ├── data/
│           │   ├── datasources/
│           │   │   ├── inspection_remote_ds.dart   # Gemini 1.5 Flash Multimodal + Multi-tier Fallback Engine
│           │   │   └── inspection_local_ds.dart    # SQFlite (Mobile) & SharedPreferences (Web) Cache
│           │   ├── models/
│           │   │   └── inspection_ticket_model.dart # Serialization, DTO, data sanitation
│           │   └── repositories/
│           │       └── inspection_repository_impl.dart # Điều phối logic Online vs Offline & Auto-sync
│           ├── domain/
│           │   ├── entities/
│           │   │   └── inspection_ticket.dart      # Business Entity thuần túy
│           │   └── repositories/
│           │       └── i_inspection_repository.dart # Interface trừu tượng
│           └── presentation/
│               ├── controllers/
│               │   └── inspection_controller.dart  # Quản lý trạng thái phiếu, ghi âm và đồng bộ
│               ├── views/
│               │   ├── voice_capture_screen.dart   # Màn hình thu âm hiện trường & Live STT Card
│               │   ├── ticket_review_screen.dart   # Duyệt biên bản, nghe lại audio & đối chiếu transcript
│               │   └── ticket_history_screen.dart  # Quản lý danh sách biên bản (Tất cả / Chờ sync / Đã sync)
│               └── widgets/
│                   ├── wave_record_button.dart     # Nút thu âm hiển thị sóng âm Equalizer thời gian thực
│                   ├── priority_badge_chip.dart    # Chip hiển thị & chọn cấp độ ưu tiên trực quan
│                   ├── permission_dialog.dart      # Dialog Dark Mode hướng dẫn mở Cài đặt Micro
│                   └── swipe_to_submit_btn.dart    # Nút trượt công nghiệp xác nhận gửi biên bản
│
├── test/
│   ├── widget_test.dart                        # Unit test Entity & Model serialization (PASS)
│   ├── audio_recorder_service_test.dart        # Unit test Pipeline âm thanh & Quyền Micro (PASS)
│   ├── speech_to_text_service_test.dart        # Unit test Nhận diện giọng nói STT (PASS)
│   └── ai_extraction_service_test.dart         # Unit test Trích xuất JSON Gemini & Fallback (PASS)
│
├── AI_WORKLOG.md                               # Nhật ký làm việc chi tiết với AI
├── README.md                                   # Tài liệu hướng dẫn cài đặt & vận hành dự án
└── pubspec.yaml                                # Cấu hình dependencies, assets & fonts
```

---

## 5. Báo Cáo Chất Lượng Mã Nguồn & Kiểm Thử

### 5.1. Phân Tích Tĩnh Cú Pháp (Static Linter Analysis)
```bash
flutter analyze
# Analyzing build_an_ai_field_assistant...
# No issues found! (ran in 1.4s)
```
- **Kết quả**: 0 lỗi (errors), 0 cảnh báo (warnings), 0 gợi ý (infos).

### 5.2. Kiểm Thử Đơn Vị Tự Động (Automated Unit Tests)
```bash
flutter test
# 00:03 +16: All tests passed!
```
- **Tổng số bài test**: 16/16 bài kiểm thử thành công.
- **Danh mục kiểm thử**:
  - `test/widget_test.dart`: Kiểm thử khởi tạo `InspectionTicket` và chuyển đổi DTO `InspectionTicketModel`.
  - `test/audio_recorder_service_test.dart`: Kiểm thử khởi tạo thư mục lưu trữ, định dạng file `.m4a` / `.wav`, cơ chế dọn dẹp file khi hủy ghi âm, xử lý ngoại lệ quyền micro.
  - `test/speech_to_text_service_test.dart`: Kiểm thử chu trình nhận diện giọng nói `SpeechToTextService` và luồng Stream từ khóa.
  - `test/ai_extraction_service_test.dart`: Kiểm thử xử lý JSON Gemini Flash, bóc tách tệp nhị phân âm thanh, bẫy lỗi mất mạng, bẫy lỗi định dạng và bộ lọc Heuristic tiếng Việt.

### 5.3. Kiểm Thử Trực Tiếp Trên Thiết Bị (Device & Emulator Verification)
- **Thiết bị kiểm thử**: Android Emulator `emulator-5554` (`sdk_gphone16k_arm64`, Android 16 / VanillaIceCream / API 37).
- **Tốc độ build**: 3.2 giây.
- **Trải nghiệm thực tế**:
  - Giao diện Dark Mode tương phản cao, thao tác nhạy.
  - Bóc băng giọng nói hiển thị từng từ (word-by-word) mượt mà.
  - Phân tích thông tin sự cố ra kết quả JSON chính xác đầy đủ các trường.
  - Nghe lại âm thanh to rõ, thanh tiến trình hiển thị chính xác.
  - Thao tác trượt gửi (Swipe-to-submit) an toàn, chống chạm nhầm.

---

## 6. Lịch Sử Commit & Đồng Bộ Mã Nguồn Git

| Commit Hash | Giai đoạn | Mô Tả Chi Tiết Commit |
| :--- | :---: | :--- |
| `b1f1189` | **Giai đoạn 1** | `feat(core): hoan thien audio player service va tich hop injection container` |
| `4e55f6e` | **Giai đoạn 2** | `feat: hoan thanh giai doan 2 audio pipeline va xu ly microphone permission` |
| `893de9b` | **Giai đoạn 2** | `fix: suppress obsolete java options warning in android gradle build` |
| `90520ff` | **Giai đoạn 2** | `feat(stt): tich hop speech_to_text boc bang giong noi truc tiep va trich xuat text` |
| `0d81571` | **Giai đoạn 3** | `feat(phase-3): ai service structured output, clean prompt json schema va multi-tier fallback` |

---

## 7. Kế Hoạch Triển Khai Tiếp Theo (Giai Đoạn 4)

- [ ] **Giai đoạn 4: Offline-First, Lưu trữ Cục bộ SQLite & Cơ chế Đồng bộ Tự động (Sync Queue)**:
  - [ ] Nâng cấp `InspectionLocalDataSource`: Thiết kế bảng SQLite `inspection_tickets` chuẩn hóa trường dữ liệu, chỉ mục (indexes) theo `status` và `created_at`.
  - [ ] Quản lý trạng thái vòng đời biên bản: `draft`, `pending_sync`, `synced`, `sync_failed`.
  - [ ] Tự động kích hoạt đồng bộ ngầm (Background Sync) khi `ConnectivityService` phát hiện có mạng trở lại.
  - [ ] Cơ chế giải quyết xung đột dữ liệu (Conflict Resolution: Last-Write-Wins hoặc Remote-Priority).
  - [ ] Thể hiện trực quan số lượng phiếu đang chờ đồng bộ trên giao diện Dashboard và nút bấm "Đồng bộ ngay".
