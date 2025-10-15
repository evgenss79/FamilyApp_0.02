package com.familyapp.android

import com.google.common.truth.Truth.assertThat
import org.junit.Test
import java.io.File
import javax.xml.parsers.DocumentBuilderFactory

class ManifestRobolectricTest {
    @Test
    fun context_and_manifest() {
        val manifestFile = File("src/main/AndroidManifest.xml")
        assertThat(manifestFile.exists()).isTrue()

        val docBuilder = DocumentBuilderFactory.newInstance().apply {
            isNamespaceAware = true
        }.newDocumentBuilder()

        val document = manifestFile.inputStream().use { stream ->
            docBuilder.parse(stream)
        }

        val packageName = document.documentElement.getAttribute("package")
        assertThat(packageName).contains("com.familyapp")
    }
}
