package com.pixelvault.pixelvault_torrent

import android.util.Log
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.cancel
import kotlinx.coroutines.delay
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
 * Tracking is keyed by `downloadId` (the Dart side's unique DB row id), not
 * `fileName` — two downloads from different sources can share the same file
 * name, which used to let one silently overwrite the other's tracked entry.
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
    private val scope = CoroutineScope(Dispatchers.IO + Job())
    private var pollingJob: Job? = null

    fun trackDownload(downloadId: String, fileName: String, fileIndex: Int, handle: TorrentHandle) {
        val expectedSize = handle.torrentFile()?.files()?.fileSize(fileIndex) ?: 0L
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

    /** Cancels the internal polling coroutine scope — call once when the owning plugin detaches. */
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
            while (true) {
                updateProgress()
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
            val handle = info.handle
            if (!handle.isValid) return@forEach

            val status = try {
                handle.status()
            } catch (e: Exception) {
                return@forEach
            }
            val total = info.expectedSize
            if (total <= 0) return@forEach

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
    }

    fun countTrackedForHandle(handle: TorrentHandle): Int {
        synchronized(this) {
            return tracked.values.count { it.handle.infoHash() == handle.infoHash() }
        }
    }

    fun getTrackedFileIndicesForHandle(handle: TorrentHandle): Set<Int> {
        synchronized(this) {
            return tracked.values
                .filter { it.handle.infoHash() == handle.infoHash() }
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
        when (alert.type()) {
            AlertType.TORRENT_FINISHED -> onTorrentFinished(alert as TorrentFinishedAlert)
            AlertType.FILE_ERROR -> onFileError(alert as FileErrorAlert)
            AlertType.TORRENT_ERROR -> onTorrentError(alert as TorrentErrorAlert)
            else -> Unit
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
            .filter { (_, info) -> info.handle.infoHash() == handle.infoHash() }
            .forEach { (id, info) -> action(id, info) }
    }

    companion object {
        private const val TAG = "TorrentProgressBridge"
    }
}
