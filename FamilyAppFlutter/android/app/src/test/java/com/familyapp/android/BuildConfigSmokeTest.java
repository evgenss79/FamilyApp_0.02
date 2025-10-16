package com.familyapp.android;

import static com.google.common.truth.Truth.assertThat;

import org.junit.Test;

public class BuildConfigSmokeTest {
    @Test
    public void buildConfig_isOk() {
        assertThat(BuildConfig.APPLICATION_ID).isNotEmpty();
    }
}
