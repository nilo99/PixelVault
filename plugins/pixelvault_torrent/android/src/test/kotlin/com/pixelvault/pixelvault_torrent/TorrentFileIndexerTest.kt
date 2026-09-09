package com.pixelvault.pixelvault_torrent

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

/**
 * Covers the per-file indexing decision. The surrounding [TorrentFileIndexer.index]
 * needs a live libtorrent `TorrentInfo` (native library, not loadable in a JVM
 * unit test), which is why the decision itself lives in a pure companion
 * function.
 */
internal class TorrentFileIndexerTest {

    private val noFolders = emptyList<String>()

    @Test
    fun indexesAnOrdinaryRomFile() {
        assertTrue(TorrentFileIndexer.shouldIndex("Pokemon Y (Europe).3ds", 1_000, noFolders))
        assertTrue(TorrentFileIndexer.shouldIndex("roms/Final Fantasy VII.chd", 5_000, noFolders))
    }

    @Test
    fun skipsZeroLengthEntries() {
        // libtorrent reports directories and padding entries with size 0.
        assertFalse(TorrentFileIndexer.shouldIndex("roms/Game.iso", 0, noFolders))
    }

    @Test
    fun skipsBlankPaths() {
        assertFalse(TorrentFileIndexer.shouldIndex("", 1_000, noFolders))
        assertFalse(TorrentFileIndexer.shouldIndex("   ", 1_000, noFolders))
    }

    @Test
    fun skipsDotfiles() {
        assertFalse(TorrentFileIndexer.shouldIndex("roms/.DS_Store", 1_000, noFolders))
        assertFalse(TorrentFileIndexer.shouldIndex(".hidden", 1_000, noFolders))
    }

    @Test
    fun skipsNonRomCompanionFiles() {
        // Scans, checksums and metadata routinely ship alongside ROM sets and
        // would otherwise clutter the catalog as if they were games.
        for (path in listOf(
            "set/Game.nfo", "set/Game.txt", "set/cover.jpg", "set/list.xml",
            "set/hashes.sha256", "set/readme.html", "set/db.sqlite", "set/scan.png"
        )) {
            assertFalse(TorrentFileIndexer.shouldIndex(path, 1_000, noFolders), path)
        }
    }

    @Test
    fun blockedExtensionMatchIsCaseInsensitive() {
        assertFalse(TorrentFileIndexer.shouldIndex("set/Game.NFO", 1_000, noFolders))
        assertFalse(TorrentFileIndexer.shouldIndex("set/COVER.JPG", 1_000, noFolders))
    }

    @Test
    fun keepsFilesWithNoExtension() {
        assertTrue(TorrentFileIndexer.shouldIndex("roms/DiscImage", 1_000, noFolders))
    }

    @Test
    fun honoursAnAllowedFolderAtTheRoot() {
        val folders = TorrentFileIndexer.normalizeFolders(listOf("USA"))
        assertTrue(TorrentFileIndexer.shouldIndex("USA/Game.iso", 1_000, folders))
        assertFalse(TorrentFileIndexer.shouldIndex("Japan/Game.iso", 1_000, folders))
    }

    @Test
    fun honoursAnAllowedFolderNestedDeeper() {
        val folders = TorrentFileIndexer.normalizeFolders(listOf("USA"))
        assertTrue(TorrentFileIndexer.shouldIndex("Pack/USA/Game.iso", 1_000, folders))
        assertFalse(TorrentFileIndexer.shouldIndex("Pack/Europe/Game.iso", 1_000, folders))
    }

    @Test
    fun folderMatchingIgnoresCaseSeparatorsAndTrailingSlashes() {
        val folders = TorrentFileIndexer.normalizeFolders(listOf("uSa/"))
        assertTrue(TorrentFileIndexer.shouldIndex("USA/Game.iso", 1_000, folders))
        // Windows-style separators appear in torrents made on Windows.
        assertTrue(TorrentFileIndexer.shouldIndex("Pack\\USA\\Game.iso", 1_000, folders))
    }

    @Test
    fun aFolderNameMustMatchAWholeSegment() {
        val folders = TorrentFileIndexer.normalizeFolders(listOf("USA"))
        // "USA-Proto" is a different folder and must not be swept in.
        assertFalse(TorrentFileIndexer.shouldIndex("USA-Proto/Game.iso", 1_000, folders))
    }

    @Test
    fun anEmptyFolderFilterAllowsEverything() {
        assertTrue(TorrentFileIndexer.shouldIndex("Anything/Game.iso", 1_000, noFolders))
    }

    @Test
    fun fileNameIsTheLastPathSegmentTrimmed() {
        assertEquals("Game.iso", TorrentFileIndexer.fileNameOf("pack/usa/Game.iso"))
        assertEquals("Game.iso", TorrentFileIndexer.fileNameOf("Game.iso "))
        assertEquals("Game.iso", TorrentFileIndexer.fileNameOf("Game.iso"))
    }
}
