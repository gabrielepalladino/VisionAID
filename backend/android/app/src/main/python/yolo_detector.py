import onnxruntime as ort
import numpy as np
from PIL import Image
import io
import json

class YoloDetector:
    def __init__(self):
        self.session = None
        self.input_size = 640
        self.confidence_threshold = 0.5
        self.iou_threshold = 0.45
        
        # Classi di pericolo (COCO dataset)
        self.danger_classes = {0, 1, 2, 3, 5, 7}
        
        # Nomi classi COCO
        self.class_names = [
            'person', 'bicycle', 'car', 'motorcycle', 'airplane', 'bus',
            'train', 'truck', 'boat', 'traffic light', 'fire hydrant',
            'stop sign', 'parking meter', 'bench', 'bird', 'cat', 'dog',
            'horse', 'sheep', 'cow', 'elephant', 'bear', 'zebra', 'giraffe',
            'backpack', 'umbrella', 'handbag', 'tie', 'suitcase', 'frisbee',
            'skis', 'snowboard', 'sports ball', 'kite', 'baseball bat',
            'baseball glove', 'skateboard', 'surfboard', 'tennis racket',
            'bottle', 'wine glass', 'cup', 'fork', 'knife', 'spoon', 'bowl',
            'banana', 'apple', 'sandwich', 'orange', 'broccoli', 'carrot',
            'hot dog', 'pizza', 'donut', 'cake', 'chair', 'couch',
            'potted plant', 'bed', 'dining table', 'toilet', 'tv', 'laptop',
            'mouse', 'remote', 'keyboard', 'cell phone', 'microwave', 'oven',
            'toaster', 'sink', 'refrigerator', 'book', 'clock', 'vase',
            'scissors', 'teddy bear', 'hair drier', 'toothbrush'
        ]
    
    def load_model(self, model_path):
        """Carica il modello ONNX"""
        try:
            self.session = ort.InferenceSession(
                model_path,
                providers=['CPUExecutionProvider']
            )
            return True
        except Exception as e:
            print(f"Errore caricamento modello: {e}")
            return False
    
    def preprocess_image(self, image_bytes):
        """Preprocessa l'immagine per YOLO"""
        try:
            # Converti bytes in immagine PIL
            image = Image.open(io.BytesIO(image_bytes))
            
            # Converti in RGB se necessario
            if image.mode != 'RGB':
                image = image.convert('RGB')
            
            # Ridimensiona mantenendo aspect ratio
            original_size = image.size
            image = image.resize((self.input_size, self.input_size), Image.BILINEAR)
            
            # Converti in numpy array e normalizza
            img_array = np.array(image).astype(np.float32)
            img_array = img_array / 255.0
            
            # Riordina dimensioni: (H, W, C) -> (C, H, W)
            img_array = np.transpose(img_array, (2, 0, 1))
            
            # Aggiungi batch dimension: (C, H, W) -> (1, C, H, W)
            img_array = np.expand_dims(img_array, axis=0)
            
            return img_array, original_size
            
        except Exception as e:
            print(f"Errore preprocessing: {e}")
            return None, None
    
    def postprocess_detections(self, outputs, original_size):
        """Post-processa le detection YOLO"""
        try:
            # YOLOv8 output: (1, 84, 8400)
            # 84 = [x, y, w, h] + 80 classi
            predictions = outputs[0]
            predictions = np.transpose(predictions[0])  # (8400, 84)
            
            detections = []
            
            for pred in predictions:
                # Estrai bbox e confidenze
                x_center, y_center, width, height = pred[:4]
                class_scores = pred[4:]
                
                # Trova classe con confidenza massima
                class_id = int(np.argmax(class_scores))
                confidence = float(class_scores[class_id])
                
                # Filtra per confidenza e classi di pericolo
                if confidence < self.confidence_threshold:
                    continue
                if class_id not in self.danger_classes:
                    continue
                
                # Converti coordinate da center format a corner format
                x1 = (x_center - width / 2) / self.input_size
                y1 = (y_center - height / 2) / self.input_size
                x2 = (x_center + width / 2) / self.input_size
                y2 = (y_center + height / 2) / self.input_size
                
                # Clamp tra 0 e 1
                x1 = max(0, min(1, x1))
                y1 = max(0, min(1, y1))
                x2 = max(0, min(1, x2))
                y2 = max(0, min(1, y2))
                
                detections.append({
                    'class_id': class_id,
                    'class_name': self.class_names[class_id],
                    'confidence': confidence,
                    'bbox': [x1, y1, x2, y2]
                })
            
            # Applica Non-Maximum Suppression
            detections = self.apply_nms(detections)
            
            return detections
            
        except Exception as e:
            print(f"Errore postprocessing: {e}")
            return []
    
    def apply_nms(self, detections):
        """Applica Non-Maximum Suppression"""
        if len(detections) == 0:
            return []
        
        # Ordina per confidenza decrescente
        detections = sorted(detections, key=lambda x: x['confidence'], reverse=True)
        
        final_detections = []
        
        while len(detections) > 0:
            # Prendi detection con confidenza massima
            best = detections[0]
            final_detections.append(best)
            detections = detections[1:]
            
            # Rimuovi detection sovrapposte
            detections = [
                d for d in detections
                if self.calculate_iou(best['bbox'], d['bbox']) < self.iou_threshold
            ]
        
        return final_detections
    
    def calculate_iou(self, box1, box2):
        """Calcola Intersection over Union"""
        x1_1, y1_1, x2_1, y2_1 = box1
        x1_2, y1_2, x2_2, y2_2 = box2
        
        # Area intersezione
        x1_i = max(x1_1, x1_2)
        y1_i = max(y1_1, y1_2)
        x2_i = min(x2_1, x2_2)
        y2_i = min(y2_1, y2_2)
        
        if x2_i < x1_i or y2_i < y1_i:
            return 0.0
        
        intersection = (x2_i - x1_i) * (y2_i - y1_i)
        
        # Area unione
        area1 = (x2_1 - x1_1) * (y2_1 - y1_1)
        area2 = (x2_2 - x1_2) * (y2_2 - y1_2)
        union = area1 + area2 - intersection
        
        return intersection / union if union > 0 else 0.0
    
    def detect(self, image_bytes):
        """Esegue detection su un'immagine"""
        if self.session is None:
            return json.dumps({'error': 'Model not loaded'})
        
        try:
            # Preprocess
            img_array, original_size = self.preprocess_image(image_bytes)
            if img_array is None:
                return json.dumps({'error': 'Preprocessing failed'})
            
            # Inference
            input_name = self.session.get_inputs()[0].name
            outputs = self.session.run(None, {input_name: img_array})
            
            # Postprocess
            detections = self.postprocess_detections(outputs, original_size)
            
            return json.dumps({
                'success': True,
                'detections': detections,
                'count': len(detections)
            })
            
        except Exception as e:
            return json.dumps({'error': str(e)})

# Istanza globale
detector = YoloDetector()

def initialize(model_path):
    """Inizializza il detector"""
    success = detector.load_model(model_path)
    return json.dumps({'success': success})

def process_frame(image_bytes):
    """Processa un frame dalla camera"""
    return detector.detect(image_bytes)