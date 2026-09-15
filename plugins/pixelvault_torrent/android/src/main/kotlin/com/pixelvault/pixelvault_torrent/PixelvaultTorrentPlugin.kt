package com.pixelvault.pixelvault_torrent

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import kotlinx.coroutines.CoroutineExceptionHandler
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import java.io.File
import java.util.concurrent.CopyOnWriteArraySet

/**
 * The torrent engine is process-wide, not per Flutter engine.
 *
 * A Flutter plugin is instantiated once per `FlutterEngine`, and this app runs
 * more than one: flutter_foreground_task starts its own engine for the
 * download notification service with `FlutterEngine(context)`, which
 * registers every plugin, and Android can recreate the activity's engine
 * while that service keeps the process alive. When each plugin instance
 * owned its own session, the process ended up with several libtorrent
 * sessions competing for the same listen ports and data directory, and an
 * engine going away called `stop()` on a session another engine was still
 * downloading through.
 *
 * Everything stateful lives here instead, shared by reference count: the
 * session stops only when the last attached engine detaches.
 */
internal object TorrentRuntime {
    private const val TAG = "TorrentRuntime"
    private val lock = Any()
    private var refCount = 0
    private var initialized = false

    lateinit var registry: TorrentHandleRegistry
        private set
    lateinit var progressBridge: TorrentProgressBridge
        private set
    lateinit var downloadService: TorrentDownloadService
        private set
    val fileIndexer = TorrentFileIndexer()
    val archiveExtractor = ArchiveExtractorService()

    @Volatile
    var listenerRegistered = false

    /** Every engine that is currently listening for progress. */
    private val sinks = CopyOnWriteArraySet<EventChannel.EventSink>()
    private val mainHandler by lazy { Handler(Looper.getMainLooper()) }

    fun acquire(context: Context) {
        synchronized(lock) {
            if (!initialized) {
                val appContext = context.applicationContext
                registry = TorrentHandleRegistry(appContext)
                progressBridge = TorrentProgressBridge { downloadId, fileName, progress, speedMBs, downloadedBytes, status ->
                    val event = mapOf(
                        "downloadId" to downloadId,
                        "fileName" to fileName,
                        "progress" to progress.toDouble(),
                        "speedMBs" to speedMBs.toDouble(),
                        "downloadedBytes" to downloadedBytes,
                        "status" to status.name
                    )
                    // An EventSink may only be touched on the main thread, and
                    // TorrentProgressBridge emits from Dispatchers.IO and from
                    // libtorrent's alert thread.
                    mainHandler.post {
                        for (sink in sinks) {
                            try {
                                sink.success(event)
                            } catch (e: Exception) {
                                Log.w(TAG, "Dropping progress event for a detached listener: ${e.message}")
                            }
                        }
                    }
                }
                downloadService = TorrentDownloadService(appContext, registry, progressBridge, archiveExtractor)
                initialized = true
            }
            refCount++
        }
    }

    fun release() {
        synchronized(lock) {
            refCount = (refCount - 1).coerceAtLeast(0)
            if (refCount > 0 || !initialized) return
            try {
                if (listenerRegistered) registry.session().removeListener(progressBridge)
            } catch (e: Exception) {
                Log.w(TAG, "Could not remove progress listener: ${e.message}")
            }
            try {
                registry.stop()
            } catch (e: Exception) {
                Log.w(TAG, "Could not stop torrent session: ${e.message}")
            }
            listenerRegistered = false
            progressBridge.dispose()
            sinks.clear()
            // The next engine to attach builds a fresh session rather than
            // reusing one whose bridge scope has just been cancelled.
            initialized = false
        }
    }

    fun addSink(sink: EventChannel.EventSink) {
        sinks.add(sink)
    }

    fun removeSink(sink: EventChannel.EventSink?) {
        if (sink != null) sinks.remove(sink)
    }
}

/**
 * Native torrent engine + 7z extraction for PixelVault, exposed over a
 * MethodChannel (commands) and an EventChannel (progress). All state is in
 * [TorrentRuntime]; an instance of this class is only the per-engine channel
 * wiring.
 */
class PixelvaultTorrentPlugin :
    FlutterPlugin,
    MethodCallHandler,
    EventChannel.StreamHandler {

    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private lateinit var appContext: Context
    private var eventSink: EventChannel.EventSink? = null
    private var attached = false

    // SupervisorJob so one failed call does not cancel its siblings, and an
    // exception handler so nothing thrown inside a coroutine reaches the main
    // thread's uncaught-exception handler, which would kill the process.
    private val scope = CoroutineScope(
        SupervisorJob() + Dispatchers.Main + CoroutineExceptionHandler { _, e ->
            Log.e(TAG, "Unhandled error in torrent plugin coroutine", e)
        }
    )

    companion object {
        private const val TAG = "PixelvaultTorrentPlugin"
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        appContext = binding.applicationContext

        methodChannel = MethodChannel(binding.binaryMessenger, "pixelvault_torrent/methods")
        methodChannel.setMethodCallHandler(this)

        eventChannel = EventChannel(binding.binaryMessenger, "pixelvault_torrent/progress")
        eventChannel.setStreamHandler(this)

        TorrentRuntime.acquire(appContext)
        attached = true
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        TorrentRuntime.removeSink(eventSink)
        eventSink = events
        if (events != null) TorrentRuntime.addSink(events)
    }

    override fun onCancel(arguments: Any?) {
        TorrentRuntime.removeSink(eventSink)
        eventSink = null
    }

    /**
     * Replies without ever throwing. Replying after the engine has gone away,
     * or a second time to the same call, raises an IllegalStateException on
     * the main thread — an uncaught one, which ends the process.
     */
    private fun Result.replySuccess(value: Any?) {
        try {
            success(value)
        } catch (e: Exception) {
            Log.w(TAG, "Reply dropped: ${e.message}")
        }
    }

    private fun Result.replyError(code: String, message: String?) {
        try {
            error(code, message, null)
        } catch (e: Exception) {
            Log.w(TAG, "Error reply dropped: ${e.message}")
        }
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "startSession" -> runCatching {
                TorrentRuntime.registry.start()
                if (!TorrentRuntime.listenerRegistered) {
                    val session = TorrentRuntime.registry.session()
                    // Removing first keeps a stop/start cycle from registering
                    // the same listener twice and doubling every event.
                    session.removeListener(TorrentRuntime.progressBridge)
                    session.addListener(TorrentRuntime.progressBridge)
                    TorrentRuntime.listenerRegistered = true
                }
            }.fold(
                onSuccess = { result.replySuccess(null) },
                onFailure = { result.replyError("START_SESSION_FAILED", it.message) }
            )

            "stopSession" -> runCatching {
                if (TorrentRuntime.listenerRegistered) {
                    TorrentRuntime.registry.session().removeListener(TorrentRuntime.progressBridge)
                }
                TorrentRuntime.registry.stop()
                TorrentRuntime.listenerRegistered = false
            }.fold(
                onSuccess = { result.replySuccess(null) },
                onFailure = { result.replyError("STOP_SESSION_FAILED", it.message) }
            )

            "fetchMetadata" -> scope.launch {
                runCatching {
                    val magnet = call.argument<String>("magnet")!!
                    val folders = call.argument<List<String>>("folders") ?: emptyList()
                    val handle = TorrentRuntime.registry.getOrFetch(magnet)
                    val info = handle.torrentFile() ?: run {
                        Log.w(TAG, "No TorrentInfo after metadata fetch")
                        throw IllegalStateException("No TorrentInfo after fetch")
                    }
                    val entries = TorrentRuntime.fileIndexer.index(info, magnet, folders)
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
                    onSuccess = { result.replySuccess(it) },
                    onFailure = { result.replyError("FETCH_METADATA_FAILED", it.message) }
                )
            }

            "startFileDownload" -> scope.launch {
                runCatching {
                    val magnet = call.argument<String>("magnet")!!
                    val fileIndex = call.argument<Int>("fileIndex")!!
                    val fileName = call.argument<String>("fileName")!!
                    val downloadId = call.argument<String>("downloadId")!!
                    TorrentRuntime.downloadService.startDownload(magnet, fileIndex, fileName, downloadId)
                }.fold(
                    onSuccess = { result.replySuccess(null) },
                    onFailure = { result.replyError("START_DOWNLOAD_FAILED", it.message) }
                )
            }

            "cancelFileDownload" -> scope.launch {
                runCatching {
                    val magnet = call.argument<String>("magnet")!!
                    val downloadId = call.argument<String>("downloadId")!!
                    TorrentRuntime.downloadService.cancelDownload(magnet, downloadId)
                }.fold(
                    onSuccess = { result.replySuccess(null) },
                    onFailure = { result.replyError("CANCEL_DOWNLOAD_FAILED", it.message) }
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
                    TorrentRuntime.downloadService.finishDownload(magnet, fileName, downloadId, destDirUri, subPath, extract)
                }.fold(
                    onSuccess = { result.replySuccess(it) },
                    onFailure = { result.replyError("FINISH_DOWNLOAD_FAILED", it.message) }
                )
            }

            "extractArchive" -> scope.launch {
                runCatching {
                    val archivePath = call.argument<String>("archivePath")!!
                    val destDirUri = call.argument<String>("destDirUri")!!
                    val subPath = call.argument<String>("subPath") ?: ""
                    TorrentRuntime.archiveExtractor.extractArchiveFile(appContext, File(archivePath), destDirUri, subPath)
                }.fold(
                    onSuccess = { result.replySuccess(it) },
                    onFailure = { result.replyError("EXTRACT_ARCHIVE_FAILED", it.message) }
                )
            }

            else -> result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        TorrentRuntime.removeSink(eventSink)
        eventSink = null
        scope.cancel()
        if (attached) {
            attached = false
            TorrentRuntime.release()
        }
    }
}
