import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static const supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru'),
  ];

  static const localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    _AppLocalizationsDelegate(),
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const _localizedValues = <String, Map<String, String>>{
    'en': {
      'appTitle': 'Family App',
      'homeHubTitle': 'Family App Hub',
      'drawerTitle': 'Family App',
      'languageMenuTitle': 'Language',
      'languageMenuSubtitle': 'Choose interface language',
      'languageEnglish': 'English',
      'languageRussian': 'Russian',
      'feature.members.title': 'Members',
      'feature.members.description':
          'Manage family members and view details',
      'feature.tasks.title': 'Tasks',
      'feature.tasks.description': 'Assign chores and track status',
      'feature.events.title': 'Events',
      'feature.events.description': 'Plan family events and gatherings',
      'feature.calendar.title': 'Calendar',
      'feature.calendar.description':
          'Overview of upcoming events and tasks',
      'feature.schedule.title': 'Schedule',
      'feature.schedule.description': 'Personal schedule and agenda',
      'feature.scoreboard.title': 'Scoreboard',
      'feature.scoreboard.description': 'Gamify tasks with points',
      'feature.gallery.title': 'Gallery',
      'feature.gallery.description': 'Family photos and memories',
      'feature.friends.title': 'Friends',
      'feature.friends.description':
          'Keep track of friends of the family',
      'feature.chats.title': 'Chats',
      'feature.chats.description': 'Group and private conversations',
      'feature.ai.title': 'AI suggestions',
      'feature.ai.description': 'Get ideas from the assistant',
      'feature.calendarFeed.title': 'Calendar feed',
      'feature.calendarFeed.description': 'Latest updates from the calendar',
      'feature.callSetup.title': 'Start a call',
      'feature.callSetup.description': 'Create an audio or video call',
      'feature.cloudCall.title': 'Cloud call',
      'feature.cloudCall.description': 'Join the cloud call lobby',
    },
    'ru': {
      'appTitle': 'Family App',
      'homeHubTitle': 'Центр управления Family App',
      'drawerTitle': 'Family App',
      'languageMenuTitle': 'Язык',
      'languageMenuSubtitle': 'Выберите язык интерфейса',
      'languageEnglish': 'Английский',
      'languageRussian': 'Русский',
      'feature.members.title': 'Участники',
      'feature.members.description':
          'Управляйте членами семьи и просматривайте данные',
      'feature.tasks.title': 'Задачи',
      'feature.tasks.description': 'Назначайте поручения и отслеживайте статус',
      'feature.events.title': 'События',
      'feature.events.description':
          'Планируйте семейные события и встречи',
      'feature.calendar.title': 'Календарь',
      'feature.calendar.description':
          'Обзор предстоящих событий и задач',
      'feature.schedule.title': 'Расписание',
      'feature.schedule.description': 'Личное расписание и дела',
      'feature.scoreboard.title': 'Таблица лидеров',
      'feature.scoreboard.description': 'Геймификация задач с баллами',
      'feature.gallery.title': 'Галерея',
      'feature.gallery.description': 'Семейные фото и воспоминания',
      'feature.friends.title': 'Друзья',
      'feature.friends.description':
          'Следите за друзьями семьи',
      'feature.chats.title': 'Чаты',
      'feature.chats.description': 'Групповые и личные беседы',
      'feature.ai.title': 'AI-подсказки',
      'feature.ai.description': 'Получайте идеи от помощника',
      'feature.calendarFeed.title': 'Лента календаря',
      'feature.calendarFeed.description': 'Последние обновления из календаря',
      'feature.callSetup.title': 'Начать звонок',
      'feature.callSetup.description': 'Создайте аудио- или видеозвонок',
      'feature.cloudCall.title': 'Облачный звонок',
      'feature.cloudCall.description': 'Подключайтесь к общему лобби звонка',
    },
  };

  String t(String key, {Map<String, String>? params}) {
    final languageCode = locale.languageCode;
    final template = _localizedValues[languageCode]?[key] ??
        _localizedValues['en']?[key] ??
        key;
    if (params == null || params.isEmpty) {
      return template;
    }
    var result = template;
    params.forEach((placeholder, value) {
      result = result.replaceAll('{$placeholder}', value);
    });
    return result;
  }

  String languageName(String code) {
    switch (code) {
      case 'ru':
        return t('languageRussian');
      case 'en':
      default:
        return t('languageEnglish');
    }
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales
        .any((supportedLocale) => supportedLocale.languageCode == locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) => false;
}

extension AppLocalizationExtension on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
