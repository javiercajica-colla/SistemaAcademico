import '../models/models.dart';
import '../models/message_models.dart';

class MockMessages {
  static List<Conversation> get conversations => [
    // Conv 1: Individual — Coordinadora ↔ Prof. Carlos
    Conversation(
      id: 'conv1',
      type: ConversationType.individual,
      title: 'Dra. Patricia Morales',
      participantIds: ['u1', 'u2'],
      createdAt: DateTime(2026, 6, 1),
    ),
    // Conv 2: Individual — Coordinadora ↔ Prof. Ana
    Conversation(
      id: 'conv2',
      type: ConversationType.individual,
      title: 'Dra. Patricia Morales',
      participantIds: ['u1', 'u3'],
      createdAt: DateTime(2026, 6, 3),
    ),
    // Conv 3: Group — Prof. Carlos → Estudiantes 6°A
    Conversation(
      id: 'conv3',
      type: ConversationType.group,
      title: 'Grupo 6°A — Matemáticas',
      participantIds: ['u2', 'u4', 'u5', 'u6', 'u10'],
      createdAt: DateTime(2026, 6, 5),
    ),
    // Conv 4: Institutional — Coordinadora → Todos
    Conversation(
      id: 'conv4',
      type: ConversationType.institutional,
      title: 'Comunicado Institucional — Cierre Período 2',
      participantIds: [
        'u1',
        'u2',
        'u3',
        'u4',
        'u5',
        'u6',
        'u7',
        'u8',
        'u9',
        'u10',
      ],
      createdAt: DateTime(2026, 6, 8),
    ),
    // Conv 5: Individual — Padre ↔ Prof. Carlos
    Conversation(
      id: 'conv5',
      type: ConversationType.individual,
      title: 'Roberto Pérez',
      participantIds: ['u7', 'u2'],
      createdAt: DateTime(2026, 6, 2),
    ),
    // Conv 6: Individual — Estudiante ↔ Prof. Ana
    Conversation(
      id: 'conv6',
      type: ConversationType.individual,
      title: 'Prof. Ana Martínez',
      participantIds: ['u4', 'u3'],
      createdAt: DateTime(2026, 6, 4),
    ),
    // Conv 7: Group — Prof. Carlos → Padres de 6°A
    Conversation(
      id: 'conv7',
      type: ConversationType.group,
      title: 'Padres de familia 6°A',
      participantIds: ['u2', 'u7'],
      createdAt: DateTime(2026, 6, 6),
    ),
    // Conv 8: Individual — Estudiante ↔ Coordinadora
    Conversation(
      id: 'conv8',
      type: ConversationType.individual,
      title: 'Dra. Patricia Morales',
      participantIds: ['u4', 'u1'],
      createdAt: DateTime(2026, 6, 9),
    ),
  ];

  static List<Message> get messages => [
    // Conv 1
    Message(
      id: 'm1',
      conversationId: 'conv1',
      senderId: 'u1',
      senderName: 'Dra. Patricia Morales',
      senderRole: UserRole.coordinator,
      content:
          'Buenos días, Prof. Carlos. ¿Podría enviarme el informe de calificaciones del Período 2 para el curso 6°A antes del viernes?',
      sentAt: DateTime(2026, 6, 10, 8, 30),
      readBy: ['u2'],
    ),
    Message(
      id: 'm2',
      conversationId: 'conv1',
      senderId: 'u2',
      senderName: 'Prof. Carlos Rodríguez',
      senderRole: UserRole.teacher,
      content:
          'Buenos días, Dra. Morales. Con gusto, lo tendrá para el jueves en la tarde.',
      sentAt: DateTime(2026, 6, 10, 9, 15),
      readBy: ['u1'],
    ),
    Message(
      id: 'm3',
      conversationId: 'conv1',
      senderId: 'u1',
      senderName: 'Dra. Patricia Morales',
      senderRole: UserRole.coordinator,
      content: 'Perfecto, muchas gracias.',
      sentAt: DateTime(2026, 6, 10, 9, 20),
      readBy: [],
    ),
    // Conv 2
    Message(
      id: 'm4',
      conversationId: 'conv2',
      senderId: 'u1',
      senderName: 'Dra. Patricia Morales',
      senderRole: UserRole.coordinator,
      content:
          'Prof. Ana, recuerde que el próximo lunes hay reunión de docentes a las 3:00 pm en la sala de juntas.',
      sentAt: DateTime(2026, 6, 11, 10, 0),
      readBy: [],
    ),
    // Conv 3 — grupo estudiantes
    Message(
      id: 'm5',
      conversationId: 'conv3',
      senderId: 'u2',
      senderName: 'Prof. Carlos Rodríguez',
      senderRole: UserRole.teacher,
      content:
          'Estimados estudiantes del 6°A, el próximo miércoles tendremos evaluación de álgebra. Por favor repasen los temas del bloque 3.',
      sentAt: DateTime(2026, 6, 9, 7, 0),
      readBy: ['u5', 'u6'],
    ),
    Message(
      id: 'm6',
      conversationId: 'conv3',
      senderId: 'u2',
      senderName: 'Prof. Carlos Rodríguez',
      senderRole: UserRole.teacher,
      content:
          'También recuerden entregar el trabajo de geometría antes del viernes sin excepción.',
      sentAt: DateTime(2026, 6, 9, 7, 3),
      readBy: ['u5'],
    ),
    // Conv 4 — institucional
    Message(
      id: 'm7',
      conversationId: 'conv4',
      senderId: 'u1',
      senderName: 'Dra. Patricia Morales',
      senderRole: UserRole.coordinator,
      content:
          'Estimada comunidad educativa: Les informamos que el día 20 de junio se llevará a cabo el cierre del Período 2. Los docentes deberán tener todas las calificaciones registradas antes del 18 de junio.',
      sentAt: DateTime(2026, 6, 8, 6, 0),
      readBy: ['u2', 'u3', 'u8', 'u9'],
    ),
    Message(
      id: 'm8',
      conversationId: 'conv4',
      senderId: 'u1',
      senderName: 'Dra. Patricia Morales',
      senderRole: UserRole.coordinator,
      content:
          'El día 22 de junio habrá jornada de entrega de boletines a padres de familia de 8:00 am a 12:00 pm. La asistencia de los estudiantes es obligatoria.',
      sentAt: DateTime(2026, 6, 8, 6, 5),
      readBy: ['u2', 'u3'],
    ),
    // Conv 5 — padre ↔ docente
    Message(
      id: 'm9',
      conversationId: 'conv5',
      senderId: 'u7',
      senderName: 'Roberto Pérez',
      senderRole: UserRole.parent,
      content:
          'Prof. Carlos, buenas tardes. Quería preguntarle cómo va el rendimiento de mi hijo Juan en Matemáticas este período.',
      sentAt: DateTime(2026, 6, 5, 14, 30),
      readBy: ['u2'],
    ),
    Message(
      id: 'm10',
      conversationId: 'conv5',
      senderId: 'u2',
      senderName: 'Prof. Carlos Rodríguez',
      senderRole: UserRole.teacher,
      content:
          'Buenas tardes, Sr. Pérez. Juan ha demostrado muy buen desempeño, con calificaciones superiores a 4.0 en el Período 1. Siga motivándolo en casa.',
      sentAt: DateTime(2026, 6, 5, 16, 0),
      readBy: ['u7'],
    ),
    Message(
      id: 'm11',
      conversationId: 'conv5',
      senderId: 'u7',
      senderName: 'Roberto Pérez',
      senderRole: UserRole.parent,
      content: 'Muchas gracias, Prof. Le haré saber. Hasta pronto.',
      sentAt: DateTime(2026, 6, 5, 16, 10),
      readBy: [],
    ),
    // Conv 6 — estudiante ↔ docente
    Message(
      id: 'm12',
      conversationId: 'conv6',
      senderId: 'u4',
      senderName: 'Juan Pérez García',
      senderRole: UserRole.student,
      content:
          'Prof. Ana, buenos días. Tengo una duda sobre la tarea de comprensión lectora. ¿A qué se refiere el punto 3?',
      sentAt: DateTime(2026, 6, 6, 7, 45),
      readBy: ['u3'],
    ),
    Message(
      id: 'm13',
      conversationId: 'conv6',
      senderId: 'u3',
      senderName: 'Prof. Ana Martínez',
      senderRole: UserRole.teacher,
      content:
          'Hola Juan, el punto 3 se refiere al análisis del personaje principal. Debes identificar sus motivaciones y cómo evoluciona a lo largo del texto.',
      sentAt: DateTime(2026, 6, 6, 9, 0),
      readBy: ['u4'],
    ),
    Message(
      id: 'm14',
      conversationId: 'conv6',
      senderId: 'u4',
      senderName: 'Juan Pérez García',
      senderRole: UserRole.student,
      content: 'Entendido, muchas gracias Prof.',
      sentAt: DateTime(2026, 6, 6, 9, 5),
      readBy: [],
    ),
    // Conv 7 — docente → padres grupo
    Message(
      id: 'm15',
      conversationId: 'conv7',
      senderId: 'u2',
      senderName: 'Prof. Carlos Rodríguez',
      senderRole: UserRole.teacher,
      content:
          'Estimados padres de familia del 6°A, les informo que la próxima semana realizaremos una salida pedagógica al parque natural. Favor revisar la circular autorización que se enviará mañana.',
      sentAt: DateTime(2026, 6, 7, 8, 0),
      readBy: [],
    ),
    // Conv 8 — estudiante ↔ coordinadora
    Message(
      id: 'm16',
      conversationId: 'conv8',
      senderId: 'u4',
      senderName: 'Juan Pérez García',
      senderRole: UserRole.student,
      content:
          'Coordinadora, buenos días. Quisiera solicitar una cita para hablar sobre mi situación académica del período anterior.',
      sentAt: DateTime(2026, 6, 9, 8, 0),
      readBy: ['u1'],
    ),
    Message(
      id: 'm17',
      conversationId: 'conv8',
      senderId: 'u1',
      senderName: 'Dra. Patricia Morales',
      senderRole: UserRole.coordinator,
      content:
          'Buenos días Juan. Claro que sí, te espero el jueves a las 10:00 am en la oficina de coordinación.',
      sentAt: DateTime(2026, 6, 9, 9, 30),
      readBy: [],
    ),
  ];
}
