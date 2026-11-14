#!/usr/bin/env python3
"""
PROYECTO MIRAI - FASE 7 (Celda 2 / Script 02)
Entrenamiento y Comparación de Modelos de IA para Detección de Botnets IoT:
  1. Random Forest Classifier (Aprendizaje Supervisado)
  2. Isolation Forest (Detección de Anomalías No Supervisada - entrenado solo con tráfico benigno)

Calcula: Exactitud (Accuracy), Precisión, Recall, F1-Score, FPR (Tasa de Falsos Positivos),
Matriz de Confusión, Top 5 Características N-BaIoT y emite el Dictamen Operativo SOC (NIST AI RMF).

Uso:
    python3 ai-pipeline/02_train_evaluate_models.py [--csv nbaiot_pnetlab.csv]
"""
import argparse
import json
from pathlib import Path

import numpy as np
import pandas as pd
from sklearn.ensemble import IsolationForest, RandomForestClassifier
from sklearn.metrics import (
    accuracy_score,
    confusion_matrix,
    f1_score,
    precision_score,
    recall_score,
)
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler


def compute_metrics(y_true: np.ndarray, y_pred: np.ndarray, model_name: str) -> dict:
    cm = confusion_matrix(y_true, y_pred, labels=[0, 1])
    tn, fp, fn, tp = cm.ravel()
    acc = accuracy_score(y_true, y_pred)
    prec = precision_score(y_true, y_pred, zero_division=0)
    rec = recall_score(y_true, y_pred, zero_division=0)
    f1 = f1_score(y_true, y_pred, zero_division=0)
    fpr = fp / (fp + tn) if (fp + tn) > 0 else 0.0

    return {
        "Modelo": model_name,
        "Accuracy": round(float(acc), 4),
        "Precision": round(float(prec), 4),
        "Recall": round(float(rec), 4),
        "F1_Score": round(float(f1), 4),
        "FPR": round(float(fpr), 4),
        "TN": int(tn),
        "FP": int(fp),
        "FN": int(fn),
        "TP": int(tp),
    }


def main():
    parser = argparse.ArgumentParser(description="Entrenamiento y Evaluación IA (Random Forest vs Isolation Forest)")
    parser.add_argument("--csv", type=str, default="nbaiot_pnetlab.csv", help="Ruta al dataset CSV de 115 features")
    args = parser.parse_args()

    csv_path = Path(args.csv)
    if not csv_path.exists():
        alt_path = Path(__file__).resolve().parent.parent / args.csv
        if alt_path.exists():
            csv_path = alt_path
        else:
            raise FileNotFoundError(f"No se encontró el archivo '{args.csv}'. Ejecuta primero 01_extract_nbaiot_115_features.py")

    print(f"[+] Cargando dataset N-BaIoT desde: {csv_path}")
    df = pd.read_csv(csv_path)

    drop_cols = [c for c in ["label", "scenario"] if c in df.columns]
    X = df.drop(columns=drop_cols).replace([np.inf, -np.inf], np.nan).fillna(0.0)
    y = df["label"].astype(int).values

    print(f"    -> Total muestras: {len(df):,} | Features: {X.shape[1]} | Benignos (0): {(y==0).sum():,} | Ataques Mirai (1): {(y==1).sum():,}")

    # División estratificada 70% entrenamiento / 30% prueba
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.30, random_state=42, stratify=y
    )

    # ==========================================================================
    # 1. MODELO SUPERVISADO: Random Forest Classifier
    # ==========================================================================
    print("\n[*] Entrenando Modelo 1: Random Forest (Supervisado)...")
    rf_model = RandomForestClassifier(
        n_estimators=150,
        max_depth=12,
        random_state=42,
        n_jobs=-1,
        class_weight="balanced",
    )
    rf_model.fit(X_train, y_train)
    y_pred_rf = rf_model.predict(X_test)
    metrics_rf = compute_metrics(y_test, y_pred_rf, "Random Forest (Supervisado)")

    # ==========================================================================
    # 2. MODELO NO SUPERVISADO: Isolation Forest
    # Se entrena únicamente con el tráfico benigno de entrenamiento (label=0)
    # ==========================================================================
    print("[*] Entrenando Modelo 2: Isolation Forest (No Supervisado - Baseline Benigno)...")
    scaler = StandardScaler()
    X_train_benign = X_train[y_train == 0]
    X_train_benign_scaled = scaler.fit_transform(X_train_benign)
    X_test_scaled = scaler.transform(X_test)

    iso_model = IsolationForest(
        n_estimators=150,
        contamination=0.05,
        random_state=42,
        n_jobs=-1,
    )
    iso_model.fit(X_train_benign_scaled)
    # IsolationForest devuelve 1 para inliers (benigno -> 0) y -1 para outliers (anomalía/ataque -> 1)
    raw_preds_iso = iso_model.predict(X_test_scaled)
    y_pred_iso = np.where(raw_preds_iso == -1, 1, 0)
    metrics_iso = compute_metrics(y_test, y_pred_iso, "Isolation Forest (No Supervisado)")

    # ==========================================================================
    # 3. TABLA COMPARATIVA Y TOP 5 CARACTERÍSTICAS N-BaIoT
    # ==========================================================================
    results_df = pd.DataFrame([metrics_rf, metrics_iso])
    print("\n==================================================================")
    print("   RESULTADOS COMPARATIVOS EN CONJUNTO DE PRUEBA (30% HOLD-OUT)")
    print("==================================================================")
    print(results_df.to_string(index=False))

    importances = pd.Series(rf_model.feature_importances_, index=X.columns).sort_values(ascending=False)
    top5 = importances.head(5)
    print("\n==================================================================")
    print("   TOP 5 CARACTERÍSTICAS MÁS DISCRIMINANTES (N-BaIoT AfterImage)")
    print("==================================================================")
    for rank, (feat_name, score) in enumerate(top5.items(), start=1):
        print(f"  {rank}. {feat_name:<35} -> Importancia: {score:.4f}")

    # ==========================================================================
    # 4. DICTAMEN OPERATIVO SOC Y RECOMENDACIÓN DE CUARENTENA SUAVE (NIST AI RMF)
    # ==========================================================================
    attack_detected = int(y_pred_rf.sum()) > 0
    alert_report = {
        "status": "ALERTA_CRITICA_BOTNET_MIRAI" if attack_detected else "NORMAL",
        "compromised_host_lan": "192.168.10.10",
        "nat_wan_ip": "172.16.0.2",
        "victim_ip": "172.16.0.100",
        "metrics_comparison": [metrics_rf, metrics_iso],
        "top_5_features": {k: round(float(v), 4) for k, v in top5.items()},
        "recommended_mikrotik_action": '/queue simple add name="cuarentena-suave-iot" target=192.168.10.10/32 max-limit=64k/64k',
    }

    report_path = Path("soc_alert_report.json")
    report_path.write_text(json.dumps(alert_report, indent=2, ensure_ascii=False), encoding="utf-8")

    print("\n==================================================================")
    print("   DICTAMEN OPERATIVO DEL SOC (Marco NIST AI RMF)")
    print("==================================================================")
    print(f"  Estado Detectado   : {alert_report['status']}")
    print(f"  Nodo Comprometido  : IoT-Cam-1 ({alert_report['compromised_host_lan']})")
    print("  Acción Mitigadora  : Aplicar Cuarentena Suave (Rate-Limit 64k/64k) en Router-Hogar:")
    print(f"                       {alert_report['recommended_mikrotik_action']}")
    print(f"  Reporte JSON       : {report_path.resolve()}")
    print("==================================================================")


if __name__ == "__main__":
    main()
