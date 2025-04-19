// This file provides integration with the Bloc state management library.
// Note: To use this integration, you need to add the 'flutter_bloc' package to your dependencies.

import '../flux_query_client.dart';

/// A mixin for Blocs that use FluxQueryClient
///
/// Example usage:
/// ```dart
/// // Define a Bloc that uses FluxQueryClient
/// class UserBloc extends Bloc<UserEvent, UserState> with QueryClientMixin {
///   UserBloc(this.queryClient) : super(UserInitial()) {
///     on<UserFetchRequested>(_onUserFetchRequested);
///   }
///
///   @override
///   final FluxQueryClient queryClient;
///
///   Future<void> _onUserFetchRequested(
///     UserFetchRequested event,
///     Emitter<UserState> emit,
///   ) async {
///     emit(UserLoading());
///
///     try {
///       final result = await queryClient.query<User>(
///         key: 'user-${event.userId}',
///         fetcher: () => fetchUser(event.userId),
///       );
///
///       emit(UserLoaded(result.data!));
///     } catch (e) {
///       emit(UserError(e.toString()));
///     }
///   }
/// }
/// ```
///
/// This is a placeholder file to show the intended API.
/// For a full implementation, you would need to add the following imports:
/// ```dart
/// import 'package:flutter_bloc/flutter_bloc.dart';
/// import '../query_client.dart';
/// ```
abstract class FluxQueryClientMixin {
  /// The FluxQueryClient instance to use
  FluxQueryClient get queryClient;
}
