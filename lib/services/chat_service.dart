import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../models/chat_models.dart';

class ChatService {
  final AuthService _authService = AuthService();
  
  // Construct API URL based on AuthService's base URL
  String get _baseUrl => AuthService.baseUrl.replaceAll('/Auth', '/Chat');

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<SessionDto?> createChat(String? title) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$_baseUrl/create-chat'),
        headers: headers,
        body: jsonEncode(CreateSessionDto(title: title).toJson()),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'];
        return SessionDto.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error creating chat: $e');
      return null;
    }
  }

  Future<List<SessionDto>> getSessions() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/sessions'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body)['data'];
        return data.map((json) => SessionDto.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error getting sessions: $e');
      return [];
    }
  }

  Future<SessionDto?> getSession(int sessionId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/sessions/$sessionId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'];
        return SessionDto.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error getting session: $e');
      return null;
    }
  }

  Future<ChatResponseDto?> sendMessage(int sessionId, String content) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$_baseUrl/sessions/$sessionId/messages'),
        headers: headers,
        body: jsonEncode(SendMessageDto(content: content).toJson()),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'];
        return ChatResponseDto.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error sending message: $e');
      return null;
    }
  }
  Future<List<MessageDto>> getMessages(int sessionId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/sessions/$sessionId/messages'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        // DEBUG PRINT
        print("Raw Messages Response: ${response.body}");
        final List<dynamic> data = jsonDecode(response.body)['data'];
        return data.map((json) => MessageDto.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error getting messages: $e');
      return [];
    }
  }
  // Returns { "success": bool, "message": String?, "documentId": int? }
  Future<Map<String, dynamic>> uploadDocument(int sessionId, List<int> bytes, String fileName) async {
    try {
      final token = await _authService.getToken();
      final uploadUrl = AuthService.baseUrl.replaceAll('/Auth', '/Document/sessions/$sessionId/upload');
      
      var request = http.MultipartRequest('POST', Uri.parse(uploadUrl));
      request.headers['Authorization'] = 'Bearer $token';
      
      request.files.add(http.MultipartFile.fromBytes(
        'File', 
        bytes,
        filename: fileName,
      ));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Assuming response body contains the DocumentItemDto directly or wrapped?
        // Controller returns `Ok(result.Data)` where Data is DocumentItemDto.
        // DocumentItemDto has `id`.
        return {
          "success": true,
          "documentId": data['id'] 
        };
      } else {
        print('Upload failed: ${response.statusCode} ${response.body}');
        return {
          "success": false,
          "message": 'Server Error: ${response.statusCode}'
        };
      }
    } catch (e) {
      print('Error uploading document: $e');
      return {
          "success": false,
          "message": 'Connection Error: $e'
      };
    }
  }

  Future<String?> getDocumentStatus(int documentId) async {
    try {
      final token = await _authService.getToken();
      final url = AuthService.baseUrl.replaceAll('/Auth', '/Document/$documentId/status');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // data['status'] is int (enum) or string? 
        // DocumentItemDto: public DocumentStatus Status { get; set; }
        // public string StatusDisplay => Status.ToString();
        // Default JSON serialization of enum acts as integer usually unless configured.
        // But let's check `StatusDisplay` if available or handle enum int.
        // Actually DocumentItemDto has `status` (enum) and `statusDisplay` (string).
        // Let's rely on `status` (int) or `statusDisplay`. 
        // 0=Pending, 1=Processed, 2=Error (Assuming enum values)
        // Let's just return the integer status or check the fields.
        if (data['status'] != null) {
           // Mapping: 0: Pending, 1: Processed, 2: Error (Need to verify Enum)
           // Let's just return the StatusDisplay if available, or raw value.
           return data['statusDisplay']?.toString() ?? data['status'].toString(); 
        }
      }
      return null;
    } catch (e) {
      print('Error checking status: $e');
      return null;
    }
  }
}
