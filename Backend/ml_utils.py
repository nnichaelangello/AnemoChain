import numpy as np
from PIL import Image
from scipy import stats
import json
import onnxruntime as ort
import os

IMAGE_RESIZE_FOR_EXTRACTION = 256
FEATURE_EXTRACTION_MIN_VALID_PIXELS = 500

def linearize_srgb_channel(channel_float):
    return np.where(
        channel_float <= 0.04045,
        channel_float / 12.92,
        ((channel_float + 0.055) / 1.055) ** 2.4,
    )

def convert_rgb_to_lab(img_rgb_float64):
    r_lin = linearize_srgb_channel(img_rgb_float64[:, :, 0])
    g_lin = linearize_srgb_channel(img_rgb_float64[:, :, 1])
    b_lin = linearize_srgb_channel(img_rgb_float64[:, :, 2])

    X = 0.4124564 * r_lin + 0.3575761 * g_lin + 0.1804375 * b_lin
    Y = 0.2126729 * r_lin + 0.7151522 * g_lin + 0.0721750 * b_lin
    Z = 0.0193339 * r_lin + 0.1191920 * g_lin + 0.9503041 * b_lin

    xn, yn, zn = 0.95047, 1.00000, 1.08883

    def lab_f(t):
        return np.where(t > 0.008856, t ** (1.0 / 3.0), 7.787 * t + 16.0 / 116.0)

    fx = lab_f(X / xn)
    fy = lab_f(Y / yn)
    fz = lab_f(Z / zn)

    L_star = 116.0 * fy - 16.0
    a_star = 500.0 * (fx - fy)
    b_star = 200.0 * (fy - fz)

    return np.stack([L_star, a_star, b_star], axis=-1)

def convert_rgb_to_hsv(img_rgb_float64):
    R = img_rgb_float64[:, :, 0]
    G = img_rgb_float64[:, :, 1]
    B = img_rgb_float64[:, :, 2]

    maxc = np.maximum(np.maximum(R, G), B)
    minc = np.minimum(np.minimum(R, G), B)
    delta = maxc - minc

    V = maxc
    S = np.where(maxc > 1e-8, delta / maxc, 0.0)

    H = np.zeros_like(R)
    mask_nonzero_delta = delta > 1e-8
    mask_r = mask_nonzero_delta & (maxc == R)
    mask_g = mask_nonzero_delta & (maxc == G)
    mask_b = mask_nonzero_delta & (maxc == B)

    H[mask_r] = ((G[mask_r] - B[mask_r]) / delta[mask_r]) % 6.0
    H[mask_g] = (B[mask_g] - R[mask_g]) / delta[mask_g] + 2.0
    H[mask_b] = (R[mask_b] - G[mask_b]) / delta[mask_b] + 4.0

    H = (H / 6.0) % 1.0

    return np.stack([H, S, V], axis=-1)

def convert_rgb_to_ycbcr(img_rgb_float64):
    R = img_rgb_float64[:, :, 0]
    G = img_rgb_float64[:, :, 1]
    B = img_rgb_float64[:, :, 2]

    Y  =  0.299000 * R + 0.587000 * G + 0.114000 * B
    Cb = -0.168736 * R - 0.331264 * G + 0.500000 * B + 0.5
    Cr =  0.500000 * R - 0.418688 * G - 0.081312 * B + 0.5

    return np.stack([Y, Cb, Cr], axis=-1)

def compute_channel_statistics(pixel_values_1d, prefix):
    result = {}
    result[f"{prefix}_mean"] = float(np.mean(pixel_values_1d))
    result[f"{prefix}_std"] = float(np.std(pixel_values_1d))
    result[f"{prefix}_skewness"] = float(stats.skew(pixel_values_1d))
    result[f"{prefix}_kurtosis"] = float(stats.kurtosis(pixel_values_1d))
    result[f"{prefix}_p10"] = float(np.percentile(pixel_values_1d, 10))
    result[f"{prefix}_p25"] = float(np.percentile(pixel_values_1d, 25))
    result[f"{prefix}_p50"] = float(np.percentile(pixel_values_1d, 50))
    result[f"{prefix}_p75"] = float(np.percentile(pixel_values_1d, 75))
    result[f"{prefix}_p90"] = float(np.percentile(pixel_values_1d, 90))
    return result

def extract_conjunctiva_features(img_pil):
    if img_pil.mode == "RGBA":
        img_resized = img_pil.resize(
            (IMAGE_RESIZE_FOR_EXTRACTION, IMAGE_RESIZE_FOR_EXTRACTION), Image.LANCZOS
        )
        img_array = np.array(img_resized, dtype=np.float64)
        valid_mask = img_array[:, :, 3] > 10.0
        img_rgb_float = img_array[:, :, :3] / 255.0
    else:
        img_rgb_pil = img_pil.convert("RGB").resize(
            (IMAGE_RESIZE_FOR_EXTRACTION, IMAGE_RESIZE_FOR_EXTRACTION), Image.LANCZOS
        )
        img_rgb_float = np.array(img_rgb_pil, dtype=np.float64) / 255.0
        luminance = (
            0.299 * img_rgb_float[:, :, 0]
            + 0.587 * img_rgb_float[:, :, 1]
            + 0.114 * img_rgb_float[:, :, 2]
        )
        valid_mask = luminance > 0.04

    num_valid_pixels = int(valid_mask.sum())
    if num_valid_pixels < FEATURE_EXTRACTION_MIN_VALID_PIXELS:
        raise ValueError(
            f"Invalid image: Too dark or does not contain conjunctiva area "
            f"(hanya {num_valid_pixels} piksel valid terdeteksi, minimum 500)."
        )

    # === VALIDASI BIOLOGIS KONJUNGTIVA ===
    # Berdasarkan statistik dataset training (Eyes-defy-anemia):
    # - Konjungtiva sehat/anemia memiliki dominansi kanal Merah (R) > Biru (B)
    # - Nilai a* LAB (sumbu merah-hijau) selalu positif (jaringan konjungtiva = kemerahan)
    # - Lightness (L*) tidak terlalu tinggi (bukan permukaan putih solid) dan tidak terlalu gelap
    # - Redness Index (R/(G+B)) berada dalam rentang biologis yang masuk akal
    img_rgb_for_validation = img_rgb_float if img_pil.mode != "RGBA" else img_array[:, :, :3] / 255.0
    img_lab_validation = convert_rgb_to_lab(img_rgb_for_validation)

    R_val = img_rgb_for_validation[:, :, 0][valid_mask]
    G_val = img_rgb_for_validation[:, :, 1][valid_mask]
    B_val = img_rgb_for_validation[:, :, 2][valid_mask]
    a_star_val = img_lab_validation[:, :, 1][valid_mask]
    L_star_val = img_lab_validation[:, :, 0][valid_mask]

    mean_R = float(np.mean(R_val))
    mean_G = float(np.mean(G_val))
    mean_B = float(np.mean(B_val))
    mean_a_star = float(np.mean(a_star_val))
    mean_L_star = float(np.mean(L_star_val))
    mean_redness = float(np.mean(R_val / (G_val + B_val + 1e-8)))

    # Aturan 1: Kanal Merah (R) HARUS lebih dominan dari Biru (B).
    # Konjungtiva selalu lebih merah dari biru. Foto lantai dingin (keramik biru/abu) akan ditolak di sini.
    if mean_R <= mean_B:
        raise ValueError(
            f"Invalid image: Color dominance is not conjunctival red "
            f"(R={mean_R:.3f} ≤ B={mean_B:.3f}). Pastikan foto menampilkan area "
            f"with adequate lighting."
        )

    # Aturan 2: Nilai a* LAB (sumbu merah) HARUS positif.
    # Konjungtiva = jaringan kemerahan → a* > 0. Lantai/dinding hijau/biru → a* < 0.
    if mean_a_star < 5.0:
        raise ValueError(
            f"Invalid image: Color does not show redness characteristics "
            f"of conjunctival tissue (a*={mean_a_star:.2f}, "
            f"minimum a*=5.0). Ensure the photo shows the eye conjunctiva, not other surfaces."
        )

    # Aturan 3: Lightness (L*) HARUS dalam rentang jaringan biologis (25–90).
    # < 25 = terlalu gelap (kamera tertutup), > 90 = terlalu terang (foto langit/lampu putih polos).
    if not (25.0 <= mean_L_star <= 90.0):
        raise ValueError(
            f"Invalid image: Image brightness is not suitable for conjunctival analysis "
            f"(L*={mean_L_star:.2f}, harus antara 25–90). "
            f"Ensure adequate lighting and the camera is not too far/close."
        )

    # Aturan 4: Redness Index HARUS berada dalam rentang biologis konjungtiva (0.30–1.80).
    # Nilai di bawah 0.30 = terlalu biru/hijau (bukan jaringan merah). Nilai > 1.80 = saturasi ekstrem.
    if not (0.30 <= mean_redness <= 1.80):
        raise ValueError(
            f"Invalid image: Pallor indicator is outside the biological range of conjunctiva "
            f"(Redness Index={mean_redness:.3f}, harus antara 0.30–1.80). "
            f"Ensure the image shows the eye conjunctiva."
        )
    # === AKHIR VALIDASI BIOLOGIS ===


    img_lab = convert_rgb_to_lab(img_rgb_float)
    img_hsv = convert_rgb_to_hsv(img_rgb_float)
    img_ycbcr = convert_rgb_to_ycbcr(img_rgb_float)

    R = img_rgb_float[:, :, 0][valid_mask]
    G = img_rgb_float[:, :, 1][valid_mask]
    B = img_rgb_float[:, :, 2][valid_mask]

    L_star = img_lab[:, :, 0][valid_mask]
    a_star = img_lab[:, :, 1][valid_mask]
    b_star = img_lab[:, :, 2][valid_mask]

    H_channel = img_hsv[:, :, 0][valid_mask]
    S_channel = img_hsv[:, :, 1][valid_mask]
    V_channel = img_hsv[:, :, 2][valid_mask]

    Y_channel = img_ycbcr[:, :, 0][valid_mask]
    Cb_channel = img_ycbcr[:, :, 1][valid_mask]
    Cr_channel = img_ycbcr[:, :, 2][valid_mask]

    features = {}
    for channel_data, channel_name in [(R, "rgb_R"), (G, "rgb_G"), (B, "rgb_B")]:
        features.update(compute_channel_statistics(channel_data, channel_name))
    for channel_data, channel_name in [(L_star, "lab_L"), (a_star, "lab_a"), (b_star, "lab_b")]:
        features.update(compute_channel_statistics(channel_data, channel_name))
    for channel_data, channel_name in [(H_channel, "hsv_H"), (S_channel, "hsv_S"), (V_channel, "hsv_V")]:
        features.update(compute_channel_statistics(channel_data, channel_name))
    for channel_data, channel_name in [(Y_channel, "ycbcr_Y"), (Cb_channel, "ycbcr_Cb"), (Cr_channel, "ycbcr_Cr")]:
        features.update(compute_channel_statistics(channel_data, channel_name))

    epsilon = 1e-8
    redness_index = R / (G + B + epsilon)
    features.update(compute_channel_statistics(redness_index, "pallor_redness_index"))

    norm_total = R + G + B + epsilon
    norm_red = R / norm_total
    norm_green = G / norm_total
    norm_blue = B / norm_total
    features.update(compute_channel_statistics(norm_red, "pallor_norm_red"))
    features.update(compute_channel_statistics(norm_green, "pallor_norm_green"))
    features.update(compute_channel_statistics(norm_blue, "pallor_norm_blue"))

    chroma_lab = np.sqrt(a_star ** 2 + b_star ** 2)
    features.update(compute_channel_statistics(chroma_lab, "pallor_chroma_lab"))

    hue_angle_lab_degrees = np.degrees(np.arctan2(b_star, a_star))
    features.update(compute_channel_statistics(hue_angle_lab_degrees, "pallor_hue_angle_lab"))

    green_minus_red = G - R
    features.update(compute_channel_statistics(green_minus_red, "pallor_green_minus_red"))

    features["meta_num_valid_pixels"] = num_valid_pixels
    features["meta_valid_pixel_ratio"] = float(valid_mask.sum() / valid_mask.size)

    return features

# Global AI Model State
onnx_session = None
scaler_mean = None
scaler_scale = None
feature_names_ordered = None

def load_ai_model():
    global onnx_session, scaler_mean, scaler_scale, feature_names_ordered
    
    base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    onnx_path = os.path.join(base_dir, "final_anemia_classifier.onnx")
    meta_path = os.path.join(base_dir, "final_anemia_classifier_metadata.json")
    
    if not os.path.exists(onnx_path) or not os.path.exists(meta_path):
        return False
        
    onnx_session = ort.InferenceSession(onnx_path)
    
    with open(meta_path, 'r') as f:
        meta = json.load(f)
        scaler_mean = np.array(meta["scaler_params"]["mean_"])
        scaler_scale = np.array(meta["scaler_params"]["scale_"])
        feature_names_ordered = meta["feature_names_ordered"]
    return True

def predict_image(img_pil):
    if onnx_session is None:
        if not load_ai_model():
            raise Exception("AI Model not trained or not found!")
            
    # Extract features
    features_dict = extract_conjunctiva_features(img_pil)
    
    # Ordering features as expected by the model
    feature_vector = np.array([features_dict[feat] for feat in feature_names_ordered], dtype=np.float32)
    
    # Apply Standard Scaler
    scaled_vector = (feature_vector - scaler_mean) / scaler_scale
    scaled_vector = scaled_vector.reshape(1, -1).astype(np.float32)
    
    # ONNX Inference
    input_name = onnx_session.get_inputs()[0].name
    proba_name = onnx_session.get_outputs()[1].name # Scikit-Learn ONNX outputs [label, probabilities]
    
    result = onnx_session.run([proba_name], {input_name: scaled_vector})
    
    # Result[0] is usually a list of dicts for skl2onnx classifiers e.g. [{0: 0.15, 1: 0.85}]
    probabilities = result[0][0]
    
    prob_class_0 = probabilities.get(0, 0.0)
    prob_class_1 = probabilities.get(1, 0.0)
    
    anemia_status = "Anemia" if prob_class_1 > 0.5 else "Non-Anemia"
    confidence = max(prob_class_0, prob_class_1)
    redness_index = features_dict.get("pallor_redness_index_mean", 0)
    
    color_details = {
        "R": features_dict.get("rgb_R_mean", 0) * 255, # Scale back to 0-255 for better display
        "G": features_dict.get("rgb_G_mean", 0) * 255,
        "B": features_dict.get("rgb_B_mean", 0) * 255,
        "L": features_dict.get("lab_L_mean", 0),
        "a": features_dict.get("lab_a_mean", 0),
        "b": features_dict.get("lab_b_mean", 0),
        "H": features_dict.get("hsv_H_mean", 0) * 360 # Scale back to 0-360 degrees
    }
    
    return {
        "status": anemia_status,
        "confidence": float(confidence),
        "redness_index": float(redness_index),
        "probabilities": [float(prob_class_0), float(prob_class_1)],
        "color_details": json.dumps(color_details)
    }
