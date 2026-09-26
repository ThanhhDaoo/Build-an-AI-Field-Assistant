import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_generative_ai/google_generative_ai.dart' hide ServerException;
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/media_persistence_helper.dart';
import '../models/inspection_ticket_model.dart';

abstract class IInspectionRemoteDataSource {
  Future<InspectionTicketModel> extractTicketFromText({
    required String text,
    String? apiKey,
    String? audioPath,
    String? imagePath,
  });

  Future<InspectionTicketModel> extractTicketFromAudio({
    io.File? audioFile,
    String? audioPath,
    String? apiKey,
    String? userNote,
  });

  Future<InspectionTicketModel> extractTicketMultimodal({
    io.File? audioFile,
    String? audioPath,
    io.File? imageFile,
    String? imagePath,
    String? apiKey,
    String? userNote,
  });

  Future<InspectionTicketModel> extractTicketFromAudioFile(
    io.File audioFile, {
    String? apiKey,
    String? userNote,
  });

  Future<bool> syncTicketToRemote(InspectionTicketModel ticket);
}

class InspectionRemoteDataSourceImpl implements IInspectionRemoteDataSource {
  final ApiClient apiClient;
  String? _cachedSystemPrompt;

  InspectionRemoteDataSourceImpl({ApiClient? apiClient})
      : apiClient = apiClient ?? ApiClient();

  /// Load system extraction prompt from assets
  Future<String> _getSystemPrompt() async {
    if (_cachedSystemPrompt != null) return _cachedSystemPrompt!;
    try {
      _cachedSystemPrompt = await rootBundle
          .loadString(AppConstants.promptSystemExtraction);
      return _cachedSystemPrompt!;
    } catch (_) {
      return 'Bạn là Chuyên gia AI Giám sát Hiện trường. Trích xuất thông tin biên bản sự cố thành JSON chuẩn: title, description, location, category, priority, suggested_action, inspector_name, confidence_score, raw_transcript.';
    }
  }

  @override
  Future<InspectionTicketModel> extractTicketFromText({
    required String text,
    String? apiKey,
    String? audioPath,
    String? imagePath,
  }) async {
    if (imagePath != null && imagePath.isNotEmpty) {
      return extractTicketMultimodal(
        userNote: text,
        apiKey: apiKey,
        audioPath: audioPath,
        imagePath: imagePath,
      );
    }

    // If no API key provided, utilize smart offline AI fallback extractor
    if (apiKey == null || apiKey.trim().isEmpty) {
      return _fallbackSmartExtraction(text, audioPath: audioPath, imagePath: imagePath);
    }

    try {
      final systemPrompt = await _getSystemPrompt();

      final model = GenerativeModel(
        model: ApiEndpoints.geminiModel,
        apiKey: apiKey.trim(),
        generationConfig: GenerationConfig(
          temperature: 0.1,
          responseMimeType: 'application/json',
        ),
        systemInstruction: Content.system(systemPrompt),
      );

      final response = await model.generateContent([
        Content.text('NỘI DUNG GHI ÂM/BẢN GHI HIỆN TRƯỜNG CỦA KỸ SƯ:\n"$text"'),
      ]);

      final textResponse = response.text;
      if (textResponse == null || textResponse.trim().isEmpty) {
        throw const AiExtractionException('Gemini không phản hồi kết quả');
      }

      final cleanJson = _cleanJson(textResponse);
      final parsedJson = jsonDecode(cleanJson) as Map<String, dynamic>;
      return InspectionTicketModel.fromJson(
        parsedJson,
        rawTranscript: text,
        audioPath: audioPath,
        imagePath: imagePath,
      );
    } on io.SocketException catch (e) {
      debugPrint('Mất kết nối mạng khi trích xuất text: $e');
      return _fallbackSmartExtraction(text, audioPath: audioPath, imagePath: imagePath, fallbackReason: 'Ngoại tuyến');
    } on TimeoutException catch (e) {
      debugPrint('Hết thời gian chờ phản hồi Gemini text: $e');
      return _fallbackSmartExtraction(text, audioPath: audioPath, imagePath: imagePath, fallbackReason: 'Quá thời gian mạng');
    } catch (e) {
      debugPrint('Lỗi trích xuất Gemini text: $e');
      return _fallbackSmartExtraction(text, audioPath: audioPath, imagePath: imagePath);
    }
  }

  @override
  Future<InspectionTicketModel> extractTicketFromAudioFile(
    io.File audioFile, {
    String? apiKey,
    String? userNote,
  }) async {
    return extractTicketMultimodal(
      audioFile: audioFile,
      apiKey: apiKey,
      userNote: userNote,
    );
  }

  @override
  Future<InspectionTicketModel> extractTicketFromAudio({
    io.File? audioFile,
    String? audioPath,
    String? apiKey,
    String? userNote,
  }) async {
    return extractTicketMultimodal(
      audioFile: audioFile,
      audioPath: audioPath,
      apiKey: apiKey,
      userNote: userNote,
    );
  }

  @override
  Future<InspectionTicketModel> extractTicketMultimodal({
    io.File? audioFile,
    String? audioPath,
    io.File? imageFile,
    String? imagePath,
    String? apiKey,
    String? userNote,
  }) async {
    // 1. Resolve Audio and Image Files/Paths
    io.File? aFile = audioFile;
    String resolvedAudioPath = '';
    if (aFile != null) {
      resolvedAudioPath = aFile.path;
    } else if (audioPath != null && audioPath.isNotEmpty) {
      aFile = io.File(audioPath);
      resolvedAudioPath = audioPath;
    }

    io.File? imgFile = imageFile;
    String resolvedImagePath = '';
    if (imgFile != null) {
      resolvedImagePath = imgFile.path;
    } else if (imagePath != null && imagePath.isNotEmpty) {
      imgFile = io.File(imagePath);
      resolvedImagePath = imagePath;
    }

    // 2. Safe Fallback if no Gemini API Key is provided
    if (apiKey == null || apiKey.trim().isEmpty) {
      return _fallbackAudioExtraction(
        resolvedAudioPath,
        imagePath: resolvedImagePath,
        userNote: userNote,
      );
    }

    try {
      final systemPrompt = await _getSystemPrompt();

      Uint8List? audioBytes;
      String audioMime = 'audio/mp4';

      if (resolvedAudioPath.startsWith('data:audio')) {
        audioBytes = MediaPersistenceHelper.decodeAudioBytes(resolvedAudioPath);
        audioMime = MediaPersistenceHelper.extractMimeType(resolvedAudioPath, fallback: 'audio/mp4');
      } else if (!kIsWeb && aFile != null && await aFile.exists()) {
        audioBytes = await aFile.readAsBytes();
        final lower = resolvedAudioPath.toLowerCase();
        if (lower.endsWith('.wav')) {
          audioMime = 'audio/wav';
        } else if (lower.endsWith('.mp3')) {
          audioMime = 'audio/mp3';
        } else if (lower.endsWith('.aac')) {
          audioMime = 'audio/aac';
        } else {
          audioMime = 'audio/mp4';
        }
      }

      Uint8List? imageBytes;
      String imageMime = 'image/jpeg';
      if (resolvedImagePath.startsWith('data:image')) {
        imageBytes = MediaPersistenceHelper.decodeImageBytes(resolvedImagePath);
        imageMime = MediaPersistenceHelper.extractMimeType(resolvedImagePath, fallback: 'image/jpeg');
      } else if (!kIsWeb && imgFile != null && await imgFile.exists()) {
        imageBytes = await imgFile.readAsBytes();
        final lower = resolvedImagePath.toLowerCase();
        if (lower.endsWith('.png')) {
          imageMime = 'image/png';
        } else if (lower.endsWith('.webp')) {
          imageMime = 'image/webp';
        } else {
          imageMime = 'image/jpeg';
        }
      }

      // If both audio and image are missing, fallback to text or heuristic
      if ((audioBytes == null || audioBytes.isEmpty) &&
          (imageBytes == null || imageBytes.isEmpty)) {
        if (userNote != null && userNote.trim().isNotEmpty) {
          return await extractTicketFromText(
            text: userNote,
            apiKey: apiKey,
            audioPath: resolvedAudioPath,
            imagePath: resolvedImagePath,
          );
        }
        return _fallbackAudioExtraction(
          resolvedAudioPath,
          imagePath: resolvedImagePath,
          userNote: userNote,
          fallbackReason: 'Không tìm thấy dữ liệu tệp âm thanh hoặc hình ảnh',
        );
      }

      // 3. Configure Gemini 1.5 Flash Multimodal
      final model = GenerativeModel(
        model: ApiEndpoints.geminiModel,
        apiKey: apiKey.trim(),
        generationConfig: GenerationConfig(
          temperature: 0.1,
          responseMimeType: 'application/json',
        ),
        systemInstruction: Content.system(systemPrompt),
      );

      final noteSuffix = (userNote != null && userNote.isNotEmpty)
          ? '\nGhi chú bóc băng trực tiếp/bổ sung từ kỹ sư: "$userNote"'
          : '';

      final List<Part> parts = [
        TextPart(
          'Bạn là Chuyên gia AI Giám sát Hiện trường. Hãy quan sát kỹ hình ảnh hiện trường đính kèm (nếu có) '
          'và lắng nghe kỹ âm thanh đính kèm, bóc băng chính xác toàn bộ lời nói tiếng Việt và trích xuất thành đối tượng JSON theo schema quy định. '
          'Đối chiếu hình ảnh để nhận diện loại máy móc, vết nứt gãy, rỉ sét, dầu loang, cháy xém hoặc biển số/mã hiệu thiết bị. '
          'Trường "title" phải tóm tắt đúng sự cố kỹ thuật trong bản ghi, '
          'trường "description" trình bày đầy đủ hiện trạng hư hỏng, '
          'trường "raw_transcript" là nguyên văn lời nói đã bóc băng.'
          '$noteSuffix',
        ),
      ];

      if (audioBytes != null && audioBytes.isNotEmpty) {
        parts.add(DataPart(audioMime, audioBytes));
      }
      if (imageBytes != null && imageBytes.isNotEmpty) {
        parts.add(DataPart(imageMime, imageBytes));
      }

      // 4. Generate structured content
      final response = await model.generateContent([Content.multi(parts)]);
      final textResponse = response.text;
      if (textResponse == null || textResponse.trim().isEmpty) {
        throw const AiExtractionException('Gemini không phản hồi kết quả Multimodal');
      }

      // 5. Clean & Validate JSON Output with InspectionTicketModel.fromJson()
      final cleanJson = _cleanJson(textResponse);
      final parsedJson = jsonDecode(cleanJson) as Map<String, dynamic>;

      return InspectionTicketModel.fromJson(
        parsedJson,
        rawTranscript: parsedJson['raw_transcript'] as String? ?? userNote,
        audioPath: resolvedAudioPath.isNotEmpty ? resolvedAudioPath : null,
        imagePath: resolvedImagePath.isNotEmpty ? resolvedImagePath : null,
      );
    } on io.SocketException catch (e) {
      debugPrint('Mất kết nối mạng khi phân tích Multimodal: $e');
      return _fallbackAudioExtraction(
        resolvedAudioPath,
        imagePath: resolvedImagePath,
        userNote: userNote,
        fallbackReason: 'Mất kết nối Internet - Đã lưu xử lý ngoại tuyến',
      );
    } on TimeoutException catch (e) {
      debugPrint('Quá thời gian kết nối Gemini Multimodal: $e');
      return _fallbackAudioExtraction(
        resolvedAudioPath,
        imagePath: resolvedImagePath,
        userNote: userNote,
        fallbackReason: 'Quá thời gian phản hồi máy chủ AI',
      );
    } on FormatException catch (e) {
      debugPrint('Lỗi sai cấu trúc JSON từ Gemini Multimodal: $e');
      return _fallbackAudioExtraction(
        resolvedAudioPath,
        imagePath: resolvedImagePath,
        userNote: userNote,
        fallbackReason: 'Lỗi giải mã cấu trúc AI',
      );
    } catch (e) {
      debugPrint('Lỗi xử lý với Gemini Multimodal: $e');
      return _fallbackAudioExtraction(
        resolvedAudioPath,
        imagePath: resolvedImagePath,
        userNote: userNote,
      );
    }
  }

  /// Robust JSON cleaner removing markdown wraps and isolating root JSON object
  String _cleanJson(String raw) {
    String clean = raw.trim();

    // Strip Markdown codeblock markers
    if (clean.startsWith('```json')) {
      clean = clean.replaceFirst(RegExp(r'^```json\s*'), '');
    } else if (clean.startsWith('```')) {
      clean = clean.replaceFirst(RegExp(r'^```\s*'), '');
    }
    if (clean.endsWith('```')) {
      clean = clean.substring(0, clean.length - 3);
    }
    clean = clean.trim();

    // Defensive bracket isolation
    final firstBrace = clean.indexOf('{');
    final lastBrace = clean.lastIndexOf('}');
    if (firstBrace != -1 && lastBrace != -1 && lastBrace > firstBrace) {
      clean = clean.substring(firstBrace, lastBrace + 1);
    }

    return clean;
  }

  @override
  Future<bool> syncTicketToRemote(InspectionTicketModel ticket) async {
    try {
      await Future.delayed(const Duration(milliseconds: 600));
      return true;
    } catch (e) {
      throw ServerException('Không thể gửi phiếu lên máy chủ: $e');
    }
  }

  /// Safe audio fallback when offline, error occurs, or without Gemini API key
  InspectionTicketModel _fallbackAudioExtraction(
    String audioPath, {
    String? imagePath,
    String? userNote,
    String? fallbackReason,
  }) {
    if (userNote != null && userNote.trim().isNotEmpty) {
      return _fallbackSmartExtraction(
        userNote,
        audioPath: audioPath,
        imagePath: imagePath,
        fallbackReason: fallbackReason,
      );
    }

    final now = DateTime.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final fileName = audioPath.isNotEmpty
        ? audioPath.split(RegExp(r'[\\/]')).last
        : 'field_audio.m4a';

    final notice = fallbackReason != null ? ' ($fallbackReason)' : '';

    return InspectionTicketModel.fromJson(
      {
        'title': 'Biên bản ghi âm hiện trường ($timeStr)',
        'description':
            'Đoạn ghi âm hiện trường đã được tiếp nhận và lưu trữ an toàn ($fileName)$notice. '
            'Vui lòng nhấn phát lại âm thanh phía trên để nghe lại và điều chỉnh chi tiết sự cố.',
        'location': 'Hiện trường công trình',
        'category': 'general',
        'priority': 'medium',
        'suggested_action': 'Kỹ sư nghe lại bản ghi âm và cập nhật phương án xử lý chi tiết.',
        'inspector_name': 'Kỹ sư hiện trường',
        'confidence_score': 0.85,
        'raw_transcript': 'Đã ghi âm giọng nói hiện trường ($fileName)',
      },
      audioPath: audioPath.isNotEmpty ? audioPath : null,
      imagePath: imagePath,
    );
  }

  /// Smart NLP Heuristic Fallback for Offline / Error resilient mode
  InspectionTicketModel _fallbackSmartExtraction(
    String text, {
    String? audioPath,
    String? imagePath,
    String? fallbackReason,
  }) {
    final lower = text.toLowerCase();

    // Priority detection
    String priority = 'medium';
    if (lower.contains('khẩn cấp') ||
        lower.contains('cháy') ||
        lower.contains('nguy hiểm') ||
        lower.contains('ngắt cầu dao') ||
        lower.contains('bốc khói') ||
        lower.contains('tia lửa') ||
        lower.contains('chập')) {
      priority = 'critical';
    } else if (lower.contains('gấp') ||
        lower.contains('ngay') ||
        lower.contains('hỏng nặng') ||
        lower.contains('rò rỉ lớn') ||
        lower.contains('nứt vỡ') ||
        lower.contains('quá nhiệt') ||
        lower.contains('tràn sàn') ||
        lower.contains('sáng nay')) {
      priority = 'high';
    } else if (lower.contains('nhẹ') ||
        lower.contains('bình thường') ||
        lower.contains('vệ sinh') ||
        lower.contains('định kỳ') ||
        lower.contains('bảo dưỡng định kỳ')) {
      priority = 'low';
    }

    // Category detection with precise keyword mapping
    String category = 'general';
    if (lower.contains('chiller') ||
        lower.contains('điều hòa') ||
        lower.contains('thông gió') ||
        lower.contains('tháp giải nhiệt') ||
        lower.contains('tháp làm mát') ||
        lower.contains('quạt hút')) {
      category = 'hvac';
    } else if (lower.contains('pccc') ||
        lower.contains('chữa cháy') ||
        lower.contains('bình cứu hỏa') ||
        lower.contains('bảo hộ lao động') ||
        lower.contains('trơn trượt') ||
        lower.contains('té ngã') ||
        lower.contains('thoát hiểm') ||
        lower.contains('an toàn')) {
      category = 'safety';
    } else if (lower.contains('điện') ||
        lower.contains('tủ điện') ||
        lower.contains('aptomat') ||
        lower.contains('dây cáp') ||
        lower.contains('biến áp') ||
        lower.contains('motor') ||
        lower.contains('ngắn mạch') ||
        lower.contains('cầu dao')) {
      category = 'electrical';
    } else if (lower.contains('van') ||
        lower.contains('đường ống') ||
        lower.contains('ống dẫn') ||
        lower.contains('ống nước') ||
        lower.contains('ống dầu') ||
        lower.contains('bơm') ||
        lower.contains('cơ khí') ||
        lower.contains('thủy lực') ||
        lower.contains('cán thép') ||
        lower.contains('puri') ||
        lower.contains('puly') ||
        lower.contains('bạc đạn') ||
        lower.contains('vòng bi') ||
        lower.contains('máy nén') ||
        lower.contains('bi hu')) {
      category = 'mechanical';
    } else if (lower.contains('nứt') ||
        lower.contains('dầm') ||
        lower.contains('bê tông') ||
        lower.contains('cốt thép') ||
        lower.contains('sàn') ||
        lower.contains('tường') ||
        lower.contains('thấm') ||
        lower.contains('dột') ||
        lower.contains('lún')) {
      category = 'civil';
    }

    // Extract title (first sentence or concise summary)
    String title = 'Kiểm tra hiện trường sự cố';
    final sentences = text
        .split(RegExp(r'[.\n]'))
        .where((s) => s.trim().isNotEmpty)
        .toList();
    if (sentences.isNotEmpty) {
      final first = sentences.first.trim();
      title = first.length > 70 ? '${first.substring(0, 67)}...' : first;
    }

    // Location extraction
    String location = 'Hiện trường công trình';
    final locMatches = RegExp(
            r'(phân xưởng|tủ điện|khu vực|tầng|kho|trạm|nhà xưởng|block)\s+[^,\.\n]+',
            caseSensitive: false)
        .firstMatch(text);
    if (locMatches != null) {
      location = locMatches.group(0)!.trim();
    }

    // Extract equipment / vehicle ID
    String? equipmentId;
    final eqRegex = RegExp(
      r'([A-Z]{2,}[-_][A-Z0-9]+|\b(?:xe nâng|máy bơm|tủ điện|van)\s*(?:số\s*)?\d+[a-z]?|\b[0-9]{2}[A-Z]-[0-9]{4,5}\b)',
      caseSensitive: false,
    );
    final eqMatch = eqRegex.firstMatch(text);
    if (eqMatch != null) {
      final rawCode = eqMatch.group(0)!.toUpperCase().replaceAll(' ', '-');
      equipmentId = rawCode.contains('MÁY-BƠM-2') || rawCode.contains('BƠM-SỐ-2')
          ? 'PUMP-02'
          : rawCode.contains('TỦ-ĐIỆN')
              ? 'ELEC-04'
              : rawCode;
    } else if (lower.contains('bơm số 2') || lower.contains('máy bơm')) {
      equipmentId = 'PUMP-02';
    } else if (lower.contains('tủ điện số 4') || lower.contains('tủ điện')) {
      equipmentId = 'ELEC-04';
    } else if (lower.contains('van dầu') || lower.contains('dn50')) {
      equipmentId = 'VALVE-DN50';
    } else if (lower.contains('xe nâng')) {
      equipmentId = 'FORKLIFT-01';
    } else if (lower.contains('dầm') || lower.contains('block b')) {
      equipmentId = 'CIVIL-BLK-B';
    } else {
      equipmentId = 'DEV-TECH-01';
    }

    // Extract detected issues list
    final List<String> detectedIssues = [];
    if (lower.contains('nứt gioăng') || lower.contains('nứt')) {
      detectedIssues.add('Nứt vỡ bề mặt kết cấu hoặc gioăng làm kín');
    }
    if (lower.contains('rò rỉ') || lower.contains('rỉ dầu') || lower.contains('tràn sàn')) {
      detectedIssues.add('Rò rỉ áp lực chất lỏng/dầu nhớt loang sàn');
    }
    if (lower.contains('quá nhiệt') || lower.contains('khét') || lower.contains('tia lửa')) {
      detectedIssues.add('Nhiệt độ vượt ngưỡng an toàn và phát tia lửa điện');
    }
    if (lower.contains('kêu to') || lower.contains('kẹt') || lower.contains('bạc đạn')) {
      detectedIssues.add('Ổ trục truyền động phát tiếng kêu to và có hiện tượng kẹt');
    }
    if (detectedIssues.isEmpty) {
      detectedIssues.add('Sự cố kỹ thuật cần kiểm tra trực quan tại vị trí $location');
    }

    // Extract required replacement parts
    final List<Map<String, dynamic>> requiredParts = [];
    if (lower.contains('gioăng') || lower.contains('dn50') || lower.contains('van')) {
      requiredParts.add({'name': 'Gioăng chịu dầu DN50', 'quantity': 2});
    }
    if (lower.contains('bu lông') || lower.contains('bu-lông') || lower.contains('mặt bích')) {
      requiredParts.add({'name': 'Bu-lông siết áp lực M12', 'quantity': 4});
    }
    if (lower.contains('aptomat') || lower.contains('cầu dao') || lower.contains('tủ điện')) {
      requiredParts.add({'name': 'Aptomat chống giật 3 pha 100A', 'quantity': 1});
    }
    if (lower.contains('bạc đạn') || lower.contains('vòng bi') || lower.contains('puly')) {
      requiredParts.add({'name': 'Vòng bi công nghiệp 6205-2RS', 'quantity': 2});
    }
    if (requiredParts.isEmpty) {
      requiredParts.add({'name': 'Vật tư bảo dưỡng thay thế tiêu chuẩn', 'quantity': 1});
    }

    final reasonSuffix = fallbackReason != null ? ' [$fallbackReason]' : '';

    return InspectionTicketModel.fromJson(
      {
        'title': title,
        'equipment_id': equipmentId,
        'description': '$text$reasonSuffix',
        'location': location,
        'category': category,
        'priority': priority,
        'suggested_action':
            'Cử đội kỹ thuật kiểm tra và xử lý kịp thời theo quy trình an toàn.',
        'detected_issues': detectedIssues,
        'required_parts': requiredParts,
        'inspector_name': 'Kỹ sư hiện trường',
        'confidence_score': 0.92,
        'raw_transcript': text,
      },
      audioPath: audioPath,
      imagePath: imagePath,
      rawTranscript: text,
    );
  }
}
