import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../data/mock_data.dart';

// Pobla Firestore con todos los datos mock del sistema.
// Crear usuarios en Firebase Auth cambia el estado de sesión, por lo que
// al finalizar se vuelve a iniciar sesión como coordinador.
class SeedService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;

  // mockId → Firebase UID real
  final Map<String, String> _uidMap = {};

  Future<void> seedAll(void Function(String) onProgress) async {
    onProgress('Creando usuarios en Firebase Auth…');
    await _seedUsers(onProgress);

    // _seedUsers deja la sesión activa como el ÚLTIMO usuario procesado
    // (que puede no tener permisos de staff, p. ej. un padre de familia).
    // Todo lo que sigue necesita permisos de staff, así que hay que volver
    // a autenticar como coordinador ANTES de continuar, no solo al final.
    onProgress('Restaurando sesión del coordinador…');
    await _auth.signInWithEmailAndPassword(
      email: 'coordinador@colegio.edu.co',
      password: '123456',
    );

    onProgress('Años académicos…');
    await _seedAcademicYears();

    onProgress('Períodos académicos…');
    await _seedAcademicPeriods();

    onProgress('Asignaturas…');
    await _seedSubjects();

    onProgress('Cursos…');
    await _seedCourses();

    onProgress('Estándares de evaluación…');
    await _seedEstandaresCompetenciasActividades();

    onProgress('Docentes…');
    await _seedTeachers();

    onProgress('Estudiantes…');
    await _seedStudents();

    onProgress('Padres de familia…');
    await _seedParents();

    onProgress('Asignaciones de asignaturas…');
    await _seedAssignments();

    onProgress('Calificaciones…');
    await _seedGrades();

    onProgress('Registros de asistencia…');
    await _seedAttendance();

    onProgress('Observaciones…');
    await _seedObservations();

    onProgress('Notificaciones…');
    await _seedNotifications();

    onProgress('Configuración de evaluación…');
    await _seedEvalConfigs();

    onProgress('PIAR — catálogo de apoyos…');
    await _seedPiarCatalogoApoyos();

    // Re-autenticar como coordinador para restaurar la sesión
    onProgress('Restaurando sesión del coordinador…');
    await _auth.signInWithEmailAndPassword(
      email: 'coordinador@colegio.edu.co',
      password: '123456',
    );

    onProgress('✓ Datos iniciales cargados exitosamente');
  }

  // ── Auth + perfil en Firestore ──────────────────────────────────────────

  Future<void> _seedUsers(void Function(String) onProgress) async {
    for (final user in MockData.users) {
      try {
        final cred = await _auth
            .createUserWithEmailAndPassword(
              email: user.email,
              password: user.password,
            )
            .timeout(
              const Duration(seconds: 15),
              onTimeout: () => throw Exception(
                'Timeout creando ${user.email} — verifica que Email/Password esté habilitado en Firebase Console → Authentication → Sign-in method',
              ),
            );
        final uid = cred.user!.uid;
        _uidMap[user.id] = uid;

        await _db.collection('users').doc(uid).set({
          'name': user.name,
          'email': user.email,
          'role': user.role.name,
          'avatar': user.avatar,
          'isActive': user.isActive,
        });
      } on fb.FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          // Ya existe en Firebase Auth (de un intento anterior). Iniciar
          // sesión para recuperar su UID real y recrear su perfil en Firestore.
          // Si la contraseña ya no coincide (p. ej. fue restablecida desde
          // "Administración de Contraseñas"), no abortamos todo el proceso:
          // avisamos y seguimos con el resto de los usuarios.
          try {
            final cred = await _auth.signInWithEmailAndPassword(
              email: user.email,
              password: user.password,
            );
            final uid = cred.user!.uid;
            _uidMap[user.id] = uid;

            await _db.collection('users').doc(uid).set({
              'name': user.name,
              'email': user.email,
              'role': user.role.name,
              'avatar': user.avatar,
              'isActive': user.isActive,
            });
          } on fb.FirebaseAuthException catch (e2) {
            onProgress(
              '⚠ ${user.email} ya existe con otra contraseña, se omite (${e2.code})',
            );
          }
        } else {
          onProgress('⚠ No se pudo crear ${user.email}, se omite (${e.code})');
        }
      }
    }
  }

  // ── Colecciones simples con batch ──────────────────────────────────────

  Future<void> _seedAcademicYears() async {
    final batch = _db.batch();
    for (final y in MockData.academicYears) {
      batch.set(_db.collection('academic_years').doc(y.id), {
        'year': y.year,
        'isActive': y.isActive,
      });
    }
    await batch.commit();
  }

  Future<void> _seedAcademicPeriods() async {
    final batch = _db.batch();
    for (final p in MockData.academicPeriods) {
      batch.set(_db.collection('academic_periods').doc(p.id), {
        'academicYearId': p.academicYearId,
        'name': p.name,
        'startDate': Timestamp.fromDate(p.startDate),
        'endDate': Timestamp.fromDate(p.endDate),
        'weight': p.weight,
        'isOpen': p.isOpen,
      });
    }
    await batch.commit();
  }

  Future<void> _seedSubjects() async {
    final batch = _db.batch();
    for (final s in MockData.subjects) {
      batch.set(_db.collection('subjects').doc(s.id), {
        'code': s.code,
        'name': s.name,
        'area': s.area,
        'hoursPerWeek': s.hoursPerWeek,
        'teacherId': s.teacherId,
      });
    }
    await batch.commit();
  }

  Future<void> _seedCourses() async {
    final batch = _db.batch();
    for (final c in MockData.courses) {
      batch.set(_db.collection('courses').doc(c.id), {
        'name': c.name,
        'grade': c.grade,
        'section': c.section,
        'academicYearId': c.academicYearId,
        'directorTeacherId': c.directorTeacherId,
      });
    }
    await batch.commit();
  }

  Future<void> _seedEstandaresCompetenciasActividades() async {
    final batch = _db.batch();
    for (final e in MockData.estandares) {
      batch.set(_db.collection('estandares').doc(e.id), {
        'subjectId': e.subjectId,
        'academicYearId': e.academicYearId,
        'name': e.name,
        'description': e.description,
        'order': e.order,
        'weight': e.weight,
      });
    }
    for (final c in MockData.competencias) {
      batch.set(_db.collection('competencias').doc(c.id), {
        'estandarId': c.estandarId,
        'periodId': c.periodId,
        'tipo': c.tipo.name,
        'name': c.name,
        'description': c.description,
        'order': c.order,
      });
    }
    for (final a in MockData.actividades) {
      batch.set(_db.collection('actividades').doc(a.id), {
        'competenciaId': a.competenciaId,
        'name': a.name,
        'description': a.description,
        'order': a.order,
        'date': a.date == null ? null : Timestamp.fromDate(a.date!),
      });
    }
    await batch.commit();
  }

  Future<void> _seedTeachers() async {
    final batch = _db.batch();
    for (final t in MockData.teachers) {
      batch.set(_db.collection('teachers').doc(t.id), {
        'userId': _uidMap[t.userId] ?? t.userId,
        'firstName': t.firstName,
        'lastName': t.lastName,
        'documentId': t.documentId,
        'specialization': t.specialization,
        'subjectIds': t.subjectIds,
      });
    }
    await batch.commit();
  }

  Future<void> _seedStudents() async {
    final batch = _db.batch();
    for (final s in MockData.students) {
      batch.set(_db.collection('students').doc(s.id), {
        'userId': _uidMap[s.userId] ?? s.userId,
        'firstName': s.firstName,
        'lastName': s.lastName,
        'documentId': s.documentId,
        'birthDate': Timestamp.fromDate(s.birthDate),
        'courseId': s.courseId,
        'parentIds': s.parentIds,
      });
    }
    await batch.commit();
  }

  Future<void> _seedParents() async {
    final batch = _db.batch();
    for (final p in MockData.parents) {
      batch.set(_db.collection('parents').doc(p.id), {
        'userId': _uidMap[p.userId] ?? p.userId,
        'firstName': p.firstName,
        'lastName': p.lastName,
        'documentId': p.documentId,
        'phone': p.phone,
        'relationship': p.relationship,
        'studentIds': p.studentIds,
      });
    }
    await batch.commit();
  }

  Future<void> _seedAssignments() async {
    final batch = _db.batch();
    for (final a in MockData.assignments) {
      batch.set(_db.collection('subject_assignments').doc(a.id), {
        'teacherId': a.teacherId,
        'subjectId': a.subjectId,
        'courseId': a.courseId,
        'academicYearId': a.academicYearId,
      });
    }
    await batch.commit();
  }

  Future<void> _seedGrades() async {
    final batch = _db.batch();
    for (final g in MockData.grades) {
      batch.set(_db.collection('grades').doc(g.id), {
        'studentId': g.studentId,
        'subjectId': g.subjectId,
        'periodId': g.periodId,
        'estandarId': g.estandarId,
        'competenciaId': g.competenciaId,
        'actividadId': g.actividadId,
        'value': g.value,
        'note': g.note,
        'registeredAt': Timestamp.fromDate(g.registeredAt),
      });
    }
    await batch.commit();
  }

  Future<void> _seedAttendance() async {
    final batch = _db.batch();
    for (final r in MockData.attendance) {
      batch.set(_db.collection('attendance').doc(r.id), {
        'studentId': r.studentId,
        'subjectId': r.subjectId,
        'periodId': r.periodId,
        'date': Timestamp.fromDate(r.date),
        'status': r.status.name,
        'note': r.note,
      });
    }
    await batch.commit();
  }

  Future<void> _seedObservations() async {
    final batch = _db.batch();
    for (final o in MockData.observations) {
      batch.set(_db.collection('observations').doc(o.id), {
        'studentId': o.studentId,
        'teacherId': o.teacherId,
        'subjectId': o.subjectId,
        'type': o.type.name,
        'title': o.title,
        'description': o.description,
        'date': Timestamp.fromDate(o.date),
      });
    }
    await batch.commit();
  }

  Future<void> _seedNotifications() async {
    for (final n in MockData.notifications) {
      final realUserId = _uidMap[n.userId] ?? n.userId;
      await _db
          .collection('notifications')
          .doc(realUserId)
          .collection('items')
          .doc(n.id)
          .set({
            'userId': realUserId,
            'title': n.title,
            'message': n.message,
            'type': n.type.name,
            'createdAt': Timestamp.fromDate(n.createdAt),
            'isRead': n.isRead,
          });
    }
  }

  Future<void> _seedEvalConfigs() async {
    final batch = _db.batch();
    for (final ec in MockData.evalConfigs) {
      batch.set(_db.collection('evaluation_configs').doc(ec.id), {
        'subjectId': ec.subjectId,
        'periodId': ec.periodId,
        'standardsWeight': ec.standardsWeight,
        'finalExamWeight': ec.finalExamWeight,
      });
    }
    await batch.commit();
  }

  Future<void> _seedPiarCatalogoApoyos() async {
    final batch = _db.batch();
    for (final a in MockData.piarCatalogoApoyos) {
      batch.set(_db.collection('piar_catalogo_apoyos').doc(a.id), {
        'nombre': a.nombre,
        'descripcion': a.descripcion,
        'activo': a.activo,
      });
    }
    await batch.commit();
  }
}
