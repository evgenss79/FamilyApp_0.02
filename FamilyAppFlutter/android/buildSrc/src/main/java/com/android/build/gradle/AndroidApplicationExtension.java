package com.android.build.gradle;

import org.gradle.api.Action;
import org.gradle.api.Project;

public class AndroidApplicationExtension {
    private final Project project;
    private final DefaultConfig defaultConfig = new DefaultConfig();
    private final CompileOptions compileOptions = new CompileOptions();
    private final KotlinOptions kotlinOptions = new KotlinOptions();
    private final SourceSets sourceSets;
    private String namespace;
    private int compileSdk;

    public AndroidApplicationExtension(Project project) {
        this.project = project;
        this.sourceSets = new SourceSets(project);
    }

    public String getNamespace() {
        return namespace;
    }

    public void setNamespace(String namespace) {
        this.namespace = namespace;
    }

    public int getCompileSdk() {
        return compileSdk;
    }

    public void setCompileSdk(int compileSdk) {
        this.compileSdk = compileSdk;
    }

    public DefaultConfig getDefaultConfig() {
        return defaultConfig;
    }

    public void defaultConfig(Action<? super DefaultConfig> action) {
        action.execute(defaultConfig);
    }

    public CompileOptions getCompileOptions() {
        return compileOptions;
    }

    public void compileOptions(Action<? super CompileOptions> action) {
        action.execute(compileOptions);
    }

    public KotlinOptions getKotlinOptions() {
        return kotlinOptions;
    }

    public void kotlinOptions(Action<? super KotlinOptions> action) {
        action.execute(kotlinOptions);
    }

    public SourceSets getSourceSets() {
        return sourceSets;
    }
}
