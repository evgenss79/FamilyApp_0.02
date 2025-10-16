package com.android.build.gradle;

import java.util.LinkedHashMap;
import java.util.Map;

public class DefaultConfig {
    private String applicationId;
    private int minSdk;
    private int targetSdk;
    private int versionCode;
    private String versionName;
    private final Map<String, Object> manifestPlaceholders = new LinkedHashMap<>();

    public String getApplicationId() {
        return applicationId;
    }

    public void setApplicationId(String applicationId) {
        this.applicationId = applicationId;
    }

    public int getMinSdk() {
        return minSdk;
    }

    public void setMinSdk(int minSdk) {
        this.minSdk = minSdk;
    }

    public int getTargetSdk() {
        return targetSdk;
    }

    public void setTargetSdk(int targetSdk) {
        this.targetSdk = targetSdk;
    }

    public int getVersionCode() {
        return versionCode;
    }

    public void setVersionCode(int versionCode) {
        this.versionCode = versionCode;
    }

    public String getVersionName() {
        return versionName;
    }

    public void setVersionName(String versionName) {
        this.versionName = versionName;
    }

    public Map<String, Object> getManifestPlaceholders() {
        return manifestPlaceholders;
    }
}
