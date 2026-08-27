package com.pixelvault.pixelvault_torrent

import android.content.Context
import android.util.Log
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import net.sf.sevenzipjbinding.ExtractAskMode
import net.sf.sevenzipjbinding.ExtractOperationResult
import net.sf.sevenzipjbinding.IArchiveExtractCallback
import net.sf.sevenzipjbinding.IInStream
import net.sf.sevenzipjbinding.ISeekableStream
import net.sf.sevenzipjbinding.ISequentialOutStream
import net.sf.sevenzipjbinding.PropID
import net.sf.sevenzipjbinding.SevenZip
import net.sf.sevenzipjbinding.SevenZipException
import java.io.BufferedOutputStream
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream
import java.io.OutputStream
import java.nio.ByteBuffer

private const val TAG = "ArchiveExtractorService"
private const val EXTRACTION_BUFFER_SIZE = 524288 // 512 KB — matches Milou's SAF IPC-call reduction
private const val MAX_EXTRACTED_ENTRIES = 20_000
private const val MAX_TOTAL_EXTRACTED_BYTES = 50L * 1024 * 1024 * 1024 // 50 GB safety cap

/**
 * Port of the 7z-only path of Milou's `ArchiveExtractorService`
 * (`extractArchiveFile` + `copyToSaf`) — zip archives are handled in pure
 * Dart via the `archive` package instead, so only the 7-Zip-JBinding branch
 * needs to live in this native plugin.
 */
class ArchiveExtractorService {

    suspend fun extractArchiveFile(
        context: Context,
        archiveFile: File,
        destinationUri: String,
        subPath: String = ""
    ): List<String> = withContext(Dispatchers.IO) {
        val extractDir = File(context.cacheDir, "extraction_temp/${System.currentTimeMillis()}")
        extractDir.mkdirs()

        try {
            val cachedFiles = FileInputStream(archiveFile).use { fis -> extractToCache(fis, extractDir) }
            if (cachedFiles.isEmpty()) {
                throw IllegalStateException("No files extracted from ${archiveFile.name}")
            }

            copyToSaf(context, cachedFiles, destinationUri, subPath)
        } finally {
            extractDir.deleteRecursively()
        }
    }

    private fun extractToCache(fis: FileInputStream, extractDir: File): List<File> {
        val results = mutableListOf<File>()
        val usedNames = mutableSetOf<String>()
        var totalExtractedBytes = 0L
        var entryCount = 0
        val channel = fis.channel
        val channelSize = channel.size()

        val inStream = object : IInStream {
            override fun read(data: ByteArray): Int {
                val n = channel.read(ByteBuffer.wrap(data))
                return if (n == -1) 0 else n
            }

            override fun seek(offset: Long, seekOrigin: Int): Long {
                val newPos = when (seekOrigin) {
                    ISeekableStream.SEEK_SET -> offset
                    ISeekableStream.SEEK_CUR -> channel.position() + offset
                    ISeekableStream.SEEK_END -> channelSize + offset
                    else -> throw SevenZipException("Unknown seek origin: $seekOrigin")
                }
                channel.position(newPos)
                return channel.position()
            }

            override fun close() {}
        }

        try {
            SevenZip.openInArchive(null, inStream).use { archive ->
                archive.extract(null, false, object : IArchiveExtractCallback {
                    var out: OutputStream? = null
                    var dest: File? = null
                    var skip = false

                    override fun getStream(index: Int, mode: ExtractAskMode): ISequentialOutStream? {
                        val isFolder = archive.getProperty(index, PropID.IS_FOLDER) as? Boolean ?: false
                        if (isFolder) {
                            skip = true
                            return null
                        }

                        entryCount++
                        if (entryCount > MAX_EXTRACTED_ENTRIES) {
                            throw SevenZipException("Archive has too many entries (> $MAX_EXTRACTED_ENTRIES)")
                        }

                        val rawPath = (archive.getProperty(index, PropID.PATH) as? String) ?: "file_$index"
                        var name = rawPath.replace('\\', '/').split("/").last()
                            .replace(Regex("[<>:\"|?* ]"), "_")
                            .ifBlank { "file_$index" }

                        if (!usedNames.add(name)) {
                            val dot = name.lastIndexOf('.')
                            val base = if (dot > 0) name.substring(0, dot) else name
                            val ext = if (dot > 0) name.substring(dot) else ""
                            var suffix = 2
                            var candidate = "${base}_$suffix$ext"
                            while (!usedNames.add(candidate)) {
                                suffix++
                                candidate = "${base}_$suffix$ext"
                            }
                            name = candidate
                        }

                        val file = File(extractDir, name)
                        dest = file
                        val stream = BufferedOutputStream(FileOutputStream(file), EXTRACTION_BUFFER_SIZE)
                        out = stream
                        skip = false

                        return ISequentialOutStream { data ->
                            totalExtractedBytes += data.size
                            if (totalExtractedBytes > MAX_TOTAL_EXTRACTED_BYTES) {
                                throw SevenZipException("Extracted data exceeds safety cap ($MAX_TOTAL_EXTRACTED_BYTES bytes)")
                            }
                            stream.write(data)
                            data.size
                        }
                    }

                    override fun prepareOperation(mode: ExtractAskMode) {}

                    override fun setOperationResult(result: ExtractOperationResult) {
                        try {
                            out?.close()
                        } catch (_: Exception) {
                        }
                        out = null

                        if (!skip && result == ExtractOperationResult.OK) {
                            dest?.let { results.add(it) }
                        } else if (!skip) {
                            Log.w(TAG, "Entry result: $result for ${dest?.name}")
                        }
                        dest = null
                        skip = false
                    }

                    override fun setCompleted(complete: Long) {}
                    override fun setTotal(total: Long) {}
                })
            }
        } catch (e: SevenZipException) {
            throw IllegalStateException("7-zip extraction error: ${e.message}", e)
        }

        return results
    }

    private fun copyToSaf(
        context: Context,
        files: List<File>,
        destinationUri: String,
        subPath: String
    ): List<String> {
        val destUriString = if (subPath.isNotEmpty()) {
            SafHelper.createDirectory(context, destinationUri, subPath)?.uri?.toString()
                ?: throw IllegalStateException("Could not create destination subfolder '$subPath'")
        } else {
            destinationUri
        }

        val copied = mutableListOf<String>()
        val buffer = ByteArray(EXTRACTION_BUFFER_SIZE)

        for (file in files) {
            val outUri = SafHelper.createFile(
                context = context,
                uriString = destUriString,
                subPath = "",
                fileName = file.name,
                overwrite = true
            )?.uri ?: throw IllegalStateException("Could not create destination file for ${file.name}")

            context.contentResolver.openOutputStream(outUri)?.use { raw ->
                BufferedOutputStream(raw, EXTRACTION_BUFFER_SIZE).use { buffOut ->
                    file.inputStream().use { input ->
                        var n: Int
                        while (input.read(buffer).also { n = it } != -1) buffOut.write(buffer, 0, n)
                    }
                }
            }
            copied.add(file.name)
        }

        return copied
    }
}
