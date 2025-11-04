import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Safe database query helpers to prevent null errors and handle edge cases

class DatabaseHelpers {
  /// Safely get a single record, returning null if not found
  static Future<Map<String, dynamic>?> safeGetSingle({
    required SupabaseClient supabase,
    required String table,
    String? id,
    Map<String, dynamic>? filters,
  }) async {
    try {
      var query = supabase.from(table).select();
      
      if (id != null) {
        query = query.eq('id', id);
      }
      
      if (filters != null) {
        filters.forEach((key, value) {
          if (value != null) {
            query = query.eq(key, value);
          }
        });
      }
      
      final result = await query.maybeSingle();
      return result != null ? Map<String, dynamic>.from(result) : null;
    } catch (e) {
      debugPrint('Error in safeGetSingle: $e');
      return null;
    }
  }

  /// Safely get multiple records with error handling
  static Future<List<Map<String, dynamic>>> safeGetList({
    required SupabaseClient supabase,
    required String table,
    Map<String, dynamic>? filters,
    String? orderBy,
    bool ascending = true,
    int? limit,
  }) async {
    try {
      dynamic query = supabase.from(table).select();
      
      if (filters != null) {
        for (final entry in filters.entries) {
          if (entry.value != null) {
            query = query.eq(entry.key, entry.value);
          }
        }
      }
      
      if (orderBy != null) {
        if (ascending) {
          query = query.order(orderBy);
        } else {
          query = query.order(orderBy, ascending: false);
        }
      }
      
      if (limit != null) {
        query = query.limit(limit);
      }
      
      final result = await query;
      return (result as List<dynamic>)
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    } catch (e) {
      debugPrint('Error in safeGetList: $e');
      return [];
    }
  }

  /// Safely insert a record with validation
  static Future<Map<String, dynamic>?> safeInsert({
    required SupabaseClient supabase,
    required String table,
    required Map<String, dynamic> data,
    bool returnRecord = true,
  }) async {
    try {
      // Remove null values to prevent database errors
      final cleanData = Map<String, dynamic>.from(
        data..removeWhere((key, value) => value == null),
      );
      
      dynamic query = supabase.from(table).insert(cleanData);
      
      if (returnRecord) {
        query = query.select();
      }
      
      final result = returnRecord
          ? await query.maybeSingle()
          : await query;
      
      return result != null ? Map<String, dynamic>.from(result) : null;
    } on PostgrestException catch (e) {
      debugPrint('Database error in safeInsert: ${e.message}');
      return {'error': e.message};
    } catch (e) {
      debugPrint('Error in safeInsert: $e');
      return {'error': e.toString()};
    }
  }

  /// Safely update a record with validation
  static Future<bool> safeUpdate({
    required SupabaseClient supabase,
    required String table,
    required String id,
    required Map<String, dynamic> data,
  }) async {
    try {
      // Remove null values and add updated_at timestamp
      final cleanData = Map<String, dynamic>.from(
        data..removeWhere((key, value) => value == null),
      );
      
      if (cleanData.isEmpty) {
        debugPrint('No data to update');
        return false;
      }
      
      // Add updated_at if the table has this column
      cleanData['updated_at'] = DateTime.now().toIso8601String();
      
      await supabase.from(table).update(cleanData).eq('id', id);
      return true;
    } on PostgrestException catch (e) {
      debugPrint('Database error in safeUpdate: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Error in safeUpdate: $e');
      return false;
    }
  }

  /// Safely delete a record
  static Future<bool> safeDelete({
    required SupabaseClient supabase,
    required String table,
    required String id,
  }) async {
    try {
      await supabase.from(table).delete().eq('id', id);
      return true;
    } on PostgrestException catch (e) {
      debugPrint('Database error in safeDelete: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Error in safeDelete: $e');
      return false;
    }
  }

  /// Check if a record exists
  static Future<bool> safeExists({
    required SupabaseClient supabase,
    required String table,
    required Map<String, dynamic> filters,
  }) async {
    try {
      dynamic query = supabase.from(table).select('id');
      
      for (final entry in filters.entries) {
        if (entry.value != null) {
          query = query.eq(entry.key, entry.value);
        }
      }
      
      query = query.limit(1);
      final result = await query.maybeSingle();
      return result != null;
    } catch (e) {
      debugPrint('Error in safeExists: $e');
      return false;
    }
  }

  /// Safely get numeric value from result with null handling
  static int safeIntFromResult(dynamic result, String key, {int defaultValue = 0}) {
    if (result == null) return defaultValue;
    final value = result[key];
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  /// Safely get double value from result with null handling
  static double safeDoubleFromResult(dynamic result, String key, {double defaultValue = 0.0}) {
    if (result == null) return defaultValue;
    final value = result[key];
    if (value == null) return defaultValue;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  /// Safely get string value from result with null handling
  static String safeStringFromResult(dynamic result, String key, {String defaultValue = ''}) {
    if (result == null) return defaultValue;
    final value = result[key];
    if (value == null) return defaultValue;
    return value.toString().trim();
  }

  /// Safely get boolean value from result with null handling
  static bool safeBoolFromResult(dynamic result, String key, {bool defaultValue = false}) {
    if (result == null) return defaultValue;
    final value = result[key];
    if (value == null) return defaultValue;
    if (value is bool) return value;
    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1';
    }
    if (value is num) return value != 0;
    return defaultValue;
  }

  /// Safely get date value from result with null handling
  static DateTime? safeDateFromResult(dynamic result, String key) {
    if (result == null) return null;
    final value = result[key];
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        debugPrint('Error parsing date: $e');
        return null;
      }
    }
    return null;
  }
}

