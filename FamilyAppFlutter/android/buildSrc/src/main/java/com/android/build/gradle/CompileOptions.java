package com.android.build.gradle;

import org.gradle.api.JavaVersion;

public class CompileOptions {
    private JavaVersion sourceCompatibility = JavaVersion.VERSION_1_8;
    private JavaVersion targetCompatibility = JavaVersion.VERSION_1_8;
    private boolean coreLibraryDesugaringEnabled;

    public JavaVersion getSourceCompatibility() {
        return sourceCompatibility;
    }

    public void setSourceCompatibility(JavaVersion sourceCompatibility) {
        this.sourceCompatibility = sourceCompatibility;
    }

    public JavaVersion getTargetCompatibility() {
        return targetCompatibility;
    }

    public void setTargetCompatibility(JavaVersion targetCompatibility) {
        this.targetCompatibility = targetCompatibility;
    }

    public boolean isCoreLibraryDesugaringEnabled() {
        return coreLibraryDesugaringEnabled;
    }

    public void setCoreLibraryDesugaringEnabled(boolean coreLibraryDesugaringEnabled) {
        this.coreLibraryDesugaringEnabled = coreLibraryDesugaringEnabled;
    }
}
