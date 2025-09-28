import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/material_model.dart'; // Updated model name

class MaterialService {
  static Future<String> _getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('base_url') ?? "http://10.0.2.2:8000/api";
  }

  static Map<String, String> _authHeaders(String token) => {
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
  };

static Future<bool> uploadMaterialFile({
  required File file,
  required String materialTitle,
  required String classroomId,
  String? materialType,
  String? description, // Added description parameter
}) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final baseUrl = await _getBaseUrl();
    final token = prefs.getString('token') ?? '';
    final uri = Uri.parse('$baseUrl/teachers/materials');

    final request = http.MultipartRequest('POST', uri);
    request.headers.addAll(_authHeaders(token));

    // Add the file
    request.files.add(await http.MultipartFile.fromPath(
      'material_file', 
      file.path
    ));
    
    // Add form fields
    request.fields['material_title'] = materialTitle;
    request.fields['class_room_id'] = classroomId.toString();
    
    // Add material type if provided
    if (materialType != null) {
      request.fields['material_type'] = materialType;
    }
    
    // Add description if provided
    if (description != null && description.isNotEmpty) {
      request.fields['description'] = description;
    }

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

  static Future<List<MaterialModel>> getClassroomMaterials(String classId) async {
    final prefs = await SharedPreferences.getInstance();
    final baseUrl = await _getBaseUrl();
    final token = prefs.getString('token') ?? '';

    final response = await http.get(
      Uri.parse('$baseUrl/teachers/materials/$classId'),
      headers: _authHeaders(token),
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map<MaterialModel>((item) {
        final rawPath = item['material_file_url'] ?? item['material_file_path'] ?? '';
        final correctedUrl = rawPath.startsWith('http') 
          ? rawPath 
          : '$baseUrl/storage/$rawPath';
        
        return MaterialModel.fromJson({
          ...item,
          'material_file_url': correctedUrl
        });
      }).toList();
    } else {
      throw Exception('Failed to fetch materials list: ${response.statusCode}');
    }
  }

  static Future<List<MaterialModel>> fetchStudentMaterials() async {
    final prefs = await SharedPreferences.getInstance();
    final baseUrl = await _getBaseUrl();
    final token = prefs.getString('token') ?? '';

    final response = await http.get(
      Uri.parse('$baseUrl/students/materials'), // Update this route if needed
      headers: _authHeaders(token),
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map<MaterialModel>((item) {
        final rawPath = item['material_file_url'] ?? item['material_file_path'] ?? '';
        final correctedUrl = rawPath.startsWith('http') 
          ? rawPath 
          : '$baseUrl/storage/$rawPath';
        
        return MaterialModel.fromJson({
          ...item,
          'material_file_url': correctedUrl
        });
      }).toList();
    } else {
      throw Exception('Failed to fetch student materials: ${response.statusCode}');
    }
  }

  static Future<bool> deleteMaterial(int materialId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final baseUrl = await _getBaseUrl();
      final token = prefs.getString('token') ?? '';

      final uri = Uri.parse('$baseUrl/teachers/materials/$materialId');
      final response = await http.delete(
        uri,
        headers: _authHeaders(token),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print("Failed to delete material: ${response.statusCode}");
        print("Server response: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Exception during delete: $e");
      return false;
    }
  }

  // Optional: Get materials filtered by type
  static Future<List<MaterialModel>> getMaterialsByType(int classId, String type) async {
    final prefs = await SharedPreferences.getInstance();
    final baseUrl = await _getBaseUrl();
    final token = prefs.getString('token') ?? '';

    final response = await http.get(
      Uri.parse('$baseUrl/teachers/materials/$classId/type/$type'),
      headers: _authHeaders(token),
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map<MaterialModel>((item) {
        final rawPath = item['material_file_url'] ?? item['material_file_path'] ?? '';
        final correctedUrl = rawPath.startsWith('http') 
          ? rawPath 
          : '$baseUrl/storage/$rawPath';
        
        return MaterialModel.fromJson({
          ...item,
          'material_file_url': correctedUrl
        });
      }).toList();
    } else {
      throw Exception('Failed to fetch materials by type: ${response.statusCode}');
    }
  }
}