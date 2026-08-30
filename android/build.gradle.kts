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

// Plugins built against AGP 9 assume built-in Kotlin and no longer apply the Kotlin
// plugin themselves. We still run with android.builtInKotlin=false because other
// plugins apply kotlin-android explicitly, which AGP 9 rejects once built-in Kotlin
// is on, so give every Android library subproject the Kotlin plugin here.
subprojects {
    plugins.withId("com.android.library") {
        if (!plugins.hasPlugin("org.jetbrains.kotlin.android")) {
            apply(plugin = "org.jetbrains.kotlin.android")
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
