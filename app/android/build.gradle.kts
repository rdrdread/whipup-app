allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// 플러그인들이 Kotlin 1.6 languageVersion을 사용하는 문제 해결:
// Kotlin 2.x는 1.6을 더 이상 지원하지 않으므로 모든 서브프로젝트에 2.0으로 강제 적용.
// isar_flutter_libs compileSdk 30 → 34 강제 업그레이드 (현대 AndroidX는 34+ 필요).
subprojects {
    afterEvaluate {
        tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
            compilerOptions {
                languageVersion.set(org.jetbrains.kotlin.gradle.dsl.KotlinVersion.KOTLIN_2_0)
                apiVersion.set(org.jetbrains.kotlin.gradle.dsl.KotlinVersion.KOTLIN_2_0)
            }
        }

        // isar_flutter_libs AAR은 compileSdk=30으로 빌드됨.
        // 현대 AndroidX 의존성(fragment 1.7, activity 1.8 등)은 compileSdk>=34 요구.
        // LibraryExtension을 통해 강제 업그레이드한다.
        extensions.findByType<com.android.build.gradle.LibraryExtension>()?.apply {
            if ((compileSdk ?: 0) < 36) {
                compileSdk = 36
            }
        }
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
