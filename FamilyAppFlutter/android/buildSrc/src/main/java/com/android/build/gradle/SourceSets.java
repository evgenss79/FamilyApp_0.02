package com.android.build.gradle;

import java.util.LinkedHashMap;
import java.util.Map;

public class SourceSets {
    private final Map<String, StubSourceSet> sets = new LinkedHashMap<>();

    public SourceSets(Object project) {
        sets.put("main", new StubSourceSet("main"));
    }

    public StubSourceSet get(String name) {
        return sets.computeIfAbsent(name, StubSourceSet::new);
    }

    public static class StubSourceSet {
        private final String name;
        private final StubManifest manifest = new StubManifest();
        private final StubJava java = new StubJava();

        StubSourceSet(String name) {
            this.name = name;
        }

        public String getName() {
            return name;
        }

        public StubManifest getManifest() {
            return manifest;
        }

        public StubJava getJava() {
            return java;
        }

        public String getJavaSrcDir() {
            return java.srcDir;
        }
    }

    public static class StubJava {
        private String srcDir;

        public void srcDir(Object path) {
            if (path != null) {
                this.srcDir = path.toString();
            }
        }
    }

    public static class StubManifest {
        private String srcFile;

        public String getSrcFile() {
            return srcFile;
        }

        public void srcFile(Object path) {
            if (path != null) {
                this.srcFile = path.toString();
            }
        }
    }
}
