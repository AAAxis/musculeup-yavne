import 'package:equatable/equatable.dart';

class LanguageState extends Equatable {
  final String language;

  const LanguageState({required this.language});

  bool get isEnglish => language == 'en';
  bool get isHebrew => language == 'he';

  @override
  List<Object> get props => [language];
}

