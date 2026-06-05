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
    // Workarounds for legacy plugins (e.g. flutter_jailbreak_detection 1.10.0):
    //  1. They don't declare an Android `namespace`, which AGP 8+ requires —
    //     derive it from the module's Gradle group.
    //  2. Their Java/Kotlin JVM targets are inconsistent (Java 1.8 vs Kotlin 21)
    //     — pin both to 17 to match the app.
    // Done here so we don't patch sources in pub-cache. Registered before
    // evaluationDependsOn so it runs before evaluation starts.
    afterEvaluate {
        if (project.hasProperty("android")) {
            val androidExtension = project.extensions.getByName("android")
            androidExtension.withGroovyBuilder {
                if (getProperty("namespace") == null) {
                    setProperty("namespace", project.group.toString())
                }
                "compileOptions" {
                    setProperty("sourceCompatibility", JavaVersion.VERSION_17)
                    setProperty("targetCompatibility", JavaVersion.VERSION_17)
                }
            }
        }
        tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
            compilerOptions {
                jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
            }
        }
    }
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
