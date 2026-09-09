package com.pixelvault.pixelvault_torrent

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

/**
 * `optimizeMagnetUri` decides which trackers survive into every metadata
 * fetch and download, so a mistake here silently degrades every torrent
 * source (dropping the info-hash, or keeping dozens of trackers and stalling
 * the fetch). It is pure, so it is cheap to pin down.
 */
internal class MagnetUriTest {

    private fun magnet(trackerCount: Int): String {
        val trackers = (1..trackerCount).joinToString("&") { "tr=udp%3A%2F%2Ftracker$it" }
        return "magnet:?xt=urn:btih:abc123&dn=Some+Pack&$trackers"
    }

    @Test
    fun leavesANonMagnetUriAlone() {
        val path = "/storage/emulated/0/file.torrent"
        assertEquals(path, TorrentHandleRegistry.optimizeMagnetUri(path))
    }

    @Test
    fun leavesAMagnetWithFewTrackersUntouched() {
        val uri = magnet(3)
        assertEquals(uri, TorrentHandleRegistry.optimizeMagnetUri(uri))
    }

    @Test
    fun keepsAtMostFourTrackers() {
        val result = TorrentHandleRegistry.optimizeMagnetUri(magnet(20))
        assertEquals(4, result.split("&").count { it.startsWith("tr=") })
    }

    @Test
    fun alwaysKeepsTheInfoHash() {
        // Losing `xt` would make the magnet unusable.
        val result = TorrentHandleRegistry.optimizeMagnetUri(magnet(20))
        assertTrue(result.startsWith("magnet:?xt=urn:btih:abc123"))
    }

    @Test
    fun keepsEveryNonTrackerParameter() {
        val result = TorrentHandleRegistry.optimizeMagnetUri(magnet(20))
        assertTrue(result.contains("dn=Some+Pack"), result)
    }

    @Test
    fun handlesAMagnetWithNoTrackersAtAll() {
        val uri = "magnet:?xt=urn:btih:abc123&dn=Bare"
        assertEquals(uri, TorrentHandleRegistry.optimizeMagnetUri(uri))
    }

    @Test
    fun isIdempotent() {
        val once = TorrentHandleRegistry.optimizeMagnetUri(magnet(20))
        assertEquals(once, TorrentHandleRegistry.optimizeMagnetUri(once))
    }
}
