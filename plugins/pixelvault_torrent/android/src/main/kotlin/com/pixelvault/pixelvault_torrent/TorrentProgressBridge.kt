package com.pixelvault.pixelvault_torrent

import android.util.Log
import kotlinx.coroutines.CoroutineExceptionHandler
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.delay
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import org.libtorrent4j.AlertListener
import org.libtorrent4j.TorrentHandle
import org.libtorrent4j.alerts.Alert
import org.libtorrent4j.alerts.AlertType
import org.libtorrent4j.alerts.FileErrorAlert
import org.libtorrent4j.alerts.TorrentErrorAlert
import org.libtorrent4j.alerts.TorrentFinishedAlert

/** Mirrors Milou's `DownloadStatus` enum, sent across the EventChannel as a string. */
enum class TorrentDownloadStatus { DOWNLOADING, COMPLETED, FAILED }

/** Emits progress events — implemented by the plugin's EventChannel sink wrapper. */
fun interface TorrentProgressEmitter {
    fun emit(downloadId: String, fileName: String, progress: Float, speedMBs: Float, downloadedBytes: Long, status: TorrentDownloadStatus)
}

/**
 * Port of Milou's `TorrentProgressBridge` — the Kotlin `DownloadProgressTracker`
 * StateFlow sink is replaced with [TorrentProgressEmitter] (backed by a
 * Flutter EventChannel on the Dart side).
 *
 * Tracking is keyed by `downloadId` (the Dart side's download attempt id), not
 * `fileName` — two downloads from different sources can share the same file
 * name, which used to let one silently overwrite the other's tracked entry.
 *
 * Nothing in here may throw out of a thread it does not own. The polling loop
 * runs on Dispatchers.IO and [alert] runs on libtorrent's own alert thread;
 * an exception escaping either is an uncaught exception, and Android kills the
 * whole process for it — every other download in flight included. Handles in
 * particular turn invalid underneath us whenever a torrent is removed, and
 * reading from an invalid handle throws.
 */
class TorrentProgressBridge(private val emitter: TorrentProgressEmitter) : AlertListener {

    private data class TrackedFile(
        val fileName: String,
        val fileIndex: Int,
        val handle: TorrentHandle,
        val expectedSize: Long,
        var lastStatus: TorrentDownloadStatus = TorrentDownloadStatus.DOWNLOADING
    )

    private val tracked = mutableMapOf<String, TrackedFile>()
    private val scope = CoroutineScope(
        SupervisorJob() + Dispatchers.IO + CoroutineExceptionHandler { _, e ->
            Log.e(TAG, "Progress polling failed", e)
        }
    )
    private var pollingJob: Job? = null

    fun trackDownload(downloadId: String, fileName: String, fileIndex: Int, handle: TorrentHandle) {
        val expectedSize = try {
            handle.torrentFile()?.files()?.fileSize(fileIndex) ?: 0L
        } catch (e: Exception) {
            0L
        }
        synchronized(this) {
            tracked[downloadId] = TrackedFile(fileName, fileIndex, handle, expectedSize)
            startPolling()
        }
        Log.d(TAG, "Tracking $fileName ($downloadId) at index $fileIndex")
    }

    fun untrackDownload(downloadId: String) {
        synchronized(this) {
            tracked.remove(downloadId)
            if (tracked.isEmpty()) stopPolling()
        }
    }

    /** Cancels the internal polling coroutine scope — call once when the owning runtime shuts down. */
    fun dispose() {
        synchronized(this) {
            tracked.clear()
            stopPolling()
        }
        scope.cancel()
    }

    private fun startPolling() {
        if (pollingJob != null) return
        pollingJob = scope.launch {
            while (isActive) {
                try {
                    updateProgress()
                } catch (e: Exception) {
                    // One bad tick must not end polling for every download.
                    Log.w(TAG, "Progress update failed: ${e.message}")
                }
                delay(1000L)
            }
        }
    }

    private fun stopPolling() {
        pollingJob?.cancel()
        pollingJob = null
    }

    private fun updateProgress() {
        val snapshot: Map<String, TrackedFile>
        synchronized(this) { snapshot = tracked.toMap() }

        snapshot.forEach { (downloadId, info) ->
            try {
                emitProgressFor(downloadId, info)
            } catch (e: Exception) {
                Log.w(TAG, "Skipping progress for $downloadId: ${e.message}")
            }
        }
    }

    private fun emitProgressFor(downloadId: String, info: TrackedFile) {
        val handle = info.handle
        if (!handle.isValid) return

        val status = handle.status()
        val total = info.expectedSize
        if (total <= 0) return

        val fileProgressBytes = try {
            handle.fileProgress()
        } catch (e: Exception) {
            null
        }
        val downloaded = if (fileProgressBytes != null && info.fileIndex < fileProgressBytes.size) {
            fileProgressBytes[info.fileIndex]
        } else {
            (status.progress() * total).toLong()
        }
        val progress = (downloaded.toFloat() / total.toFloat()).coerceIn(0f, 1f)
        val speedMBs = status.downloadPayloadRate() / (1024f * 1024f)
        val isFinished = downloaded >= total

        val newStatus = if (isFinished) TorrentDownloadStatus.COMPLETED else TorrentDownloadStatus.DOWNLOADING
        if (newStatus != info.lastStatus) {
            synchronized(this) { tracked[downloadId]?.lastStatus = newStatus }
        }

        emitter.emit(downloadId, info.fileName, progress, speedMBs, downloaded, newStatus)
    }

    fun countTrackedForHandle(handle: TorrentHandle): Int {
        synchronized(this) {
            return tracked.values.count { sameTorrent(it.handle, handle) }
        }
    }

    fun getTrackedFileIndicesForHandle(handle: TorrentHandle): Set<Int> {
        synchronized(this) {
            return tracked.values
                .filter { sameTorrent(it.handle, handle) }
                .map { it.fileIndex }
                .toSet()
        }
    }

    override fun types(): IntArray = intArrayOf(
        AlertType.TORRENT_FINISHED.swig(),
        AlertType.FILE_ERROR.swig(),
        AlertType.TORRENT_ERROR.swig()
    )

    override fun alert(alert: Alert<*>) {
        try {
            when (alert.type()) {
                AlertType.TORRENT_FINISHED -> onTorrentFinished(alert as TorrentFinishedAlert)
                AlertType.FILE_ERROR -> onFileError(alert as FileErrorAlert)
                AlertType.TORRENT_ERROR -> onTorrentError(alert as TorrentErrorAlert)
                else -> Unit
            }
        } catch (e: Exception) {
            Log.e(TAG, "Alert handling failed", e)
        }
    }

    private fun onTorrentFinished(alert: TorrentFinishedAlert) {
        val handle = alert.handle() ?: return
        forEachTrackedForHandle(handle) { downloadId, info ->
            if (info.lastStatus != TorrentDownloadStatus.COMPLETED) {
                emitter.emit(downloadId, info.fileName, 1f, 0f, info.expectedSize, TorrentDownloadStatus.COMPLETED)
                Log.i(TAG, "Torrent finished: ${info.fileName}")
            }
        }
    }

    private fun onFileError(alert: FileErrorAlert) {
        val handle = alert.handle() ?: return
        Log.e(TAG, "File error: ${alert.message()}")
        forEachTrackedForHandle(handle) { downloadId, info ->
            emitter.emit(downloadId, info.fileName, 0f, 0f, 0L, TorrentDownloadStatus.FAILED)
            // Untrack immediately — otherwise the 1s polling loop keeps
            // re-emitting DOWNLOADING/COMPLETED for this entry forever,
            // potentially overriding the FAILED status just sent.
            untrackDownload(downloadId)
        }
    }

    private fun onTorrentError(alert: TorrentErrorAlert) {
        val handle = alert.handle() ?: return
        Log.e(TAG, "Torrent error: ${alert.message()}")
        forEachTrackedForHandle(handle) { downloadId, info ->
            emitter.emit(downloadId, info.fileName, 0f, 0f, 0L, TorrentDownloadStatus.FAILED)
            untrackDownload(downloadId)
        }
    }

    private fun forEachTrackedForHandle(handle: TorrentHandle, action: (String, TrackedFile) -> Unit) {
        val snapshot: Map<String, TrackedFile>
        synchronized(this) { snapshot = tracked.toMap() }
        snapshot.entries
            .filter { (_, info) -> sameTorrent(info.handle, handle) }
            .forEach { (id, info) -> action(id, info) }
    }

    /** Info-hash comparison that treats an invalid handle as "not the same" instead of throwing. */
    private fun sameTorrent(a: TorrentHandle, b: TorrentHandle): Boolean {
        return try {
            a.isValid && b.isValid && a.infoHash() == b.infoHash()
        } catch (e: Exception) {
            false
        }
    }

    companion object {
        private const val TAG = "TorrentProgressBridge"
    }
}
