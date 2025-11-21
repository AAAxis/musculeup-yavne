import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muscleup/data/services/language_service.dart';
import 'package:muscleup/presentation/language/bloc/language_event.dart';
import 'package:muscleup/presentation/language/bloc/language_state.dart';

class LanguageBloc extends Bloc<LanguageEvent, LanguageState> {
  final LanguageService _languageService;

  LanguageBloc({required LanguageService languageService})
      : _languageService = languageService,
        super(const LanguageState(language: 'he')) {
    on<LanguageLoadRequested>(_onLanguageLoadRequested);
    on<LanguageChanged>(_onLanguageChanged);
    
    // Load language on initialization
    add(const LanguageLoadRequested());
  }

  Future<void> _onLanguageLoadRequested(
    LanguageLoadRequested event,
    Emitter<LanguageState> emit,
  ) async {
    try {
      final language = await _languageService.getLanguage();
      emit(LanguageState(language: language ?? 'he'));
    } catch (e) {
      emit(const LanguageState(language: 'he'));
    }
  }

  Future<void> _onLanguageChanged(
    LanguageChanged event,
    Emitter<LanguageState> emit,
  ) async {
    try {
      await _languageService.setLanguage(event.language);
      emit(LanguageState(language: event.language));
    } catch (e) {
      // If save fails, still emit the new state
      emit(LanguageState(language: event.language));
    }
  }
}

