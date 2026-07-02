# AnemoChain (PRISMA)

> **1.92 billion people live with anemia. Most can't access a blood test. AnemoChain screens them from a single photo.**
>
> *Non-invasive. Tamper-evident. Deployable Anywhere.*

---

![Python](https://img.shields.io/badge/Python-3.10%2B-3776AB?style=for-the-badge&logo=python&logoColor=white)
![Flutter](https://img.shields.io/badge/Flutter-Mobile-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![FastAPI](https://img.shields.io/badge/FastAPI-Backend-009688?style=for-the-badge&logo=fastapi&logoColor=white)
![Flask](https://img.shields.io/badge/Flask-Dashboard-000000?style=for-the-badge&logo=flask&logoColor=white)
![Blockchain](https://img.shields.io/badge/Blockchain-Hyperledger%20Fabric-2F3134?style=for-the-badge&logo=hyperledger&logoColor=white)
![ONNX](https://img.shields.io/badge/ONNX-Runtime-005CED?style=for-the-badge&logo=onnx&logoColor=white)
![SQLite](https://img.shields.io/badge/SQLite-Database-003B57?style=for-the-badge&logo=sqlite&logoColor=white)
![scikit-learn](https://img.shields.io/badge/Scikit--learn-ML-F7931E?style=for-the-badge&logo=scikit-learn&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-yellow?style=for-the-badge)

---

## Problem Statement

Anemia is one of the most widespread and underdiagnosed conditions on earth. According to the Global Burden of Disease Study 2021, **approximately 1.92 billion people** — representing **24.3% of the global population** — currently live with anemia, with the burden falling heaviest on children under five and women of reproductive age. [(Source: PMC, 2021)](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC12459588/)

Despite its scale, frontline diagnosis still depends almost entirely on **invasive venipuncture** — blood draws that require trained phlebotomists, sterile needle kits, laboratory centrifuges, and cold-chain transport of specimens. In the vast majority of low- and middle-income settings, this infrastructure simply does not exist at the community level. The result: **millions go unscreened until symptoms become severe**, directly undermining SDG 3 (Good Health and Well-Being).

Two further structural problems compound the diagnostic gap:

**1. Zero input validation in existing non-invasive systems.**
Published non-invasive approaches — including the RUSBoost system by Dimauro et al. (2023), the AutoML CNN study by Riazi Esfahani et al. (2026), and the deep ensemble by Sehar et al. (2025) — accept any image fed to them and return a prediction. A photo of a floor, a wall, or a random object would pass through the inference pipeline and silently produce a clinical label. No published system has implemented a mechanism to reject non-ocular or low-quality images before inference, creating a systematic risk of false diagnostic outputs in real-world deployments.

**2. No tamper-evident record integrity layer.**
Electronic medical records are under escalating attack. According to the HIPAA Journal, **hacking-related healthcare data breaches rose 239% and ransomware attacks rose 278% between 2018 and 2023** in the United States alone. [(Source: HIPAA Journal)](https://www.hipaajournal.com/healthcare-data-breach-statistics/) In 2024, the Change Healthcare ransomware attack — the largest healthcare data breach in history — exposed the records of an estimated **192.7 million individuals**. [(Source: HIPAA Journal)](https://www.hipaajournal.com/healthcare-data-breach-statistics/) Meanwhile, **no existing non-invasive anemia system** across all published literature includes any mechanism to verify that a stored screening record has not been altered after the fact.

These are not theoretical concerns. They are structural vulnerabilities in every non-invasive anemia system deployed or studied today.

---

## Solution Overview

**AnemoChain (PRISMA)** is an integrated **AI + Blockchain + Mobile** ecosystem that screens for anemia from a single conjunctiva (inner eyelid) photo — no blood draw required. The system is built on two core design principles that directly address the gaps above:

**1. Two-Layer Image Validation Gate** — before any inference occurs, captured images pass through a pixel-level quality check and a biological conjunctiva check. Any image that does not pass both layers is rejected immediately and the user is prompted to retake the photo. This is the **first published non-invasive anemia pipeline with an explicit input validation mechanism** that rejects non-ocular images.

**2. "Blockchain First, Database Last"** — every prediction is immediately hashed (SHA-256) and sealed into a Hyperledger Fabric blockchain ledger **before** the full record is persisted to a relational database. Any subsequent modification to the database record becomes immediately detectable by cross-checking against the immutable on-chain hash. This provides a **tamper-evident audit trail** that no prior non-invasive anemia system has implemented.

---

## Key Features

- 📸 **Mobile image capture** (Flutter) with a **two-layer validation gate** that rejects non-ocular and low-quality photos before they reach the AI model
- 🧠 **ML inference pipeline** benchmarking five classifiers across a 171-feature multi-colorspace matrix (RGB, CIE LAB, HSV, YCbCr + clinical pallor indices), exported to ONNX for lightweight edge inference
- ⛓️ **Blockchain-sealed records** — every prediction hash is chained into a Hyperledger Fabric-style ledger prior to database write
- 🏥 **Hospital Dashboard** (Flask) for clinicians to review patient history and cryptographically verify record integrity against the blockchain
- 🔐 **Anti-manipulation by design** — any tampering with a database record will no longer match its sealed blockchain hash, making data corruption self-evident and auditable
- 🌐 **Edge-first deployment** — lightweight ONNX model designed for low-resource environments such as community health posts (posyandu) and rural clinics (puskesmas)

---

## Screenshots

### 📱 Mobile Application

| Screenshot | Description |
|---|---|
| <img width="720" height="1600" alt="WhatsApp Image 2026-07-02 at 13 43 59" src="https://github.com/user-attachments/assets/42343c64-23d2-4f2c-ba12-9ad901754477" /> | **Landing Page** — Main home screen of the PRISMA AnemoChain mobile app. Users can capture a conjunctiva photo directly via camera, upload from gallery, or access their screening history. |
| <img width="720" height="1600" alt="WhatsApp Image 2026-07-02 at 13 43 59 (1)" src="https://github.com/user-attachments/assets/71ecae56-b6d5-4f64-a605-8ae040c7a8a0" /> | **Screening Result (Status & Image Preview)** — Displays the conjunctiva photo preview alongside the initial clinical status (Anemia Risk or Non-Anemia) processed in real-time using Edge AI. |
| <img width="720" height="1600" alt="WhatsApp Image 2026-07-02 at 13 43 59 (2)" src="https://github.com/user-attachments/assets/7c00ae22-bb16-4eba-a384-2e1e44695412" /> | **Screening Result (Clinical Detail)** — Extended result view showing advanced optical color metrics such as Erythema (R), Lightness (L\*), and Hue, alongside an AI Interpretation and health recommendations for the patient. |
| <img width="720" height="1600" alt="WhatsApp Image 2026-07-02 at 13 44 00" src="https://github.com/user-attachments/assets/c7a7ca87-39d0-4d1d-8113-2aa77d93b2be" /> | **Invalid Image Handling** — Intuitive error message displayed when the submitted photo is blurry, too dark, or cannot be identified as a human eye by the AI validation system. |

---

### 🏥 Hospital Dashboard

| Screenshot | Description |
|---|---|
| <img width="1901" height="1198" alt="image" src="https://github.com/user-attachments/assets/509af8e8-971b-443b-83f6-8cde307ea2ce" /> | **Record Verified (No Tampering)** — The Hospital Dashboard when a clinician verifies a patient record. The system validates that the local medical record matches 100% with the hash stored on the Blockchain network, confirming data integrity. |
| <img width="1895" height="1198" alt="image" src="https://github.com/user-attachments/assets/d49f8905-d05f-4e65-8051-9f496d90f1f1" /> | **Tampering Detected** — The system's protective response when it detects unauthorized modification of a local database record. A `DATA TAMPERED` warning is raised because the local data hash no longer matches the Blockchain. |

---

### ⛓️ Blockchain Ledger

| Screenshot | Description |
|---|---|
| <img width="1901" height="1198" alt="image" src="https://github.com/user-attachments/assets/0b94a2d0-7f8c-4b74-b132-9cdba9540707" /> | **Block View** — The Hyperledger Blockchain Explorer displaying the list of transaction blocks in the network. This demonstrates that every medical record has been decentralized, hashed, and securely stored using blockchain technology. |

---

## Research Flow & System Architecture

<img width="2307" height="1219" alt="Research Flow" src="https://github.com/user-attachments/assets/04b04da5-76f7-41d9-96e6-4bc8901e6567" />

---

## Two-Layer Image Validation

<img width="2291" height="966" alt="Two-Layer Validation" src="https://github.com/user-attachments/assets/404db28a-a82e-43fd-852d-337b7a2235dd" />

Before any feature extraction or ML inference occurs, each submitted image passes through a two-stage gate implemented in the FastAPI backend (`ml_utils.py`):

**Layer 1 — Pixel Quality Check**
- Image is resized to 256 × 256 pixels
- Mean luminance is computed
- The image must contain **≥ 500 valid (non-masked) pixels** to proceed

**Layer 2 — Biological Conjunctiva Check**
The image must satisfy all four constraints simultaneously:
- **Red dominance**: `mean_R > mean_B` (conjunctiva tissue is redder than blue)
- **LAB redness**: `a* ≥ 5.0` (positive a\* axis = redness in CIE LAB space)
- **Brightness**: `25.0 ≤ L* ≤ 90.0` (valid tissue luminance range)
- **Redness index**: `0.30 ≤ index ≤ 1.80`

If **any** of the eight checks across both layers fails, the image is rejected and the user is prompted to retake the photo. Only images passing all checks proceed to feature extraction and inference.

---

## Technologies Used

| Layer | Technology |
|---|---|
| Machine Learning | Python, Scikit-learn, XGBoost, ONNX Runtime |
| Backend API | FastAPI, SQLite |
| Blockchain Layer | FastAPI-based ledger node (Hyperledger Fabric–style: peers + ordering service) |
| Hospital Dashboard | Flask, Jinja2, Tailwind CSS |
| Mobile App | Flutter / Dart |
| Dataset | Eyes-Defy-Anemia (Italy n=123, India n=95) — see [Dataset Citation](#dataset-citation) |

---

## Model Benchmark Results

Five classifiers were trained and evaluated on the Eyes-Defy-Anemia feature matrix across three stratified train/test splits. `HistGradientBoosting` was selected as the production model (exported to ONNX).

### Split 90:10
| Model | Accuracy | F1 | AUC | Sensitivity | Specificity |
|---|---|---|---|---|---|
| SVM_RBF | 0.6875 | 0.6863 | 0.8500 | 1.0000 | 0.5000 |
| RandomForest | 0.6875 | 0.6863 | 0.8833 | 0.8333 | 0.6000 |
| **HistGradientBoosting** | **0.8125** | **0.8057** | **0.9333** | 0.8333 | 0.8000 |
| KNN | 0.6875 | 0.6761 | 0.8000 | 0.6667 | 0.7000 |
| XGBoost | 0.8750 | 0.8667 | 0.9333 | 0.8333 | 0.9000 |

### Split 80:20
| Model | Accuracy | F1 | AUC | Sensitivity | Specificity |
|---|---|---|---|---|---|
| SVM_RBF | 0.7419 | 0.7417 | 0.8500 | 1.0000 | 0.6000 |
| RandomForest | 0.8065 | 0.8013 | 0.9000 | 0.9091 | 0.7500 |
| **HistGradientBoosting** | **0.9032** | **0.8963** | **0.9500** | 0.9091 | 0.9000 |
| KNN | 0.7419 | 0.7182 | 0.8773 | 0.6364 | 0.8000 |
| XGBoost | 0.8387 | 0.8272 | 0.9409 | 0.8182 | 0.8500 |

### Split 70:30
| Model | Accuracy | F1 | AUC | Sensitivity | Specificity |
|---|---|---|---|---|---|
| SVM_RBF | 0.7447 | 0.7446 | 0.8451 | 1.0000 | 0.6000 |
| RandomForest | 0.7021 | 0.6954 | 0.8471 | 0.7647 | 0.6667 |
| HistGradientBoosting | 0.7447 | 0.7235 | 0.8627 | 0.6471 | 0.8000 |
| KNN | 0.7021 | 0.6775 | 0.7941 | 0.5882 | 0.7667 |
| **XGBoost** | 0.7021 | 0.6849 | **0.8549** | 0.6471 | 0.7333 |

### Average Across All Splits
| Model | Accuracy | F1 | AUC | Sensitivity | Specificity |
|---|---|---|---|---|---|
| SVM_RBF | 0.7247 | 0.7242 | 0.8484 | **1.0000** | 0.5667 |
| RandomForest | 0.7320 | 0.7277 | 0.8768 | 0.8357 | 0.6722 |
| **HistGradientBoosting** | **0.8201** | **0.8085** | **0.9153** | 0.7965 | **0.8333** |
| KNN | 0.7105 | 0.6906 | 0.8238 | 0.6304 | 0.7556 |
| XGBoost | 0.8053 | 0.7929 | 0.9097 | 0.7662 | 0.8278 |

> **`HistGradientBoosting`** achieves the best average Accuracy (0.8201), F1 (0.8085), AUC (0.9153), and Specificity (0.8333) across all three splits — selected as the production model exported to ONNX.

---

## Comparison with Prior Research

| Study | Accuracy | Sensitivity | Specificity | AUC | Mobile App | Blockchain | Input Validation |
|---|---|---|---|---|---|---|---|
| [Dimauro et al. (2023)](https://doi.org/10.1016/j.artmed.2022.102477) — RUSBoost, palpebral conjunctiva | 0.8800 | 0.6600 | 0.9100 | — | ✗ | ✗ | ✗ |
| [Riazi Esfahani et al. (2026)](https://doi.org/10.1002/ajh.70143) — AutoML CNN, Full → Palpebral | — | 1.0000 | 0.6700 | 0.8990 | ✗ | ✗ | ✗ |
| [Sehar et al. (2025)](https://doi.org/10.4258/hir.2025.31.1.57) — Stacking Ensemble (VGG16 + ResNet-50 + InceptionV3, DCGAN-augmented) | 0.8948 | — | — | 0.9700 | ✗ | ✗ | ✗ |
| **AnemoChain / PRISMA (this project)** — HistGradientBoosting, avg. across splits | **0.8201** | **0.7965** | **0.8333** | **0.9153** | ✅ | ✅ | ✅ |

### Critical Gap Analysis

| Author (Year) | Objective | Methodology | Identified Gaps |
|---|---|---|---|
| [Dimauro et al. (2023)](https://doi.org/10.1016/j.artmed.2022.102477) | Automated diagnosis exploiting the Eyes-Defy-Anemia dataset | RUSBoost handling imbalanced data with 14 color features | No input validation; no mobile integration; no record integrity mechanism |
| [Riazi Esfahani et al. (2026)](https://doi.org/10.1002/ajh.70143) | Comparative training analysis using deep neural networks | AutoML CNN evaluating full-eye vs. palpebral configurations | Closed-box AutoML prevents edge inference; no mobile integration; no anti-manipulation security |
| [Sehar et al. (2025)](https://doi.org/10.4258/hir.2025.31.1.57) | Deep learning–based detection from conjunctiva images | DCGAN augmentation + SLIC segmentation + stacking ensemble | Computationally prohibitive for mobile devices; no input rejection logic; no blockchain integrity layer |

**Discussion:**
- AnemoChain's classical ML pipeline achieves a **more balanced sensitivity/specificity trade-off** than the 2023 RUSBoost baseline (0.80/0.83 vs. 0.66/0.91) and the 2026 AutoML CNN study (0.80/0.83 vs. 1.00/0.67, which sacrifices specificity almost entirely for sensitivity).
- Its AUC (0.9153) sits between the RUSBoost-era baseline and the computationally heavy deep-learning ensemble of Sehar et al. (AUC 0.97), which relies on GAN-based augmentation (764 → 4,315 images) and a CNN ensemble (VGG16 + ResNet-50 + InceptionV3).
- AnemoChain deliberately favors a **lightweight, ONNX-exportable classical model** over deep CNN ensembles, prioritizing feasibility of edge inference for low-resource deployment over squeezing out additional AUC points.
- **AnemoChain is the only system in this comparison integrating all three missing components**: a mobile application, a blockchain tamper-detection layer, and an explicit input validation gate.
- Direct metric comparison should be interpreted with caution: all four studies use different subsets, splits, and preprocessing of the same underlying dataset, and sample sizes remain small (n ≈ 95–218).

---

## Limitations & Future Work

### Current Limitations

- **Small dataset**: The Eyes-Defy-Anemia dataset contains only n ≈ 218 samples from two cohorts (Italy, India), which limits generalizability across diverse populations and lighting conditions.
- **Not clinical-grade**: This system is designed as a pre-screening and triage tool, not a replacement for laboratory hemoglobin measurement. Results should always be confirmed by a trained medical professional.
- **Lighting sensitivity**: Conjunctiva color is affected by ambient lighting conditions. The validation gate mitigates extreme cases but does not fully account for all real-world lighting variability.
- **Single-eye input**: The current model accepts a single conjunctiva image; bilateral comparison (both eyes) may improve robustness.
- **Windows-only scripts**: The provided `.bat` deployment scripts are Windows-only; Linux/macOS equivalents have not yet been packaged.

### Future Work

- Expand training data through multi-country field collection, particularly from Southeast Asian populations (Indonesia, Philippines, Vietnam) where anemia prevalence among pregnant women and children remains high.
- Integrate hemoglobin (Hb g/dL) regression alongside binary classification to provide a quantitative severity estimate.
- Explore on-device ONNX inference within the Flutter app to enable fully offline screening with zero backend dependency.
- Pursue clinical validation study in partnership with community health facilities (posyandu/puskesmas) to assess real-world diagnostic performance.
- Replace the simulated Hyperledger Fabric–style ledger with a production Hyperledger Fabric deployment for enterprise-grade auditability.

---

## How to Run

### Prerequisites

- Python 3.10+ (for Backend & Blockchain services)
- Flutter SDK (for Mobile)
- Windows environment (the provided `.bat` scripts are Windows batch files)
- A configured `.env` file at the project root defining inter-service URLs/ports

### Step-by-step

1. **Start the Blockchain node** (must be first — Backend depends on it):
   ```
   1_start_blockchain.bat
   ```
   Runs the ledger node on its configured port (default: `8001`).

2. **Start the Backend service**:
   ```
   2_start_backend.bat
   ```
   Runs the FastAPI inference & records API (default: `8000`), loading the ONNX-exported `HistGradientBoosting` model and connecting to the Blockchain node.

3. **Start the Hospital Dashboard**:
   ```
   3_start_dashboards.bat
   ```
   Runs the Flask dashboard (default: `8002`) for clinicians to review records and verify database–blockchain hash integrity.

4. **Start the DB Admin panel**:
   ```
   4_start_db_admin.bat
   ```

5. **Build a distributable APK**:
   ```
   5_build_apk.bat
   ```

### Configuring the Mobile App IP Address

Before running the app on a physical device, you need to point the mobile app to the correct backend server IP address:

1. Open the mobile app — tap the **⚙️ gear icon** in the top-right corner to open Settings.
2. Set the IP address to match the **IPv4 address of the PC running the backend**.
3. To find your PC's IPv4 address, open Command Prompt and run:
   ```
   ipconfig
   ```
   Look for the **IPv4 Address** under your active network adapter (e.g., `192.168.x.x`).
4. Enter that IP address in the app settings and save.
   
### Typical Usage Flow

1. Open the Mobile app → capture a conjunctiva (inner eyelid) photo.
2. The backend runs the **two-layer validation gate** — if the image is not a valid conjunctiva photo, the user is prompted to retake it.
3. On a valid image, the backend performs feature extraction (171 features across RGB, CIE LAB, HSV, YCbCr) and runs ONNX inference.
4. The result is **immediately hashed (SHA-256) and sealed on the Blockchain ledger**.
5. The user may choose to sync the full record to the hospital database.
6. A clinician opens the Hospital Dashboard to review the patient's history and **verify record integrity** by cross-checking the database hash against the sealed blockchain hash.

---

## Dataset Citation

The machine learning models in this project were trained on the **Eyes-Defy-Anemia** dataset:

> Giovanni Dimauro, Rosalia Maglietta, Thulasi Bai, Sivachandar Kasiviswanathan, "Eyes-defy-anemia," *IEEE Dataport*, January 31, 2022. doi:[10.21227/t5s2-4j73](https://doi.org/10.21227/T5S2-4J73)

We gratefully acknowledge the dataset authors for making this resource publicly available to the research community.

---

## Target Users

- **Community health workers & clinics in low-resource settings** (posyandu, puskesmas), where lab infrastructure for routine blood draws is limited or unavailable
- **Hospitals and clinicians** who need an auditable, tamper-evident patient record system alongside a rapid pre-screening tool
- **Public health / NGO screening programs** conducting mass, low-cost anemia pre-screening among pregnant women and children under five
- **Researchers** studying non-invasive hemoglobin/pallor estimation, who can reuse the open feature-extraction and benchmarking pipeline

---

## Team

**Solo Developer:** Michael Angello Qadosy Riyadi

> All system components — machine learning pipeline, FastAPI backend, blockchain ledger node, Flask hospital dashboard, and Flutter mobile application — were designed, built, and integrated independently as a solo submission.

---

*Built for the ML Empowerment Build Challenge · MIT License*
