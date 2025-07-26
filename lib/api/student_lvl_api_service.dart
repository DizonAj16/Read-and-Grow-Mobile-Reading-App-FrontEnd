import 'dart:convert';

import 'package:http/http.dart' as http;

Future<void> fetchActivities(String token) async {
  final response = await http.get(
    Uri.parse('http://<your-ip>:8000/api/activities'),
    headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    print('Activities: $data');
  } else {
    print('Error ${response.statusCode}: ${response.body}');
  }
}
