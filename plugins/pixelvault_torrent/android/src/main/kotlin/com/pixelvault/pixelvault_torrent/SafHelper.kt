package com.pixelvault.pixelvault_torrent

import android.content.Context
import android.provider.DocumentsContract
import android.util.Log
import androidx.core.net.toUri
import androidx.documentfile.provider.DocumentFile
import java.io.OutputStream

/**
 * Port of the subset of Milou's `StorageHelper` needed here: resolving a SAF
 * tree URI, creating nested sub-directories, and creating/overwriting a file
 * inside them.
 */
object SafHelper {
    private const val TAG = "SafHelper"

    fun getDocumentFile(context: Context, uriString: String): DocumentFile? {
        return try {
            val uri = uriString.toUri()
            if (uri.scheme == "content") {
                if (DocumentsContract.isTreeUri(uri)) {
                    DocumentFile.fromTreeUri(context, uri)
                } else {
                    DocumentFile.fromSingleUri(context, uri)
                }
            } else {
                null
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error getting document file for $uriString: ${e.message}")
            null
        }
    }

    fun createDirectory(context: Context, uriString: String, subPath: String): DocumentFile? {
        val baseDocument = getDocumentFile(context, uriString) ?: run {
            Log.e(TAG, "Could not get base document for URI: $uriString")
            return null
        }

        try {
            if (!baseDocument.exists() || !baseDocument.canRead()) {
                Log.e(TAG, "Base directory missing/unreadable: ${baseDocument.uri}")
                return null
            }
        } catch (e: Exception) {
            Log.e(TAG, "Base directory inaccessible: ${e.message}")
            return null
        }

        val pathParts = subPath.split("/").filter { it.isNotEmpty() }
        var currentDir = baseDocument

        for (part in pathParts) {
            val existingDir = try {
                currentDir.findFile(part)
            } catch (e: Exception) {
                null
            }

            currentDir = if (existingDir != null && existingDir.isDirectory) {
                existingDir
            } else {
                try {
                    currentDir.createDirectory(part) ?: return null
                } catch (e: Exception) {
                    Log.e(TAG, "Exception creating sub-directory '$part': ${e.message}")
                    return null
                }
            }
        }
        return currentDir
    }

    fun createFile(
        context: Context,
        uriString: String,
        subPath: String,
        fileName: String,
        mimeType: String = "application/octet-stream",
        overwrite: Boolean = true
    ): DocumentFile? {
        val directory = createDirectory(context, uriString, subPath) ?: return null
        if (overwrite) {
            try {
                directory.findFile(fileName)?.delete()
            } catch (e: Exception) {
                Log.w(TAG, "Error deleting existing file $fileName: ${e.message}")
            }
        } else {
            try {
                directory.findFile(fileName)?.let { return it }
            } catch (e: Exception) {
                Log.w(TAG, "Error checking for existing file $fileName: ${e.message}")
            }
        }
        return try {
            directory.createFile(mimeType, fileName)
        } catch (e: Exception) {
            Log.e(TAG, "Exception creating file $fileName: ${e.message}")
            null
        }
    }

    fun getOutputStream(context: Context, documentFile: DocumentFile): OutputStream? {
        return try {
            context.contentResolver.openOutputStream(documentFile.uri)
        } catch (e: Exception) {
            Log.e(TAG, "Error opening output stream: ${e.message}")
            null
        }
    }
}
