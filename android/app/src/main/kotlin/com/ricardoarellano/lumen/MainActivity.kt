package com.ricardoarellano.lumen

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

/**
 * Integración nativa con el sensor de luz ambiental de Android.
 *
 *  - MethodChannel "lumen/light_info": pregunta si el dispositivo tiene sensor.
 *  - EventChannel  "lumen/light":      envía las lecturas en lux a Flutter.
 *
 * El sensor solo se registra mientras Flutter escucha (onListen) y se libera
 * al dejar de escuchar (onCancel), para no gastar batería.
 */
class MainActivity : FlutterActivity() {

    private var lightListener: SensorEventListener? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val sensorManager = getSystemService(Context.SENSOR_SERVICE) as SensorManager
        val lightSensor: Sensor? = sensorManager.getDefaultSensor(Sensor.TYPE_LIGHT)
        val messenger = flutterEngine.dartExecutor.binaryMessenger

        MethodChannel(messenger, "lumen/light_info").setMethodCallHandler { call, result ->
            when (call.method) {
                "hasSensor" -> result.success(lightSensor != null)
                else -> result.notImplemented()
            }
        }

        EventChannel(messenger, "lumen/light").setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    if (lightSensor == null) {
                        events?.error("NO_SENSOR", "Este dispositivo no tiene sensor de luz", null)
                        return
                    }
                    val listener = object : SensorEventListener {
                        override fun onSensorChanged(event: SensorEvent) {
                            events?.success(event.values[0].toDouble())
                        }

                        override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}
                    }
                    lightListener = listener
                    sensorManager.registerListener(
                        listener,
                        lightSensor,
                        SensorManager.SENSOR_DELAY_UI
                    )
                }

                override fun onCancel(arguments: Any?) {
                    lightListener?.let { sensorManager.unregisterListener(it) }
                    lightListener = null
                }
            }
        )
    }
}
