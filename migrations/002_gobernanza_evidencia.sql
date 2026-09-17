-- =============================================================================
-- FACTOS — Migración 002: gobernanza y evidencia
--
-- Corrige cuatro gaps detectados en revisión externa del paquete v2.0:
--   Q3 · Modelo de correcciones era implícito (dependía de un trigger de
--        auditoría interno, no de un registro público diseñado para eso).
--   Q5 · Nada en el esquema impedía dar al partido un rol que tocara
--        Capa 1/2. El riesgo era de gobernanza operativa, no del esquema.
--   Q6 · revisor_id y verificador_id podían fijarse ambos por la misma
--        persona con cuenta 'editor'; la constraint sólo exige que sean
--        distintos, no que el revisor haya actuado con su propia sesión.
--   Q7 · "Evidencia archivada" no tenía manifiesto formal (faltaban
--        cabeceras HTTP capturadas en el momento de la cosecha).
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Q7 · Manifiesto de evidencia completo
-- -----------------------------------------------------------------------------
-- El SHA-256 demuestra integridad (el archivo no cambió DESPUÉS de capturado).
-- No demuestra procedencia ni momento de captura. Eso lo dan tres cosas juntas:
--   1. Las cabeceras HTTP capturadas en el momento (nuevo campo).
--   2. El snapshot de un tercero independiente (archive.org), cuyo timestamp
--      no está bajo nuestro control — ya existía snapshot_url, se refuerza.
--   3. La trazabilidad a la corrida del harvester (ya existía vía corrida_id):
--      qué versión de código hizo la captura y cuándo corrió el job.

alter table interno.fuente_cruda
  add column if not exists http_headers jsonb,
  add column if not exists metodo_captura text not null default 'harvester_automatico'
    check (metodo_captura in ('harvester_automatico','carga_manual','api_oficial'));

comment on column interno.fuente_cruda.http_headers is
  'Cabeceras completas de la respuesta HTTP en el momento de la cosecha (ETag, Last-Modified, Content-Type, etc.), como evidencia adicional de procedencia y momento de captura. El SHA-256 por sí solo no prueba ni origen ni fecha.';

comment on table interno.fuente_cruda is
  'Manifiesto de evidencia archivada. Un registro completo exige: archivo original intacto + sha256 + url + http_headers + obtenido_en + corrida_id (qué harvester, qué versión) + snapshot_url de un tercero independiente cuando esté disponible. Ninguno de estos campos sustituye a los otros.';

-- Regla dura: no se acepta evidencia sin snapshot de tercero SALVO que se
-- documente explícitamente por qué no fue posible (paywall, robots.txt, etc.)
alter table interno.fuente_cruda
  add column if not exists snapshot_no_disponible_motivo text;

alter table interno.fuente_cruda
  add constraint fuente_cruda_snapshot_o_motivo
  check (snapshot_url is not null or snapshot_no_disponible_motivo is not null);


-- -----------------------------------------------------------------------------
-- Q5 · Aislamiento estructural: el partido nunca toca Capa 1/2
-- -----------------------------------------------------------------------------
-- No basta con "no darle ese rol" como convención de equipo. Se modela como
-- un rol separado que estructuralmente no puede escribir en verificacion,
-- evidencia, afirmacion, captura ni fuente_cruda — sólo en su propia tabla.

alter type public.rol_usuario add value if not exists 'analista_partido';

create table public.analisis_variante (
  id              uuid primary key default gen_random_uuid(),
  verificacion_id uuid not null references public.verificacion(id) on delete cascade,
  variante        text not null check (variante in ('independiente','partido')),
  texto           text not null,
  autor_id        uuid not null references public.usuario(id),
  creado_en       timestamptz not null default now(),
  actualizado_en  timestamptz not null default now(),
  unique (verificacion_id, variante)
);
-- Reemplaza al campo suelto `verificacion.analisis` del diseño anterior:
-- ahora el análisis de Capa 3 vive en una tabla propia, con su propio
-- dueño y su propia política de acceso, desacoplada de Capa 1/2.

comment on table public.analisis_variante is
  'Capa 3 únicamente. Nunca contiene hecho ni evidencia. Es la única tabla que el rol analista_partido puede escribir.';

alter table public.analisis_variante enable row level security;

-- Lectura: cualquiera con rol interno, o público si la verificación está publicada
create policy p_analisis_lectura on public.analisis_variante
  for select using (
    public.fn_rol() is not null
    or exists (
      select 1 from public.verificacion v
      where v.id = analisis_variante.verificacion_id and v.estado = 'publicada'
    )
  );

-- Escritura de Capa 3: analista_partido SOLO puede escribir variante='partido'
-- sobre su propio autor_id. Nunca puede tocar verificacion, evidencia, etc.
-- (esas tablas ya no lo incluyen en sus políticas de escritura — ver abajo).
create policy p_analisis_escritura_partido on public.analisis_variante
  for all
  using (
    public.fn_rol() = 'analista_partido'
    and variante = 'partido'
  )
  with check (
    public.fn_rol() = 'analista_partido'
    and variante = 'partido'
    and autor_id = auth.uid()
  );

-- El equipo editorial puede escribir cualquier variante (por si el propio
-- equipo redacta el análisis independiente, o cubre al partido si no hay
-- analista disponible).
create policy p_analisis_escritura_editorial on public.analisis_variante
  for all
  using (public.fn_rol() in ('verificador','revisor','editor','admin'))
  with check (public.fn_rol() in ('verificador','revisor','editor','admin'));

-- Confirmación explícita: las políticas de verificacion/evidencia/afirmacion/
-- captura/fuente_cruda de la migración 001 YA restringen escritura a
-- verificador/revisor/editor/admin. analista_partido no aparece en ninguna
-- de esas listas, ni debe agregarse nunca. Esta migración no las reabre.


-- -----------------------------------------------------------------------------
-- Q6 · Auto-aprobación forzada: el revisor debe fijar su propio ID
-- -----------------------------------------------------------------------------
-- La constraint original (verif_dos_personas) sólo exige que verificador_id
-- y revisor_id sean distintos. No exige que la cuenta que actúa como revisor
-- sea la que fija ese campo. Un 'editor' podía fijar ambos IDs sin que la
-- segunda persona hubiera actuado realmente. Se cierra con un trigger:
-- nadie puede fijar revisor_id salvo la propia persona autenticada como ese
-- revisor.

create or replace function public.fn_forzar_autoaprobacion()
returns trigger language plpgsql as $$
begin
  if new.revisor_id is not null
     and (old.revisor_id is null or old.revisor_id is distinct from new.revisor_id) then
    if new.revisor_id <> auth.uid() then
      raise exception
        'revisor_id sólo puede fijarlo la propia persona autenticada como revisor (uid actual: %).', auth.uid();
    end if;
  end if;
  return new;
end;
$$;

create trigger trg_forzar_autoaprobacion
  before insert or update on public.verificacion
  for each row execute function public.fn_forzar_autoaprobacion();

comment on function public.fn_forzar_autoaprobacion is
  'Cierra el gap Q6: dos IDs distintos en las columnas no bastan como prueba de que dos personas actuaron. Esta función obliga a que quien aparece como revisor haya iniciado sesión con su propia cuenta para fijarlo.';


-- -----------------------------------------------------------------------------
-- Q3 · Revisiones publicadas inmutables, versionadas, con historial conservado
-- -----------------------------------------------------------------------------
-- El diseño original dependía implícitamente de interno.auditoria (que no es
-- pública ni fue diseñada para esto) para reconstruir versiones anteriores.
-- Se formaliza: cada vez que una verificación se publica o se corrige
-- estando publicada, se escribe una fila INMUTABLE con el contenido completo
-- de esa versión. Nunca se borra ni se edita una fila de esta tabla.

create table public.verificacion_revision (
  id              uuid primary key default gen_random_uuid(),
  verificacion_id uuid not null references public.verificacion(id),
  version         integer not null,
  veredicto       veredicto not null,
  titulo_publico  text not null,
  resumen_hecho   text not null,
  metodologia     text not null,
  hash_contenido  text not null,
  motivo          tipo_correccion,   -- null en la primera publicación
  descripcion_cambio text,           -- por qué difiere de la versión anterior
  autor_id        uuid references public.usuario(id),
  creado_en       timestamptz not null default now(),
  unique (verificacion_id, version)
);

comment on table public.verificacion_revision is
  'Registro público, append-only, de cada versión publicada de una verificación. Responde exactamente a Q3: no existe "edición silenciosa" — cada cambio sobre una ficha publicada crea una fila nueva aquí, la anterior queda intacta y visible.';

alter table public.verificacion_revision enable row level security;

create policy p_revision_lectura on public.verificacion_revision
  for select using (true);  -- pública siempre; es la prueba de integridad

-- Inmutable: ni UPDATE ni DELETE, ni para el rol de aplicación.
create trigger trg_revision_inmutable
  before update or delete on public.verificacion_revision
  for each row execute function public.fn_bloquear_modificacion();

-- La inserción ocurre automáticamente al publicar o corregir — nunca a mano.
create or replace function public.fn_registrar_revision()
returns trigger language plpgsql as $$
begin
  if new.estado = 'publicada'
     and (old.estado is distinct from 'publicada' or old.version is distinct from new.version) then
    insert into public.verificacion_revision
      (verificacion_id, version, veredicto, titulo_publico, resumen_hecho,
       metodologia, hash_contenido, autor_id)
    values
      (new.id, new.version, new.veredicto, new.titulo_publico, new.resumen_hecho,
       new.metodologia, new.hash_contenido, new.revisor_id);
  end if;
  return new;
end;
$$;
-- Nota: new.hash_contenido se calcula en la capa de aplicación (A1) antes del
-- UPDATE, igual que en el esquema original — esta migración no cambia eso.

create trigger trg_registrar_revision
  after insert or update on public.verificacion
  for each row execute function public.fn_registrar_revision();

comment on function public.fn_registrar_revision is
  'Ejecuta automáticamente al publicar o re-publicar. No requiere que ningún agente "recuerde" versionar: es estructural, no un paso manual que se puede olvidar.';


-- -----------------------------------------------------------------------------
-- Corrección de nomenclatura: 'analisis' en verificacion queda obsoleto
-- -----------------------------------------------------------------------------
-- El análisis ahora vive en analisis_variante (Q5). Se conserva la columna
-- por compatibilidad durante la migración de datos, pero no se escribe más.
comment on column public.verificacion.analisis is
  'OBSOLETO desde la migración 002. El análisis de Capa 3 vive en analisis_variante. No escribir aquí en código nuevo. Se elimina en una migración futura una vez migrados los datos existentes.';
