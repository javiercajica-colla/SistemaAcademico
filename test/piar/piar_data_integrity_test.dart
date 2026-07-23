// Prueba obligatoria del módulo PIAR (caso 6): cambiar el texto de una
// competencia en el plan de área no debe alterar `competenciaTextoOriginal`
// de los ajustes ya creados — el campo es una copia congelada, nunca una
// referencia que se vuelva a leer de `Standard`.
//
// No requiere Firebase ni el emulador: usa MockDataRepository (repositorio
// en memoria) tal como ya lo usa el resto de la app en modo desarrollo.
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_academico/models/models.dart';
import 'package:sistema_academico/models/piar_models.dart';
import 'package:sistema_academico/repositories/mock/mock_data_repository.dart';

void main() {
  test(
    'editar un Standard no altera competenciaTextoOriginal de ajustes ya creados',
    () async {
      final repo = MockDataRepository();
      const standardId = 'piar_test_standard_1';
      const ajusteId = 'piar_test_ajuste_1';
      const textoOriginal = 'Resuelve problemas de suma con números naturales.';

      // 1. Estándar tal como existe hoy en el plan de área.
      await repo.saveStandard(
        const Standard(
          id: standardId,
          subjectId: 's1',
          periodId: 'ap1',
          name: 'Pensamiento numérico',
          description: textoOriginal,
          weight: 100,
        ),
      );

      // 2. Se crea el ajuste PIAR copiando el texto vigente en ese momento.
      final ahora = DateTime.now();
      await repo.savePiarAjuste(
        PiarAjuste(
          id: ajusteId,
          inscripcionId: 'ins_test',
          subjectId: 's1',
          standardId: standardId,
          periodId: 'ap1',
          competenciaTextoOriginal: textoOriginal,
          requiereAjuste: true,
          tiposAjuste: const {PiarTipoAjuste.acceso},
          descripcionAjuste:
              'Se usará material manipulativo y tiempo adicional durante la clase de matemáticas.',
          metaMinima: textoOriginal,
          evidenciaEsperada: 'Registro fotográfico del ejercicio resuelto con apoyo.',
          docenteResponsableId: 'teacher_test_1',
          estado: PiarEstadoAjuste.borrador,
          creadoPor: 'uid_test',
          creadoEn: ahora,
          actualizadoPor: 'uid_test',
          actualizadoEn: ahora,
        ),
      );

      // 3. Coordinación edita el plan de área: cambia el texto del estándar.
      await repo.saveStandard(
        const Standard(
          id: standardId,
          subjectId: 's1',
          periodId: 'ap1',
          name: 'Pensamiento numérico',
          description: 'Texto completamente distinto tras la edición.',
          weight: 100,
        ),
      );

      // 4. El ajuste ya creado debe conservar el texto original congelado.
      final ajustes = await repo
          .piarAjustesStream(inscripcionId: 'ins_test')
          .first;
      final ajuste = ajustes.singleWhere((a) => a.id == ajusteId);

      expect(ajuste.competenciaTextoOriginal, textoOriginal);
      expect(
        ajuste.competenciaTextoOriginal,
        isNot(contains('completamente distinto')),
      );
    },
  );
}
