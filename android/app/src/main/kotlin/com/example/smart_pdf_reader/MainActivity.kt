package com.example.smart_pdf_reader

import android.content.Intent
import android.database.Cursor
import android.net.Uri
import android.provider.OpenableColumns
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
	private val methodChannelName = "smart_pdf_reader/external_pdf"
	private val eventChannelName = "smart_pdf_reader/external_pdf_events"
	private var eventSink: EventChannel.EventSink? = null
	private val pendingUris = mutableListOf<String>()

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)

		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, methodChannelName)
			.setMethodCallHandler { call, result ->
				when (call.method) {
					"getInitialPdf" -> result.success(cachePdfUri(intent?.data))
					"cachePdf" -> {
						val uri = call.argument<String>("uri")?.let(Uri::parse)
						result.success(cachePdfUri(uri))
					}
					else -> result.notImplemented()
				}
			}

		EventChannel(flutterEngine.dartExecutor.binaryMessenger, eventChannelName)
			.setStreamHandler(object : EventChannel.StreamHandler {
				override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
					eventSink = events
					pendingUris.toList().forEach { emitCachedPdf(it) }
					pendingUris.clear()
				}

				override fun onCancel(arguments: Any?) {
					eventSink = null
				}
			})
	}

	override fun onNewIntent(newIntent: Intent) {
		super.onNewIntent(newIntent)
		setIntent(newIntent)
		val uri = newIntent.dataString ?: return
		if (eventSink == null) {
			pendingUris.add(uri)
		} else {
			emitCachedPdf(uri)
		}
	}

	private fun emitCachedPdf(uriString: String) {
		val cached = cachePdfUri(Uri.parse(uriString)) ?: return
		eventSink?.success(cached)
	}

	private fun cachePdfUri(uri: Uri?): Map<String, String>? {
		if (uri == null) return null
		if (uri.scheme == "file") {
			return mapOf(
				"path" to (uri.path ?: return null),
				"name" to (uri.lastPathSegment ?: "document.pdf"),
			)
		}

		val name = queryDisplayName(uri) ?: "document.pdf"
		val safeName = name.replace(Regex("[^A-Za-z0-9._-]"), "_")
		val output = File(cacheDir, "external_pdf_${uri.toString().hashCode()}_$safeName")
		if (!output.exists()) {
			val input = contentResolver.openInputStream(uri) ?: return null
			input.use { source ->
				FileOutputStream(output).use { destination -> source.copyTo(destination) }
			}
		}
		return mapOf("path" to output.absolutePath, "name" to name)
	}

	private fun queryDisplayName(uri: Uri): String? {
		val cursor: Cursor? = contentResolver.query(
			uri,
			arrayOf(OpenableColumns.DISPLAY_NAME),
			null,
			null,
			null,
		)
		return cursor?.use {
			if (it.moveToFirst()) it.getString(0) else null
		}
	}
}
