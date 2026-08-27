package com.pixelvault.pixelvault_torrent

import android.content.Context
import android.util.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import java.io.File

/**
 * Native torrent engine + 7z extraction for PixelVault. Wraps
 * `TorrentHandleRegistry`/`TorrentDownloadService`/`TorrentProgressBridge`
 * (ported from Milou's Kotlin implementation, see sibling files) behind a
 * MethodChannel (commands) + EventChannel (progress stream), so the Flutter
 * side stays pure Dart/UI and this plugin owns the whole torrent lifecycle.
 */
class PixelvaultTorrentPlugin :
    FlutterPlugin,
    MethodCallHandler,
    EventChannel.StreamHandler {

    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private lateinit var appContext: Context

    private lateinit var registry: TorrentHandleRegistry
    private lateinit var progressBridge: TorrentProgressBridge
    private lateinit var downloadService: TorrentDownloadService
    private val fileIndexer = TorrentFileIndexer()
    private val archiveExtractor = ArchiveExtractorService()

    private var eventSink: EventChannel.EventSink? = null
    private val scope = CoroutineScope(Dispatchers.Main + Job())

    companion object {
        private const val TAG = "PixelvaultTorrentPlugin"
    }
    private var listenerRegistered = false

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        appContext = binding.applicationContext

        methodChannel = MethodChannel(binding.binaryMessenger, "pixelvault_torrent/methods")
        methodChannel.setMethodCallHandler(this)

        eventChannel = EventChannel(binding.binaryMessenger, "pixelvault_torrent/progress")
        eventChannel.setStreamHandler(this)

        registry = TorrentHandleRegistry(appContext)
        progressBridge = TorrentProgressBridge { downloadId, fileName, progress, speedMBs, downloadedBytes, status ->
            // EventSink must only be touched on the platform (main) thread;
            // TorrentProgressBridge polls/emits from Dispatchers.IO.
            scope.launch {
                eventSink?.success(
                    mapOf(
                        "downloadId" to downloadId,
                        "fileName" to fileName,
                        "progress" to progress.toDouble(),
                        "speedMBs" to speedMBs.toDouble(),
                        "downloadedBytes" to downloadedBytes,
                        "status" to status.name
                    )
                )
            }
        }
        downloadService = TorrentDownloadService(appContext, registry, progressBridge, archiveExtractor)
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "startSession" -> {
                registry.start()
                if (!listenerRegistered) {
                    registry.session().addListener(progressBridge)
                    listenerRegistered = true
                }
                result.success(null)
            }

            "stopSession" -> {
                registry.stop()
                listenerRegistered = false
                result.success(null)
            }

            "fetchMetadata" -> scope.launch {
                runCatching {
                    val magnet = call.argument<String>("magnet")!!
                    val folders = call.argument<List<String>>("folders") ?: emptyList()
                    val handle = registry.getOrFetch(magnet)
                    val info = handle.torrentFile() ?: run {
                        Log.w(TAG, "No TorrentInfo after fetch for $magnet")
                        throw IllegalStateException("No TorrentInfo after fetch")
                    }
                    val entries = fileIndexer.index(info, magnet, folders)
                    mapOf(
                        "infoHash" to info.infoHash().toString(),
                        "files" to entries.map {
                            mapOf(
                                "fileName" to it.fileName,
                                "fileIndex" to it.fileIndex,
                                "fileSize" to it.fileSize
                            )
                        }
                    )
                }.fold(
                    onSuccess = { result.success(it) },
                    onFailure = { result.error("FETCH_METADATA_FAILED", it.message, null) }
                )
            }

            "startFileDownload" -> scope.launch {
                runCatching {
                    val magnet = call.argument<String>("magnet")!!
                    val fileIndex = call.argument<Int>("fileIndex")!!
                    val fileName = call.argument<String>("fileName")!!
                    val downloadId = call.argument<String>("downloadId")!!
                    downloadService.startDownload(magnet, fileIndex, fileName, downloadId)
                }.fold(
                    onSuccess = { result.success(null) },
                    onFailure = { result.error("START_DOWNLOAD_FAILED", it.message, null) }
                )
            }

            "cancelFileDownload" -> scope.launch {
                runCatching {
                    val magnet = call.argument<String>("magnet")!!
                    val downloadId = call.argument<String>("downloadId")!!
                    downloadService.cancelDownload(magnet, downloadId)
                }.fold(
                    onSuccess = { result.success(null) },
                    onFailure = { result.error("CANCEL_DOWNLOAD_FAILED", it.message, null) }
                )
            }

            "finishFileDownload" -> scope.launch {
                runCatching {
                    val magnet = call.argument<String>("magnet")!!
                    val fileName = call.argument<String>("fileName")!!
                    val downloadId = call.argument<String>("downloadId")!!
                    val destDirUri = call.argument<String>("destDirUri")!!
                    val subPath = call.argument<String>("subPath") ?: ""
                    val extract = call.argument<Boolean>("extract") ?: false
                    downloadService.finishDownload(magnet, fileName, downloadId, destDirUri, subPath, extract)
                }.fold(
                    onSuccess = { result.success(it) },
                    onFailure = { result.error("FINISH_DOWNLOAD_FAILED", it.message, null) }
                )
            }

            "extractArchive" -> scope.launch {
                runCatching {
                    val archivePath = call.argument<String>("archivePath")!!
                    val destDirUri = call.argument<String>("destDirUri")!!
                    val subPath = call.argument<String>("subPath") ?: ""
                    archiveExtractor.extractArchiveFile(appContext, File(archivePath), destDirUri, subPath)
                }.fold(
                    onSuccess = { result.success(it) },
                    onFailure = { result.error("EXTRACT_ARCHIVE_FAILED", it.message, null) }
                )
            }

            else -> result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        registry.stop()
        listenerRegistered = false
        progressBridge.dispose()
        scope.cancel()
    }
}
