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
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

subprojects {
    val configureAndroid: (Project) -> Unit = { proj ->
        if (proj.hasProperty("android")) {
            val android = proj.extensions.findByName("android") as? com.android.build.gradle.BaseExtension
            android?.apply {
                compileSdkVersion(36)
            }
        }
    }

    // Nếu project đã chạy xong vòng đời đánh giá, cấu hình trực tiếp luôn
    if (this.state.executed) {
        configureAndroid(this)
    } else {
        // Nếu chưa, đợi sau khi đánh giá xong mới cấu hình
        this.afterEvaluate {
            configureAndroid(this)
        }
    }
}
