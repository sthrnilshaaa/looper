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

subprojects {
    project.configurations.all {
        resolutionStrategy.eachDependency {
            if (requested.group == "com.android.support" && !requested.name.startsWith("multidex")) {
                useVersion("28.0.0")
            }
        }
    }
}

subprojects {
    val forceCompileSdk = {
        val android = project.extensions.findByName("android")
        if (android != null) {
            val sdkVersion = 36
            try {
                // Try setCompileSdk (AGP 7.0+)
                val method = android.javaClass.getMethod("setCompileSdk", Int::class.javaPrimitiveType)
                method.invoke(android, sdkVersion)
            } catch (e: Exception) {
                try {
                    // Try setCompileSdkVersion (Older AGP)
                    val method = android.javaClass.getMethod("setCompileSdkVersion", Int::class.javaPrimitiveType)
                    method.invoke(android, sdkVersion)
                } catch (e2: Exception) {
                    // Ignore
                }
            }
        }
    }
    if (project.state.executed) {
        forceCompileSdk()
    } else {
        project.afterEvaluate { forceCompileSdk() }
    }
}

subprojects {
    val applyNamespace = {
        val android = project.extensions.findByName("android")
        if (android != null) {
            try {
                // Check if namespace is already set
                val getNamespace = android.javaClass.getMethod("getNamespace")
                val namespace = getNamespace.invoke(android) as? String
                if (namespace == null || namespace.isEmpty()) {
                    val newNamespace = when (project.name) {
                        "isar_flutter_libs" -> "dev.isar.isar_flutter_libs"
                        "metadata_god" -> "com.shinayser.metadata_god"
                        else -> "com.looper_player.${project.name.replace("-", "_")}"
                    }
                    android.javaClass.getMethod("setNamespace", String::class.java).invoke(android, newNamespace)
                }
            } catch (e: Exception) {
                // Ignore errors
            }
        }
    }
    if (project.state.executed) {
        applyNamespace()
    } else {
        project.afterEvaluate { applyNamespace() }
    }
}

// appambit_sdk_flutter 1.2.1 ships the same class twice, in two files whose
// names differ only by case, which is a Kotlin redeclaration error.
project(":appambit_sdk_flutter").tasks
    .matching { it.name.startsWith("compile") && it.name.endsWith("Kotlin") }
    .configureEach {
        (this as org.gradle.api.tasks.util.PatternFilterable)
            .exclude("**/AppambitSdkFlutterPlugin.kt")
    }

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
