package com.pixelvault.pixelvault_torrent

import android.util.Log
import org.libtorrent4j.TorrentInfo

/** A single ROM file discovered inside a torrent. Mirrors Milou's `TorrentFileEntry`. */
data class TorrentFileEntry(
    val fileName: String,
    val fileIndex: Int,
    val fileSize: Long,
    val torrentMagnet: String
)

/**
 * Ported verbatim from Milou's `TorrentFileIndexer` — walks the file tree
 * inside a [TorrentInfo] and returns indexable ROM files, applying the same
 * blocked-extension and allowed-folder filtering.
 */
class TorrentFileIndexer {

    fun index(info: TorrentInfo, magnet: String, allowedFolders: List<String> = emptyList()): List<TorrentFileEntry> {
        val files = info.files()
        val results = mutableListOf<TorrentFileEntry>()

        val normalizedFolders = normalizeFolders(allowedFolders)

        for (i in 0 until files.numFiles()) {
            val rawPath = files.filePath(i)
            val size = files.fileSize(i)

            if (!shouldIndex(rawPath, size, normalizedFolders)) continue

            results.add(TorrentFileEntry(fileNameOf(rawPath), i, size, magnet))
        }

        Log.i(
            TAG,
            "Indexed ${results.size} files in '${info.name()}'" +
                if (normalizedFolders.isNotEmpty()) " (folders: $allowedFolders)" else ""
        )
        return results
    }

    companion object {
        private const val TAG = "TorrentFileIndexer"

        /**
         * The whole per-file decision, pulled out of [index] so it can be
         * unit-tested without a live libtorrent `TorrentInfo` (which needs
         * the native library and so cannot exist in a JVM test).
         */
        fun shouldIndex(rawPath: String, size: Long, normalizedFolders: List<String>): Boolean {
            if (size == 0L) return false
            if (rawPath.isBlank()) return false

            val fileName = fileNameOf(rawPath)
            if (fileName.startsWith(".") || fileName.isBlank()) return false

            val ext = ".${fileName.substringAfterLast('.', "")}".lowercase()
            if (ext in BLOCKED_EXTENSIONS) return false

            if (normalizedFolders.isNotEmpty()) {
                val normalizedPath = rawPath.replace('\\', '/').lowercase()
                val inAllowedFolder = normalizedFolders.any { folder ->
                    normalizedPath.startsWith("$folder/") || normalizedPath.contains("/$folder/")
                }
                if (!inAllowedFolder) return false
            }
            return true
        }

        fun normalizeFolders(allowedFolders: List<String>): List<String> =
            allowedFolders.map { it.replace('\\', '/').lowercase().trimEnd('/') }

        fun fileNameOf(rawPath: String): String = rawPath.substringAfterLast('/').trim()

        private val BLOCKED_EXTENSIONS = setOf(
            ".xml", ".sqlite", ".nfo", ".txt", ".pdf", ".log", ".html", ".htm",
            ".sfv", ".md5", ".sha1", ".sha256",
            ".jpg", ".jpeg", ".png", ".gif", ".bmp", ".webp",
            ".ds_store"
        )
    }
}
