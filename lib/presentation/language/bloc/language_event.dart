import 'package:equatable/equatable.dart';

abstract class LanguageEvent extends Equatable {
  const LanguageEvent();

  @override
  List<Object> get props => [];
}

class LanguageChanged extends LanguageEvent {
  final String language;

  const LanguageChanged(this.language);

  @override
  List<Object> get props => [language];
}

class LanguageLoadRequested extends LanguageEvent {
  const LanguageLoadRequested();
}

