#!/usr/bin/env python3
"""
build_erm2026_db.py
Procesa files/candidatos_todos_jee.json y los catálogos de ubigeo para construir
la base de datos SQLite oficial database/erm2026.db para ERM 2026 (101,617+ candidatos).
"""

import os
import sys
import json
import csv
import sqlite3
import shutil
import re

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DB_PATH = os.path.join(BASE_DIR, 'database', 'erm2026.db')
BACKUP_PATH = os.path.join(BASE_DIR, 'database', 'erm2026.db.bak')
JSON_PATH = os.path.join(BASE_DIR, 'files', 'candidatos_todos_jee.json')
UBIGEO_RENIEC_PATH = os.path.join(BASE_DIR, 'database', 'ubigeo_reniec.csv')
UBIGEO_INEI_PATH = os.path.join(BASE_DIR, 'database', 'ubigeo_inei.csv')

def normalize_name(name_str):
    if not name_str:
        return ''
    clean = re.sub(r'[-_]+', ' ', name_str)
    return ' '.join(clean.split()).strip()

def extract_solicitud_id(exp_str):
    if not exp_str:
        return 0
    digits = re.sub(r'\D', '', exp_str)
    return int(digits) if digits else 0

def main():
    print("=== CONTEOYA: Construcción de Base de Datos erm2026.db ===")
    
    if not os.path.exists(JSON_PATH):
        print(f"Error: No se encontró el archivo {JSON_PATH}")
        sys.exit(1)

    if os.path.exists(DB_PATH):
        print(f"Creando respaldo en {BACKUP_PATH}...")
        shutil.copy2(DB_PATH, BACKUP_PATH)
        os.remove(DB_PATH)

    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    cursor.execute("PRAGMA journal_mode = WAL;")
    cursor.execute("PRAGMA synchronous = NORMAL;")
    cursor.execute("PRAGMA foreign_keys = OFF;")

    print("1. Creando tablas SQLite...")
    cursor.executescript("""
    CREATE TABLE departments (
        code VARCHAR(5) NOT NULL, 
        name VARCHAR(100) NOT NULL, 
        PRIMARY KEY (code)
    );

    CREATE TABLE provinces (
        code VARCHAR(5) NOT NULL, 
        name VARCHAR(100) NOT NULL, 
        department_code VARCHAR(5) NOT NULL, 
        PRIMARY KEY (code), 
        FOREIGN KEY(department_code) REFERENCES departments (code)
    );

    CREATE TABLE districts (
        code VARCHAR(6) NOT NULL, 
        name VARCHAR(100) NOT NULL, 
        department_code VARCHAR(5) NOT NULL, 
        province_code VARCHAR(5) NOT NULL, 
        PRIMARY KEY (code), 
        FOREIGN KEY(department_code) REFERENCES departments (code), 
        FOREIGN KEY(province_code) REFERENCES provinces (code)
    );

    CREATE TABLE political_organizations (
        id INTEGER NOT NULL, 
        name VARCHAR(255) NOT NULL, 
        short_name VARCHAR(50), 
        org_type VARCHAR(50), 
        logo_url TEXT, 
        PRIMARY KEY (id)
    );

    CREATE TABLE electoral_lists (
        id_solicitud_lista INTEGER NOT NULL, 
        organization_id INTEGER NOT NULL, 
        election_type VARCHAR(50) NOT NULL, 
        department_code VARCHAR(5), 
        province_code VARCHAR(5), 
        district_code VARCHAR(6), 
        status VARCHAR(50), 
        PRIMARY KEY (id_solicitud_lista), 
        FOREIGN KEY(organization_id) REFERENCES political_organizations (id)
    );

    CREATE TABLE candidates (
        id INTEGER PRIMARY KEY AUTOINCREMENT, 
        id_solicitud_lista INTEGER NOT NULL, 
        id_hoja_vida VARCHAR(100), 
        full_name VARCHAR(255) NOT NULL, 
        position VARCHAR(100) NOT NULL, 
        status VARCHAR(50), 
        list_number INTEGER, 
        photo_url TEXT, 
        FOREIGN KEY(id_solicitud_lista) REFERENCES electoral_lists (id_solicitud_lista)
    );

    CREATE TABLE candidate_cvs (
        id_hoja_vida VARCHAR(100) NOT NULL, 
        candidate_id INTEGER NOT NULL, 
        general_data JSON, 
        academic_data JSON, 
        work_experience JSON, 
        political_trajectory JSON, 
        sworn_declaration JSON, 
        penal_sentences JSON, 
        additional_info JSON, 
        PRIMARY KEY (id_hoja_vida), 
        FOREIGN KEY(candidate_id) REFERENCES candidates (id)
    );
    """)

    print("2. Cargando Ubigeos Base (RENIEC / INEI)...")
    departments = {}
    provinces = {}
    districts = {}

    if os.path.exists(UBIGEO_RENIEC_PATH):
        with open(UBIGEO_RENIEC_PATH, 'r', encoding='utf-8-sig') as f:
            reader = csv.reader(f)
            headers = next(reader, None)
            for row in reader:
                if len(row) >= 6:
                    dist_code = row[0].strip().zfill(6)
                    dep_code = row[1].strip().zfill(2)
                    dep_name = row[2].strip()
                    prov_code = row[3].strip().zfill(4)
                    prov_name = row[4].strip()
                    dist_name = row[5].strip()

                    departments[dep_code] = dep_name
                    provinces[prov_code] = (prov_name, dep_code)
                    districts[dist_code] = (dist_name, dep_code, prov_code)

    print(f"3. Leyendo y procesando {JSON_PATH} (199+ MB)...")
    with open(JSON_PATH, 'r', encoding='utf-8') as f:
        candidates_data = json.load(f)

    print(f"   Total registros leídos: {len(candidates_data):,}")

    orgs_map = {}
    lists_map = {}
    candidates_list = []

    # Enriquecer ubigeos desde los registros del JEE para soportar distritos de reciente creación
    for r in candidates_data:
        ubigeo = (r.get('strUbigeoPostula') or '').strip()
        dep_name = (r.get('strDepartamento') or '').strip()
        prov_name = (r.get('strProvincia') or '').strip()
        dist_name = (r.get('strDistrito') or '').strip()

        if len(ubigeo) >= 2:
            dep_code = ubigeo[:2]
            if dep_code not in departments and dep_name:
                departments[dep_code] = dep_name

        if len(ubigeo) >= 4 and ubigeo[2:4] != '00':
            prov_code = ubigeo[:4]
            dep_code = ubigeo[:2]
            if prov_code not in provinces and prov_name:
                provinces[prov_code] = (prov_name, dep_code)

        if len(ubigeo) >= 6 and ubigeo[4:6] != '00':
            dist_code = ubigeo[:6]
            prov_code = ubigeo[:4]
            dep_code = ubigeo[:2]
            if dist_code not in districts and dist_name:
                districts[dist_code] = (dist_name, dep_code, prov_code)

    # Insertar departamentos, provincias y distritos completos
    cursor.executemany("INSERT OR REPLACE INTO departments (code, name) VALUES (?, ?)",
                       [(k, v) for k, v in departments.items()])
    cursor.executemany("INSERT OR REPLACE INTO provinces (code, name, department_code) VALUES (?, ?, ?)",
                       [(k, v[0], v[1]) for k, v in provinces.items()])
    cursor.executemany("INSERT OR REPLACE INTO districts (code, name, department_code, province_code) VALUES (?, ?, ?, ?)",
                       [(k, v[0], v[1], v[2]) for k, v in districts.items()])

    print(f"   Departamentos: {len(departments)}, Provincias: {len(provinces)}, Distritos: {len(districts)}")

    for r in candidates_data:
        # 1. Organización Política
        org_id = r.get('idOrganizacionPolitica')
        org_name = (r.get('strOrganizacionPolitica') or '').strip()
        org_type = (r.get('strTipoOrgPolitica') or 'PARTIDO POLÍTICO').strip()
        if org_id and org_id not in orgs_map:
            logo_url = f"https://stovotoinformadodev.blob.core.windows.net/contenedor-2/{org_id}.png"
            orgs_map[org_id] = (org_id, org_name, None, org_type, logo_url)

        # 2. Lista Electoral
        exp_str = (r.get('strCodExpedienteExt') or '').strip()
        solicitud_id = extract_solicitud_id(exp_str)
        election_type = (r.get('strTipoEleccion') or 'MUNICIPAL DISTRITAL').strip().upper()
        ubigeo = (r.get('strUbigeoPostula') or '').strip()
        list_status = (r.get('strEstado') or 'INSCRITO').strip().upper()

        dep_code = None
        prov_code = None
        dist_code = None

        if len(ubigeo) >= 2:
            dep_code = ubigeo[:2]
        if len(ubigeo) >= 4 and ubigeo[2:4] != '00':
            prov_code = ubigeo[:4]
        if len(ubigeo) >= 6 and ubigeo[4:6] != '00':
            dist_code = ubigeo[:6]

        if election_type == 'REGIONAL':
            prov_code = None
            dist_code = None
        elif election_type == 'MUNICIPAL PROVINCIAL':
            dist_code = None

        if solicitud_id and solicitud_id not in lists_map:
            lists_map[solicitud_id] = (
                solicitud_id,
                org_id,
                election_type,
                dep_code,
                prov_code,
                dist_code,
                list_status
            )

        # 3. Candidato
        dni = (r.get('strDocumentoIdentidad') or '').strip()
        raw_name = (r.get('strNombreCompleto') or '').strip()
        full_name = normalize_name(raw_name)
        position = (r.get('strCargoEleccion') or 'CANDIDATO').strip().upper()
        cand_status = (r.get('strEstadoPersona') or list_status or 'INSCRITO').strip().upper()
        list_number = r.get('idPosicion') or 0
        photo_url = f"https://stovotoinformadodev.blob.core.windows.net/contenedor-1/{dni}.jpg" if dni else None

        candidates_list.append((
            solicitud_id,
            dni,
            full_name,
            position,
            cand_status,
            list_number,
            photo_url
        ))

    print(f"4. Insertando Organizaciones Políticas ({len(orgs_map)})...")
    cursor.executemany(
        "INSERT OR REPLACE INTO political_organizations (id, name, short_name, org_type, logo_url) VALUES (?, ?, ?, ?, ?)",
        list(orgs_map.values())
    )

    print(f"5. Insertando Listas Electorales ({len(lists_map):,})...")
    cursor.executemany(
        "INSERT OR REPLACE INTO electoral_lists (id_solicitud_lista, organization_id, election_type, department_code, province_code, district_code, status) VALUES (?, ?, ?, ?, ?, ?, ?)",
        list(lists_map.values())
    )

    print(f"6. Insertando Candidatos ({len(candidates_list):,})...")
    cursor.executemany(
        "INSERT INTO candidates (id_solicitud_lista, id_hoja_vida, full_name, position, status, list_number, photo_url) VALUES (?, ?, ?, ?, ?, ?, ?)",
        candidates_list
    )

    print("7. Creando Índices para consultas de alta velocidad...")
    cursor.executescript("""
    CREATE INDEX IF NOT EXISTS idx_candidates_solicitud ON candidates (id_solicitud_lista);
    CREATE INDEX IF NOT EXISTS idx_candidates_hoja_vida ON candidates (id_hoja_vida);
    CREATE INDEX IF NOT EXISTS idx_candidates_position ON candidates (position);
    CREATE INDEX IF NOT EXISTS idx_candidates_status ON candidates (status);
    CREATE INDEX IF NOT EXISTS idx_electoral_lists_org ON electoral_lists (organization_id);
    CREATE INDEX IF NOT EXISTS idx_electoral_lists_ubigeo ON electoral_lists (department_code, province_code, district_code);
    CREATE INDEX IF NOT EXISTS idx_electoral_lists_type ON electoral_lists (election_type);
    """)

    conn.commit()
    cursor.execute("PRAGMA optimize;")
    conn.close()

    print("\n✅ Base de datos SQLite erm2026.db construida con éxito con Ubigeos RENIEC!")

if __name__ == '__main__':
    main()
