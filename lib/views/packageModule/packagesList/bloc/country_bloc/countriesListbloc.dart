import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:esimtel/utills/connectivity/connectivity_bloc.dart';
import 'package:esimtel/views/packageModule/packagesList/model/countryListModel.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:esimtel/core/bloc/api_bloc.dart';
import 'package:esimtel/core/bloc/api_state.dart';
import 'package:esimtel/utills/api_end_points.dart';
import 'package:esimtel/utills/services/ApiService.dart';
import 'package:esimtel/views/packageModule/packagesList/bloc/country_bloc/country_event.dart';

class CountryBloc
    extends
        ApiBloc<CountryEvent, ApiState<CountryListModel>, CountryListModel> {
  final ApiService apiService;
  final ConnectivityBloc _connectivityBloc;
  late StreamSubscription connectivitySubscription;
  CountryBloc(this.apiService, this._connectivityBloc) : super(ApiInitial()) {
    on<CountryEvent>(_onFetchCountries);

    connectivitySubscription = _connectivityBloc.stream.listen((state) {
      if (state is Connected) {
        add(CountryEvent());
      }
    });
  }

  Future<void> _onFetchCountries(
    CountryEvent event,
    Emitter<ApiState<CountryListModel>> emit,
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
  Future<CountryListModel> executeApiCall(CountryEvent event) async {
    try {
      Map<String, dynamic> parameterbody = {
        'fromApp': Platform.isAndroid ? 'android' : 'ios',
      };
      final response = await apiService.get(
        ApiEndPoints.COUNTRYLIST,
        query: parameterbody,
      );
      return CountryListModel.fromJson(response);
    } on DioException catch (e) {
      throw e.message ?? 'Failed to fetch countries';
    } catch (e) {
      throw 'Unknown error occurred';
    }
  }

  @override
  ApiState<CountryListModel> loadingState() => ApiLoading();

  @override
  ApiState<CountryListModel> successState(CountryListModel response) =>
      ApiSuccess(response);

  @override
  ApiState<CountryListModel> errorState(String error) => ApiFailure(error);
}
