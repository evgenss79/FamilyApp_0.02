package com.familyapp.android

import com.google.common.truth.Truth.assertThat
import org.junit.Test

class BuildConfigSmokeTest {
    @Test
    fun buildConfig_isOk() {
        assertThat(BuildConfig.APPLICATION_ID).isNotEmpty()
    }
}
