import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLanguage extends ChangeNotifier {
  static const String _prefKey = 'language';
  String _lang = 'ru';

  String get lang => _lang;

  AppLanguage() {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    _lang = prefs.getString(_prefKey) ?? 'ru';
    notifyListeners();
  }

  Future<void> setLanguage(String lang) async {
    _lang = lang;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, lang);
    notifyListeners();
  }

  String t(String key) {
    return _translations[key]?[_lang] ?? _translations[key]?['en'] ?? key;
  }

  static const Map<String, Map<String, String>> _translations = {
    // App
    'app_name': {'tj': 'Интеллект Арена', 'ru': 'Интеллект Арена', 'en': 'Intellect Arena'},

    // Home
    'play_offline': {'tj': 'Офлайн бозӣ', 'ru': 'Играть офлайн', 'en': 'Play Offline'},
    'play_online': {'tj': 'Онлайн бозӣ', 'ru': 'Играть онлайн', 'en': 'Play Online'},
    'rating': {'tj': 'Рейтинг', 'ru': 'Рейтинг', 'en': 'Rating'},
    'settings': {'tj': 'Танзимот', 'ru': 'Настройки', 'en': 'Settings'},
    'profile': {'tj': 'Профил', 'ru': 'Профиль', 'en': 'Profile'},
    'admin_panel': {'tj': 'Панели Админ', 'ru': 'Панель Админа', 'en': 'Admin Panel'},

    // Auth / Profile
    'enter_name': {'tj': 'Номатонро ворид кунед', 'ru': 'Введите имя', 'en': 'Enter your name'},
    'your_name': {'tj': 'Номи шумо', 'ru': 'Ваше имя', 'en': 'Your name'},
    'save': {'tj': 'Захира кун', 'ru': 'Сохранить', 'en': 'Save'},
    'saved': {'tj': 'Захира шуд!', 'ru': 'Сохранено!', 'en': 'Saved!'},
    'games_played': {'tj': 'Бозиҳо', 'ru': 'Игры', 'en': 'Games'},
    'games_won': {'tj': 'Ғалабаҳо', 'ru': 'Победы', 'en': 'Wins'},
    'total_score': {'tj': 'Умумӣ', 'ru': 'Итого', 'en': 'Total'},

    // Online Menu
    'create_room': {'tj': 'Ҳуҷра эҷод кун', 'ru': 'Создать комнату', 'en': 'Create Room'},
    'join_room': {'tj': 'Ба ҳуҷра дохил шав', 'ru': 'Войти в комнату', 'en': 'Join Room'},
    'enter_code': {'tj': 'Кодро ворид кунед', 'ru': 'Введите код', 'en': 'Enter Code'},
    'room_code': {'tj': 'Коди ҳуҷра', 'ru': 'Код комнаты', 'en': 'Room Code'},
    'join': {'tj': 'Дохил шав', 'ru': 'Войти', 'en': 'Join'},
    'room_not_found': {'tj': 'Ҳуҷра ёфт нашуд', 'ru': 'Комната не найдена', 'en': 'Room not found'},
    'room_already_started': {'tj': 'Бозӣ аллакай оғоз шудааст', 'ru': 'Игра уже началась', 'en': 'Game already started'},

    // Create Room
    'question_source': {'tj': 'Манбаи саволҳо', 'ru': 'Источник вопросов', 'en': 'Question Source'},
    'from_json': {'tj': 'Саволҳои тайёр', 'ru': 'Готовые вопросы', 'en': 'Built-in questions'},
    'from_admin': {'tj': 'Саволҳои ман', 'ru': 'Мои вопросы', 'en': 'My questions'},
    'from_both': {'tj': 'Ҳама саволҳо', 'ru': 'Все вопросы', 'en': 'All questions'},
    'question_count': {'tj': 'Шумораи саволҳо', 'ru': 'Количество вопросов', 'en': 'Number of questions'},
    'time_per_question': {'tj': 'Вақт барои ҳар савол (сония)', 'ru': 'Время на вопрос (сек)', 'en': 'Time per question (sec)'},
    'start_game': {'tj': 'Бозиро оғоз кун', 'ru': 'Начать игру', 'en': 'Start Game'},
    'copy_code': {'tj': 'Кодро нусхабардор кун', 'ru': 'Скопировать код', 'en': 'Copy Code'},
    'code_copied': {'tj': 'Код нусхабардорӣ шуд!', 'ru': 'Код скопирован!', 'en': 'Code copied!'},
    'waiting_for_players': {'tj': 'Интизори бозигарон...', 'ru': 'Ожидание игроков...', 'en': 'Waiting for players...'},
    'players': {'tj': 'Бозигарон', 'ru': 'Игроки', 'en': 'Players'},
    'host': {'tj': 'Мезбон', 'ru': 'Хозяин', 'en': 'Host'},
    'min_players': {'tj': 'Камаш 2 нафар бояд бошад', 'ru': 'Нужно минимум 2 игрока', 'en': 'Need at least 2 players'},

    // Game
    'question': {'tj': 'Савол', 'ru': 'Вопрос', 'en': 'Question'},
    'correct': {'tj': 'Дуруст!', 'ru': 'Правильно!', 'en': 'Correct!'},
    'wrong': {'tj': 'Нодуруст!', 'ru': 'Неправильно!', 'en': 'Wrong!'},
    'time_up': {'tj': 'Вақт тамом шуд!', 'ru': 'Время вышло!', 'en': 'Time\'s up!'},
    'score': {'tj': 'Холҳо', 'ru': 'Очки', 'en': 'Score'},
    'leaderboard': {'tj': 'Рейтинг', 'ru': 'Таблица лидеров', 'en': 'Leaderboard'},
    'next_question': {'tj': 'Саволи навбатӣ', 'ru': 'Следующий вопрос', 'en': 'Next Question'},

    // Winner
    'game_over': {'tj': 'Бозӣ тамом шуд!', 'ru': 'Игра окончена!', 'en': 'Game Over!'},
    'winner': {'tj': 'Ғолиб', 'ru': 'Победитель', 'en': 'Winner'},
    'final_scores': {'tj': 'Натиҷаҳои ниҳоӣ', 'ru': 'Финальные результаты', 'en': 'Final Scores'},
    'play_again': {'tj': 'Боз бозӣ кун', 'ru': 'Играть снова', 'en': 'Play Again'},
    'back_home': {'tj': 'Ба хона', 'ru': 'На главную', 'en': 'Back Home'},

    // Rating
    'global_rating': {'tj': 'Рейтинги умумӣ', 'ru': 'Глобальный рейтинг', 'en': 'Global Rating'},
    'rank': {'tj': 'Ҷой', 'ru': 'Место', 'en': 'Rank'},
    'name': {'tj': 'Ном', 'ru': 'Имя', 'en': 'Name'},
    'points': {'tj': 'Холҳо', 'ru': 'Очки', 'en': 'Points'},
    'wins': {'tj': 'Ғалабаҳо', 'ru': 'Победы', 'en': 'Wins'},

    // Admin
    'add_question': {'tj': 'Савол илова кун', 'ru': 'Добавить вопрос', 'en': 'Add Question'},
    'question_text': {'tj': 'Матни савол', 'ru': 'Текст вопроса', 'en': 'Question text'},
    'answer_options': {'tj': 'Вариантҳои ҷавоб', 'ru': 'Варианты ответа', 'en': 'Answer options'},
    'correct_answer': {'tj': 'Ҷавоби дуруст', 'ru': 'Правильный ответ', 'en': 'Correct answer'},
    'category': {'tj': 'Категория', 'ru': 'Категория', 'en': 'Category'},
    'difficulty': {'tj': 'Мушкилӣ', 'ru': 'Сложность', 'en': 'Difficulty'},
    'easy': {'tj': 'Осон', 'ru': 'Лёгкий', 'en': 'Easy'},
    'medium': {'tj': 'Миёна', 'ru': 'Средний', 'en': 'Medium'},
    'hard': {'tj': 'Душвор', 'ru': 'Сложный', 'en': 'Hard'},
    'delete': {'tj': 'Нест кун', 'ru': 'Удалить', 'en': 'Delete'},
    'edit': {'tj': 'Таҳрир', 'ru': 'Редактировать', 'en': 'Edit'},
    'confirm_delete': {'tj': 'Нест карда шавад?', 'ru': 'Удалить?', 'en': 'Delete?'},
    'yes': {'tj': 'Ҳа', 'ru': 'Да', 'en': 'Yes'},
    'no': {'tj': 'Не', 'ru': 'Нет', 'en': 'No'},
    'questions_list': {'tj': 'Рӯйхати саволҳо', 'ru': 'Список вопросов', 'en': 'Questions List'},
    'no_questions': {'tj': 'Саволе нест', 'ru': 'Вопросов нет', 'en': 'No questions'},

    // Settings
    'language': {'tj': 'Забон', 'ru': 'Язык', 'en': 'Language'},
    'sound': {'tj': 'Садо', 'ru': 'Звук', 'en': 'Sound'},
    'vibration': {'tj': 'Ларзиш', 'ru': 'Вибрация', 'en': 'Vibration'},
    'theme': {'tj': 'Намо', 'ru': 'Тема', 'en': 'Theme'},
    'dark_mode': {'tj': 'Торик', 'ru': 'Тёмная', 'en': 'Dark'},
    'light_mode': {'tj': 'Равшан', 'ru': 'Светлая', 'en': 'Light'},
    'about': {'tj': 'Дар бора', 'ru': 'О приложении', 'en': 'About'},
    'version': {'tj': 'Версия', 'ru': 'Версия', 'en': 'Version'},

    // Errors
    'error': {'tj': 'Хато', 'ru': 'Ошибка', 'en': 'Error'},
    'try_again': {'tj': 'Боз кӯшиш кун', 'ru': 'Попробуйте снова', 'en': 'Try Again'},
    'loading': {'tj': 'Боргузорӣ...', 'ru': 'Загрузка...', 'en': 'Loading...'},
    'cancel': {'tj': 'Бекор кун', 'ru': 'Отмена', 'en': 'Cancel'},
    'ok': {'tj': 'Хуб', 'ru': 'Ок', 'en': 'OK'},
    'field_required': {'tj': 'Ин майдонро пур кунед', 'ru': 'Заполните поле', 'en': 'This field is required'},

    // ─── Нав (v2) ───
    'play_offline_d': {'tj': 'Худро санҷед, рекорд гузоред', 'ru': 'Проверь себя и побей рекорд', 'en': 'Test yourself and set a record'},
    'play_online_d': {'tj': 'Бо дӯстон рақобат кунед', 'ru': 'Соревнуйся с друзьями', 'en': 'Compete with friends'},
    'create_room_d': {'tj': 'Коди ҳуҷраро ба дӯстон диҳед', 'ru': 'Дай друзьям код комнаты', 'en': 'Share the room code with friends'},
    'or': {'tj': 'ё', 'ru': 'или', 'en': 'or'},
    'paste': {'tj': 'Гузоштан', 'ru': 'Вставить', 'en': 'Paste'},
    'code_6': {'tj': 'Коди 6-ҳарфаро ворид кунед', 'ru': 'Введите 6-значный код', 'en': 'Enter the 6-character code'},
    'room_full': {'tj': 'Ҳуҷра пур аст', 'ru': 'Комната заполнена', 'en': 'Room is full'},
    'room_closed': {'tj': 'Ҳуҷра баста шуд', 'ru': 'Комната закрыта', 'en': 'The room was closed'},
    'waiting_host': {'tj': 'Интизори оғози бозӣ аз мизбон...', 'ru': 'Ждём, пока хозяин начнёт игру...', 'en': 'Waiting for the host to start...'},
    'waiting_others': {'tj': 'Интизори дигарон...', 'ru': 'Ждём остальных...', 'en': 'Waiting for others...'},
    'next_soon': {'tj': 'Ба зудӣ саволи навбатӣ...', 'ru': 'Скоро следующий вопрос...', 'en': 'Next question soon...'},
    'exit_game_q': {'tj': 'Аз бозӣ мебароед?', 'ru': 'Выйти из игры?', 'en': 'Leave the game?'},
    'exit_game_text': {'tj': 'Пешрафти шумо гум мешавад.', 'ru': 'Ваш прогресс будет потерян.', 'en': 'Your progress will be lost.'},
    'exit_online_text': {'tj': 'Шумо аз бозӣ хориҷ мешавед ва холҳоятон ба ҳисоб намераванд.', 'ru': 'Вы покинете игру, очки не засчитаются.', 'en': 'You will leave the game and your score will not count.'},
    'game_mode': {'tj': 'Намуди бозӣ', 'ru': 'Режим игры', 'en': 'Game mode'},
    'mode_classic': {'tj': 'Классикӣ', 'ru': 'Классика', 'en': 'Classic'},
    'mode_classic_d': {'tj': 'Шумораи муайяни савол, ҳар кадом бо вақт', 'ru': 'Заданное число вопросов с таймером', 'en': 'Fixed number of timed questions'},
    'mode_survival': {'tj': 'Зинда мондан', 'ru': 'Выживание', 'en': 'Survival'},
    'mode_survival_d': {'tj': '3 ҷон. Хато кунед, ҷон гум мекунед', 'ru': '3 жизни. Ошибся — потерял жизнь', 'en': '3 lives. Miss and lose one'},
    'sec_short': {'tj': 'сон', 'ru': 'сек', 'en': 'sec'},
    'skip': {'tj': 'Гузариш', 'ru': 'Пропуск', 'en': 'Skip'},
    'no_questions_filter': {'tj': 'Барои ин интихоб савол ёфт нашуд. Категория ё душвориро иваз кунед.', 'ru': 'По этому выбору вопросов не найдено. Измените категорию или сложность.', 'en': 'No questions match this selection. Change the category or difficulty.'},
    'back': {'tj': 'Бозгашт', 'ru': 'Назад', 'en': 'Back'},
    'cat_all': {'tj': 'Ҳама', 'ru': 'Все', 'en': 'All'},
    'cat_general': {'tj': 'Умумӣ', 'ru': 'Общие', 'en': 'General'},
    'cat_geography': {'tj': 'Ҷуғрофия', 'ru': 'География', 'en': 'Geography'},
    'cat_science': {'tj': 'Илм', 'ru': 'Наука', 'en': 'Science'},
    'cat_history': {'tj': 'Таърих', 'ru': 'История', 'en': 'History'},
    'cat_math': {'tj': 'Математика', 'ru': 'Математика', 'en': 'Math'},
    'cat_tech': {'tj': 'Технология', 'ru': 'Технологии', 'en': 'Tech'},
    'cat_islam': {'tj': 'Ислом', 'ru': 'Ислам', 'en': 'Islam'},
    'cat_culture': {'tj': 'Фарҳанг', 'ru': 'Культура', 'en': 'Culture'},
    'cat_sport': {'tj': 'Варзиш', 'ru': 'Спорт', 'en': 'Sport'},
    'result_great': {'tj': 'Аъло!', 'ru': 'Великолепно!', 'en': 'Excellent!'},
    'result_good': {'tj': 'Хуб!', 'ru': 'Хорошо!', 'en': 'Nice!'},
    'result_try': {'tj': 'Боз кӯшиш кунед!', 'ru': 'Попробуйте ещё!', 'en': 'Try again!'},
    'new_record': {'tj': 'Рекорди нав!', 'ru': 'Новый рекорд!', 'en': 'New record!'},
    'best_score': {'tj': 'Беҳтарин натиҷа', 'ru': 'Лучший результат', 'en': 'Best score'},
    'correct_answers': {'tj': 'Ҷавобҳои дуруст', 'ru': 'Верных ответов', 'en': 'Correct answers'},
    'accuracy': {'tj': 'Дурустӣ', 'ru': 'Точность', 'en': 'Accuracy'},
    'best_streak': {'tj': 'Беҳтарин серия', 'ru': 'Лучшая серия', 'en': 'Best streak'},
    'avg_time': {'tj': 'Вақти миёна', 'ru': 'Среднее время', 'en': 'Avg. time'},
    'no_mistakes': {'tj': 'Хато нест, олӣ!', 'ru': 'Ошибок нет, супер!', 'en': 'No mistakes, great!'},
    'review_mistakes': {'tj': 'Хатоҳо', 'ru': 'Ошибки', 'en': 'Mistakes'},
    'you_won': {'tj': 'Шумо ғолиб шудед!', 'ru': 'Вы победили!', 'en': 'You won!'},
    'your_place': {'tj': 'Ҷойи шумо', 'ru': 'Ваше место', 'en': 'Your place'},
    'level': {'tj': 'Сатҳ', 'ru': 'Уровень', 'en': 'Level'},
    'level_1': {'tj': 'Навомӯз', 'ru': 'Новичок', 'en': 'Beginner'},
    'level_2': {'tj': 'Донишҷӯ', 'ru': 'Ученик', 'en': 'Student'},
    'level_3': {'tj': 'Донишманд', 'ru': 'Знаток', 'en': 'Scholar'},
    'level_4': {'tj': 'Моҳир', 'ru': 'Эксперт', 'en': 'Expert'},
    'level_5': {'tj': 'Устод', 'ru': 'Мастер', 'en': 'Master'},
    'level_6': {'tj': 'Афсона', 'ru': 'Легенда', 'en': 'Legend'},
    'achievements': {'tj': 'Нишонҳо', 'ru': 'Достижения', 'en': 'Achievements'},
    'ach_first_game': {'tj': 'Оғоз', 'ru': 'Начало', 'en': 'First steps'},
    'ach_first_game_d': {'tj': 'Аввалин бозиро анҷом диҳед', 'ru': 'Сыграйте первую игру', 'en': 'Play your first game'},
    'ach_ten_games': {'tj': 'Бозингари фаъол', 'ru': 'Активный игрок', 'en': 'Regular'},
    'ach_ten_games_d': {'tj': '10 бозӣ кунед', 'ru': 'Сыграйте 10 игр', 'en': 'Play 10 games'},
    'ach_first_win': {'tj': 'Аввалин ғалаба', 'ru': 'Первая победа', 'en': 'First win'},
    'ach_first_win_d': {'tj': 'Дар бозии онлайн ғолиб шавед', 'ru': 'Победите в онлайн-игре', 'en': 'Win an online game'},
    'ach_five_wins': {'tj': 'Қаҳрамон', 'ru': 'Чемпион', 'en': 'Champion'},
    'ach_five_wins_d': {'tj': '5 маротиба ғолиб шавед', 'ru': 'Выиграйте 5 раз', 'en': 'Win 5 times'},
    'ach_streak5': {'tj': 'Оташин', 'ru': 'Огонь', 'en': 'On fire'},
    'ach_streak5_d': {'tj': '5 ҷавоби дурусти пайдарпай', 'ru': '5 верных ответов подряд', 'en': '5 correct answers in a row'},
    'ach_streak10': {'tj': 'Барқ', 'ru': 'Молния', 'en': 'Lightning'},
    'ach_streak10_d': {'tj': '10 ҷавоби дурусти пайдарпай', 'ru': '10 верных ответов подряд', 'en': '10 correct in a row'},
    'ach_perfect': {'tj': 'Беғалат', 'ru': 'Без ошибок', 'en': 'Flawless'},
    'ach_perfect_d': {'tj': 'Бозиро бе як хато анҷом диҳед', 'ru': 'Пройдите игру без ошибок', 'en': 'Finish a game with no mistakes'},
    'ach_score10k': {'tj': 'Ҳазорҳо хол', 'ru': 'Тысячи очков', 'en': 'High scorer'},
    'ach_score10k_d': {'tj': '10 000 хол ҷамъ кунед', 'ru': 'Наберите 10 000 очков', 'en': 'Earn 10,000 points'},
    'name_hint': {'tj': 'Барои идома додан номи худро ворид кунед', 'ru': 'Введите имя, чтобы продолжить', 'en': 'Enter your name to continue'},
    'no_players': {'tj': 'Ҳоло бозингар нест', 'ru': 'Игроков пока нет', 'en': 'No players yet'},
    'password': {'tj': 'Парол', 'ru': 'Пароль', 'en': 'Password'},
    'confirm_password': {'tj': 'Тасдиқи парол', 'ru': 'Подтвердите пароль', 'en': 'Confirm password'},
    'set_password_hint': {'tj': 'Барои панели админ парол гузоред', 'ru': 'Задайте пароль для панели админа', 'en': 'Set a password for the admin panel'},
    'password_short': {'tj': 'Парол бояд на кам аз 4 аломат бошад', 'ru': 'Пароль — минимум 4 символа', 'en': 'Password must be at least 4 characters'},
    'password_mismatch': {'tj': 'Паролҳо мувофиқат намекунанд', 'ru': 'Пароли не совпадают', 'en': 'Passwords do not match'},
    'wrong_password': {'tj': 'Парол нодуруст аст', 'ru': 'Неверный пароль', 'en': 'Wrong password'},
    'forgot_password': {'tj': 'Паролро фаромӯш кардам', 'ru': 'Забыли пароль', 'en': 'Forgot password'},
    'reset_password_q': {'tj': 'Парол нав карда шавад?', 'ru': 'Сбросить пароль?', 'en': 'Reset password?'},
    'reset_password_text': {'tj': 'Пароли кӯҳна нест карда мешавад ва шумо пароли нав мегузоред. Саволҳои шумо нигоҳ дошта мешаванд.', 'ru': 'Старый пароль будет удалён, и вы зададите новый. Ваши вопросы сохранятся.', 'en': 'The old password will be removed and you will set a new one. Your questions are kept.'},
    'tap_correct': {'tj': 'Ҷавоби дурустро бо доира ишора кунед', 'ru': 'Отметьте верный ответ кружком', 'en': 'Tap the circle to mark the correct answer'},

    // ─── Намудҳои савол (v3) ───
    'q_type': {'tj': 'Намуди савол', 'ru': 'Тип вопросов', 'en': 'Question type'},
    'type_all': {'tj': 'Омехта', 'ru': 'Смешанные', 'en': 'Mixed'},
    'type_choice': {'tj': 'Тест', 'ru': 'Тест', 'en': 'Test'},
    'type_text': {'tj': 'Пӯшида', 'ru': 'Впиши ответ', 'en': 'Type answer'},
    'type_match': {'tj': 'Мувофиқат', 'ru': 'Соответствие', 'en': 'Matching'},
    'type_choice_d': {'tj': 'Аз чанд вариант як ҷавобро интихоб кунед', 'ru': 'Выберите один ответ из вариантов', 'en': 'Pick one answer from the options'},
    'type_text_d': {'tj': 'Ҷавобро худатон менависед', 'ru': 'Ответ нужно написать самому', 'en': 'You type the answer yourself'},
    'type_match_d': {'tj': 'Ҷуфтҳоро ба ҳам мувофиқ кунед', 'ru': 'Сопоставьте пары', 'en': 'Match the pairs'},
    'hint_text': {'tj': 'Ҷавобро нависед', 'ru': 'Впишите ответ', 'en': 'Type your answer'},
    'hint_match': {'tj': 'Ҳар ҷузъро бо ҷавоби худ мувофиқ кунед', 'ru': 'Сопоставьте каждый элемент с ответом', 'en': 'Match each item with its answer'},
    'type_here': {'tj': 'Ҷавоби худро нависед...', 'ru': 'Введите ответ...', 'en': 'Type your answer...'},
    'submit': {'tj': 'Ҷавоб додан', 'ru': 'Ответить', 'en': 'Answer'},
    'partial': {'tj': 'Қисман дуруст', 'ru': 'Частично верно', 'en': 'Partly correct'},
    'source_hint': {'tj': 'Саволҳои тайёр дар худи барнома ҳастанд. Саволҳои ман: онҳое, ки шумо дар Панели Админ илова кардаед.', 'ru': 'Готовые вопросы встроены в приложение. Мои вопросы: те, что вы добавили в Панели Админа.', 'en': 'Built-in questions come with the app. My questions are the ones you added in the Admin Panel.'},
    'alt_answers': {'tj': 'Ҷавобҳои дигари қобили қабул', 'ru': 'Другие допустимые ответы', 'en': 'Other accepted answers'},
    'alt_answers_hint': {'tj': 'Бо вергул ҷудо кунед. Масалан: Мекка, Макка', 'ru': 'Через запятую. Например: Мекка, Макка', 'en': 'Separate with commas. E.g. Mecca, Makkah'},
    'left_item': {'tj': 'Чап', 'ru': 'Левая часть', 'en': 'Left'},
    'right_item': {'tj': 'Рост', 'ru': 'Правая часть', 'en': 'Right'},
    'add_pair': {'tj': 'Ҷуфт илова кун', 'ru': 'Добавить пару', 'en': 'Add pair'},
    'pairs_label': {'tj': 'Ҷуфтҳо (аз 3 то 5)', 'ru': 'Пары (от 3 до 5)', 'en': 'Pairs (3 to 5)'},
    'pairs_unique': {'tj': 'Тарафҳои рост бояд гуногун бошанд', 'ru': 'Правые части должны быть разными', 'en': 'Right items must be different'},
    'min_pairs': {'tj': 'Камаш 3 ҷуфт лозим аст', 'ru': 'Нужно минимум 3 пары', 'en': 'At least 3 pairs are required'},

    // ─── Аниматсияҳо (v4) ───
    'get_ready': {'tj': 'Омода шавед!', 'ru': 'Приготовьтесь!', 'en': 'Get ready!'},
    'go': {'tj': 'Шурӯъ!', 'ru': 'Вперёд!', 'en': 'Go!'},
    'streak': {'tj': 'Серия', 'ru': 'Серия', 'en': 'Streak'},
    'splash_tagline': {'tj': 'Донишро санҷед ва рақобат кунед!', 'ru': 'Проверь знания и соревнуйся!', 'en': 'Test your knowledge and compete!'},
  };
}
