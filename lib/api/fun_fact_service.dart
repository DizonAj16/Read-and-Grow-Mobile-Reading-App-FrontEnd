import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class FunFactService {
  static const List<String> _localFacts = [
    "Did you know? A group of flamingos is called a 'flamboyance'! 🦩",
    "Octopuses have three hearts! ❤️❤️❤️",
    "Bananas are berries, but strawberries aren't! 🍌🍓",
    "Elephants can't jump, but they're great swimmers! 🐘",
    "A snail can sleep for three years! 🐌💤",
    "The dot over the 'i' is called a tittle! 🔤",
    "Sloths can hold their breath longer than dolphins! 🦥",
    "Butterflies taste with their feet! 🦋👣",
    "Honey never spoils - archaeologists found 3,000-year-old honey in pyramids! 🍯",
    "Sharks existed before trees did! 🌲🦈",
  ];

  static Future<String> getInstantFact() async {
    final prefs = await SharedPreferences.getInstance();
    final usedIndexes = prefs.getStringList('used_fact_indexes') ?? [];

    final availableIndexes =
        List.generate(
          _localFacts.length,
          (i) => i,
        ).where((i) => !usedIndexes.contains(i.toString())).toList();

    if (availableIndexes.isEmpty) {
      await prefs.remove('used_fact_indexes');
      return _localFacts[0];
    }

    final random = availableIndexes.toList()..shuffle();
    final index = random.first;
    usedIndexes.add(index.toString());

    await prefs.setStringList('used_fact_indexes', usedIndexes);
    return _localFacts[index];
  }

  static Future<String> getRandomFact() async {
    final prefs = await SharedPreferences.getInstance();
    final lastFact = prefs.getString('last_fun_fact');

    try {
      final newFact = await _fetchApiFact();
      if (newFact != null && newFact != lastFact) {
        await _saveFactToPrefs(newFact);
        return newFact;
      }
    } catch (e) {
      debugPrint("API fact fetch error: $e");
    }

    return lastFact ?? _getLocalFact();
  }

  static Future<String?> _fetchApiFact() async {
    try {
      final response = await http
          .get(
            Uri.parse('https://uselessfacts.jsph.pl/random.json?language=en'),
          )
          .timeout(const Duration(seconds: 2));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _sanitizeFact(data['text']);
      }
    } catch (e) {
      debugPrint("API fetch error: $e");
    }
    return null;
  }

  static String _getLocalFact() {
    return _localFacts[Random().nextInt(_localFacts.length)];
  }

  static String _sanitizeFact(String fact) {
    return fact
        .replaceAll(RegExp(r'\[.*?\]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static Future<void> _saveFactToPrefs(String fact) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_fun_fact', fact);
  }
}
