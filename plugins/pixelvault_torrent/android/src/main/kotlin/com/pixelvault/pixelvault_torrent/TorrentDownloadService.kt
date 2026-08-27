package com.pixelvault.pixelvault_torrent

import android.content.Context
import android.util.Log
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.withContext
import org.libtorrent4j.Priority
import java.io.BufferedInputStream
import java.io.BufferedOutputStream
import java.io.File
import java.util.concurrent.ConcurrentHashMap

/**
 * Adapted from Milou's `TorrentDownloadService`: selective per-file torrent
 * download (mark every file IGNORE except the requested index, resume,
 * `TorrentProgressBridge` takes over for progress) plus the cache→SAF move
 * on completion (`finishDownload`), which in the original app lived in
 * `DownloadService.moveTorrentFile` — folded in here since this plugin owns
 * the whole torrent lifecycle.
 *
 * Tracking is keyed by [downloadId] (the Dart side's unique DB row id, as a
 * string), not [fileName] — two different sources can produce files with the
 * same name (common with region variants), and keying by name alone let a
 * second download silently steal the first one's progress/cache entry.
 */
class TorrentDownloadService(
    private val context: Context,
    private val registry: TorrentHandleRegistry,
    private val progressBridge: TorrentProgressBridge,
    private val archiveExtractor: ArchiveExtractorService
) {
    data class TorrentFileInfo(val relativePath: String, val expectedSize: Long)

    private val fileInfoCache = ConcurrentHashMap<String, TorrentFileInfo>()

    suspend fun startDownload(
        magnet: String,
        fileIndex: Int,
        fileName: String,
        downloadId: String
    ) = withContext(Dispatchers.IO) {
        val handle = registry.getOrFetch(magnet)
        val torrentInfo = handle.torrentFile()
            ?: throw IllegalStateException("No TorrentInfo for $fileName")

        if (fileIndex >= torrentInfo.numFiles()) {
            throw IllegalArgumentException("fileIndex $fileIndex out of range")
        }

        val relativePath = torrentInfo.files().filePath(fileIndex)
        val expectedSize = torrentInfo.files().fileSize(fileIndex)
        fileInfoCache[downloadId] = TorrentFileInfo(relativePath, expectedSize)

        progressBridge.trackDownload(downloadId, fileName, fileIndex, handle)

        val priorities = Array(torrentInfo.numFiles()) { Priority.IGNORE }
        for (idx in progressBridge.getTrackedFileIndicesForHandle(handle)) {
            if (idx < priorities.size) priorities[idx] = Priority.DEFAULT
        }
        handle.prioritizeFiles(priorities)

        val torrentDataDir = registry.torrentDataDir
        val currentSavePath = try {
            handle.status().swig().save_path
        } catch (_: Exception) {
            null
        }
        if (currentSavePath != torrentDataDir.absolutePath) {
            handle.moveStorage(torrentDataDir.absolutePath)
        }

        handle.resume()
        Log.i(TAG, "Torrent resumed for $fileName ($downloadId) — TorrentProgressBridge takes over")
    }

    /**
     * Moves (or extracts, if [extract] is true) the completed file from the
     * libtorrent cache directory into the SAF destination, deletes the cache
     * copy, untracks it and releases the torrent handle if no sibling
     * downloads from the same torrent remain. Returns the resulting file
     * name(s) in the SAF destination — a single-element list for a plain
     * move, or every extracted entry's name when [extract] is true.
     *
     * Polls for up to 15s for the on-disk file size to catch up with the
     * expected size first — libtorrent marks a file complete (via
     * `fileProgress`) after hash-verification, but its disk thread flushes
     * writes asynchronously (mirrors `DownloadService.moveTorrentFile`). If
     * the file is still short after the timeout, this throws rather than
     * silently copying/extracting a truncated file.
     */
    suspend fun finishDownload(
        magnet: String,
        fileName: String,
        downloadId: String,
        destDirUri: String,
        subPath: String,
        extract: Boolean
    ): List<String> = withContext(Dispatchers.IO) {
        val info = fileInfoCache.remove(downloadId)
            ?: throw IllegalStateException("No cached torrent file info for $fileName ($downloadId)")

        val sourceFile = resolveWithinTorrentDataDir(info.relativePath)
        if (!sourceFile.exists()) {
            throw IllegalStateException("Downloaded file not found at ${sourceFile.absolutePath}")
        }

        var waitedMs = 0
        while (sourceFile.length() < info.expectedSize && waitedMs < 15_000 && registry.isRunning) {
            delay(500)
            waitedMs += 500
        }
        if (sourceFile.length() < info.expectedSize) {
            throw IllegalStateException(
                "Downloaded file for $fileName is incomplete: ${sourceFile.length()} / ${info.expectedSize} bytes"
            )
        }

        val resultNames = if (extract) {
            archiveExtractor.extractArchiveFile(context, sourceFile, destDirUri, subPath)
        } else {
            val destDoc = SafHelper.createFile(
                context = context,
                uriString = destDirUri,
                subPath = subPath,
                fileName = fileName,
                overwrite = true
            ) ?: throw IllegalStateException("Could not create destination file for $fileName")

            val outStream = SafHelper.getOutputStream(context, destDoc)
                ?: throw IllegalStateException("Could not open output stream for $fileName")

            BufferedOutputStream(outStream, COPY_BUFFER_SIZE).use { out ->
                BufferedInputStream(sourceFile.inputStream(), COPY_BUFFER_SIZE).use { input ->
                    input.copyTo(out, COPY_BUFFER_SIZE)
                }
            }
            listOf(fileName)
        }

        sourceFile.delete()
        cleanupEmptyParents(sourceFile)

        val handle = registry.getCachedHandle(magnet)
        progressBridge.untrackDownload(downloadId)
        val stillTracked = if (handle != null) progressBridge.countTrackedForHandle(handle) else 0
        if (stillTracked == 0) {
            registry.releaseHandle(magnet)
            Log.i(TAG, "Handle released after successful move for $fileName")
        }

        resultNames
    }

    suspend fun cancelDownload(magnet: String, downloadId: String) = withContext(Dispatchers.IO) {
        val info = fileInfoCache.remove(downloadId)
        val handle = registry.getCachedHandle(magnet)
        progressBridge.untrackDownload(downloadId)

        if (info != null) {
            val partialFile = resolveWithinTorrentDataDir(info.relativePath)
            if (partialFile.exists()) {
                partialFile.delete()
                cleanupEmptyParents(partialFile)
            }
        }

        val remaining = if (handle != null) progressBridge.countTrackedForHandle(handle) else 0
        if (remaining == 0) {
            registry.releaseHandle(magnet)
            Log.i(TAG, "Stopped and purged torrent download for $downloadId")
        }
    }

    /**
     * Resolves [relativePath] (from the torrent's own metadata — tracker/peer
     * controlled, not something we generated) against [TorrentHandleRegistry.torrentDataDir],
     * rejecting anything that canonicalizes outside of it (e.g. `../../etc/...`
     * path-traversal segments in a malicious torrent's file list).
     */
    private fun resolveWithinTorrentDataDir(relativePath: String): File {
        val root = registry.torrentDataDir.canonicalFile
        val candidate = File(registry.torrentDataDir, relativePath).canonicalFile
        if (candidate != root && !candidate.path.startsWith(root.path + File.separator)) {
            throw SecurityException("Torrent file path escapes the data directory: $relativePath")
        }
        return candidate
    }

    /** Walks up from [file]'s parent, deleting directories left empty by a delete, bounded to [TorrentHandleRegistry.torrentDataDir]. */
    private fun cleanupEmptyParents(file: File) {
        var dir = file.parentFile
        while (dir != null && dir != registry.torrentDataDir && dir.list()?.isEmpty() == true) {
            val parent = dir.parentFile
            dir.delete()
            dir = parent
        }
    }

    companion object {
        private const val TAG = "TorrentDownloadService"
        private const val COPY_BUFFER_SIZE = 524288
    }
}
