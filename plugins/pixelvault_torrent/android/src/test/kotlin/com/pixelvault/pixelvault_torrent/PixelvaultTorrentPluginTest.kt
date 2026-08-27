package com.pixelvault.pixelvault_torrent

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.mockito.Mockito
import kotlin.test.Test

internal class PixelvaultTorrentPluginTest {
    @Test
    fun onMethodCall_unknownMethod_callsNotImplemented() {
        val plugin = PixelvaultTorrentPlugin()

        val call = MethodCall("someUnknownMethod", null)
        val mockResult: MethodChannel.Result = Mockito.mock(MethodChannel.Result::class.java)
        plugin.onMethodCall(call, mockResult)

        Mockito.verify(mockResult).notImplemented()
    }
}
