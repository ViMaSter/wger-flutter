package de.wger.flutter

import com.google.android.gms.wearable.PutDataMapRequest
import com.google.android.gms.wearable.PutDataRequest
import com.google.android.gms.wearable.Wearable
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.nio.charset.Charset
class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.wger.watch"

    private lateinit var dataClient: com.google.android.gms.wearable.DataClient
    private var message = "";

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        dataClient = Wearable.getDataClient(this)

        val latch = java.util.concurrent.CountDownLatch(1)

        val listener = com.google.android.gms.wearable.DataClient.OnDataChangedListener { dataEvents ->
            for (event in dataEvents) {
                if (event.type == com.google.android.gms.wearable.DataEvent.TYPE_CHANGED) {
                    val dataMap = com.google.android.gms.wearable.DataMapItem.fromDataItem(event.dataItem).dataMap
                    var tmpMsg = dataMap.getString("message");
                    if (tmpMsg != null)
                    {
                        message = tmpMsg;
                    }
                    break
                }
            }
            latch.countDown()
        }

        dataClient.addListener(listener)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "sendUsername" && isPhone()) {
                    val msg = call.argument<String>("message")
                    sendMessageToWatch(msg ?: "")
                    result.success(null)
                } else if (call.method == "getData") {
                    val msg = fetchMessageForWatch()
                    if (msg.isEmpty()) {
                        result.error("null data for now1", "null data for now2", "null data for now3")
                    } else {
                        result.success(msg)
                    }
                } else {
                    result.notImplemented()
                }
            }
    }

    private fun fetchMessageForWatch(): String {
        return message
    }

    private fun sendMessageToWatch(message: String) {
        val nodeClient = Wearable.getNodeClient(this)
        val messageClient = Wearable.getDataClient(this)
        nodeClient.connectedNodes.addOnSuccessListener { nodes ->
            val putDataReq: PutDataRequest = PutDataMapRequest.create("/count").run {
                dataMap.putString("message", message)
                asPutDataRequest()
            }
            messageClient.putDataItem(putDataReq);
        }
    }

    private fun isPhone(): Boolean {
        // Simple check: watches usually don't have telephony features
        return packageManager.hasSystemFeature("android.hardware.telephony")
    }

    private fun isWatch(): Boolean {
        // Wear OS devices have this feature
        return packageManager.hasSystemFeature("android.hardware.type.watch")
    }
}
