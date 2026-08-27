package com.pixelvault.pixelvault_torrent

import android.content.Context
import android.util.Log
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withContext
import kotlinx.coroutines.withTimeoutOrNull
import org.libtorrent4j.SessionManager
import org.libtorrent4j.TorrentHandle
import org.libtorrent4j.TorrentInfo
import java.io.File
import java.util.concurrent.ConcurrentHashMap

/**
 * Ported near-verbatim from Milou's `TorrentHandleRegistry` (see
 * milou-master/app/.../data/service/TorrentHandleRegistry.kt) — the only
 * changes are dropping Hilt DI (manual constructor injection instead) and
 * the package name.
 */
class TorrentHandleRegistry(private val context: Context) {

    private val session = SessionManager()
    private val handles = ConcurrentHashMap<String, TorrentHandle>()
    private val fetchMutexes = ConcurrentHashMap<String, Mutex>()

    var handleCount: Int = 0
        private set

    fun start() {
        if (!session.isRunning) {
            session.start()
            DHT_BOOTSTRAP_NODES.forEach { (host, port) ->
                try {
                    session.swig().add_dht_node(org.libtorrent4j.swig.string_int_pair(host, port))
                } catch (e: Exception) {
                    Log.w(TAG, "DHT node $host:$port failed: ${e.message}")
                }
            }
            Log.i(TAG, "libtorrent4j session started")
        }
    }

    fun stop() {
        if (session.isRunning) {
            handles.values.forEach { if (it.isValid) it.pause() }
            handles.clear()
            fetchMutexes.clear()
            handleCount = 0
            session.stop()
            Log.i(TAG, "libtorrent4j session stopped")
        }
    }

    val isRunning: Boolean get() = session.isRunning

    suspend fun getOrFetch(uri: String): TorrentHandle = withContext(Dispatchers.IO) {
        if (!session.isRunning) {
            start()
        }
        val optimizedUri = if (uri.startsWith("magnet:")) optimizeMagnetUri(uri) else uri
        handles[optimizedUri]?.takeIf { it.isValid }?.let { return@withContext it }
        val mutex = fetchMutexes.getOrPut(optimizedUri) { Mutex() }
        mutex.withLock {
            handles[optimizedUri]?.takeIf { it.isValid }?.let { return@withLock it }
            Log.d(TAG, "Fetching metadata for $optimizedUri")
            val handle = fetchMetadata(optimizedUri)
            handles[optimizedUri] = handle
            handleCount = handles.size
            Log.i(TAG, "Metadata cached (${handles.size} total handles)")
            handle
        }
    }

    fun getCachedHandle(magnet: String): TorrentHandle? {
        val optimizedMagnet = if (magnet.startsWith("magnet:")) optimizeMagnetUri(magnet) else magnet
        return handles[optimizedMagnet]?.takeIf { it.isValid }
    }

    fun getCachedInfo(magnet: String): TorrentInfo? {
        val optimizedMagnet = if (magnet.startsWith("magnet:")) optimizeMagnetUri(magnet) else magnet
        return handles[optimizedMagnet]?.takeIf { it.isValid }?.torrentFile()
    }

    fun releaseHandle(magnet: String) {
        val optimizedMagnet = if (magnet.startsWith("magnet:")) optimizeMagnetUri(magnet) else magnet
        handles.remove(optimizedMagnet)?.let { handle ->
            if (handle.isValid) {
                try {
                    session.remove(handle)
                } catch (e: Exception) {
                    Log.e(TAG, "Error removing torrent: ${e.message}")
                }
            }
        }
        fetchMutexes.remove(optimizedMagnet)
        handleCount = handles.size
        Log.i(TAG, "Released handle for $optimizedMagnet (${handles.size} remaining)")
    }

    fun session(): SessionManager = session

    val torrentDataDir: File get() = File(context.cacheDir, "torrent_data").apply { mkdirs() }

    private suspend fun fetchMetadata(uri: String): TorrentHandle =
        withContext(Dispatchers.IO) {
            val params = if (uri.startsWith("magnet:")) {
                org.libtorrent4j.AddTorrentParams.parseMagnetUri(uri)
            } else {
                val torrentFile = File(uri)
                val ti = org.libtorrent4j.TorrentInfo(torrentFile)
                val p = org.libtorrent4j.AddTorrentParams()
                p.torrentInfo = ti
                p
            }

            val swigParams = params.swig()
            swigParams.save_path = torrentDataDir.absolutePath

            val ec = org.libtorrent4j.swig.error_code()
            val swigHandle = try {
                session.swig().add_torrent(swigParams, ec)
            } catch (e: Exception) {
                null
            }

            val handle = if (swigHandle != null && swigHandle.is_valid) {
                TorrentHandle(swigHandle)
            } else {
                val infoHash = swigParams.info_hashes.v1
                val existingSwig = session.swig().find_torrent(infoHash)
                if (existingSwig != null && existingSwig.is_valid) {
                    TorrentHandle(existingSwig)
                } else {
                    val errorMsg = if (ec.value() != 0) ec.message() else "unknown error"
                    Log.w(TAG, "Failed to add torrent for $uri: $errorMsg")
                    throw Exception("Failed to add torrent: $errorMsg")
                }
            }

            try {
                handle.pause()
            } catch (e: Exception) {
                Log.w(TAG, "Failed to pause handle: ${e.message}")
            }

            handle.resume() // Resume just to fetch metadata
            waitForMetadata(handle, uri)
        }

    private suspend fun waitForMetadata(handle: TorrentHandle, uri: String): TorrentHandle {
        val result = withTimeoutOrNull(METADATA_FETCH_TIMEOUT_MS) {
            while (!Thread.currentThread().isInterrupted) {
                try {
                    if (handle.isValid && handle.torrentFile() != null) {
                        handle.pause()
                        val info = handle.torrentFile()
                        if (info != null) {
                            val priorities = Array(info.numFiles()) { org.libtorrent4j.Priority.IGNORE }
                            handle.prioritizeFiles(priorities)
                        }
                        return@withTimeoutOrNull handle
                    }
                } catch (e: Exception) {
                    return@withTimeoutOrNull null
                }
                delay(METADATA_POLL_INTERVAL_MS)
            }
            null
        }

        if (result == null) {
            try {
                if (handle.isValid) session.swig().remove_torrent(handle.swig())
            } catch (_: Exception) {
            }
            Log.w(TAG, "Metadata fetch timed out for $uri")
            throw TorrentMetadataTimeoutException(
                "Metadata fetch timed out after ${METADATA_FETCH_TIMEOUT_MS / 1000}s"
            )
        }
        handle.pause()
        return result
    }

    companion object {
        private const val TAG = "TorrentHandleRegistry"
        private const val METADATA_FETCH_TIMEOUT_MS = 20_000L
        private const val METADATA_POLL_INTERVAL_MS = 500L
        private const val MAX_TRACKERS_PER_MAGNET = 4

        private val DHT_BOOTSTRAP_NODES = listOf(
            "router.bittorrent.com" to 6881,
            "dht.transmissionbt.com" to 6881,
            "router.utorrent.com" to 6881,
            "dht.aelitis.com" to 6881
        )

        /** Ported from Milou's `FileParsingUtils.optimizeMagnetUri`. */
        fun optimizeMagnetUri(uri: String): String {
            if (!uri.startsWith("magnet:?")) return uri

            val parts = uri.split("&")
            val base = parts[0]
            val params = parts.drop(1)

            val trackers = params.filter { it.startsWith("tr=") }
            val otherParams = params.filter { !it.startsWith("tr=") }

            if (trackers.size <= MAX_TRACKERS_PER_MAGNET) return uri

            val optimizedTrackers = trackers.take(MAX_TRACKERS_PER_MAGNET)
            val optimizedParams = (otherParams + optimizedTrackers).joinToString("&")

            return if (optimizedParams.isEmpty()) base else "$base&$optimizedParams"
        }
    }
}

class TorrentMetadataTimeoutException(message: String) : Exception(message)
