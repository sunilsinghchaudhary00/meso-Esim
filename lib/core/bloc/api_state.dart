import 'package:equatable/equatable.dart';

abstract class ApiState<T> extends Equatable {
  final T? data;
  final String? error;

  const ApiState({this.data, this.error});

  @override
  List<Object?> get props => [data, error];
}

class ApiInitial<T> extends ApiState<T> {
  const ApiInitial() : super();
}

class ApiLoading<T> extends ApiState<T> {
  const ApiLoading() : super();
}

class ApiSuccess<T> extends ApiState<T> {
   @override
  final T data;
  const ApiSuccess(this.data);
  
  @override
  List<Object?> get props => [data]; 
}

class ApiFailure<T> extends ApiState<T> {
  @override
  final String error;
  const ApiFailure(this.error);
  
  @override
  List<Object?> get props => [error]; 
}
