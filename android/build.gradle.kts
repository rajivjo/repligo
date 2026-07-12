allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// Some plugins (e.g. pdfx 2.6.0) still declare an old hardcoded compileSdkVersion
// in their own android/build.gradle, which fails AAR metadata checks against
// newer AndroidX transitive dependencies. Force every plugin module to compile
// against the same SDK level as the app. Because evaluationDependsOn(":app")
// above can cause plugin projects to already be evaluated by the time this
// block runs, afterEvaluate() would throw here — so apply immediately when
// that's the case, and only fall back to afterEvaluate() otherwise.
subprojects {
    if (project.name != "app") {
        fun overrideCompileSdk() {
            extensions.findByType(com.android.build.api.dsl.CommonExtension::class.java)?.let {
                it.compileSdk = 36
            }
        }
        if (project.state.executed) {
            overrideCompileSdk()
        } else {
            afterEvaluate { overrideCompileSdk() }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
