package com.familyapp.android;

import static com.google.common.truth.Truth.assertThat;

import java.io.File;
import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import org.junit.Test;
import org.w3c.dom.Document;

public class ManifestRobolectricTest {
    @Test
    public void context_and_manifest() throws Exception {
        File manifestFile = new File("src/main/AndroidManifest.xml");
        assertThat(manifestFile.exists()).isTrue();

        DocumentBuilderFactory factory = DocumentBuilderFactory.newInstance();
        factory.setNamespaceAware(true);
        DocumentBuilder builder = factory.newDocumentBuilder();

        try (var stream = manifestFile.toURI().toURL().openStream()) {
            Document document = builder.parse(stream);
            String packageName = document.getDocumentElement().getAttribute("package");
            assertThat(packageName).contains("com.familyapp");
        }
    }
}
