package com.example.test1

import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.chaquo.python.Python
import com.chaquo.python.android.AndroidPlatform
import java.io.File
import org.json.JSONObject

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.test1/yolo"
    private lateinit var python: Python
    private var isModelLoaded = false
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Inizializza Python
        if (!Python.isStarted()) {
            Python.start(AndroidPlatform(this))
        }
        python = Python.getInstance()
        
        // Setup MethodChannel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "loadModel" -> {
                    val modelPath = call.argument<String>("modelPath")
                    if (modelPath != null) {
                        loadModel(modelPath, result)
                    } else {
                        result.error("INVALID_ARGUMENT", "Model path is null", null)
                    }
                }
                "detectObjects" -> {
                    val imageBytes = call.argument<ByteArray>("imageBytes")
                    if (imageBytes != null) {
                        detectObjects(imageBytes, result)
                    } else {
                        result.error("INVALID_ARGUMENT", "Image bytes are null", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
    
    private fun loadModel(assetPath: String, result: MethodChannel.Result) {
        Thread {
            try {
                // Copia modello da assets a file temporaneo
                val assetManager = assets
                val inputStream = assetManager.open(assetPath)
                
                val modelFile = File(cacheDir, "yolov8n.onnx")
                modelFile.outputStream().use { outputStream ->
                    inputStream.copyTo(outputStream)
                }
                
                // Carica modello in Python
                val module = python.getModule("yolo_detector")
                val initResult = module.callAttr("initialize", modelFile.absolutePath).toString()
                
                val json = JSONObject(initResult)
                isModelLoaded = json.getBoolean("success")
                
                Handler(Looper.getMainLooper()).post {
                    if (isModelLoaded) {
                        result.success(true)
                    } else {
                        result.error("MODEL_LOAD_ERROR", "Failed to load model", null)
                    }
                }
                
            } catch (e: Exception) {
                Handler(Looper.getMainLooper()).post {
                    result.error("MODEL_LOAD_ERROR", e.message, null)
                }
            }
        }.start()
    }
    
    private fun detectObjects(imageBytes: ByteArray, result: MethodChannel.Result) {
        if (!isModelLoaded) {
            result.error("MODEL_NOT_LOADED", "Model not loaded", null)
            return
        }
        
        Thread {
            try {
                val module = python.getModule("yolo_detector")
                val detectResult = module.callAttr("process_frame", imageBytes).toString()
                
                Handler(Looper.getMainLooper()).post {
                    result.success(detectResult)
                }
                
            } catch (e: Exception) {
                Handler(Looper.getMainLooper()).post {
                    result.error("DETECTION_ERROR", e.message, null)
                }
            }
        }.start()
    }
}