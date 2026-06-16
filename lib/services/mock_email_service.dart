import '../models/email_models.dart';
import '../models/models.dart';
import 'email_service.dart';

class MockEmailService implements EmailService {
  static final List<InternalEmail> _emails = [
    InternalEmail(
      id: 'em1',
      senderId: 'u7',
      senderName: 'Roberto Pérez',
      receiverId: 'u1',
      receiverName: 'Dra. Patricia Morales',
      subject: 'Consulta: calificaciones de Juan Pérez - Período 1',
      body: 'Estimada Coordinadora,\n\nMe dirijo a usted para solicitar información sobre las calificaciones de mi hijo Juan Pérez García del curso 6A durante el período 1.\n\nAgradezco su pronta atención.\n\nCordialmente,\nRoberto Pérez',
      timestamp: DateTime(2026, 6, 14, 9, 30),
      isRead: false,
    ),
    InternalEmail(
      id: 'em2',
      senderId: 'u2',
      senderName: 'Prof. Carlos Rodríguez',
      receiverId: 'u1',
      receiverName: 'Dra. Patricia Morales',
      subject: 'Solicitud de insumos: Laboratorio de Ciencias',
      body: 'Estimada Coordinadora,\n\nSolicito respetuosamente la adquisición de los siguientes materiales para el laboratorio de Ciencias Naturales:\n\n- 2 microscopios\n- Reactivos básicos para experimentos de química\n- Láminas de preparación histológica\n\nEstos materiales son necesarios para las prácticas del período 2.\n\nEsperando su respuesta.\n\nAtentamente,\nProf. Carlos Rodríguez',
      timestamp: DateTime(2026, 6, 13, 14, 15),
      isRead: false,
    ),
    InternalEmail(
      id: 'em3',
      senderId: 'u3',
      senderName: 'Prof. Ana Martínez',
      receiverId: 'u1',
      receiverName: 'Dra. Patricia Morales',
      subject: 'Informe mensual grupo 6B - Mayo 2026',
      body: 'Estimada Coordinadora,\n\nPresento a usted el informe del grupo 6B correspondiente al mes de mayo:\n\n• Promedio del grupo: 3.8\n• Porcentaje de asistencia: 94%\n• Observaciones generales: El grupo muestra excelente disposición hacia las actividades propuestas. Hay tres estudiantes que requieren seguimiento especial.\n\nQuedo atenta a sus comentarios.\n\nAtentamente,\nProf. Ana Martínez',
      timestamp: DateTime(2026, 6, 12, 10, 0),
      isRead: true,
    ),
    InternalEmail(
      id: 'em4',
      senderId: 'u1',
      senderName: 'Dra. Patricia Morales',
      receiverId: 'u2',
      receiverName: 'Prof. Carlos Rodríguez',
      subject: 'Re: Solicitud de insumos - Aprobada',
      body: 'Estimado Profesor Carlos,\n\nMe complace informarle que su solicitud de insumos para el laboratorio de Ciencias ha sido aprobada.\n\nLos materiales serán entregados la próxima semana. Por favor coordine con el área administrativa el día martes para el recibo de los mismos.\n\nCordialmente,\nDra. Patricia Morales\nCoordinadora Académica — Colegio San José',
      timestamp: DateTime(2026, 6, 13, 16, 30),
      isRead: true,
      replyToId: 'em2',
    ),
    InternalEmail(
      id: 'em5',
      senderId: 'u17',
      senderName: 'Ana María Torres',
      receiverId: 'u1',
      receiverName: 'Dra. Patricia Morales',
      subject: 'Permiso retiro temprano - Diego Herrera Silva',
      body: 'Estimada Coordinadora,\n\nPor medio de la presente solicito permiso para retirar a mi hijo Diego Herrera Silva del colegio el día miércoles 18 de junio a las 2:00 p.m., debido a cita médica programada previamente.\n\nMe comprometo a traer la excusa médica al día siguiente.\n\nGracias por su comprensión.\n\nAna María Torres\nMadre de Diego Herrera Silva - Curso 7A',
      timestamp: DateTime(2026, 6, 11, 8, 45),
      isRead: false,
    ),
    InternalEmail(
      id: 'em6',
      senderId: 'u2',
      senderName: 'Prof. Carlos Rodríguez',
      receiverId: 'u3',
      receiverName: 'Prof. Ana Martínez',
      subject: 'Reunión de área Ciencias - Viernes 20 de junio',
      body: 'Estimada colega,\n\nLe informo que la reunión de área de Ciencias Naturales se realizará el viernes 20 de junio a las 3:00 p.m. en la sala de docentes.\n\nTemas a tratar:\n1. Planificación del período 3\n2. Ajuste de mallas curriculares\n3. Seguimiento de estudiantes con bajo rendimiento\n4. Socialización de nuevas metodologías\n\nSu asistencia es fundamental.\n\nSaludos,\nProf. Carlos Rodríguez\nJefe de Área — Ciencias',
      timestamp: DateTime(2026, 6, 10, 11, 20),
      isRead: false,
    ),
    InternalEmail(
      id: 'em7',
      senderId: 'u1',
      senderName: 'Dra. Patricia Morales',
      receiverId: 'u3',
      receiverName: 'Prof. Ana Martínez',
      subject: 'Felicitaciones por resultados del grupo 7A',
      body: 'Estimada Profesora Ana,\n\nDeseo felicitarla por los excelentes resultados obtenidos en el grupo 7A durante este período académico.\n\nEl promedio de 4.1 y la asistencia del 96% reflejan su dedicación y el alto compromiso de los estudiantes. El Colegio San José se enorgullece de contar con docentes comprometidas como usted.\n\nSiga adelante con ese gran trabajo que tanto impacto positivo genera.\n\nCordialmente,\nDra. Patricia Morales\nCoordinadora Académica',
      timestamp: DateTime(2026, 6, 9, 9, 0),
      isRead: true,
    ),
    InternalEmail(
      id: 'em8',
      senderId: 'u4',
      senderName: 'Juan Pérez García',
      receiverId: 'u2',
      receiverName: 'Prof. Carlos Rodríguez',
      subject: 'Consulta nota Estándar 2 - Matemáticas',
      body: 'Profe Carlos,\n\nLe escribo porque tengo una duda sobre mi nota en el estándar 2 de Matemáticas del período 1.\n\nEntreguée todas las actividades programadas pero la nota que aparece en el sistema no coincide con lo que esperaba haber obtenido.\n\n¿Es posible verificarla o concertar una cita para hablar al respecto?\n\nGracias,\nJuan Pérez García\nEstudiante — 6A',
      timestamp: DateTime(2026, 6, 8, 16, 5),
      isRead: false,
    ),
    InternalEmail(
      id: 'em9',
      senderId: 'u1',
      senderName: 'Dra. Patricia Morales',
      receiverId: 'u7',
      receiverName: 'Roberto Pérez',
      subject: 'Re: Calificaciones de Juan Pérez - Período 1',
      body: 'Estimado señor Pérez,\n\nEn respuesta a su consulta, le informo que las calificaciones de Juan Pérez García en el período 1 son las siguientes:\n\n• Matemáticas: 3.8\n• Ciencias Naturales: 4.0\n• Español y Literatura: 3.6\n• Inglés: 4.2\n• Educación Física: 4.5\n\nPromedio general: 4.02 — Desempeño BÁSICO.\n\nLe invitamos a una reunión el próximo martes 17 de junio a las 10:00 a.m. para analizar el progreso académico de Juan y establecer metas para el período 2.\n\nCordialmente,\nDra. Patricia Morales\nCoordinadora Académica — Colegio San José',
      timestamp: DateTime(2026, 6, 14, 11, 0),
      isRead: true,
      replyToId: 'em1',
    ),
    InternalEmail(
      id: 'em10',
      senderId: 'u2',
      senderName: 'Prof. Carlos Rodríguez',
      receiverId: 'u1',
      receiverName: 'Dra. Patricia Morales',
      subject: 'Plan de área Matemáticas - Período 2',
      body: 'Estimada Coordinadora,\n\nAdjunto el plan de área de Matemáticas para el período 2, actualizado con los ajustes sugeridos en la última reunión docente:\n\nSemana 1–2: Sistemas de ecuaciones lineales\nSemana 3–4: Geometría analítica y plano cartesiano\nSemana 5–6: Estadística descriptiva básica\nSemana 7–8: Funciones cuadráticas e interpretación gráfica\n\nIncluye actividades diferenciadas para los estudiantes que presentaron dificultades en el período anterior.\n\nQuedo pendiente de su revisión y aprobación.\n\nAtentamente,\nProf. Carlos Rodríguez',
      timestamp: DateTime(2026, 6, 7, 13, 30),
      isRead: true,
    ),
  ];

  @override
  int countUnread(String userId) => _emails
      .where((e) => e.receiverId == userId && !e.isRead && !e.isDeleted && !e.isDraft)
      .length;

  @override
  Future<List<InternalEmail>> getInbox(String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _emails
        .where((e) => e.receiverId == userId && !e.isDeleted && !e.isDraft)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  @override
  Future<List<InternalEmail>> getSent(String userId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _emails
        .where((e) => e.senderId == userId && !e.isDeleted && !e.isDraft)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  @override
  Future<List<InternalEmail>> getDrafts(String userId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _emails
        .where((e) => e.senderId == userId && e.isDraft && !e.isDeleted)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  @override
  Future<List<InternalEmail>> getTrash(String userId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _emails
        .where((e) =>
            (e.receiverId == userId || e.senderId == userId) && e.isDeleted)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  @override
  Future<void> sendEmail(InternalEmail email) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _emails.removeWhere((e) => e.id == email.id);
    _emails.add(email);
  }

  @override
  Future<void> saveDraft(InternalEmail draft) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _emails.removeWhere((e) => e.id == draft.id);
    _emails.add(draft);
  }

  @override
  Future<void> markAsRead(String emailId) async {
    final idx = _emails.indexWhere((e) => e.id == emailId);
    if (idx != -1) _emails[idx].isRead = true;
  }

  @override
  Future<void> markAsUnread(String emailId) async {
    final idx = _emails.indexWhere((e) => e.id == emailId);
    if (idx != -1) _emails[idx].isRead = false;
  }

  @override
  Future<void> moveToTrash(String emailId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final idx = _emails.indexWhere((e) => e.id == emailId);
    if (idx != -1) _emails[idx].isDeleted = true;
  }

  @override
  Future<void> restoreFromTrash(String emailId) async {
    final idx = _emails.indexWhere((e) => e.id == emailId);
    if (idx != -1) _emails[idx].isDeleted = false;
  }

  @override
  Future<void> permanentlyDelete(String emailId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _emails.removeWhere((e) => e.id == emailId);
  }

  @override
  Future<List<AppUser>> getAvailableRecipients(
    String currentUserId,
    List<AppUser> allUsers,
  ) async {
    return allUsers.where((u) => u.id != currentUserId).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }
}
