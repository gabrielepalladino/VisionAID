from ultralytics import YOLO

print("📥 Caricamento yolov8n.pt...")
model = YOLO("yolov8n.pt")

print("🔄 Conversione in TFLite...")
model.export(
    format="tflite",
    imgsz=320,
    int8=False,    # NO quantizzazione
    half=False,    # NO FP16, usa FP32 completo
    nms=False,
    simplify=True,
)

print("✅ Conversione completata!")
print("📁 Cerca il file in: yolov8n_saved_model/")

# Lista i file generati
import os
for root, dirs, files in os.walk('yolov8n_saved_model'):
    for file in files:
        if file.endswith('.tflite'):
            filepath = os.path.join(root, file)
            size = os.path.getsize(filepath) / 1024 / 1024
            print(f"   ✓ {filepath} ({size:.2f} MB)")