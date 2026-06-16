App iOS en SwiftUI que muestra el calendario completo del Mundial 2026 adaptado a un usuario en España.

Pantalla principal

• Listado cronológico de las 36 jornadas del torneo (11 jun – 19 jul 2026), agrupadas por día.
• Cada partido se muestra con: hora local de Madrid, equipos, grupo o fase, canal de TV (La 1 + DAZN gratis, o solo DAZN de pago) y resultado si ya se jugó.
• El día actual se marca con 📍 HOY; los días pasados aparecen atenuados.
• Los partidos de España se resaltan en verde con la bandera 🇪🇸.
• La gran final se resalta en dorado.

Filtros y búsqueda

• Búsqueda por equipo (texto libre, sin distinguir mayúsculas/acentos).
• Filtro por fase: Todos · Grupos · 1/16 · 1/8 · Cuartos · Semis · Final.
• Filtro por grupo (A – L): muestra solo los partidos de ese grupo y dibuja su tabla de clasificación (PJ, PG, PE, PP, GF, GC, DG, Pts), ordenada según criterios FIFA.
• Filtro por país anfitrión (México / Canadá / EE.UU.): muestra los partidos disputados en estadios de ese país.
• Filtro por estadio concreto.
• Barra de "filtro activo" con botón Limpiar para resetear todo de un toque.

Detalle del partido (hoja modal)

Al tocar un partido se abre un sheet con:

• Resultado final en grande si ya se jugó (o "Próximo partido" / "Equipos por definir" si aún no).
• Ficha: fecha, hora España, grupo/fase, estadio, ciudad, canal y estado.
• Alineaciones de ambos equipos (segmented picker para alternar local/visitante):
   • Formación táctica (4-3-3, 3-4-2-1, …).
   • Once inicial + suplentes con dorsal, nombre y posición.
   • Eventos por jugador con el minuto exacto: ⚽ goles (incluye penalti y en propia puerta), 🟨 amarillas, 🟥 rojas, ↑ entrada y ↓ salida en sustituciones (soporta tiempo añadido tipo "45+5'").

Datos y actualización

• Al arrancar muestra instantáneamente los datos cacheados (o los integrados en el bundle si no hay caché).
• En segundo plano descarga un JSON remoto alojado en GitHub raw que se regenera automáticamente cada 30 min con resultados oficiales (cache-buster + no-cache para evitar versiones viejas).
• Pull-to-refresh para forzar actualización manual.
• Indicador de última actualización en la cabecera.

Diseño

• Tema oscuro permanente, paleta azul marino + dorado.
• Iconografía consistente: punto azul = emisión gratuita, punto dorado = solo DAZN.
• Localización de fechas según idioma del sistema ("sáb 14 jun" en español).
