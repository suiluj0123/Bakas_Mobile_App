import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class IdValidationResult {
  final bool isValid;
  final String? idType;
  final String message;

  IdValidationResult({
    required this.isValid,
    this.idType,
    required this.message,
  });
}

class IdValidationService {
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  static const Map<String, List<String>> _idKeywords = {
    'UMID': ['UNIFIED MULTI-PURPOSE ID', 'CRN', 'SSS'],
    'PhilID (National ID)': ['PHILIPPINE IDENTIFICATION', 'PhilSys', 'NATIONAL ID'],
    "Driver's License": ['DRIVER\'S LICENSE', 'LTO', 'RESTRICTIONS'],
    'Passport': ['REPUBLIKA NG PILIPINAS', 'PASAPORTE', 'PASSPORT'],
    'Postal ID': ['POSTAL ID', 'PHILPOST', 'POSTAL'],
    "Voter's ID": ['COMMISSION ON ELECTIONS', 'VOTER\'S ID', 'PRECINCT'],
    'PRC ID': ['PROFESSIONAL REGULATION COMMISSION', 'PRC'],
    'Senior Citizen ID': ['SENIOR CITIZEN', 'OSCA'],
  };

  Future<IdValidationResult> validatePhId(File imageFile, {String? selectedType}) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      
      String fullText = recognizedText.text.toUpperCase();
      
      if (fullText.isEmpty) {
        return IdValidationResult(
          isValid: false,
          message: "No text detected in the image. Please take a clearer photo.",
        );
      }

      // If a specific type is selected, we MUST find its keywords
      if (selectedType != null && _idKeywords.containsKey(selectedType)) {
        List<String> keywords = _idKeywords[selectedType]!;
        bool matched = false;
        
        for (var keyword in keywords) {
          if (fullText.contains(keyword)) {
            matched = true;
            break;
          }
        }

        if (!matched) {
          return IdValidationResult(
            isValid: false,
            message: "The uploaded photo does not look like a $selectedType. Please ensure you uploaded the correct ID.",
          );
        }

        return IdValidationResult(
          isValid: true,
          idType: selectedType,
          message: "Valid $selectedType detected.",
        );
      }

      // Default logic if no specific type selected (Fallback)
      String? detectedType;
      int maxMatches = 0;

      _idKeywords.forEach((type, keywords) {
        int matches = 0;
        for (var keyword in keywords) {
          if (fullText.contains(keyword)) {
            matches++;
          }
        }
        
        if (matches >= 1) {
          if (matches > maxMatches) {
            maxMatches = matches;
            detectedType = type;
          }
        }
      });

      if (detectedType != null) {
        return IdValidationResult(
          isValid: true,
          idType: detectedType,
          message: "Valid PH Government ID detected: $detectedType",
        );
      }

      // Fallback: Check if it's generally a PH ID
      if (fullText.contains('REPUBLIC OF THE PHILIPPINES') || 
          fullText.contains('REPUBLIKA NG PILIPINAS') ||
          fullText.contains('PILIPINAS')) {
        return IdValidationResult(
          isValid: true,
          idType: 'PH Government ID',
          message: "Valid PH Government ID detected.",
        );
      }

      return IdValidationResult(
        isValid: false,
        message: "This does not appear to be a official Philippine Government ID.",
      );
    } catch (e) {
      return IdValidationResult(
        isValid: false,
        message: "Error processing image: ${e.toString()}",
      );
    }
  }

  void dispose() {
    _textRecognizer.close();
  }
}
