import 'package:dio/dio.dart';
import 'package:esimtel/views/notificationModule/model/NotificationResponse.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:esimtel/core/bloc/api_bloc.dart';
import 'package:esimtel/core/bloc/api_state.dart';
import 'package:esimtel/utills/api_end_points.dart';
import 'package:esimtel/utills/services/ApiService.dart';
import 'noti_event.dart';

class FetchNotificationbloc
    extends
        ApiBloc<
          fetchNotiEvent,
          ApiState<NotificationResponse>,
          NotificationResponse
        > {
  final ApiService apiService;

  FetchNotificationbloc(this.apiService) : super(ApiInitial()) {
    on<fetchNotiEvent>(_onfetchnotiDetails);
  }

  Future<void> _onfetchnotiDetails(
    fetchNotiEvent event,
    Emitter<ApiState<NotificationResponse>> emit,
  ) async {
    emit(loadingState());
    try {
      final result = await executeApiCall(event);
      emit(successState(result));
    } catch (e) {
      emit(errorState(e.toString()));
    }
  }

  @override
  Future<NotificationResponse> executeApiCall(fetchNotiEvent event) async {
    try {
      final url = event.url ?? ApiEndPoints.NOTIFICATION;
      final response = await apiService.get(
        url,
        query: {"is_read": event.isAllread, 'per_page': '10'},
      );
      return NotificationResponse.fromJson(response);
    } on DioException catch (e) {
      throw e.message ?? 'Failed to fetch NOTIFICATIONList';
    } catch (e) {
      throw 'Unknown error occurred ${e.toString()}';
    }
  }

  @override
  ApiState<NotificationResponse> loadingState() => ApiLoading();

  @override
  ApiState<NotificationResponse> successState(NotificationResponse response) =>
      ApiSuccess(response);

  @override
  ApiState<NotificationResponse> errorState(String error) => ApiFailure(error);
}
