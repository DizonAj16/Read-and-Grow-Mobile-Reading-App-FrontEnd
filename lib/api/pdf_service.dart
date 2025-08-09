import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pdf_material.dart';

class PdfService {
  static Future<String> _getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('base_url') ?? "http://10.0.2.2:8000/api";
  }

  static Map<String, String> _authHeaders(String token) => {
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
  };

  static Future<bool> uploadPdfFile({
    required File file,
    required String pdfTitle,
    required int classroomId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final baseUrl = await _getBaseUrl();
      final token = prefs.getString('token') ?? '';
      final uri = Uri.parse('$baseUrl/teachers/pdfs');

      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll(_authHeaders(token));

      request.files.add(await http.MultipartFile.fromPath('pdf_file', file.path));
      request.fields['pdf_title'] = pdfTitle;
      request.fields['class_room_id'] = classroomId.toString();

      final response = await request.send();

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return true;
      } else {
        final respStr = await response.stream.bytesToString();
        print("Upload failed: ${response.statusCode}");
        print("Server response: $respStr");
        return false;
      }
    } catch (e) {
      print("Exception during upload: $e");
      return false;
    }
  }

  static Future<List<PdfMaterial>> getUploadedPdfList(int classId) async {
    final prefs = await SharedPreferences.getInstance();
    final baseUrl = await _getBaseUrl();
    final token = prefs.getString('token') ?? '';

    final response = await http.get(
      Uri.parse('$baseUrl/teachers/pdfs/$classId'),
      headers: _authHeaders(token),
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map<PdfMaterial>((item) {
        final rawPath = item['pdf_file_path'] ?? item['url'] ?? '';
        final correctedUrl = rawPath.startsWith('http') 
          ? rawPath 
          : '$baseUrl/storage/$rawPath';
        return PdfMaterial.fromJson({...item, 'url': correctedUrl});
      }).toList();
    } else {
      throw Exception('Failed to fetch PDF list: ${response.statusCode}');
    }
  }

  static Future<List<PdfMaterial>> fetchStudentPdfMaterials() async {
    final prefs = await SharedPreferences.getInstance();
    final baseUrl = await _getBaseUrl();
    final token = prefs.getString('token') ?? '';

    final response = await http.get(
      Uri.parse('$baseUrl/students/pdfs'),
      headers: _authHeaders(token),
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map<PdfMaterial>((item) {
        final rawPath = item['pdf_file_path'] ?? item['url'] ?? '';
        final correctedUrl = rawPath.startsWith('http') 
          ? rawPath 
          : '$baseUrl/storage/$rawPath';
        return PdfMaterial.fromJson({...item, 'url': correctedUrl});
      }).toList();
    } else {
      throw Exception('Failed to fetch student PDFs: ${response.statusCode}');
    }
  }

  static Future<bool> deletePdf(int pdfId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final baseUrl = await _getBaseUrl();
      final token = prefs.getString('token') ?? '';

      final uri = Uri.parse('$baseUrl/teachers/pdfs/$pdfId');
      final response = await http.delete(
        uri,
        headers: _authHeaders(token),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print("Failed to delete PDF: ${response.statusCode}");
        print("Server response: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Exception during delete: $e");
      return false;
    }
  }
}