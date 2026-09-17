-- =============================================================================
-- FACTOS — Esquema base
-- PostgreSQL 15+ / Supabase
--
-- Principio rector: ninguna verificación puede publicarse sin evidencia
-- apuntando a una fuente cruda archivada y verificada por dos personas.
-- Eso NO se confía a la disciplina del equipo: lo impone la base de datos.
-- =============================================================================

create extension if not exists "pgcrypto";
create extension if not exists "unaccent";
create extension if not exists "pg_trgm";

-- Esquema separado para lo que NUNCA debe exponerse por la API pública.
-- PostgREST/Supabase sólo expone `public` por defecto.
create schema if not exists interno;

-- Wrapper IMMUTABLE de unaccent (requerido para columnas generadas)
create or replace function public.f_unaccent(text)
returns text language sql immutable strict parallel safe as
$$ select public.unaccent('public.unaccent', $1) $$;


-- =============================================================================
-- 1. TIPOS
-- =============================================================================

create type public.veredicto as enum (
  'exacto',                     -- la afirmación coincide con la fuente
  'exacto_descontextualizado',  -- el dato es correcto, el uso es engañoso
  'impreciso',                  -- parcialmente correcto, con error material
  'falso',                      -- contradice la fuente oficial
  'insostenible',               -- no existe base fáctica alguna
  'no_verificable'              -- no hay información pública suficiente
);
-- 'no_verificable' es distinto de 'falso'. Confundirlos es el error más
-- caro que puede cometer un sitio de verificación.

create type public.estado_afirmacion as enum
  ('candidata','en_revision','aprobada','descartada');

create type public.estado_verificacion as enum
  ('borrador','en_revision','publicada','retirada');

create type public.tipo_captura as enum
  ('video','audio','acta_sesion','texto','imagen','transmision');

create type public.metodo_evidencia as enum
  ('api','parser','manual');

create type public.rol_usuario as enum
  ('colaborador','verificador','revisor','editor','admin');

create type public.tipo_correccion as enum
  ('correccion','aclaracion','retiro');


-- =============================================================================
-- 2. PERSONAS Y ROLES
-- =============================================================================

create table public.usuario (
  id            uuid primary key references auth.users(id) on delete restrict,
  nombre_publico text not null,
  rol           rol_usuario not null default 'colaborador',
  activo        boolean not null default true,
  creado_en     timestamptz not null default now()
);
-- Nota: `nombre_publico` puede ser seudónimo. No guardamos más PII de
-- colaboradores de la necesaria: en este proyecto son un blanco.


-- =============================================================================
-- 3. ACTORES (los verificados)
-- =============================================================================

create table public.actor (
  id              uuid primary key default gen_random_uuid(),
  slug            text not null unique,
  nombre_completo text not null,
  rut             text unique,          -- desambiguación; público en SERVEL
  fecha_nacimiento date,
  ids_externos    jsonb not null default '{}'::jsonb,
    -- {"camara": 1234, "senado": 55, "servel": "...", "bcn": "..."}
  creado_en       timestamptz not null default now(),
  actualizado_en  timestamptz not null default now()
);

create index actor_nombre_trgm on public.actor
  using gin (public.f_unaccent(nombre_completo) gin_trgm_ops);

-- Historial de cargos: define en qué calidad hablaba en la fecha de la
-- afirmación. Sin esto, "el ministro dijo" es indefendible.
create table public.cargo (
  id          uuid primary key default gen_random_uuid(),
  actor_id    uuid not null references public.actor(id) on delete cascade,
  titulo      text not null,
  institucion text not null,
  partido     text,
  desde       date not null,
  hasta       date,
  fuente_url  text not null,
  constraint cargo_periodo_valido check (hasta is null or hasta >= desde)
);
create index cargo_actor_idx on public.cargo (actor_id, desde desc);


-- =============================================================================
-- 4. CAPTURA — el lado "qué dijo"
-- =============================================================================

create table public.canal (
  id        uuid primary key default gen_random_uuid(),
  nombre    text not null,
  tipo      text not null,   -- youtube | radio | tv | congreso | x | prensa
  url_base  text,
  activo    boolean not null default true
);

-- El artefacto capturado. INMUTABLE una vez insertado.
create table public.captura (
  id                uuid primary key default gen_random_uuid(),
  canal_id          uuid references public.canal(id),
  tipo              tipo_captura not null,
  url_original      text not null,
  titulo            text,
  publicado_en      timestamptz,
  capturado_en      timestamptz not null default now(),
  duracion_seg      integer,
  sha256            text not null unique,   -- integridad del archivo original
  storage_path      text not null,          -- copia propia en almacenamiento frío
  snapshot_url      text,                   -- archive.org / archive.today
  transcripcion_path text,
  nota_licencia     text
);
create index captura_publicado_idx on public.captura (publicado_en desc);

-- La afirmación concreta, con su contexto.
create table public.afirmacion (
  id                uuid primary key default gen_random_uuid(),
  actor_id          uuid not null references public.actor(id),
  captura_id        uuid not null references public.captura(id),
  cargo_id          uuid references public.cargo(id),
  texto_literal     text not null,
  ts_inicio_seg     integer,
  ts_fin_seg        integer,
  contexto_previo   text,   -- >= 60s antes, obligatorio en video/audio
  contexto_posterior text,  -- >= 60s después
  detectado_por     text not null default 'agente',  -- agente | humano | aporte
  estado            estado_afirmacion not null default 'candidata',
  creado_en         timestamptz not null default now(),
  constraint afirmacion_ts_valido
    check (ts_fin_seg is null or ts_inicio_seg is null or ts_fin_seg > ts_inicio_seg),
  constraint afirmacion_contexto_av
    check (
      estado in ('candidata','descartada')
      or (select tipo from public.captura c where c.id = captura_id)
         not in ('video','audio','transmision')
      or (contexto_previo is not null and contexto_posterior is not null)
    )
);
-- La última constraint impide aprobar una afirmación de audio/video sin
-- contexto guardado. "Me sacaron de contexto" es la defensa estándar;
-- se desarma publicando el contexto, no prometiéndolo.

create index afirmacion_actor_idx on public.afirmacion (actor_id, creado_en desc);
create index afirmacion_estado_idx on public.afirmacion (estado)
  where estado in ('candidata','en_revision');


-- =============================================================================
-- 5. EVIDENCIA — el lado "qué dice la fuente oficial"
-- =============================================================================

-- Catálogo de fuentes oficiales
create table public.fuente (
  id           uuid primary key default gen_random_uuid(),
  nombre       text not null,            -- "Cámara de Diputados — Votaciones"
  organismo    text not null,
  modo_acceso  text not null,            -- api | descarga | scraping
  url_base     text not null,
  licencia     text,
  robots_ok    boolean not null default true,
  notas        text
);

-- Corrida de cosecha (trazabilidad del harvester)
create table interno.corrida (
  id                uuid primary key default gen_random_uuid(),
  fuente_id         uuid not null references public.fuente(id),
  version_harvester text not null,
  iniciada_en       timestamptz not null default now(),
  terminada_en      timestamptz,
  estado            text not null default 'en_curso',
  items_ok          integer not null default 0,
  items_error       integer not null default 0,
  detalle_error     jsonb
);

-- El artefacto crudo descargado. INMUTABLE. Esto es la evidencia legal.
create table interno.fuente_cruda (
  id            uuid primary key default gen_random_uuid(),
  fuente_id     uuid not null references public.fuente(id),
  corrida_id    uuid references interno.corrida(id),
  url           text not null,
  sha256        text not null unique,
  storage_path  text not null,
  content_type  text,
  bytes         bigint,
  http_status   integer,
  obtenido_en   timestamptz not null default now(),
  snapshot_url  text
);
create index fuente_cruda_fuente_idx on interno.fuente_cruda (fuente_id, obtenido_en desc);

-- El dato extraído, con puntero exacto a su origen.
create table public.evidencia (
  id              uuid primary key default gen_random_uuid(),
  fuente_cruda_id uuid not null references interno.fuente_cruda(id),
  cita_textual    text not null,
  localizador     jsonb not null,
    -- {"pagina": 14} | {"articulo": "art. 3 inc. 2"}
    -- {"xpath": "/Votaciones/Votacion[@Id='45']"} | {"hoja":"Resumen","celda":"D22"}
  valor_extraido  numeric,
  unidad          text,          -- CLP | % | UF | personas
  metodo          metodo_evidencia not null,
  extraido_por    uuid references public.usuario(id),
  notas           text,
  creado_en       timestamptz not null default now()
);


-- =============================================================================
-- 6. VERIFICACIÓN — la ficha publicada
-- =============================================================================

create table public.tema (
  id     uuid primary key default gen_random_uuid(),
  slug   text not null unique,
  nombre text not null
);

create table public.verificacion (
  id             uuid primary key default gen_random_uuid(),
  afirmacion_id  uuid not null references public.afirmacion(id),
  slug           text not null unique,
  titulo_publico text not null,   -- redactado como la gente lo busca
  veredicto      veredicto not null,
  resumen_hecho  text not null,   -- CAPA 1: neutro, sin adjetivos
  metodologia    text not null,   -- qué se revisó y qué no se pudo verificar
  analisis       text,            -- CAPA 3: opinión, etiquetada, opcional
  estado         estado_verificacion not null default 'borrador',
  verificador_id uuid references public.usuario(id),
  revisor_id     uuid references public.usuario(id),
  publicado_en   timestamptz,
  version        integer not null default 1,
  creado_en      timestamptz not null default now(),
  actualizado_en timestamptz not null default now(),

  constraint verif_dos_personas
    check (revisor_id is null or verificador_id is null or revisor_id <> verificador_id),
  constraint verif_publicada_completa
    check (
      estado <> 'publicada'
      or (publicado_en is not null
          and verificador_id is not null
          and revisor_id is not null)
    )
);

create table public.verificacion_evidencia (
  verificacion_id uuid not null references public.verificacion(id) on delete cascade,
  evidencia_id    uuid not null references public.evidencia(id),
  orden           integer not null default 0,
  primary key (verificacion_id, evidencia_id)
);

create table public.verificacion_tema (
  verificacion_id uuid not null references public.verificacion(id) on delete cascade,
  tema_id         uuid not null references public.tema(id),
  primary key (verificacion_id, tema_id)
);

-- Historial público de correcciones. Append-only.
create table public.correccion (
  id              uuid primary key default gen_random_uuid(),
  verificacion_id uuid not null references public.verificacion(id),
  tipo            tipo_correccion not null,
  descripcion     text not null,
  campo_afectado  text,
  valor_anterior  text,
  autor_id        uuid references public.usuario(id),
  ocurrido_en     timestamptz not null default now()
);


-- =============================================================================
-- 7. BUZÓN DE APORTES (envíos del público)
-- =============================================================================

create table public.aporte (
  id           uuid primary key default gen_random_uuid(),
  url          text not null,
  descripcion  text,
  actor_sugerido text,
  email_contacto text,
  ip_hash      text,      -- hash con sal, nunca la IP en claro
  estado       text not null default 'nuevo',
  creado_en    timestamptz not null default now()
);


-- =============================================================================
-- 8. LA REGLA DURA: no se publica sin evidencia
-- =============================================================================

create or replace function public.fn_verificacion_publicable()
returns trigger language plpgsql as $$
declare
  n_evidencia integer;
  n_archivada integer;
begin
  if new.estado = 'publicada' then

    select count(*) into n_evidencia
    from public.verificacion_evidencia ve
    where ve.verificacion_id = new.id;

    if n_evidencia = 0 then
      raise exception
        'No se puede publicar la verificación % sin al menos una evidencia.', new.id;
    end if;

    -- Toda evidencia debe apuntar a una fuente cruda efectivamente archivada
    select count(*) into n_archivada
    from public.verificacion_evidencia ve
    join public.evidencia e on e.id = ve.evidencia_id
    join interno.fuente_cruda fc on fc.id = e.fuente_cruda_id
    where ve.verificacion_id = new.id
      and (fc.storage_path is null or fc.sha256 is null);

    if n_archivada > 0 then
      raise exception
        'Hay evidencia sin fuente cruda archivada en la verificación %.', new.id;
    end if;

    if new.publicado_en is null then
      new.publicado_en := now();
    end if;
  end if;

  new.actualizado_en := now();
  return new;
end;
$$;

create trigger trg_verificacion_publicable
  before insert or update on public.verificacion
  for each row execute function public.fn_verificacion_publicable();


-- Inmutabilidad de los artefactos de evidencia
create or replace function public.fn_bloquear_modificacion()
returns trigger language plpgsql as $$
begin
  raise exception 'Registro inmutable: % no admite UPDATE ni DELETE.', tg_table_name;
end;
$$;

create trigger trg_captura_inmutable
  before update or delete on public.captura
  for each row execute function public.fn_bloquear_modificacion();

create trigger trg_fuente_cruda_inmutable
  before update or delete on interno.fuente_cruda
  for each row execute function public.fn_bloquear_modificacion();


-- =============================================================================
-- 9. AUDITORÍA APPEND-ONLY
-- =============================================================================

create table interno.auditoria (
  id            bigserial primary key,
  tabla         text not null,
  registro_id   text not null,
  accion        text not null,
  usuario_id    uuid,
  datos_antes   jsonb,
  datos_despues jsonb,
  ocurrido_en   timestamptz not null default now()
);

create or replace function interno.fn_auditar()
returns trigger language plpgsql security definer as $$
begin
  insert into interno.auditoria (tabla, registro_id, accion, usuario_id, datos_antes, datos_despues)
  values (
    tg_table_name,
    coalesce(new.id::text, old.id::text),
    tg_op,
    auth.uid(),
    case when tg_op in ('UPDATE','DELETE') then to_jsonb(old) end,
    case when tg_op in ('INSERT','UPDATE') then to_jsonb(new) end
  );
  return coalesce(new, old);
end;
$$;

create trigger trg_auditar_verificacion
  after insert or update or delete on public.verificacion
  for each row execute function interno.fn_auditar();

create trigger trg_auditar_evidencia
  after insert or update or delete on public.evidencia
  for each row execute function interno.fn_auditar();

create trigger trg_auditar_afirmacion
  after insert or update or delete on public.afirmacion
  for each row execute function interno.fn_auditar();


-- =============================================================================
-- 10. BÚSQUEDA EN ESPAÑOL
-- =============================================================================

alter table public.verificacion
  add column busqueda tsvector
  generated always as (
    setweight(to_tsvector('spanish', public.f_unaccent(coalesce(titulo_publico,''))), 'A') ||
    setweight(to_tsvector('spanish', public.f_unaccent(coalesce(resumen_hecho,''))),  'B') ||
    setweight(to_tsvector('spanish', public.f_unaccent(coalesce(metodologia,''))),    'D')
  ) stored;

create index verificacion_busqueda_idx on public.verificacion using gin (busqueda);
create index verificacion_publicada_idx on public.verificacion (publicado_en desc)
  where estado = 'publicada';
create index verificacion_veredicto_idx on public.verificacion (veredicto)
  where estado = 'publicada';


-- =============================================================================
-- 11. VISTA PÚBLICA (lo único que ve el anónimo)
-- =============================================================================

create or replace view public.v_ficha as
select
  v.id,
  v.slug,
  v.titulo_publico,
  v.veredicto,
  v.resumen_hecho,
  v.metodologia,
  v.analisis,
  v.publicado_en,
  v.version,
  a.texto_literal      as afirmacion,
  a.ts_inicio_seg,
  a.ts_fin_seg,
  a.contexto_previo,
  a.contexto_posterior,
  act.slug             as actor_slug,
  act.nombre_completo  as actor,
  c.titulo             as cargo,
  c.institucion,
  cap.url_original     as fuente_dicho_url,
  cap.snapshot_url     as fuente_dicho_snapshot,
  cap.publicado_en     as dicho_en
from public.verificacion v
join public.afirmacion a  on a.id = v.afirmacion_id
join public.actor act     on act.id = a.actor_id
join public.captura cap   on cap.id = a.captura_id
left join public.cargo c  on c.id = a.cargo_id
where v.estado = 'publicada';


-- =============================================================================
-- 12. RLS
-- =============================================================================

alter table public.verificacion            enable row level security;
alter table public.afirmacion              enable row level security;
alter table public.evidencia               enable row level security;
alter table public.captura                 enable row level security;
alter table public.actor                   enable row level security;
alter table public.cargo                   enable row level security;
alter table public.correccion              enable row level security;
alter table public.aporte                  enable row level security;
alter table public.usuario                 enable row level security;
alter table public.verificacion_evidencia  enable row level security;

-- Helper de rol
create or replace function public.fn_rol()
returns rol_usuario language sql stable security definer as $$
  select rol from public.usuario where id = auth.uid() and activo
$$;

-- Lectura pública: sólo lo publicado
create policy p_verif_lectura on public.verificacion
  for select using (estado = 'publicada' or public.fn_rol() is not null);

create policy p_actor_lectura   on public.actor      for select using (true);
create policy p_cargo_lectura   on public.cargo      for select using (true);
create policy p_correc_lectura  on public.correccion for select using (true);

create policy p_afirm_lectura on public.afirmacion
  for select using (
    public.fn_rol() is not null
    or exists (select 1 from public.verificacion v
               where v.afirmacion_id = afirmacion.id and v.estado = 'publicada')
  );

-- Escritura: sólo roles internos
create policy p_verif_escritura on public.verificacion
  for all using (public.fn_rol() in ('verificador','revisor','editor','admin'))
  with check (public.fn_rol() in ('verificador','revisor','editor','admin'));

create policy p_evid_escritura on public.evidencia
  for all using (public.fn_rol() in ('verificador','revisor','editor','admin'))
  with check (public.fn_rol() in ('verificador','revisor','editor','admin'));

-- Aportes: cualquiera inserta, nadie anónimo lee
create policy p_aporte_insert on public.aporte for insert with check (true);
create policy p_aporte_lectura on public.aporte
  for select using (public.fn_rol() is not null);

-- El esquema `interno` no se expone por la API en ningún caso.
revoke all on schema interno from anon, authenticated;
revoke all on all tables in schema interno from anon, authenticated;


-- =============================================================================
-- 13. SEMILLA DE VEREDICTOS (para la página de metodología)
-- =============================================================================
comment on type public.veredicto is
  'Escala pública. Debe estar documentada en /metodologia con ejemplos reales.';
