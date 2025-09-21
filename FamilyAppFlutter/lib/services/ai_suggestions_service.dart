import '../models/family_member.dart';

/// Service that generates gift and activity suggestions for family members.
///
/// In a future version this service could integrate with a machine learning
/// model or external API to provide personalized recommendations based on
/// hobbies, upcoming events and past behaviour. For now it returns
/// simple suggestions based on age ranges and hobbies.
class AISuggestionsService {
  /// Suggests gift ideas for [member].
  List<String> suggestGifts(FamilyMember member) {
    final now = DateTime.now();
    final age = member.birthday == null
        ? null
        : now.year - member.birthday!.year -
            ((now.month < member.birthday!.month ||
                    (now.month == member.birthday!.month &&
                        now.day < member.birthday!.day))
                ? 1
                : 0);
    final suggestions = <String>[];
    if (age != null) {
      if (age < 10) {
        suggestions.addAll([
          'Настольная игра с героями из любимого мультика',
          'Конструктор LEGO',
          'Набор для творчества',
        ]);
      } else if (age < 18) {
        suggestions.addAll([
          'Беспроводные наушники',
          'Настольный теннис',
          'Сертификат на мастер‑класс по любимому хобби',
        ]);
      } else {
        suggestions.addAll([
          'Смарт‑гаджет для дома',
          'Абонемент в спортзал',
          'Книга по теме интересов',
        ]);
      }
    }
    // Добавляем предложение на основе увлечений
    if (member.hobbies != null) {
      final hobbies = member.hobbies!.split(',');
      for (final hobby in hobbies) {
        final trimmed = hobby.trim().toLowerCase();
        if (trimmed.isEmpty) continue;
        suggestions.add('Аксессуары для увлечения «${trimmed}»');
      }
    }
    return suggestions;
  }

  /// Suggests activities for the whole family.
  List<String> suggestActivities(List<FamilyMember> members) {
    // Простейшая реализация: возвращает общий набор идей
    return [
      'Совместный поход в парк или на природу',
      'Настольная игра всей семьёй',
      'Вечер кино дома с любимым фильмом',
      'Мастер‑класс по кулинарии',
    ];
  }
}