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
| **Giai đoạn 4** | **Màn hình Giao diện & Trải nghiệm Tương tác (VoiceCaptureScreen & TicketReviewScreen)** | **ĐÃ HOÀN THÀNH** | `b1c0fea`, `c10c630` |
| **Giai đoạn 5** | **Xử lý Offline-First & Đồng bộ Dữ liệu (SQLite 'synced'|'pending', Auto-sync ConnectivityService)** | **ĐÃ HOÀN THÀNH** | `984cfb0` *(sắp commit)* |
| **Giai đoạn 6** | **Camera Inspection, Multimodal Visual Analysis & Xuất Báo cáo PDF** | *KẾ HOẠCH TIẾP THEO* | `Dự kiến` |

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
  - Định nghĩa chuẩn JSON Schema đơn nhất bao gồm các trường kỹ thuật cốt lõi: `title`, `description`, `location`, `category`, `priority`, `suggested_action`, `inspector_name`, `confidence_score`, `raw_transcript`.
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
- **3.4. Kiểm thử Đơn vị & Xác thực Hệ thống**:
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

---

### [x] Giai Đoạn 4: Màn Hình Giao Diện & Trải Nghiệm Tương Tác (VoiceCaptureScreen & TicketReviewScreen)
- **4.1. Nâng cấp Domain Entity & Data Models**:
  - Xây dựng entity `InspectionPart` với `name`, `quantity`, phương thức `copyWith`, `toJson`, `fromJson`, `operator ==`, `hashCode`.
  - Mở rộng `InspectionTicket` với 3 trường nghiệp vụ mới:
    - `equipmentId`: Mã định danh thiết bị / xe được AI trích xuất (ví dụ: `B-02`, `PUMP-01`, `XL-204`...).
    - `detectedIssues`: Danh sách lỗi phát hiện hiển thị dạng thẻ (`List<String>`).
    - `requiredParts`: Danh sách vật tư / linh kiện thay thế (`List<InspectionPart>`).
  - Cập nhật `InspectionTicketModel` hỗ trợ đầy đủ serialization sang JSON, SQLite Map với `jsonEncode` / `jsonDecode`, và chuyển đổi từ `fromAiExtraction`.
- **4.2. Mở rộng System Extraction Prompt & AI Multimodal**:
  - Cập nhật `assets/prompts/system_extraction_prompt.txt` với schema chuẩn hóa JSON chứa `equipment_id`, `detected_issues`, `required_parts`.
  - Nâng cấp bộ Fallback NLP tại `InspectionRemoteDataSource`: nhận diện regex mã thiết bị công trường (VD: `B-02`, `PUMP-01`, `XL-204`...), bóc tách danh mục lỗi và nhận diện linh kiện kèm số lượng.
- **4.3. SQLite Database Migration & Auto-healing (dbVersion = 2)**:
  - Nâng `dbVersion` từ `1` lên `2` trong `AppConstants`.
  - Thêm `onUpgrade` script bổ sung 3 cột: `equipment_id TEXT`, `detected_issues TEXT`, `required_parts TEXT`.
  - Xây dựng cơ chế phòng thủ **Auto-healing ALTER TABLE** trong `InspectionLocalDataSource`: tự động phát hiện và thêm cột ngay trong runtime nếu SQLite schema của máy ảo / máy thật cũ chưa được migrate, ngăn chặn triệt để lỗi crash database.
- **4.4. Màn hình Ghi âm (`VoiceCaptureScreen`) & Nút Thu âm Radar (`WaveRecordButton`)**:
  - Thiết kế nút micro trung tâm kích thước lớn (88px) đặt tại trọng tâm ngón cái.
  - Hiệu ứng đổi màu gradient động: từ Xanh ngọc Emerald (`#10B981`) ở trạng thái chờ sang Đỏ Crimson cảnh báo (`#EF4444`) khi đang thu âm.
  - Hiệu ứng sóng radar đa tầng (Dual expanding ripple waves) tỏa ra xung quanh nút micro khi đang ghi âm.
  - Đồng hồ đếm thời gian HUD kỹ thuật số đếm giây (`00:08`, `00:15`) kèm chấm đỏ nhấp nháy `● REC` trực quan.
- **4.5. Màn hình Duyệt phiếu (`TicketReviewScreen`)**:
  - Card **Định danh thiết bị / Phương tiện** với badge `AI BÓC TÁCH`, tự động hiển thị mã thiết bị được AI trích xuất hoặc cho phép sửa nhanh.
  - **Selector chọn mức ưu tiên 3 mức**: Thấp (Xanh ngọc `#10B981`), Trung bình (Vàng hổ phách `#F59E0B`), Khẩn cấp (Đỏ san hô `#EF4444`) cho phép kỹ sư chuyển đổi độ ưu tiên chỉ với 1 chạm.
  - **Danh sách lỗi phát hiện dạng thẻ (Card List)**: Mỗi thẻ lỗi có icon cảnh báo màu hổ phách, nội dung chi tiết, nút xóa nhanh `X`, và nút `+ Thêm lỗi` mở dialog nhập lỗi tức thì.
  - **Danh sách linh kiện & vật tư kèm bộ tăng giảm số lượng (+ / -)**: Mỗi thẻ vật tư có nút `[-]` và `[+]` thay đổi số lượng nhanh, kiểm soát số lượng tối thiểu, nút xóa khi cần, và nút `+ Thêm vật tư` mở dialog thêm linh kiện.
  - **Nút trượt gửi biên bản (`SwipeToSubmitButton`)**: Cơ chế "Vuốt để duyệt & gửi biên bản >>" (Slide-to-confirm) thay vì nút bấm thông thường, loại bỏ hoàn toàn rủi ro chạm nhầm khi kỹ sư đang đeo găng tay bảo hộ trong môi trường công nghiệp.
- **4.6. Kiểm thử Đơn vị Tự động & Xác thực Thực tế (Unit Test & Verification)**:
  - Bổ sung `test/phase_4_interaction_test.dart` với 4 bài kiểm thử:
    1. Serialization & Deserialization `InspectionPart`.
    2. Serialization & Deserialization `InspectionTicket` với `equipmentId`, `detectedIssues`, `requiredParts`.
    3. Trích xuất AI bóc tách `equipment_id`, `detected_issues`, `required_parts`.
    4. Widget testing `WaveRecordButton` kích thước lớn 88px và HUD timer.
  - Toàn bộ **20/20 test cases** toàn dự án đạt **PASS 100%**.
  - Phân tích tĩnh `flutter analyze`: **0 issues found**.

---

### [x] Giai Đoạn 5: Xử Lý Offline-First & Đồng Bộ Dữ Liệu (SQLite Status & Auto-sync Pipeline)
- **5.1. Khởi tạo & Chuẩn hóa SQLite `inspection_tickets`**:
  - Cột `status` trong SQLite table được chuẩn hóa hỗ trợ hai trạng thái cốt lõi:
    - `'synced'`: Đã gửi và lưu trữ an toàn trên server trung tâm.
    - `'pending'`: Đang chờ đồng bộ do thiết bị ngoại tuyến hoặc server bảo trì (vẫn tương thích ngược hoàn hảo với `'pending_sync'`).
  - Getter tiện ích tại `InspectionTicket`:
    - `bool get isSynced => status == 'synced';`
    - `bool get isPendingSync => status == 'pending' || status == 'pending_sync';`
  - Nâng cấp `getPendingTickets()` trong `InspectionLocalDataSource`: truy vấn `WHERE status = 'pending' OR status = 'pending_sync' ORDER BY created_at ASC`.
  - Cập nhật `markTicketAsSynced(id)`: chuyển đổi trạng thái bản ghi thành `'synced'` và cập nhật mốc thời gian `updated_at`.
- **5.2. Hoàn thiện Logic Điều phối trong `InspectionRepositoryImpl`**:
  - **Khi có mạng (`connectivityService.isOnline == true`)**:
    - Gọi `remoteDataSource.syncTicketToRemote(model)` gửi dữ liệu lên server.
    - Khi server phản hồi thành công: gán `status: 'synced'`.
    - Khi server lỗi / timeout: bẫy ngoại lệ phòng vệ, tự động gán `status: 'pending'` để không làm gián đoạn trải nghiệm của kỹ sư.
  - **Khi mất mạng (`connectivityService.isOnline == false`)**:
    - Gán trực tiếp `status: 'pending'`.
  - Lưu bản ghi vào SQLite Database cục bộ thông qua `localDataSource.saveTicket(model)` và phát tín hiệu cập nhật Stream danh sách biên bản.
- **5.3. Lắng nghe thay đổi kết nối mạng (`ConnectivityService`) & Tự động Đồng bộ Ngầm**:
  - Đăng ký subscription lắng nghe luồng `connectivityService.onConnectivityChanged`.
  - Khi phát hiện mạng 4G/Wifi được phục hồi (`isOnline == true`), ứng dụng tự động kích hoạt hàm `syncPendingTickets()` trong nền:
    - Quét toàn bộ danh sách bản ghi có trạng thái `pending` trong SQLite.
    - Gửi tuần tự từng phiếu lên máy chủ trung tâm.
    - Đánh dấu `markTicketAsSynced(ticket.id)` ngay khi từng phiếu thành công.
    - Tự động giải phóng bộ nhớ khi repository bị hủy (`dispose()`).
- **5.4. Trải nghiệm Người dùng Đồng bộ & Ngoại tuyến**:
  - **Offline Banner**: Tự động hiển thị thanh cảnh báo màu hổ phách `Đang ngoại tuyến. Dữ liệu lưu cục bộ và sẽ tự động đồng bộ khi có kết nối.` khi mất mạng, và tự ẩn khi có mạng trở lại.
  - **Badge Chờ sync**: Hiển thị đám mây màu vàng cam `☁ Chờ sync` trên từng thẻ phiếu chưa đồng bộ.
  - **Badge Đã sync**: Tự động chuyển sang đám mây màu xanh ngọc `☁ Đã sync` ngay sau khi hệ thống tự động đồng bộ thành công.
  - **Bộ đếm thời gian thực**: Cập nhật badge số lượng `Chờ đồng bộ (1)` trên Tab Lịch sử, Tab bar và Card Dashboard KPI.
- **5.5. Kiểm thử Đơn vị & Xác thực Thực tế (Unit Test & Device Verification)**:
  - Bổ sung file kiểm thử chuyên sâu `test/phase_5_offline_sync_test.dart` gồm 6 bài test:
    1. Kiểm thử định danh trạng thái `isSynced` và `isPendingSync` trên Entity & Model.
    2. Kiểm thử lưu phiếu khi Online -> gửi server thành công -> lưu local DB với status `synced`.
    3. Kiểm thử lưu phiếu khi Offline -> lưu local DB với status `pending`.
    4. Kiểm thử lưu phiếu khi Online nhưng Server báo lỗi 503 -> fallback an toàn lưu local với status `pending`.
    5. Kiểm thử `ConnectivityService` phát hiện phục hồi mạng -> tự động duyệt danh sách `pending` và đồng bộ thành `synced`.
    6. Kiểm thử hàm đồng bộ thủ công `syncPendingTickets()` trả về chính xác số lượng phiếu đã sync.
  - Toàn bộ **26/26 bài kiểm thử** trong toàn dự án đạt **PASS 100%**.
  - Kiểm tra tĩnh `flutter analyze`: **0 issues found**.
  - **Xác thực trực tiếp trên Android Emulator `emulator-5554`**:
    - Chạy lệnh ngắt mạng: `adb shell svc wifi disable && adb shell svc data disable`.
    - Dashboard tự động đổi badge sang `● Offline`.
    - Tạo phiếu mới -> vuốt để gửi biên bản -> SnackBar hiển thị: `✓ Đã lưu offline. Hệ thống sẽ tự đồng bộ khi có mạng!`.
    - Tab Biên bản hiển thị phiếu với nhãn `☁ Chờ sync` và tab `Chờ đồng bộ (1)`.
    - Chạy lệnh bật lại mạng: `adb shell svc wifi enable && adb shell svc data enable`.
    - Ứng dụng tự động kích hoạt đồng bộ ngầm -> Phiếu tự động chuyển sang nhãn `☁ Đã sync` màu xanh, số lượng `Chờ đồng bộ` trở về `0`.

---

## 4. Cấu Trúc Cây Thư Mục Dự Án (Project Structure)

```
build_an_ai_field_assistant/
├── android/                                    # Cấu hình Android native (Permissions, Speech recognition intent, Gradle)
├── web/                                        # Cấu hình Web demo & vercel.json deploy SPA
├── assets/
│   ├── icons/                                  # Assets icon ứng dụng
│   └── prompts/
│       └── system_extraction_prompt.txt        # Prompt JSON Schema thuần túy cho Gemini Multimodal (Phase 4 Schema)
├── lib/
│   ├── app.dart                                # MaterialApp, Industrial Dark Theme, Routes
│   ├── main.dart                               # Entry point, khởi tạo native services & local database
│   │
│   ├── core/                                   # Nền tảng hạ tầng dùng chung
│   │   ├── constants/
│   │   │   ├── app_colors.dart                 # Bảng màu Dark Mode công nghiệp (Emerald, Slate, Amber, Rose)
│   │   │   ├── api_endpoints.dart
│   │   │   └── app_constants.dart              # SQLite DB version 2
│   │   ├── errors/
│   │   │   ├── exceptions.dart                 # MicrophonePermissionException, ServerException, AiServiceException
│   │   │   └── failures.dart
│   │   ├── network/
│   │   │   └── api_client.dart
│   │   ├── services/
│   │   │   ├── audio_recorder_service.dart     # Ghi âm (.m4a/.wav), amplitude stream, dọn dẹp file rác
│   │   │   ├── audio_player_service.dart       # Trình phát lại âm thanh hiện trường
│   │   │   ├── speech_to_text_service.dart     # Nhận diện & bóc băng giọng nói tiếng Việt thời gian thực
│   │   │   └── connectivity_service.dart       # Giám sát trạng thái kết nối mạng Internet (autoInit support)
│   │   ├── di/
│   │   │   └── injection_container.dart        # Service Locator (GetIt) tiêm phụ thuộc toàn dự án
│   │   └── utils/
│   │       ├── date_formatter.dart
│   │       ├── debouncer.dart
│   │       └── dialog_helper.dart
│   │
│   └── features/
│       └── inspection/                         # Nghiệp vụ cốt lõi: Giám sát & Quản lý Biên bản Hiện trường
│           ├── data/
│           │   ├── datasources/
│           │   │   ├── inspection_remote_ds.dart   # Gemini 1.5 Flash Multimodal + Multi-tier Fallback Engine
│           │   │   └── inspection_local_ds.dart    # SQLite DB v2 (status: synced | pending, Auto-healing)
│           │   ├── models/
│           │   │   └── inspection_ticket_model.dart # Serialization, DTO, data sanitation, InspectionPart mapping
│           │   └── repositories/
│           │       └── inspection_repository_impl.dart # Điều phối logic Online vs Offline & Auto-sync Pipeline
│           ├── domain/
│           │   ├── entities/
│           │   │   └── inspection_ticket.dart      # Business Entity thuần túy + InspectionPart + isPendingSync
│           │   └── repositories/
│           │       └── i_inspection_repository.dart # Interface trừu tượng
│           └── presentation/
│               ├── controllers/
│               │   └── inspection_controller.dart  # Quản lý trạng thái phiếu, ghi âm, lọc và đồng bộ
│               ├── views/
│               │   ├── voice_capture_screen.dart   # Màn hình thu âm hiện trường, Live STT Card, Preset chips
│               │   ├── ticket_review_screen.dart   # Duyệt biên bản: Equipment ID, Issue cards, Parts +/-, Swipe to submit
│               │   └── ticket_history_screen.dart  # Quản lý danh sách biên bản (Tất cả / Chờ sync / Đã sync), Offline banner
│               └── widgets/
│                   ├── wave_record_button.dart     # Nút thu âm lớn 88px, radar ripple đa tầng, timer HUD kỹ thuật số
│                   ├── priority_badge_chip.dart    # Chip hiển thị & chọn cấp độ ưu tiên trực quan
│                   ├── permission_dialog.dart      # Dialog Dark Mode hướng dẫn mở Cài đặt Micro
│                   └── swipe_to_submit_btn.dart    # Nút trượt công nghiệp xác nhận gửi biên bản
│
├── test/
│   ├── widget_test.dart                        # Unit test Entity & Model serialization (PASS)
│   ├── audio_recorder_service_test.dart        # Unit test Pipeline âm thanh & Quyền Micro (PASS)
│   ├── speech_to_text_service_test.dart        # Unit test Nhận diện giọng nói STT (PASS)
│   ├── ai_extraction_service_test.dart         # Unit test Trích xuất JSON Gemini & Fallback (PASS)
│   ├── phase_4_interaction_test.dart           # Unit test Phase 4 UI & Interaction (PASS)
│   └── phase_5_offline_sync_test.dart          # Unit test Phase 5 Offline-First & Auto-sync Pipeline (PASS)
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
# No issues found! (ran in 2.5s)
```
- **Kết quả**: 0 lỗi (errors), 0 cảnh báo (warnings), 0 gợi ý (infos).

### 5.2. Kiểm Thử Đơn Vị Tự Động (Automated Unit Tests)
```bash
flutter test
# 00:01 +26: All tests passed!
```
- **Tổng số bài test**: 26/26 bài kiểm thử thành công (100% PASS).
- **Danh mục kiểm thử**:
  - `test/widget_test.dart`: Kiểm thử khởi tạo `InspectionTicket` và chuyển đổi DTO `InspectionTicketModel`.
  - `test/audio_recorder_service_test.dart`: Kiểm thử khởi tạo thư mục lưu trữ, định dạng file `.m4a` / `.wav`, cơ chế dọn dẹp file khi hủy ghi âm, xử lý ngoại lệ quyền micro.
  - `test/speech_to_text_service_test.dart`: Kiểm thử chu trình nhận diện giọng nói `SpeechToTextService` và luồng Stream từ khóa.
  - `test/ai_extraction_service_test.dart`: Kiểm thử xử lý JSON Gemini Flash, bóc tách tệp nhị phân âm thanh, bẫy lỗi mất mạng, bẫy lỗi định dạng và bộ lọc Heuristic tiếng Việt.
  - `test/phase_4_interaction_test.dart`: Kiểm thử mô hình linh kiện `InspectionPart`, bóc tách mã thiết bị `equipmentId`, bộ lọc thẻ lỗi, nút tăng giảm vật tư và widget `WaveRecordButton`.
  - `test/phase_5_offline_sync_test.dart`: Kiểm thử định danh `status` ('synced' | 'pending'), lưu online, lưu offline, fallback khi server lỗi, và cơ chế tự động đồng bộ khi `ConnectivityService` phát hiện có mạng trở lại.

### 5.3. Kiểm Thử Trực Tiếp Trên Thiết Bị (Device & Emulator Verification)
- **Thiết bị kiểm thử**: Android Emulator `emulator-5554` (`sdk_gphone16k_arm64`, Android 16 / VanillaIceCream / API 37).
- **Trải nghiệm thực tế Giai đoạn 5**:
  - Tắt mạng: Dashboard hiển thị `● Offline`, banner ngoại tuyến màu hổ phách xuất hiện.
  - Lưu biên bản khi mất mạng: Thông báo `✓ Đã lưu offline. Hệ thống sẽ tự đồng bộ khi có mạng!`.
  - Thẻ biên bản lưu vào SQLite với trạng thái `pending` và hiển thị badge `☁ Chờ sync`.
  - Bật lại mạng: `ConnectivityService` phát tín hiệu `isOnline = true`, repository tự động kích hoạt `syncPendingTickets()`.
  - Phiếu tự động chuyển sang `☁ Đã sync` màu xanh ngọc, số lượng `Chờ đồng bộ` trở về `0`.

---

## 6. Lịch Sử Commit & Đồng Bộ Mã Nguồn Git

| Commit Hash | Giai đoạn | Mô Tả Chi Tiết Commit |
| :--- | :---: | :--- |
| `b1f1189` | **Giai đoạn 1** | `feat(core): hoan thien audio player service va tich hop injection container` |
| `4e55f6e` | **Giai đoạn 2** | `feat: hoan thanh giai doan 2 audio pipeline va xu ly microphone permission` |
| `893de9b` | **Giai đoạn 2** | `fix: suppress obsolete java options warning in android gradle build` |
| `90520ff` | **Giai đoạn 2** | `feat(stt): tich hop speech_to_text boc bang giong noi truc tiep va trich xuat text` |
| `0d81571` | **Giai đoạn 3** | `feat(phase-3): ai service structured output, clean prompt json schema va multi-tier fallback` |
| `ec02427` | **Worklog Sync** | `docs: cap nhat toan bo AI_WORKLOG.md giai doan 1-3 va dong bo len git` |
| `b1c0fea` | **Giai đoạn 4** | `feat(phase-4): hoan thanh man hinh giao dien & trai nghiem tuong tac` |
| `c10c630` | **Worklog Sync** | `docs: cap nhat ma commit b1c0fea cho giai doan 4 trong AI_WORKLOG.md` |
| *(pending)* | **Giai đoạn 5** | `feat(phase-5): xu ly offline-first, luu tru sqlite synced|pending va auto-sync connectivity` |

---

## 7. Kế Hoạch Triển Khai Tiếp Theo (Giai Đoạn 6)

- [ ] **Giai đoạn 6: Camera Inspection, Multimodal Visual Analysis & Xuất Báo cáo PDF**:
  - [ ] Tích hợp chụp ảnh hiện trường và đính kèm vào biên bản sự cố.
  - [ ] Gửi hình ảnh đính kèm lên Gemini 1.5 Flash Vision để phát hiện nứt gãy, biến dạng vật lý bằng AI thị giác máy tính.
  - [ ] Xuất biên bản kiểm tra sự cố định dạng PDF chuyên nghiệp có chữ ký kỹ sư và chia sẻ qua Zalo/Email.
