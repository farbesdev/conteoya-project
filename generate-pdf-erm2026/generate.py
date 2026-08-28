import os
import sys
import random
import argparse
from pathlib import Path
import psycopg2
import psycopg2.extras
from dotenv import load_dotenv

from reportlab.lib.pagesizes import A4
from reportlab.lib import colors
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, PageBreak
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import cm

def load_db_config():
    script_dir = Path(__file__).resolve().parent
    env_paths = [script_dir / "../api/.env", script_dir / ".env", Path.cwd() / "api/.env", Path.cwd() / ".env"]
    for p in env_paths:
        if p.exists():
            load_dotenv(p)
            break
    return {
        "host": os.getenv("DB_HOST", "127.0.0.1"),
        "port": os.getenv("DB_PORT", "5432"),
        "database": os.getenv("DB_DATABASE", "conteoya_bd"),
        "user": os.getenv("DB_USERNAME", "postgres"),
        "password": os.getenv("DB_PASSWORD", "150185"),
    }

def get_db_connection():
    cfg = load_db_config()
    try:
        return psycopg2.connect(host=cfg["host"], port=cfg["port"], dbname=cfg["database"], user=cfg["user"], password=cfg["password"], cursor_factory=psycopg2.extras.DictCursor)
    except Exception as e:
        print(f"Error PostgreSQL: {e}")
        sys.exit(1)

def fetch_mesa_data(conn, mesa_code):
    cur = conn.cursor()
    q = "SELECT ps.code as mesa_code, ps.registered_voters, ps.status as station_status, ps.odpe, ps.department_name, ps.province_name, ps.district_name, d.code as department_code, p.code as province_code, dist.code as district_code FROM polling_stations ps LEFT JOIN departments d ON UPPER(TRIM(d.name)) = UPPER(TRIM(ps.department_name)) LEFT JOIN provinces p ON UPPER(TRIM(p.name)) = UPPER(TRIM(ps.province_name)) AND p.department_code = d.code LEFT JOIN districts dist ON UPPER(TRIM(dist.name)) = UPPER(TRIM(ps.district_name)) AND dist.province_code = p.code WHERE ps.code = %s LIMIT 1;"
    cur.execute(q, (mesa_code,))
    r = cur.fetchone()
    return dict(r) if r else None

def fetch_regional_lists(conn, department_code):
    cur = conn.cursor()
    q = "SELECT DISTINCT po.name as org_name, po.short_name as org_short_name, el.status as list_status, el.jee_solicitud_id FROM electoral_lists el JOIN political_organizations po ON po.id = el.political_organization_id JOIN electoral_levels lvl ON lvl.id = el.electoral_level_id WHERE lvl.code = 'REGIONAL_GOBERNADOR' AND el.department_code = %s AND el.status IN ('INSCRITO', 'ADMITIDO', 'INSCRITA', 'ADMITIDA') ORDER BY po.name ASC;"
    cur.execute(q, (department_code,))
    return [dict(r) for r in cur.fetchall()]

def fetch_municipal_lists(conn, department_code, province_code, district_code):
    cur = conn.cursor()
    qp = "SELECT DISTINCT po.name as org_name, po.short_name as org_short_name, el.status as list_status, el.jee_solicitud_id FROM electoral_lists el JOIN political_organizations po ON po.id = el.political_organization_id JOIN electoral_levels lvl ON lvl.id = el.electoral_level_id WHERE lvl.code = 'MUNICIPAL_PROVINCIAL' AND el.department_code = %s AND el.province_code = %s AND el.status IN ('INSCRITO', 'ADMITIDO', 'INSCRITA', 'ADMITIDA') ORDER BY po.name ASC;"
    cur.execute(qp, (department_code, province_code))
    prov = [dict(r) for r in cur.fetchall()]
    qd = "SELECT DISTINCT po.name as org_name, po.short_name as org_short_name, el.status as list_status, el.jee_solicitud_id FROM electoral_lists el JOIN political_organizations po ON po.id = el.political_organization_id JOIN electoral_levels lvl ON lvl.id = el.electoral_level_id WHERE lvl.code = 'MUNICIPAL_DISTRITAL' AND el.department_code = %s AND el.province_code = %s AND el.district_code = %s AND el.status IN ('INSCRITO', 'ADMITIDO', 'INSCRITA', 'ADMITIDA') ORDER BY po.name ASC;"
    cur.execute(qd, (department_code, province_code, district_code))
    dist = [dict(r) for r in cur.fetchall()]
    return prov, dist

def distribuir_votos(total_votantes, num_op):
    if num_op <= 0 or total_votantes <= 0:
        return []
    if num_op == 1:
        return [total_votantes]
    raw = [random.uniform(0.5, 3.5) for _ in range(num_op)]
    sw = sum(raw)
    votos = [int((w / sw) * total_votantes) for w in raw]
    dif = total_votantes - sum(votos)
    while dif > 0:
        idx = random.randint(0, num_op - 1)
        votos[idx] += 1
        dif -= 1
    while dif < 0:
        idx = random.randint(0, num_op - 1)
        if votos[idx] > 0:
            votos[idx] -= 1
            dif += 1
    return votos

def simular_escrutinio(electores_habiles, orgs_list):
    if electores_habiles <= 0:
        electores_habiles = 300
    min_v = max(10, int(electores_habiles * 0.78))
    max_v = min(electores_habiles, int(electores_habiles * 0.93))
    ciudadanos = random.randint(min_v, max_v)
    no_val = random.randint(5, max(8, int(ciudadanos * 0.08)))
    val = ciudadanos - no_val
    blancos = random.randint(1, no_val // 2)
    nulos = no_val - blancos
    imp = 0
    num_ops = len(orgs_list)
    v_ops = distribuir_votos(val, num_ops)
    d_votos = {orgs_list[i]: v_ops[i] for i in range(num_ops)}
    tot_emit = sum(v_ops) + blancos + nulos + imp
    return {
        "ciudadanos_votaron": ciudadanos,
        "votos_ops": d_votos,
        "votos_blancos": blancos,
        "votos_nulos": nulos,
        "votos_impugnados": imp,
        "total_emitidos": tot_emit
    }

from reportlab.graphics.shapes import Drawing, Rect, String

def draw_checkbox_symbol():
    d = Drawing(14, 14)
    d.add(Rect(1, 2, 10, 10, fillColor=colors.white, strokeColor=colors.black, strokeWidth=1))
    return d

def make_sig_line(w=135):
    d = Drawing(w, 14)
    d.add(Rect(0, 10, w - 5, 0.75, fillColor=colors.black, strokeColor=colors.black))
    return d

def crear_estilos():
    styles = getSampleStyleSheet()
    return {
        "header_onpe": ParagraphStyle("HdrOnpe", parent=styles["Normal"], fontName="Helvetica-Bold", fontSize=8.5, alignment=1, leading=9.5),
        "header_onpe_sub": ParagraphStyle("HdrOnpeSub", parent=styles["Normal"], fontName="Helvetica", fontSize=5.5, alignment=1, leading=6.5),
        "header_badge": ParagraphStyle("HdrBadge", parent=styles["Normal"], fontName="Helvetica-Bold", fontSize=11, alignment=1, leading=12, textColor=colors.white),
        "title_top": ParagraphStyle("TTop", parent=styles["Normal"], fontName="Helvetica-Bold", fontSize=7.5, alignment=1, leading=9),
        "title_mid": ParagraphStyle("TMid", parent=styles["Normal"], fontName="Helvetica-Bold", fontSize=9.5, alignment=1, leading=11.5),
        "title_acta": ParagraphStyle("TActa", parent=styles["Normal"], fontName="Helvetica-Bold", fontSize=12.5, alignment=1, leading=14),
        "meta_lbl": ParagraphStyle("MetaLbl", parent=styles["Normal"], fontName="Helvetica", fontSize=5, leading=6, textColor=colors.HexColor("#222222")),
        "meta_val": ParagraphStyle("MetaVal", parent=styles["Normal"], fontName="Helvetica-Bold", fontSize=12, leading=13),
        "ubigeo_lbl": ParagraphStyle("UbiLbl", parent=styles["Normal"], fontName="Helvetica", fontSize=5, leading=6, textColor=colors.HexColor("#222222")),
        "ubigeo_val": ParagraphStyle("UbiVal", parent=styles["Normal"], fontName="Helvetica-Bold", fontSize=8, leading=9.5),
        "sec_title": ParagraphStyle("SecTitle", parent=styles["Normal"], fontName="Helvetica-Bold", fontSize=8.5, leading=10),
        "sec_sub": ParagraphStyle("SecSub", parent=styles["Normal"], fontName="Helvetica", fontSize=6.5, leading=7.5),
        "sec_orgs": ParagraphStyle("SecOrgs", parent=styles["Normal"], fontName="Helvetica-Bold", fontSize=7, leading=8),
        "th_col": ParagraphStyle("THCol", parent=styles["Normal"], fontName="Helvetica-Bold", fontSize=5.5, alignment=1, leading=6.8),
        "td_num": ParagraphStyle("TDNum", parent=styles["Normal"], fontName="Helvetica", fontSize=6.5, alignment=1, leading=7.5),
        "td_org": ParagraphStyle("TDOrg", parent=styles["Normal"], fontName="Helvetica-Bold", fontSize=6.5, leading=7.5),
        "td_val": ParagraphStyle("TDVal", parent=styles["Normal"], fontName="Helvetica", fontSize=7.5, alignment=1, leading=8.5),
        "td_tot_lbl": ParagraphStyle("TDTotLbl", parent=styles["Normal"], fontName="Helvetica-Bold", fontSize=6.5, leading=7.5),
        "td_tot_val": ParagraphStyle("TDTotVal", parent=styles["Normal"], fontName="Helvetica-Bold", fontSize=7.5, alignment=1, leading=8.5),
        "obs_lbl": ParagraphStyle("ObsLbl", parent=styles["Normal"], fontName="Helvetica-Oblique", fontSize=6, leading=7),
        "obs_txt": ParagraphStyle("ObsTxt", parent=styles["Normal"], fontName="Helvetica-Oblique", fontSize=6.5, leading=7.5),
        "sig_role": ParagraphStyle("SigRole", parent=styles["Normal"], fontName="Helvetica-Bold", fontSize=6, alignment=1, leading=7),
        "sig_sec": ParagraphStyle("SigSec", parent=styles["Normal"], fontName="Helvetica-Bold", fontSize=7, leading=8),
        "sig_sub_p": ParagraphStyle("SigSubP", parent=styles["Normal"], fontName="Helvetica", fontSize=5.5, leading=6.5),
    }

def build_acta_elements(mesa_data, tipo_acta, st):
    elements = []
    mesa_code = mesa_data["mesa_code"]
    habiles = mesa_data["registered_voters"]
    dept = mesa_data["department_name"] or "---"
    prov = mesa_data["province_name"] or "---"
    dist = mesa_data["district_name"] or "---"
    badge_code = "1b" if tipo_acta == "REGIONAL" else "4b"
    title_level_text = "GOBERNADOR Y VICEGOBERNADOR REGIONAL" if tipo_acta == "REGIONAL" else "MUNICIPAL PROVINCIAL - DISTRITAL"

    # A. Logo ONPE | Titulo Central | Badge 4b/1b
    onpe_box = [
        Paragraph("<b>ONPE</b>", st["header_onpe"]),
        Paragraph("(plantilla)", st["header_onpe_sub"])
    ]

    center_table = Table(
        [
            [Paragraph("ELECCIONES REGIONALES Y MUNICIPALES 2026", st["title_top"])],
            [Paragraph(f"<b>{title_level_text}</b>", st["title_mid"])],
            [Table([[Paragraph("<b>ACTA ELECTORAL</b>", st["title_acta"]), draw_checkbox_symbol()]], colWidths=[175, 16], hAlign="CENTER")]
        ],
        colWidths=[14.8 * cm]
    )
    center_table.setStyle(TableStyle([
        ("ALIGN", (0,0), (-1,-1), "CENTER"),
        ("VALIGN", (0,0), (-1,-1), "MIDDLE"),
        ("TOPPADDING", (0,0), (-1,-1), 0),
        ("BOTTOMPADDING", (0,0), (-1,-1), 0),
    ]))

    badge_d = Drawing(34, 22)
    badge_d.add(Rect(0, 0, 34, 22, rx=2, ry=2, fillColor=colors.black, strokeColor=colors.black))
    badge_d.add(String(17, 6, badge_code, fontName="Helvetica-Bold", fontSize=11, fillColor=colors.white, textAnchor="middle"))

    t_header = Table([[onpe_box, center_table, badge_d]], colWidths=[1.8 * cm, 14.8 * cm, 1.6 * cm])
    t_header.setStyle(TableStyle([
        ("BOX", (0,0), (0,0), 1, colors.black),
        ("VALIGN", (0,0), (-1,-1), "MIDDLE"),
        ("ALIGN", (0,0), (-1,-1), "CENTER"),
        ("TOPPADDING", (0,0), (-1,-1), 0),
        ("BOTTOMPADDING", (0,0), (-1,-1), 0),
        ("LEFTPADDING", (0,0), (0,0), 2),
        ("RIGHTPADDING", (0,0), (0,0), 2),
    ]))
    elements.append(t_header)
    elements.append(Spacer(1, 0.15 * cm))

    # B. Cajas Mesa y Electores Habiles
    box_mesa = [Paragraph("MESA DE SUFRAGIO Nº", st["meta_lbl"]), Paragraph(f"<b>{mesa_code}</b>", st["meta_val"])]
    box_habiles = [Paragraph("TOTAL DE ELECTORES HÁBILES", st["meta_lbl"]), Paragraph(f"<b>{habiles}</b>", st["meta_val"])]
    t_meta = Table([[box_mesa, "", box_habiles]], colWidths=[4.6 * cm, 9.0 * cm, 4.6 * cm])
    t_meta.setStyle(TableStyle([
        ("BOX", (0,0), (0,0), 1, colors.black),
        ("BOX", (2,0), (2,0), 1, colors.black),
        ("VALIGN", (0,0), (-1,-1), "TOP"),
        ("TOPPADDING", (0,0), (-1,-1), 1.5),
        ("BOTTOMPADDING", (0,0), (-1,-1), 1.5),
        ("LEFTPADDING", (0,0), (-1,-1), 4),
        ("RIGHTPADDING", (0,0), (-1,-1), 4),
    ]))
    elements.append(t_meta)
    elements.append(Spacer(1, 0.12 * cm))

    # C. Cajas de Ubicacion
    t_ubi = Table([[[Paragraph("DEPARTAMENTO", st["ubigeo_lbl"]), Paragraph(f"<b>{dept}</b>", st["ubigeo_val"])], [Paragraph("PROVINCIA", st["ubigeo_lbl"]), Paragraph(f"<b>{prov}</b>", st["ubigeo_val"])], [Paragraph("DISTRITO", st["ubigeo_lbl"]), Paragraph(f"<b>{dist}</b>", st["ubigeo_val"])]]], colWidths=[6.0 * cm, 6.0 * cm, 6.2 * cm])
    t_ubi.setStyle(TableStyle([
        ("BOX", (0,0), (-1,-1), 1, colors.black),
        ("INNERGRID", (0,0), (-1,-1), 1, colors.black),
        ("VALIGN", (0,0), (-1,-1), "TOP"),
        ("TOPPADDING", (0,0), (-1,-1), 1.5),
        ("BOTTOMPADDING", (0,0), (-1,-1), 1.5),
        ("LEFTPADDING", (0,0), (-1,-1), 4),
    ]))
    elements.append(t_ubi)
    elements.append(Spacer(1, 0.12 * cm))

    # D. Encabezado Seccion Escrutinio
    elements.append(Paragraph("<b>C &nbsp; ACTA DE ESCRUTINIO</b>", st["sec_title"]))
    elements.append(Paragraph("Siendo las ... 17:01 HORAS ... del 4 de octubre de 2026, se inició el ACTO DE ESCRUTINIO.", st["sec_sub"]))
    elements.append(Spacer(1, 0.04 * cm))
    elements.append(Paragraph("&nbsp;&nbsp;&nbsp;&nbsp;<b>ORGANIZACIONES POLÍTICAS</b>", st["sec_orgs"]))
    elements.append(Spacer(1, 0.04 * cm))

    if tipo_acta == "REGIONAL":
        orgs = [o["org_name"] for o in mesa_data["regional_lists"]]
        if not orgs:
            orgs = ["SIN LISTAS INSCRITAS"]
        sim = simular_escrutinio(habiles, orgs)
        num_rows = len(orgs)
        pad_v = 0.8 if num_rows > 16 else (1.5 if num_rows > 10 else 2.5)
        font_sz = 5.2 if num_rows > 16 else (6.2 if num_rows > 10 else 7.0)
        st_td_org = ParagraphStyle("TDO_Dyn", parent=st["td_org"], fontSize=font_sz, leading=font_sz + 1.1)
        st_td_val = ParagraphStyle("TDV_Dyn", parent=st["td_val"], fontSize=font_sz + 0.5, leading=font_sz + 1.3)

        table_data = [["", "", Paragraph("TOTAL VOTOS<br/>GOBERNADOR REGIONAL", st["th_col"])]]
        for i, org in enumerate(orgs, 1):
            v_val = str(sim["votos_ops"].get(org, 0))
            table_data.append([Paragraph(str(i), st["td_num"]), Paragraph(org, st_td_org), Paragraph(v_val, st_td_val)])

        col_w = [0.8 * cm, 13.6 * cm, 3.8 * cm]
        t_style = [
            ("BOX", (0,0), (-1,-1), 1, colors.black),
            ("INNERGRID", (0,0), (-1,-1), 0.5, colors.black),
            ("BACKGROUND", (0,0), (-1,0), colors.HexColor("#ECEFF1")),
            ("VALIGN", (0,0), (-1,-1), "MIDDLE"),
            ("TOPPADDING", (0,0), (-1,-1), pad_v),
            ("BOTTOMPADDING", (0,0), (-1,-1), pad_v),
            ("LEFTPADDING", (0,0), (-1,-1), 3),
            ("RIGHTPADDING", (0,0), (-1,-1), 3),
        ]
        t_votos = Table(table_data, colWidths=col_w)
        t_votos.setStyle(TableStyle(t_style))
        elements.append(t_votos)
        elements.append(Spacer(1, 0.08 * cm))

        totales_data = [
            [Paragraph("<b>VOTOS EN BLANCO</b>", st["td_tot_lbl"]), "", Paragraph(f"<b>{sim['votos_blancos']}</b>", st["td_tot_val"])],
            [Paragraph("<b>VOTOS NULOS</b>", st["td_tot_lbl"]), "", Paragraph(f"<b>{sim['votos_nulos']}</b>", st["td_tot_val"])],
            [Paragraph("<b>VOTOS IMPUGNADOS</b>", st["td_tot_lbl"]), "", Paragraph(f"<b>{sim['votos_impugnados']}</b>", st["td_tot_val"])],
            [Paragraph("<b>TOTAL DE VOTOS EMITIDOS</b>", st["td_tot_lbl"]), "", Paragraph(f"<b>{sim['total_emitidos']}</b>", st["td_tot_val"])],
            [Paragraph("<b>TOTAL DE CIUDADANOS QUE VOTARON</b>", st["td_tot_lbl"]), "", Paragraph(f"<b>{sim['ciudadanos_votaron']}</b>", st["td_tot_val"])],
        ]
        t_tot_style = [
            ("BOX", (0,0), (-1,-1), 1, colors.black),
            ("INNERGRID", (0,0), (-1,-1), 0.5, colors.black),
            ("VALIGN", (0,0), (-1,-1), "MIDDLE"),
            ("TOPPADDING", (0,0), (-1,-1), pad_v),
            ("BOTTOMPADDING", (0,0), (-1,-1), pad_v),
            ("LEFTPADDING", (0,0), (-1,-1), 3),
            ("RIGHTPADDING", (0,0), (-1,-1), 3),
            ("SPAN", (0,0), (1,0)),
            ("SPAN", (0,1), (1,1)),
            ("SPAN", (0,2), (1,2)),
            ("SPAN", (0,3), (1,3)),
            ("SPAN", (0,4), (1,4)),
        ]
        t_tot = Table(totales_data, colWidths=col_w)
        t_tot.setStyle(TableStyle(t_tot_style))
        elements.append(t_tot)

    else:  # MUNICIPAL (4b)
        prov_orgs = [o["org_name"] for o in mesa_data["prov_lists"]]
        dist_orgs = [o["org_name"] for o in mesa_data["dist_lists"]]
        all_ops = sorted(list(set(prov_orgs + dist_orgs)))
        if not all_ops:
            all_ops = ["SIN LISTAS INSCRITAS"]
        sim_p = simular_escrutinio(habiles, prov_orgs)
        ciudadanos_votaron = sim_p["ciudadanos_votaron"]
        no_validos_d = random.randint(5, max(8, int(ciudadanos_votaron * 0.08)))
        validos_d = ciudadanos_votaron - no_validos_d
        v_ops_d = distribuir_votos(validos_d, len(dist_orgs))
        dict_dist = {dist_orgs[i]: v_ops_d[i] for i in range(len(dist_orgs))}
        blancos_d = random.randint(1, no_validos_d // 2)
        nulos_d = no_validos_d - blancos_d
        imp_d = 0

        num_rows = len(all_ops)
        pad_v = 0.5 if num_rows > 18 else (1.2 if num_rows > 10 else 2.2)
        font_sz = 4.8 if num_rows > 18 else (5.8 if num_rows > 10 else 6.8)
        st_td_org = ParagraphStyle("TDO_DynM", parent=st["td_org"], fontSize=font_sz, leading=font_sz + 0.9)
        st_td_val = ParagraphStyle("TDV_DynM", parent=st["td_val"], fontSize=font_sz + 0.3, leading=font_sz + 1.1)

        table_data = [["", "", Paragraph("TOTAL VOTOS<br/>MUNICIPAL PROVINCIAL", st["th_col"]), Paragraph("TOTAL VOTOS<br/>MUNICIPAL DISTRITAL", st["th_col"])]]
        for i, op in enumerate(all_ops, 1):
            val_p = str(sim_p["votos_ops"].get(op, 0)) if op in prov_orgs else "0"
            val_d = str(dict_dist.get(op, 0)) if op in dist_orgs else "0"
            table_data.append([Paragraph(str(i), st["td_num"]), Paragraph(op, st_td_org), Paragraph(val_p, st_td_val), Paragraph(val_d, st_td_val)])

        col_w = [0.8 * cm, 10.4 * cm, 3.5 * cm, 3.5 * cm]
        t_style = [
            ("BOX", (0,0), (-1,-1), 1, colors.black),
            ("INNERGRID", (0,0), (-1,-1), 0.5, colors.black),
            ("BACKGROUND", (0,0), (-1,0), colors.HexColor("#ECEFF1")),
            ("VALIGN", (0,0), (-1,-1), "MIDDLE"),
            ("TOPPADDING", (0,0), (-1,-1), pad_v),
            ("BOTTOMPADDING", (0,0), (-1,-1), pad_v),
            ("LEFTPADDING", (0,0), (-1,-1), 3),
            ("RIGHTPADDING", (0,0), (-1,-1), 3),
        ]
        t_votos = Table(table_data, colWidths=col_w)
        t_votos.setStyle(TableStyle(t_style))
        elements.append(t_votos)
        elements.append(Spacer(1, 0.08 * cm))

        totales_data = [
            [Paragraph("<b>VOTOS EN BLANCO</b>", st["td_tot_lbl"]), "", Paragraph(f"<b>{sim_p['votos_blancos']}</b>", st["td_tot_val"]), Paragraph(f"<b>{blancos_d}</b>", st["td_tot_val"])],
            [Paragraph("<b>VOTOS NULOS</b>", st["td_tot_lbl"]), "", Paragraph(f"<b>{sim_p['votos_nulos']}</b>", st["td_tot_val"]), Paragraph(f"<b>{nulos_d}</b>", st["td_tot_val"])],
            [Paragraph("<b>VOTOS IMPUGNADOS</b>", st["td_tot_lbl"]), "", Paragraph(f"<b>{sim_p['votos_impugnados']}</b>", st["td_tot_val"]), Paragraph(f"<b>{imp_d}</b>", st["td_tot_val"])],
            [Paragraph("<b>TOTAL DE VOTOS EMITIDOS</b>", st["td_tot_lbl"]), "", Paragraph(f"<b>{sim_p['total_emitidos']}</b>", st["td_tot_val"]), Paragraph(f"<b>{ciudadanos_votaron}</b>", st["td_tot_val"])],
            [Paragraph("<b>TOTAL DE CIUDADANOS QUE VOTARON</b>", st["td_tot_lbl"]), "", Paragraph(f"<b>{ciudadanos_votaron}</b>", st["td_tot_val"]), Paragraph(f"<b>{ciudadanos_votaron}</b>", st["td_tot_val"])],
        ]
        t_tot_style = [
            ("BOX", (0,0), (-1,-1), 1, colors.black),
            ("INNERGRID", (0,0), (-1,-1), 0.5, colors.black),
            ("VALIGN", (0,0), (-1,-1), "MIDDLE"),
            ("TOPPADDING", (0,0), (-1,-1), pad_v),
            ("BOTTOMPADDING", (0,0), (-1,-1), pad_v),
            ("LEFTPADDING", (0,0), (-1,-1), 3),
            ("RIGHTPADDING", (0,0), (-1,-1), 3),
            ("SPAN", (0,0), (1,0)),
            ("SPAN", (0,1), (1,1)),
            ("SPAN", (0,2), (1,2)),
            ("SPAN", (0,3), (1,3)),
            ("SPAN", (0,4), (1,4)),
        ]
        t_tot = Table(totales_data, colWidths=col_w)
        t_tot.setStyle(TableStyle(t_tot_style))
        elements.append(t_tot)

    # 6. Observaciones y Cierre
    elements.append(Spacer(1, 0.08 * cm))
    elements.append(Paragraph("Siendo las ... 18:20 HORAS ... finalizó el ACTO DE ESCRUTINIO.", st["sec_sub"]))
    elements.append(Spacer(1, 0.06 * cm))

    obs_box = [
        Paragraph("<i>OBSERVACIONES:</i>", st["obs_lbl"]),
        Spacer(1, 1),
        Paragraph("<i>( X ) &nbsp; NO HAY OBSERVACIONES</i>", st["obs_txt"])
    ]
    t_obs = Table([[obs_box]], colWidths=[18.2 * cm])
    t_obs.setStyle(TableStyle([
        ("BOX", (0,0), (-1,-1), 1, colors.black),
        ("TOPPADDING", (0,0), (-1,-1), 2),
        ("BOTTOMPADDING", (0,0), (-1,-1), 3),
        ("LEFTPADDING", (0,0), (-1,-1), 4),
    ]))
    elements.append(t_obs)
    elements.append(Spacer(1, 0.12 * cm))

    # 7. Firmas Miembros (Lineas continuas vectoriales)
    elements.append(Paragraph("<b>FIRMA DE LOS MIEMBROS DE MESA (OBLIGATORIO)</b>", st["sig_sec"]))
    elements.append(Spacer(1, 0.35 * cm))

    t_firmas_miembros = Table(
        [[
            [make_sig_line(135), Paragraph("PRESIDENTE", st["sig_role"])],
            [make_sig_line(135), Paragraph("SECRETARIO", st["sig_role"])],
            [make_sig_line(135), Paragraph("TERCER MIEMBRO", st["sig_role"])]
        ]],
        colWidths=[6.0 * cm, 6.0 * cm, 6.2 * cm]
    )
    t_firmas_miembros.setStyle(TableStyle([
        ("ALIGN", (0,0), (-1,-1), "CENTER"),
        ("VALIGN", (0,0), (-1,-1), "TOP"),
        ("BOTTOMPADDING", (0,0), (-1,-1), 0),
        ("TOPPADDING", (0,0), (-1,-1), 0),
    ]))
    elements.append(t_firmas_miembros)
    elements.append(Spacer(1, 0.12 * cm))

    # 8. Firma Personero (Linea continua vectorial)
    elements.append(Paragraph("<b>FIRMA Y HUELLA DEL PERSONERO QUE RECIBE COPIA (OPCIONAL)</b>", st["sig_sec"]))
    elements.append(Spacer(1, 0.35 * cm))

    t_firma_personero = Table(
        [[
            [make_sig_line(180), Paragraph("Nombre / DNI / Organización política", st["sig_sub_p"])],
            ""
        ]],
        colWidths=[9.0 * cm, 9.2 * cm]
    )
    t_firma_personero.setStyle(TableStyle([
        ("ALIGN", (0,0), (-1,-1), "LEFT"),
        ("VALIGN", (0,0), (-1,-1), "TOP"),
        ("BOTTOMPADDING", (0,0), (-1,-1), 0),
        ("TOPPADDING", (0,0), (-1,-1), 0),
    ]))
    elements.append(t_firma_personero)

    return elements

def generar_actas_para_mesa(conn, mesa_code, output_dir="output_pdf"):
    print(f"\n[INFO] Consultando datos para la Mesa {mesa_code}...")
    mesa_info = fetch_mesa_data(conn, mesa_code)
    if not mesa_info:
        print(f"[ERROR] La mesa con codigo '{mesa_code}' no existe en la base de datos.")
        return None
    print(f"  Ubicacion: {mesa_info['department_name']} / {mesa_info['province_name']} / {mesa_info['district_name']}")
    print(f"  Electores Habiles: {mesa_info['registered_voters']} | ODPE: {mesa_info['odpe']}")
    d_code = mesa_info["department_code"]
    p_code = mesa_info["province_code"]
    dist_code = mesa_info["district_code"]
    reg_lists = fetch_regional_lists(conn, d_code)
    prov_lists, dist_lists = fetch_municipal_lists(conn, d_code, p_code, dist_code)
    mesa_info["regional_lists"] = reg_lists
    mesa_info["prov_lists"] = prov_lists
    mesa_info["dist_lists"] = dist_lists
    print(f"  Listas: Regionales (1b)={len(reg_lists)}, Provinciales={len(prov_lists)}, Distritales={len(dist_lists)}")
    out_path = Path(output_dir)
    out_path.mkdir(parents=True, exist_ok=True)
    styles = crear_estilos()
    pdf_reg_name = out_path / f"Acta_Regional_1b_Mesa_{mesa_code}.pdf"
    doc_reg = SimpleDocTemplate(str(pdf_reg_name), pagesize=A4, leftMargin=1.0 * cm, rightMargin=1.0 * cm, topMargin=0.8 * cm, bottomMargin=0.8 * cm)
    doc_reg.build(build_acta_elements(mesa_info, "REGIONAL", styles))
    print(f"  -> PDF Regional generado: {pdf_reg_name}")
    pdf_mun_name = out_path / f"Acta_Municipal_4b_Mesa_{mesa_code}.pdf"
    doc_mun = SimpleDocTemplate(str(pdf_mun_name), pagesize=A4, leftMargin=1.0 * cm, rightMargin=1.0 * cm, topMargin=0.8 * cm, bottomMargin=0.8 * cm)
    doc_mun.build(build_acta_elements(mesa_info, "MUNICIPAL", styles))
    print(f"  -> PDF Municipal generado: {pdf_mun_name}")
    pdf_comb_name = out_path / f"Actas_Completas_ERM2026_Mesa_{mesa_code}.pdf"
    doc_comb = SimpleDocTemplate(str(pdf_comb_name), pagesize=A4, leftMargin=1.0 * cm, rightMargin=1.0 * cm, topMargin=0.8 * cm, bottomMargin=0.8 * cm)
    comb = []
    comb.extend(build_acta_elements(mesa_info, "MUNICIPAL", styles))
    comb.append(PageBreak())
    comb.extend(build_acta_elements(mesa_info, "REGIONAL", styles))
    doc_comb.build(comb)
    print(f"  -> PDF Combinado (2 paginas) generado: {pdf_comb_name}")
    return {"mesa": mesa_code, "regional_pdf": str(pdf_reg_name), "municipal_pdf": str(pdf_mun_name), "combined_pdf": str(pdf_comb_name)}

def main():
    parser = argparse.ArgumentParser(description="Generador de Actas Electorales ERM 2026 (Regional 1b y Municipal 4b) desde PostgreSQL.")
    parser.add_argument("mesas", nargs="*", help="Codigos de mesa de sufragio (ej: 030390 040104 021038)")
    parser.add_argument("-o", "--output", default="generate-pdf-erm2026/output", help="Carpeta de destino")
    args = parser.parse_args()
    conn = get_db_connection()
    mesas_to_process = args.mesas
    if not mesas_to_process:
        print("=" * 70)
        print(" CONTEOYA — GENERADOR DE ACTAS ELECTORALES ERM 2026 (ONPE)")
        print("=" * 70)
        entrada = input("Ingrese el o los codigos de mesa (ej: 030390 040104 021038): ").strip()
        if not entrada:
            print("No se ingreso ningun codigo de mesa. Finalizando.")
            conn.close()
            return
        mesas_to_process = entrada.split()
    print(f"Iniciando generacion para {len(mesas_to_process)} mesa(s)...")
    res = []
    for m in mesas_to_process:
        r = generar_actas_para_mesa(conn, m.strip(), args.output)
        if r:
            res.append(r)
    conn.close()
    print("\n" + "=" * 70)
    print(f"Proceso finalizado. Se generaron actas para {len(res)} mesa(s).")
    print(f"Carpeta de salida: {os.path.abspath(args.output)}")
    print("=" * 70)

if __name__ == "__main__":
    main()
