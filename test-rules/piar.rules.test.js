// Pruebas de autorización del módulo PIAR contra las Firestore Security
// Rules REALES (firestore.rules), corridas contra el Firebase Emulator
// Suite — no contra el repositorio mock de la app, que no tiene rules.
//
// Ejecutar desde la raíz de sistema_academico/:
//   firebase emulators:exec --only firestore "npm --prefix test-rules test"
//
// Cubre los casos obligatorios 1-5 de la especificación del módulo PIAR
// (los casos 6 y 7 son invariantes de aplicación/UI, no de autorización,
// y se prueban en Dart en fases posteriores).

import { strict as assert } from 'node:assert';
import test from 'node:test';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} from '@firebase/rules-unit-testing';
import {
  doc,
  getDoc,
  setDoc,
  updateDoc,
} from 'firebase/firestore';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

const PROJECT_ID = 'sistema-academico-rules-test';

// Uids de Firebase Auth de prueba.
const UID_DOCENTE_A = 'uid_docente_a'; // dicta el ajuste de prueba
const UID_DOCENTE_B = 'uid_docente_b'; // NO dicta esa asignatura
const UID_COORDINADOR = 'uid_coordinador';
const UID_PADRE = 'uid_padre';

// Teacher.id (documento interno) — distinto del uid de Auth a propósito,
// para probar que las rules resuelven la relación Teacher.id -> userId
// correctamente y no confunden ambos ids.
const TEACHER_ID_A = 'teacher_doc_a';
const TEACHER_ID_B = 'teacher_doc_b';

let testEnv;

async function seed(fn) {
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await fn(db);
  });
}

function dbAs(uid) {
  return testEnv.authenticatedContext(uid, {}).firestore();
}

test.before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: {
      rules: fs.readFileSync(
        path.join(__dirname, '..', 'firestore.rules'),
        'utf8',
      ),
      host: '127.0.0.1',
      port: 8080,
    },
  });
});

test.after(async () => {
  await testEnv.cleanup();
});

test.beforeEach(async () => {
  await testEnv.clearFirestore();
  // Datos base que casi todos los casos necesitan: perfiles de usuario
  // (las rules leen el rol desde aquí, no del token) y los dos docentes.
  await seed(async (db) => {
    await setDoc(doc(db, 'users', UID_DOCENTE_A), { role: 'teacher' });
    await setDoc(doc(db, 'users', UID_DOCENTE_B), { role: 'teacher' });
    await setDoc(doc(db, 'users', UID_COORDINADOR), { role: 'coordinator' });
    await setDoc(doc(db, 'users', UID_PADRE), { role: 'parent' });
    await setDoc(doc(db, 'teachers', TEACHER_ID_A), { userId: UID_DOCENTE_A });
    await setDoc(doc(db, 'teachers', TEACHER_ID_B), { userId: UID_DOCENTE_B });
  });
});

// ─── 1. Un docente no puede leer ni escribir ajustes de una asignatura ────
// ─── que no dicta ──────────────────────────────────────────────────────

test('docente no dueño no puede leer un ajuste ajeno', async () => {
  await seed(async (db) => {
    await setDoc(doc(db, 'piar_ajustes', 'adj1'), {
      inscripcionId: 'ins1',
      subjectId: 's1',
      standardId: 'st1',
      periodId: 'ap1',
      competenciaTextoOriginal: 'Resuelve problemas de suma.',
      requiereAjuste: true,
      tiposAjuste: ['acceso'],
      metaMinima: 'Resuelve problemas de suma.',
      estado: 'borrador',
      docenteResponsableId: TEACHER_ID_A,
    });
  });

  await assertFails(getDoc(doc(dbAs(UID_DOCENTE_B), 'piar_ajustes', 'adj1')));
  await assertSucceeds(
    getDoc(doc(dbAs(UID_DOCENTE_A), 'piar_ajustes', 'adj1')),
  );
});

test('docente no dueño no puede escribir un ajuste ajeno', async () => {
  await seed(async (db) => {
    await setDoc(doc(db, 'piar_ajustes', 'adj1'), {
      inscripcionId: 'ins1',
      subjectId: 's1',
      standardId: 'st1',
      periodId: 'ap1',
      competenciaTextoOriginal: 'Resuelve problemas de suma.',
      requiereAjuste: true,
      tiposAjuste: ['acceso'],
      metaMinima: 'Resuelve problemas de suma.',
      estado: 'borrador',
      docenteResponsableId: TEACHER_ID_A,
    });
  });

  await assertFails(
    updateDoc(doc(dbAs(UID_DOCENTE_B), 'piar_ajustes', 'adj1'), {
      descripcionAjuste: 'Intento de otro docente'.padEnd(85, '.'),
    }),
  );
});

// ─── 2. Ningún rol docente puede acceder a un soporte externo por ─────────
// ─── ninguna vía ───────────────────────────────────────────────────────

test('un docente autorizado para el perfil del estudiante NO puede leer sus soportes externos', async () => {
  await seed(async (db) => {
    await setDoc(doc(db, 'piar_inscripciones', 'ins1'), {
      studentId: 'est1',
      academicYearId: 'ay1',
      courseId: 'c1',
      estado: 'activo',
      docentesAutorizadosIds: [UID_DOCENTE_A],
      padresAutorizadosIds: [UID_PADRE],
    });
    await setDoc(doc(db, 'piar_soportes_externos', 'sop1'), {
      inscripcionId: 'ins1',
      tipo: 'informePsicologico',
      entidadEmisora: 'Clínica X',
    });
  });

  // uidA SÍ está autorizado a ver el perfil de apoyo de este estudiante,
  // pero NUNCA a ver sus soportes externos — es exactamente la
  // separación de capas que exige el negocio.
  await assertFails(
    getDoc(doc(dbAs(UID_DOCENTE_A), 'piar_soportes_externos', 'sop1')),
  );
  await assertFails(
    updateDoc(doc(dbAs(UID_DOCENTE_A), 'piar_soportes_externos', 'sop1'), {
      observaciones: 'intento',
    }),
  );
  // Coordinación y la propia familia sí pueden.
  await assertSucceeds(
    getDoc(doc(dbAs(UID_COORDINADOR), 'piar_soportes_externos', 'sop1')),
  );
  await assertSucceeds(
    getDoc(doc(dbAs(UID_PADRE), 'piar_soportes_externos', 'sop1')),
  );
});

// ─── 3. meta_minima no puede diferir de competencia_texto_original si el ──
// ─── ajuste no incluye significativo, aunque se envíe directo al servidor ─

test('meta_minima distinta de competencia_texto_original sin significativo se rechaza en servidor', async () => {
  await assertFails(
    setDoc(doc(dbAs(UID_DOCENTE_A), 'piar_ajustes', 'adj2'), {
      inscripcionId: 'ins1',
      subjectId: 's1',
      standardId: 'st1',
      periodId: 'ap1',
      competenciaTextoOriginal: 'Resuelve problemas de suma.',
      requiereAjuste: true,
      tiposAjuste: ['acceso'],
      metaMinima: 'Meta distinta inventada por el cliente',
      estado: 'borrador',
      docenteResponsableId: TEACHER_ID_A,
    }),
  );
});

test('meta_minima igual a competencia_texto_original sin significativo se acepta', async () => {
  await assertSucceeds(
    setDoc(doc(dbAs(UID_DOCENTE_A), 'piar_ajustes', 'adj3'), {
      inscripcionId: 'ins1',
      subjectId: 's1',
      standardId: 'st1',
      periodId: 'ap1',
      competenciaTextoOriginal: 'Resuelve problemas de suma.',
      requiereAjuste: true,
      tiposAjuste: ['acceso'],
      metaMinima: 'Resuelve problemas de suma.',
      estado: 'borrador',
      docenteResponsableId: TEACHER_ID_A,
    }),
  );
});

test('meta_minima distinta SÍ se permite cuando el ajuste es significativo', async () => {
  await assertSucceeds(
    setDoc(doc(dbAs(UID_DOCENTE_A), 'piar_ajustes', 'adj4'), {
      inscripcionId: 'ins1',
      subjectId: 's1',
      standardId: 'st1',
      periodId: 'ap1',
      competenciaTextoOriginal: 'Resuelve problemas de suma.',
      requiereAjuste: true,
      tiposAjuste: ['significativo'],
      metaMinima: 'Reconoce el símbolo + en una suma sencilla.',
      justificacionSignificativo: 'El estudiante requiere una meta adaptada.',
      estado: 'borrador',
      docenteResponsableId: TEACHER_ID_A,
    }),
  );
});

// ─── 4. Un ajuste con significativo y sin justificación no se puede ───────
// ─── enviar ─────────────────────────────────────────────────────────────

test('ajuste significativo sin justificación no se puede enviar', async () => {
  await seed(async (db) => {
    await setDoc(doc(db, 'piar_ajustes', 'adj5'), {
      inscripcionId: 'ins1',
      subjectId: 's1',
      standardId: 'st1',
      periodId: 'ap1',
      competenciaTextoOriginal: 'Resuelve problemas de suma.',
      requiereAjuste: true,
      tiposAjuste: ['significativo'],
      metaMinima: 'Reconoce el símbolo + en una suma sencilla.',
      justificacionSignificativo: 'Justificación inicial.',
      estado: 'borrador',
      docenteResponsableId: TEACHER_ID_A,
    });
  });

  // Guardar borrador sin justificación: no valida, se permite.
  await assertSucceeds(
    updateDoc(doc(dbAs(UID_DOCENTE_A), 'piar_ajustes', 'adj5'), {
      justificacionSignificativo: '',
      estado: 'borrador',
    }),
  );
  // Enviar (estado != borrador) sin justificación: se rechaza.
  await assertFails(
    updateDoc(doc(dbAs(UID_DOCENTE_A), 'piar_ajustes', 'adj5'), {
      justificacionSignificativo: '',
      estado: 'enviado',
    }),
  );
  // Enviar con justificación: se acepta.
  await assertSucceeds(
    updateDoc(doc(dbAs(UID_DOCENTE_A), 'piar_ajustes', 'adj5'), {
      justificacionSignificativo: 'El estudiante requiere una meta adaptada.',
      estado: 'enviado',
    }),
  );
});

// ─── 5. Un registro de período cerrado no admite actualización ───────────

test('un seguimiento de período cerrado no admite actualización', async () => {
  await seed(async (db) => {
    await setDoc(doc(db, 'academic_periods', 'ap_cerrado'), {
      academicYearId: 'ay1',
      name: 'Período 1',
      isOpen: false,
    });
    await setDoc(doc(db, 'academic_periods', 'ap_abierto'), {
      academicYearId: 'ay1',
      name: 'Período 2',
      isOpen: true,
    });
    await setDoc(doc(db, 'piar_seguimientos', 'seg_cerrado'), {
      ajusteId: 'adj1',
      docenteResponsableId: TEACHER_ID_A,
      periodId: 'ap_cerrado',
      aplicacion: 'completo',
      valoracion: 'enProceso',
      queLogro: 'x',
      conQueApoyo: 'y',
      queSigue: 'z',
      decisionAjuste: 'mantener',
    });
    await setDoc(doc(db, 'piar_seguimientos', 'seg_abierto'), {
      ajusteId: 'adj1',
      docenteResponsableId: TEACHER_ID_A,
      periodId: 'ap_abierto',
      aplicacion: 'completo',
      valoracion: 'enProceso',
      queLogro: 'x',
      conQueApoyo: 'y',
      queSigue: 'z',
      decisionAjuste: 'mantener',
    });
  });

  await assertFails(
    updateDoc(doc(dbAs(UID_DOCENTE_A), 'piar_seguimientos', 'seg_cerrado'), {
      queSigue: 'intento de corregir un registro cerrado',
    }),
  );
  await assertSucceeds(
    updateDoc(doc(dbAs(UID_DOCENTE_A), 'piar_seguimientos', 'seg_abierto'), {
      queSigue: 'esto sí se puede editar',
    }),
  );
  // La rectificación (documento nuevo) sobre un período cerrado sí se
  // puede CREAR — solo la actualización del registro original se bloquea.
  await assertSucceeds(
    setDoc(doc(dbAs(UID_DOCENTE_A), 'piar_seguimientos', 'seg_rectificacion'), {
      ajusteId: 'adj1',
      docenteResponsableId: TEACHER_ID_A,
      periodId: 'ap_cerrado',
      aplicacion: 'completo',
      valoracion: 'enProceso',
      queLogro: 'x',
      conQueApoyo: 'y',
      queSigue: 'z corregido',
      decisionAjuste: 'mantener',
      esRectificacion: true,
      rectificaARegistroId: 'seg_cerrado',
    }),
  );
});
