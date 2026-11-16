#!/usr/bin/env python3
"""
PROYECTO MIRAI - FASE 7 (Celda 1 / Script 01)
Extracción VERBOSE EN CALIENTE de las 115 características estadísticas de N-BaIoT con AfterImage (Kitsune-py).
Compatible con Google Colab y ejecución local en SOC-Sniffer (Python 3.10 - 3.14+ y NumPy 1.x / 2.x+).

Uso:
    python3 ai-pipeline/01_extract_nbaiot_115_features.py [--pcap-dir ./pcaps] [--out nbaiot_pnetlab.csv]
"""
import argparse
import subprocess
import sys
import time
import types
import warnings
from pathlib import Path

# Silenciar SyntaxWarnings de secuencias de escape antiguas en Kitsune-py bajo Python 3.12+/3.14
warnings.filterwarnings("ignore", category=SyntaxWarning)

# Shim para pyximport (Cython): Kitsune-py/netStat.py ejecuta 'import pyximport; pyximport.install()'
# aunque AfterImage.py es 100% Python puro. Si Cython no está instalado, proveemos un módulo no-op.
try:
    import pyximport  # type: ignore
except ImportError:
    _dummy_pyximport = types.ModuleType("pyximport")
    _dummy_pyximport.install = lambda *args, **kwargs: None  # type: ignore
    sys.modules["pyximport"] = _dummy_pyximport

import numpy as np
import pandas as pd

# Shim de compatibilidad con NumPy 2.0+ (Kitsune-py/AfterImage.py utiliza alias antiguos como np.Inf y np.NaN)
if not hasattr(np, "Inf"):
    np.Inf = np.inf  # type: ignore[attr-defined]
if not hasattr(np, "NaN"):
    np.NaN = np.nan  # type: ignore[attr-defined]
if not hasattr(np, "infty"):
    np.infty = np.inf  # type: ignore[attr-defined]
if not hasattr(np, "float_"):
    np.float_ = np.float64  # type: ignore[attr-defined]
if not hasattr(np, "int_"):
    np.int_ = np.int64  # type: ignore[attr-defined]


def patch_kitsune_files(kitsune_dir: Path) -> None:
    """Parchea en disco netStat.py y AfterImage.py si hay permisos de escritura."""
    netstat_py = kitsune_dir / "netStat.py"
    if netstat_py.exists():
        try:
            txt = netstat_py.read_text(encoding="utf-8", errors="ignore")
            new_txt = txt.replace("\nimport pyximport", "\n#import pyximport").replace(
                "pyximport.install()", "#pyximport.install()"
            )
            if new_txt != txt:
                netstat_py.write_text(new_txt, encoding="utf-8")
        except OSError:
            pass

    afterimage_py = kitsune_dir / "AfterImage.py"
    if afterimage_py.exists():
        try:
            txt = afterimage_py.read_text(encoding="utf-8", errors="ignore")
            new_txt = txt.replace("np.Inf", "np.inf").replace("np.NaN", "np.nan")
            if new_txt != txt:
                afterimage_py.write_text(new_txt, encoding="utf-8")
        except OSError:
            pass


def ensure_kitsune_repo(base_dir: Path) -> Path:
    """Busca o clona Kitsune-py para importar FeatureExtractor (AfterImage)."""
    candidates = [
        Path("/content/Kitsune-py"),
        base_dir / "Kitsune-py",
        Path.cwd() / "Kitsune-py",
    ]
    for candidate in candidates:
        if (candidate / "FeatureExtractor.py").exists():
            patch_kitsune_files(candidate)
            sys.path.insert(0, str(candidate))
            return candidate

    target = base_dir / "Kitsune-py"
    print(f"[*] Clonando Kitsune-py en {target}...")
    subprocess.run(
        ["git", "clone", "-q", "https://github.com/ymirsky/Kitsune-py.git", str(target)],
        check=True,
    )
    patch_kitsune_files(target)
    sys.path.insert(0, str(target))
    return target


def resolve_pcap_path(filename: str, search_dirs: list[Path]) -> Path:
    for d in search_dirs:
        p = d / filename
        if p.exists():
            return p
    raise FileNotFoundError(
        f"No se encontró '{filename}' en ninguna de las rutas: {[str(d) for d in search_dirs]}"
    )


def pcap_a_dataframe(ruta_pcap: Path, etiqueta: int, escenario: str) -> pd.DataFrame:
    from FeatureExtractor import FE

    # Eliminar archivos .tsv temporales previos si existen para forzar re-extracción limpia
    tsv_file = Path(f"{ruta_pcap}.tsv")
    if tsv_file.exists():
        try:
            tsv_file.unlink()
        except PermissionError:
            pass

    print("------------------------------------------------------------------")
    print(f"[+] EXTRAYENDO EN CALIENTE 115 FEATURES N-BaIoT: {ruta_pcap.name}")
    print(f"    Escenario: {escenario} | Etiqueta: {etiqueta} ({'ATAQUE MIRAI' if etiqueta == 1 else 'TRÁFICO BENIGNO'})")
    t0 = time.time()
    extractor = FE(str(ruta_pcap), limit=np.inf)

    # Estimar total de paquetes desde el archivo .tsv recién generado por tshark
    total_pkts = 0
    if tsv_file.exists():
        try:
            with tsv_file.open("rb") as f:
                total_pkts = max(0, sum(1 for _ in f) - 1)
        except OSError:
            total_pkts = 0

    columnas = extractor.nstat.getNetStatHeaders()
    filas = []
    step_log = max(1, total_pkts // 10) if total_pkts > 20 else 25

    while True:
        vector = extractor.get_next_vector()
        if len(vector) == 0:
            break
        filas.append(vector)
        n = len(filas)
        if n == 1 or n % step_log == 0 or (total_pkts > 0 and n == total_pkts):
            elapsed = max(0.001, time.time() - t0)
            rate = n / elapsed
            pct_str = f"{(n / total_pkts) * 100:5.1f}%" if total_pkts > 0 else "  en curso"
            w_val = float(vector[0]) if len(vector) > 0 else 0.0
            mean_val = float(vector[1]) if len(vector) > 1 else 0.0
            print(
                f"    [AfterImage EN VIVO] Paquete {n:6,d}/{total_pkts or '?'} ({pct_str}) "
                f"| {rate:6.1f} pkt/s | MI_dir_L5_weight={w_val:.2f} | MI_dir_L5_mean={mean_val:.1f} B",
                flush=True,
            )

    df = pd.DataFrame(filas, columns=columnas)
    df["label"] = etiqueta
    df["scenario"] = escenario
    total_time = time.time() - t0
    print(f"    [OK] {ruta_pcap.name} completado en {total_time:.2f}s -> {len(df):,} vectores x {df.shape[1]} columnas")
    return df


def main():
    parser = argparse.ArgumentParser(description="Extractor Verbose de 115 features N-BaIoT (AfterImage)")
    parser.add_argument("--pcap-dir", type=str, default=".", help="Directorio donde están los .pcap")
    parser.add_argument("--out", type=str, default="nbaiot_pnetlab.csv", help="Ruta del CSV de salida")
    args = parser.parse_args()

    script_dir = Path(__file__).resolve().parent
    project_root = script_dir.parent
    ensure_kitsune_repo(script_dir)

    search_dirs = [
        Path(args.pcap_dir).resolve(),
        Path.cwd(),
        project_root / "pcaps",
        script_dir,
    ]

    benign_path = resolve_pcap_path("benign.pcap", search_dirs)
    scan_path = resolve_pcap_path("mirai_scan.pcap", search_dirs)
    syn_path = resolve_pcap_path("mirai_syn.pcap", search_dirs)

    df_0 = pcap_a_dataframe(benign_path, etiqueta=0, escenario="benign")
    df_1a = pcap_a_dataframe(scan_path, etiqueta=1, escenario="mirai_scan")
    df_1b = pcap_a_dataframe(syn_path, etiqueta=1, escenario="mirai_syn")

    df_pnetlab = (
        pd.concat([df_0, df_1a, df_1b], ignore_index=True)
        .sample(frac=1, random_state=42)
        .reset_index(drop=True)
    )

    out_path = Path(args.out).resolve()
    df_pnetlab.to_csv(out_path, index=False)

    print("\n==================================================================")
    print(f"[OK] Dataset N-BaIoT generado con éxito: {out_path}")
    print(f"     Dimensiones totales : {df_pnetlab.shape[0]:,} filas x {df_pnetlab.shape[1]} columnas")
    print("     Distribución por etiqueta (0=Benigno, 1=Mirai):")
    print(df_pnetlab["label"].value_counts().to_string())
    print("     Distribución por escenario:")
    print(df_pnetlab["scenario"].value_counts().to_string())
    print("==================================================================")


if __name__ == "__main__":
    main()
