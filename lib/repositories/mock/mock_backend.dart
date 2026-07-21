import 'dart:async';

import '../../models/models.dart';
import 'mock_seed_data.dart';

/// Lista observable simple (equivalente en memoria a una colección de
/// Firestore + su `snapshots()`): guarda el estado actual y lo emite a
/// cualquier nuevo listener, además de las actualizaciones posteriores.
class LiveList<T> {
  final List<T> _items;
  final _controller = StreamController<List<T>>.broadcast();

  LiveList(List<T> initial) : _items = List<T>.from(initial);

  List<T> get value => List<T>.unmodifiable(_items);

  Stream<List<T>> get stream async* {
    yield value;
    yield* _controller.stream;
  }

  void _emit() => _controller.add(value);

  void upsert(T item, bool Function(T) matchesId) {
    final idx = _items.indexWhere(matchesId);
    if (idx >= 0) {
      _items[idx] = item;
    } else {
      _items.add(item);
    }
    _emit();
  }

  void removeWhere(bool Function(T) test) {
    _items.removeWhere(test);
    _emit();
  }

  void add(T item) {
    _items.add(item);
    _emit();
  }
}

/// Backend en memoria compartido por [MockAuthRepository] y
/// [MockDataRepository] (equivalente a "la base de datos falsa"), de forma
/// que un usuario creado por el repositorio de auth aparezca también en el
/// stream de usuarios del repositorio de datos, igual que ocurriría con
/// Firebase Auth + Firestore reales.
class MockBackend {
  MockBackend._internal()
    : credentials = Map<String, String>.from(mockCredentials),
      users = LiveList(seedUsers()),
      students = LiveList(seedStudents()),
      teachers = LiveList(seedTeachers()),
      parents = LiveList(seedParents()),
      courses = LiveList(seedCourses()),
      subjects = LiveList(seedSubjects()),
      years = LiveList(seedYears()),
      periods = LiveList(seedPeriods()),
      standards = LiveList(seedStandards()),
      indicators = LiveList(seedIndicators()),
      activities = LiveList(seedActivities()),
      grades = LiveList(seedGrades()),
      attendance = LiveList(seedAttendance()),
      observations = LiveList(seedObservations()),
      assignments = LiveList(seedAssignments()),
      evalConfigs = LiveList(seedEvalConfigs()),
      notifications = <String, LiveList<AppNotification>>{} {
    for (final n in seedNotifications()) {
      notificationsFor(n.userId).add(n);
    }
  }

  static final MockBackend instance = MockBackend._internal();

  /// email (minúsculas) → password. Usado por MockAuthRepository.
  final Map<String, String> credentials;
  AppUser? currentUser;

  final LiveList<AppUser> users;
  final LiveList<Student> students;
  final LiveList<Teacher> teachers;
  final LiveList<Parent> parents;
  final LiveList<Course> courses;
  final LiveList<Subject> subjects;
  final LiveList<AcademicYear> years;
  final LiveList<AcademicPeriod> periods;
  final LiveList<Standard> standards;
  final LiveList<Indicator> indicators;
  final LiveList<Activity> activities;
  final LiveList<Grade> grades;
  final LiveList<AttendanceRecord> attendance;
  final LiveList<Observation> observations;
  final LiveList<SubjectAssignment> assignments;
  final LiveList<EvaluationConfig> evalConfigs;
  final Map<String, LiveList<AppNotification>> notifications;

  LiveList<AppNotification> notificationsFor(String userId) =>
      notifications.putIfAbsent(userId, () => LiveList(const []));

  /// Simula la latencia de red de Firebase.
  static Future<void> delay([int ms = 300]) =>
      Future.delayed(Duration(milliseconds: ms));
}
