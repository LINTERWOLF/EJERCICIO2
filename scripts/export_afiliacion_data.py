#!/usr/bin/env python
"""
Extrae los escenarios de `Afiliacion.feature` desde el reporte HTML de Karate y
genera dos artefactos reutilizables:

1. `target/afiliacion-casos.json`  -> lista de escenarios con request / response.
2. `target/Afiliacion-casos.xlsx`  -> hoja de cálculo (para análisis manual).

Este script permite que otros features lean datos reales sin tocar el feature
original ni depender de parsing manual.

Requisitos: `beautifulsoup4` y `openpyxl` (ya utilizados en el proyecto).
Uso: `python scripts/export_afiliacion_data.py`
"""

from __future__ import annotations

import json
import re
from dataclasses import asdict, dataclass, field
from pathlib import Path
from typing import Any, Dict, List, Optional

from bs4 import BeautifulSoup
from openpyxl import Workbook

PROJECT_ROOT = Path(__file__).resolve().parents[1]
REPORT_PATH = PROJECT_ROOT / "target" / "karate-reports" / "Afiliacion.html"
JSON_OUTPUT = PROJECT_ROOT / "target" / "afiliacion-casos.json"
EXCEL_OUTPUT = PROJECT_ROOT / "target" / "Afiliacion-casos.xlsx"


@dataclass
class ScenarioRecord:
    scenario_name: str
    status: str
    expected_status: Optional[int]
    actual_status: Optional[int]
    tx_status: Optional[str]
    reason_code: Optional[str]
    reason_text: Optional[str]
    doc_type: Optional[str]
    doc_id: Optional[str]
    account_type: Optional[str]
    account_id: Optional[str]
    payload: Optional[Dict[str, Any]] = field(default=None)
    response: Optional[Dict[str, Any]] = field(default=None)

    def to_dict(self) -> Dict[str, Any]:
        data = asdict(self)
        # Serializa request/response como JSON amigable.
        data["payload"] = self.payload
        data["response"] = self.response
        return data


def _extract_json_from_text(block: str) -> Optional[Dict[str, Any]]:
    """Devuelve el primer objeto JSON válido dentro de un bloque de texto."""
    if not block:
        return None
    start = block.find("{")
    end = block.rfind("}")
    if start == -1 or end == -1 or end <= start:
        return None
    snippet = block[start : end + 1]
    try:
        return json.loads(snippet)
    except json.JSONDecodeError:
        return None


def _extract_http_status(block: str) -> Optional[int]:
    match = re.search(r"status code was: (\d+)", block)
    if match:
        return int(match.group(1))
    match = re.search(r"1 < (\d{3})", block)
    if match:
        return int(match.group(1))
    return None


def parse_report() -> List[ScenarioRecord]:
    if not REPORT_PATH.exists():
        raise FileNotFoundError(
            f"No se encontró el reporte HTML en {REPORT_PATH}. Ejecuta primero "
            "Afiliacion.feature (p.ej. `mvn --% test -Dkarate.options=classpath:Afiliacion.feature`)."
        )

    soup = BeautifulSoup(REPORT_PATH.read_text(encoding="utf-8", errors="ignore"), "html.parser")
    records: List[ScenarioRecord] = []

    for scenario_div in soup.select("div.scenario"):
        heading = scenario_div.select_one("div.scenario-heading")
        if not heading:
            continue
        name_tag = heading.select_one(".scenario-name")
        if not name_tag:
            continue
        scenario_name = name_tag.get_text(strip=True)

        time_div = heading.select_one("div.scenario-time")
        status = "failed" if time_div and "failed" in time_div.get("class", []) else "passed"

        payload_json: Optional[Dict[str, Any]] = None
        response_json: Optional[Dict[str, Any]] = None
        actual_status: Optional[int] = None

        for pre in scenario_div.select("div.preformatted"):
            text = pre.get_text("\n", strip=True)
            if "request:" in text and payload_json is None:
                payload_json = _extract_json_from_text(text.split("request:", 1)[1])
            if "response:" in text:
                response_json = _extract_json_from_text(text.split("response:", 1)[1])
            status_candidate = _extract_http_status(text)
            if status_candidate is not None:
                actual_status = status_candidate

        expected_status = 200  # Todos los escenarios esperan 200 según el feature.

        doc_type = doc_id = account_type = account_id = None
        if isinstance(payload_json, dict):
            acct = payload_json.get("acctEnroll") or payload_json.get("AcctEnroll") or {}
            acct_data = acct.get("acct") or acct.get("Acct") or {}
            doc_type = acct_data.get("docTp") or acct_data.get("docType")
            doc_id = acct_data.get("docId")
            account_type = acct_data.get("acctTp")
            account_id = acct_data.get("acctId")

        tx_status = reason_code = reason_text = None
        if isinstance(response_json, dict):
            qry = response_json.get("AcctEnroll") or response_json.get("acctEnroll") or response_json.get("QryAccByCred")
            if isinstance(qry, dict):
                tx_status = qry.get("TxSts")
                reason = qry.get("Rsn") or {}
                reason_code = reason.get("RsnCd")
                reason_text = reason.get("AddtlInf")

        records.append(
            ScenarioRecord(
                scenario_name=scenario_name,
                status=status,
                expected_status=expected_status,
                actual_status=actual_status,
                tx_status=tx_status,
                reason_code=reason_code,
                reason_text=reason_text,
                doc_type=doc_type,
                doc_id=doc_id,
                account_type=account_type,
                account_id=account_id,
                payload=payload_json,
                response=response_json,
            )
        )

    return records


def dump_json(records: List[ScenarioRecord]) -> None:
    JSON_OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    JSON_OUTPUT.write_text(
        json.dumps([record.to_dict() for record in records], ensure_ascii=False, indent=2),
        encoding="utf-8",
    )


def dump_excel(records: List[ScenarioRecord]) -> None:
    wb = Workbook()
    ws = wb.active
    ws.title = "afiliacion"
    headers = [
        "scenario_name",
        "status",
        "expected_status",
        "actual_status",
        "tx_status",
        "reason_code",
        "reason_text",
        "doc_type",
        "doc_id",
        "account_type",
        "account_id",
        "payload_json",
        "response_json",
    ]
    ws.append(headers)
    for record in records:
        ws.append(
            [
                record.scenario_name,
                record.status,
                record.expected_status,
                record.actual_status,
                record.tx_status,
                record.reason_code,
                record.reason_text,
                record.doc_type,
                record.doc_id,
                record.account_type,
                record.account_id,
                json.dumps(record.payload, ensure_ascii=False),
                json.dumps(record.response, ensure_ascii=False),
            ]
        )
    EXCEL_OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    wb.save(EXCEL_OUTPUT)


def main() -> None:
    records = parse_report()
    dump_json(records)
    try:
        dump_excel(records)
    except PermissionError as exc:
        print(f"[WARN] No se pudo escribir el Excel ({exc}). Cierra el archivo y vuelve a ejecutar si necesitas la hoja.")
    print(f"Escenarios exportados: {len(records)}")
    print(f"JSON:  {JSON_OUTPUT}")
    if EXCEL_OUTPUT.exists():
        print(f"Excel: {EXCEL_OUTPUT}")


if __name__ == "__main__":
    main()
