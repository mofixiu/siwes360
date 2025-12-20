import 'dart:developer';
import 'dart:convert' as dart_convert;
import 'dart:io' show Platform, File;
import 'package:dio/dio.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http_parser/http_parser.dart';

// Platform-specific host configuration
String get host {
  if (kIsWeb) {
    return "http://localhost:3001";
  } else if (Platform.isAndroid) {
    return "http://10.0.2.2:3001";
    // return "http://192.168.1.XXX:3001"; // For physical device
  } else if (Platform.isIOS) {
    return "http://localhost:3001";
  } else {
    return "http://localhost:3001";
  }
}

String get baseUrl => "$host/api";

class RequestService {
  static late Dio _dio;
  static String? _authToken;
  static bool _isInitialized = false;

  // Initialize RequestService with Dio setup
  static Future<void> initialize() async {
    if (_isInitialized) {
      log('RequestService already initialized');
      return;
    }

    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );

    // Load token first before setting up interceptors
    await loadAuthToken();

    // Add interceptors for auth token
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Get fresh token from storage before each request
          if (_authToken == null) {
            await loadAuthToken();
          }

          if (_authToken != null) {
            options.headers['Authorization'] = 'Bearer $_authToken';
          }
          log('REQUEST: ${options.method} ${options.uri}');
          log('DATA: ${options.data}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          log(
            'RESPONSE: ${response.statusCode} ${response.requestOptions.uri}',
          );
          log('RESPONSE DATA: ${response.data}');
          return handler.next(response);
        },
        onError: (error, handler) {
          log('ERROR: ${error.message}');
          if (error.response != null) {
            log('ERROR RESPONSE: ${error.response?.data}');
          }
          handler.next(error);
        },
      ),
    );

    _isInitialized = true;
    log('RequestService initialized successfully');
  }

  // Load auth token from storage
  static Future<void> loadAuthToken() async {
    try {
      final box = await Hive.openBox(
        'auth',
      ); // Changed from 'userBox' to 'auth'
      final token = box.get('token'); // Changed from 'auth_token' to 'token'
      if (token != null) {
        _authToken = token;
        log('Auth token loaded from storage');
      } else {
        log('No auth token found in storage');
      }
    } catch (e) {
      log('Error loading auth token: $e');
    }
  }

  // Get current auth token
  static String? get authToken => _authToken;

  // Check if service is initialized
  static bool get isInitialized => _isInitialized;

  // Auth Methods
  static Future<Map<String, dynamic>?> login(
    String email,
    String password,
  ) async {
    return post('/auth/login', {'email': email, 'password': password});
  }

  static Future<Map<String, dynamic>?> register(
    Map<String, dynamic> userData,
  ) async {
    return post('/auth/register', userData);
  }

  static Future<Map<String, dynamic>?> getProfile() async {
    return get('/auth/profile');
  }

  // Student Methods
  static Future<Map<String, dynamic>?> getStudentProfile(int studentId) async {
    return get('/students/$studentId');
  }

  static Future<Map<String, dynamic>?> updateStudentProfile(
    int studentId,
    Map<String, dynamic> profileData,
  ) async {
    return put('/students/$studentId', profileData);
  }

  static Future<Map<String, dynamic>?> updateStudentInternshipDates(
    int studentId,
    String startDate,
    String endDate, {
    String? workplaceName,
    String? workplaceAddress,
    String? workplaceLocation,
    int? supervisorId,
    String? supervisorName,
    String? supervisorPhone,
    String? supervisorEmail,
  }) async {
    final data = {
      'internship_start_date': startDate,
      'internship_end_date': endDate,
      if (workplaceName != null) 'workplace_name': workplaceName,
      if (workplaceAddress != null) 'workplace_address': workplaceAddress,
      if (workplaceLocation != null) 'workplace_location': workplaceLocation,
      if (supervisorId != null) 'supervisor_id': supervisorId,
      if (supervisorName != null) 'supervisor_name': supervisorName,
      if (supervisorPhone != null) 'supervisor_phone': supervisorPhone,
      if (supervisorEmail != null) 'supervisor_email': supervisorEmail,
    };

    return patch('/students/$studentId/internship-dates', data);
  }

  static Future<Map<String, dynamic>?> getStudentDetails(int studentId) async {
    return get('/students/$studentId');
  }

  static Future<Map<String, dynamic>?> getStudentDashboardData(
    int studentId,
  ) async {
    return get('/students/$studentId/dashboard');
  }

  static Future<Map<String, dynamic>?> searchSupervisors(String query) async {
    return get('/students/search/supervisors?query=$query');
  }

  // Daily Log Methods
  static Future<Map<String, dynamic>?> getAllDailyLogs(int studentId) async {
    return get('/logs/student/$studentId');
  }

  static Future<Map<String, dynamic>?> getDailyLogById(int logId) async {
    return get('/logs/$logId');
  }

  static Future<Map<String, dynamic>?> createDailyLog(
    Map<String, dynamic> logData, {
    List<File>? attachments,
  }) async {
    try {
      if (!isInitialized) {
        throw Exception('RequestService not initialized');
      }

      // Create FormData with explicit boundary
      Map<String, dynamic> formFields = {};

      // Ensure all fields are strings
      logData.forEach((key, value) {
        if (value != null) {
          formFields[key] = value.toString();
        }
      });

      FormData formData = FormData.fromMap(formFields);

      // Add file attachments if any
      if (attachments != null && attachments.isNotEmpty) {
        log('Processing ${attachments.length} attachments');

        for (int i = 0; i < attachments.length; i++) {
          var file = attachments[i];
          String fileName = file.path.split('/').last;
          String fileExtension = fileName.split('.').last.toLowerCase();

          log('Processing file $i: $fileName (${await file.length()} bytes)');

          // Determine MIME type
          String mimeType = 'application/octet-stream';
          if (['jpg', 'jpeg'].contains(fileExtension)) {
            mimeType = 'image/jpeg';
          } else if (fileExtension == 'png') {
            mimeType = 'image/png';
          } else if (fileExtension == 'pdf') {
            mimeType = 'application/pdf';
          } else if (fileExtension == 'docx') {
            mimeType =
                'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
          } else if (fileExtension == 'doc') {
            mimeType = 'application/msword';
          } else if (fileExtension == 'xlsx') {
            mimeType =
                'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
          } else if (fileExtension == 'xls') {
            mimeType = 'application/vnd.ms-excel';
          }

          // Read file as bytes
          final bytes = await file.readAsBytes();
          log('Read ${bytes.length} bytes from file');

          // Add to FormData using MultipartFile.fromBytes
          formData.files.add(
            MapEntry(
              'attachments',
              MultipartFile.fromBytes(
                bytes,
                filename: fileName,
                contentType: MediaType.parse(mimeType),
              ),
            ),
          );

          log('Added file to FormData: $fileName');
        }
      }

      log('Creating daily log with ${formData.files.length} attachments');
      log('Form fields: ${formFields.keys.join(", ")}');

      // Make request with explicit headers
      final response = await _dio.post(
        '/logs',
        data: formData,
        options: Options(
          headers: {'Accept': 'application/json'},
          contentType: 'multipart/form-data',
          validateStatus: (status) {
            // Accept all status codes to handle errors gracefully
            return status != null && status < 600;
          },
          sendTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 60),
        ),
      );

      log('Daily log response status: ${response.statusCode}');
      log('Daily log response: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data is Map<String, dynamic>) {
          return response.data as Map<String, dynamic>;
        }
        return {'status': 'success', 'data': response.data};
      } else {
        // Handle error responses
        String errorMessage = 'Failed to create log';
        if (response.data is Map && response.data['message'] != null) {
          errorMessage = response.data['message'];
        }
        return {'status': 'error', 'message': errorMessage};
      }
    } catch (e, stackTrace) {
      log('Create daily log error: $e');
      log('Stack trace: $stackTrace');
      return {
        'status': 'error',
        'message': 'Failed to create log: ${e.toString()}',
      };
    }
  }

  static Future<Map<String, dynamic>?> getStudentDailyLogs(
    int studentId,
  ) async {
    return get('/logs/student/$studentId');
  }

  static Future<Map<String, dynamic>?> approveDailyLog(
    int logId,
    String comment,
  ) async {
    return put('/logs/$logId/approve', {'supervisor_comment': comment});
  }

  static Future<Map<String, dynamic>?> rejectDailyLog(
    int logId,
    String comment,
  ) async {
    return put('/logs/$logId/reject', {'supervisor_comment': comment});
  }

  static Future<Map<String, dynamic>?> updateDailyLog(
    int logId,
    Map<String, dynamic> data,
  ) async {
    return patch('/logs/$logId', data);
  }

  static Future<Map<String, dynamic>?> deleteDailyLog(int logId) async {
    return delete('/logs/$logId');
  }

  // Notification Methods
  static Future<Map<String, dynamic>?> getNotifications(int userId) async {
    return get('/notifications/user/$userId');
  }

  static Future<Map<String, dynamic>?> markNotificationAsRead(
    int notificationId,
  ) async {
    return put('/notifications/$notificationId/read', {});
  }

  static Future<Map<String, dynamic>?> markAllNotificationsAsRead(
    int userId,
  ) async {
    return put('/notifications/user/$userId/read-all', {});
  }

  static Future<Map<String, dynamic>?> deleteNotification(
    int notificationId,
  ) async {
    return delete('/notifications/$notificationId');
  }

  // Supervisor Methods
  static Future<Map<String, dynamic>?> getSupervisorStudents(
    int supervisorId,
  ) async {
    return get('/supervisors/$supervisorId/students');
  }

  static Future<Map<String, dynamic>?> getSupervisorDashboardData(
    int supervisorId,
  ) async {
    return get('/supervisors/$supervisorId/dashboard');
  }

  // Update supervisor profile
  static Future<Map<String, dynamic>?> updateSupervisorProfile(
    int supervisorId,
    Map<String, dynamic> profileData,
  ) async {
    // Update both user and supervisor tables
    final userUpdateData = {
      'full_name': profileData['full_name'],
      'email': profileData['email'],
      'phone': profileData['phone'],
    };

    final supervisorUpdateData = {
      'organization': profileData['organization'],
      'position': profileData['position'],
    };

    // Update user table first
    await put('/users/$supervisorId', userUpdateData);

    // Then update supervisor table
    return patch('/supervisors/$supervisorId', supervisorUpdateData);
  }

  // Password Reset Methods
  static Future<Map<String, dynamic>?> forgotPassword(String email) async {
    return post('/auth/forgot-password', {'email': email});
  }

  static Future<Map<String, dynamic>?> verifyResetOTP(
    String email,
    String otp,
  ) async {
    return post('/auth/verify-reset-otp', {'email': email, 'otp': otp});
  }

  static Future<Map<String, dynamic>?> resetPassword(
    String resetToken,
    String newPassword,
  ) async {
    return post('/auth/reset-password', {
      'reset_token': resetToken,
      'new_password': newPassword,
    });
  }

  // Generic HTTP Methods
  static Future<Map<String, dynamic>?> post(
    String path,
    Map<String, dynamic> data,
  ) async {
    if (!_isInitialized) {
      initialize();
    }

    try {
      log('Making POST request to: $path');
      final response = await _dio.post(path, data: data);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data is Map<String, dynamic>) {
          return response.data as Map<String, dynamic>;
        } else if (response.data is String) {
          try {
            final Map<String, dynamic> parsed = Map<String, dynamic>.from(
              dart_convert.jsonDecode(response.data),
            );
            return parsed;
          } catch (e) {
            log('Failed to parse string response as JSON: $e');
            return {
              'status': 'error',
              'message': 'Invalid response format',
              'data': response.data,
            };
          }
        } else {
          return {'status': 'success', 'data': response.data};
        }
      }

      return {
        'status': 'error',
        'message': 'Request failed with status: ${response.statusCode}',
      };
    } on DioException catch (e) {
      log('DioException: ${e.message}');
      if (e.response != null) {
        log('Error response: ${e.response!.data}');
        return {
          'status': 'error',
          'message': e.response!.data['message'] ?? 'Request failed',
          'data': e.response!.data,
        };
      }
      return {'status': 'error', 'message': 'Network error: ${e.message}'};
    } catch (e) {
      log('General error: $e');
      return {'status': 'error', 'message': 'Unexpected error: $e'};
    }
  }

  static Future<Map<String, dynamic>?> get(String path) async {
    if (!_isInitialized) {
      initialize();
    }

    try {
      final response = await _dio.get(path);

      if (response.statusCode == 200) {
        if (response.data is Map<String, dynamic>) {
          return response.data as Map<String, dynamic>;
        }
      }

      return {
        'status': 'error',
        'message': 'Request failed with status: ${response.statusCode}',
      };
    } on DioException catch (e) {
      log('DioException: ${e.message}');
      if (e.response != null) {
        log('Error response: ${e.response!.data}');
        return {
          'status': 'error',
          'message': e.response!.data['message'] ?? 'Request failed',
          'data': e.response!.data,
        };
      }
      return {'status': 'error', 'message': 'Network error: ${e.message}'};
    } catch (e) {
      log('General error: $e');
      return {'status': 'error', 'message': 'Unexpected error: $e'};
    }
  }

  static Future<Map<String, dynamic>?> patch(
    String path,
    Map<String, dynamic> data,
  ) async {
    if (!_isInitialized) {
      initialize();
    }

    try {
      log('Making PATCH request to: $path');
      final response = await _dio.patch(path, data: data);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data is Map<String, dynamic>) {
          return response.data as Map<String, dynamic>;
        }
      }

      return {
        'status': 'error',
        'message': 'Request failed with status: ${response.statusCode}',
      };
    } on DioException catch (e) {
      log('PATCH DioException: ${e.message}');
      if (e.response != null) {
        log('Error response: ${e.response!.data}');
        return {
          'status': 'error',
          'message': e.response!.data['message'] ?? 'Request failed',
          'data': e.response!.data,
        };
      }
      return {'status': 'error', 'message': 'Network error: ${e.message}'};
    } catch (e) {
      log('PATCH General error: $e');
      return {'status': 'error', 'message': 'Unexpected error: $e'};
    }
  }

  static Future<Map<String, dynamic>?> put(
    String path,
    Map<String, dynamic> data,
  ) async {
    if (!_isInitialized) {
      initialize();
    }

    try {
      log('Making PUT request to: $path');
      log('PUT data: $data');

      final response = await _dio.put(path, data: data);

      if (response.statusCode == 200 || response.statusCode == 201) {
        log('PUT response: ${response.data}');
        if (response.data is Map<String, dynamic>) {
          return response.data as Map<String, dynamic>;
        }
        return {'status': 'success', 'data': response.data};
      }

      return {
        'status': 'error',
        'message': 'Request failed with status: ${response.statusCode}',
      };
    } on DioException catch (e) {
      log('PUT DioException: ${e.message}');
      if (e.response != null) {
        log('PUT Error response: ${e.response!.data}');
        return {
          'status': 'error',
          'message': e.response!.data['message'] ?? 'Request failed',
          'data': e.response!.data,
        };
      }
      return {'status': 'error', 'message': 'Network error: ${e.message}'};
    } catch (e) {
      log('PUT General error: $e');
      return {'status': 'error', 'message': 'Unexpected error: $e'};
    }
  }

  static Future<Map<String, dynamic>?> delete(String path) async {
    try {
      if (!isInitialized) {
        throw Exception('RequestService not initialized');
      }

      log('DELETE Request to: $baseUrl$path');
      final response = await _dio.delete(path);

      log('DELETE Response: ${response.data}');
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      return {'status': 'success', 'data': response.data};
    } catch (e) {
      log('DELETE Error: $e');
      return {'status': 'error', 'message': 'Delete failed: $e'};
    }
  }

  // Auth token management
  static Future<void> saveAuthToken(String token) async {
    try {
      _authToken = token;
      final box = await Hive.openBox('auth');
      await box.put('token', token);
      log('Auth token saved');
    } catch (e) {
      log('Error saving auth token: $e');
    }
  }

  // User data management
  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    try {
      final box = await Hive.openBox('user');
      await box.put('userData', dart_convert.jsonEncode(userData));
      log('User data saved');
    } catch (e) {
      log('Error saving user data: $e');
    }
  }

  static Future<Map<String, dynamic>?> loadUserData() async {
    try {
      final box = await Hive.openBox('user');
      final userDataString = box.get('userData');
      if (userDataString != null) {
        log('User data loaded from storage');
        return dart_convert.jsonDecode(userDataString);
      }
      log('No user data found in storage');
      return null;
    } catch (e) {
      log('Error loading user data: $e');
      return null;
    }
  }

  static Future<void> clearUserData() async {
    try {
      // Clear both auth and user boxes
      final authBox = await Hive.openBox('auth');
      await authBox.clear();

      final userBox = await Hive.openBox('user');
      await userBox.clear();

      _authToken = null;
      log('User data cleared');
    } catch (e) {
      log('Error clearing user data: $e');
    }
  }

  static Future<void> clearAllData() async {
    try {
      await clearUserData();
      log('All data cleared');
    } catch (e) {
      log('Error clearing all data: $e');
    }
  }

  // Get student by ID (for fetching internship dates)
  static Future<Map<String, dynamic>?> getStudentById(int studentId) async {
    return get('/students/$studentId');
  }

  // Get supervisor by ID (for fetching supervisor profile)
  static Future<Map<String, dynamic>?> getSupervisorById(
    int supervisorId,
  ) async {
    return get('/supervisors/$supervisorId');
  }
}
