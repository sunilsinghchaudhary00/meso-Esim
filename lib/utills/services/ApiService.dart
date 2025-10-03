import 'dart:convert';
import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:esimtel/utills/config.dart';

class ApiService {
  final Dio _dio;
  ApiService()
    : _dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 90),
          receiveTimeout: const Duration(seconds: 90),
          headers: {'Content-Type': 'application/json'},
        ),
      ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final prefs = await SharedPreferences.getInstance();
          final userData = prefs.getString('UserProfileData');
          if (userData != null) {
            try {
              final userMap = jsonDecode(userData);
              final token = userMap['data']['token'];
              log('token from shared pref: $token');
              if (token != null) {
                options.headers['Authorization'] = 'Bearer $token';
              }
            } catch (e) {
              log("Error decoding user data: $e");
            }
          }
          return handler.next(options);
        },
        onError: (error, handler) {
          if (error.response?.statusCode == 401) {
            log('eror apicall 401 check in apiservices ${error.message}');
          }
          return handler.next(error);
        },
      ),
    );
  }

  Future<dynamic> post(String endpoint, {dynamic data}) async {
    try {
      final response = await _dio.post(endpoint, data: data);
      return response.data;
    } on DioException catch (e) {
      print('post error in api service ${e.message}');
      print('post error in api 2 ${e.error}');

      if (e.response != null) {
        if (e.response!.data['success'] == false) {
          final message = e.response!.data['message'] ?? 'Something went wrong';
          throw DioException(
            requestOptions: e.response!.requestOptions,
            response: e.response,
            type: DioExceptionType.badResponse,
            error: message,
          );
        }
      }
      log('DioException response ->  $e');
      rethrow;
    }
  }

  Future<dynamic> get(String endpoint, {Map<String, dynamic>? query}) async {
    try {
      log(
        'get method endpoinsts are $baseUrl$endpoint endpoint and query is $query',
      );
      // Build full URL with query parameters
      final fullUrl = Uri.parse(
        baseUrl + endpoint,
      ).replace(queryParameters: query).toString();
      log('Full URL: $fullUrl');
      final response = await _dio.get(endpoint, queryParameters: query);

      return response.data;
    } on DioException catch (e) {
      log(
        'get method error ${e.message} and code is ${e.response?.statusCode} and data is ${e.response?.data}',
      );
      if (e.response != null) {
        if (e.response!.data['success'] == false) {
          final message = e.response!.data['message'] ?? 'Something went wrong';
          throw DioException(
            requestOptions: e.response!.requestOptions,
            response: e.response,
            type: DioExceptionType.badResponse,
            error: message,
          );
        }
      }
      log('DioException response ->  $e');
      rethrow;
    }
  }
}
