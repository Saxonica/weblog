plugins {
  id("java")
  id("com.nwalsh.gradle.saxon.saxon-gradle") version "0.10.2"
}

import java.io.InputStream
import java.io.InputStreamReader
import java.io.ByteArrayOutputStream
import com.nwalsh.gradle.saxon.SaxonXsltTask

repositories {
  mavenLocal()
  mavenCentral()
}

val saxonVersion = project.findProperty("saxonVersion") as String
val linkCheck = "true".equals(project.findProperty("linkCheck"))
val pythonExecutable = project.findProperty("pythonExecutable") as String
val serverPort = project.findProperty("serverPort") as String

val saxonee = configurations.create("saxonee") {
  extendsFrom(configurations["implementation"])
}

val validateRuntime = configurations.create("validateRuntime") {
  extendsFrom(configurations["implementation"])
}

val projectImplementationClasspath = configurations.create("projectImplementationClasspath") {
  extendsFrom(configurations["implementation"])
}

val projectRuntimeClasspath = configurations.create("projectRuntimeClasspath") {
  extendsFrom(configurations["runtimeOnly"])
}

dependencies {
  implementation("net.sf.saxon:Saxon-HE:${saxonVersion}")
}

defaultTasks("publishWeblog")

val weblogAuthors = mapOf("announcements" to "announcements",
                          "mike" to "michael-kay",
                          "oneil" to "oneil-delpratt",
                          "norm" to "norm-tovey-walsh")

fun gitRef(post: String): String {
    val commandLine = listOf("git", "rev-parse", "--short", "HEAD")
    val builder = ProcessBuilder(commandLine)
    val process = builder.start()

    val stdout = ByteArrayOutputStream()
    val stderr = ByteArrayOutputStream()

    val stdoutReader = ProcessOutputReader(process.inputStream, stdout)
    val stderrReader = ProcessOutputReader(process.errorStream, stderr)

    val stdoutThread = Thread(stdoutReader)
    val stderrThread = Thread(stderrReader)

    stdoutThread.start()
    stderrThread.start()

    val rc = process.waitFor()
    stdoutThread.join()
    stderrThread.join()

    if (rc != 0) {
      throw RuntimeException("Attempt to get git hash failed: ${rc}")
    }

    return stdout.toString().trim()
}

internal class ProcessOutputReader(val stream: InputStream,
                                   val buffer: ByteArrayOutputStream): Runnable {
  override fun run() {
    val reader = InputStreamReader(stream)
    val buf = CharArray(4096)
    var len = reader.read(buf)
    while (len >= 0) {
      if (len == 0) {
        Thread.sleep(250)
      } else {
        // This is the most efficient way? Really!?
        for (pos in 0 until len) {
          buffer.write(buf[pos].code)
        }
      }
      len = reader.read(buf)
    }
  }
}

//var heAvailable = true
//var peAvailable = true
//var eeAvailable = true
//configurations["saxonee"].forEach { it ->
//  val filename = it.getAbsolutePath().lowercase()
//  eeAvailable = eeAvailable || filename.contains("saxon-ee")
//  peAvailable = peAvailable || filename.contains("saxon-pe")
//}

val publishHtml = tasks.register("publishHtml") {
  // nop
}

val weblogPosts = mutableMapOf<String,String>()
val postRegex = "(\\d+)\\/(\\d+)\\/.*\\.html$".toRegex()
for ((author, name) in weblogAuthors) {
  val basepath = "${projectDir}/src/${author}/"
  val baselen = basepath.length
  fileTree(mapOf("dir" to layout.projectDirectory.file("src/${author}"))).forEach { file ->
    val path = file.getAbsolutePath().substring(baselen)
    if (postRegex.matches(path)) {
      // A proper string, not a Groovy GString
      val key = "${author}/${path}"
      weblogPosts.put(key, file.getAbsolutePath())
      val taskId = key.replace("/", "_").replace("-", "_").replace(".html", "")
      val t = tasks.register<SaxonXsltTask>("${taskId}") {
        dependsOn("updateNavigation")
        classpath(configurations["saxonee"])
        input(file.getAbsolutePath())
        stylesheet("${layout.projectDirectory.file("xslt/post.xsl")}")
        output("${layout.buildDirectory.file("docs/${key}").get().asFile}")
      }
      publishHtml { dependsOn(t) }
    }
  }
}

val everythingElse = mutableListOf<String>()
fileTree(mapOf("dir" to layout.projectDirectory.file("src"))).forEach { file ->
  val baselen = "${projectDir}/src".length + 1
  val path = file.toString().substring(baselen)
  if (path !in weblogPosts) {
    everythingElse.add(path)
  }
}

//task configureEnvironment() {
//  def envVars = [:]
//  envVars['SAXON_CP'] = EXCP
//  envVars['VERBOSE'] = verbose
//  tasks.withType(Exec) {
//    environment << envVars
//  }
//}

val copyResources = tasks.register<Copy>("copyResources") {
  inputs.files(everythingElse)

  into(layout.buildDirectory.dir("docs"))
  from(layout.projectDirectory.dir("src")) {
    include(everythingElse)
  }

  doFirst {
    mkdir(layout.buildDirectory.dir("docs"))
  }
}

val updateNavigation = tasks.register<SaxonXsltTask>("updateNavigation") {
  inputs.files(weblogPosts.values)
  classpath(configurations["saxonee"])
  stylesheet("${layout.projectDirectory.file("xslt/navigate.xsl")}")
  output("${layout.buildDirectory.file("navigation.xml").get().asFile}")
  args(listOf("-it"))
}

val atomize = tasks.register<SaxonXsltTask>("atomize") {
  dependsOn(updateNavigation)
  classpath(configurations["saxonee"])
  input("${layout.buildDirectory.file("navigation.xml").get().asFile}")
  stylesheet("${layout.projectDirectory.file("xslt/atom.xsl")}")
  output("${layout.buildDirectory.file("docs/atom.xml").get().asFile}")
}

for ((blog, aid) in weblogAuthors) {
  val t = tasks.register<SaxonXsltTask>("atomize-${blog}") {
    dependsOn(updateNavigation)
    classpath(configurations["saxonee"])
    input("${layout.buildDirectory.file("navigation.xml").get().asFile}")
    stylesheet("${layout.projectDirectory.file("xslt/atom.xsl")}")
    output("${layout.buildDirectory.file("docs/${blog}/atom.xml").get().asFile}")
    parameters(mapOf("author-id" to aid))
  }
  atomize { dependsOn(t) }
}

val gitData = tasks.register<Exec>("gitData") {
  inputs.dir(layout.projectDirectory.dir("src"))
  inputs.file(layout.projectDirectory.file("bin/git-data"))
  outputs.file(layout.buildDirectory.file("git-data.txt"))
  commandLine("${layout.projectDirectory.file("bin/git-data")}",
              "${layout.buildDirectory.file("git-data.txt").get().asFile}")
  doFirst {
    mkdir(layout.buildDirectory)
  }
}

val sitemap = tasks.register<SaxonXsltTask>("sitemap") {
  dependsOn(gitData)
  classpath(configurations["saxonee"])
  stylesheet("${layout.projectDirectory.file("xslt/sitemap.xsl")}")
  output("${layout.buildDirectory.file("docs/sitemap.xml").get().asFile}")
  args(listOf("-it"))
}

val linkcheckTask = tasks.register<Exec>("linkcheck") {
  commandLine(pythonExecutable,
              "${layout.projectDirectory.file("bin/linkcheck.py")}",
              "--debug",
              "-s",
              "${layout.buildDirectory.file("docs").get().asFile}")
}

val publishWeblog = tasks.register<SaxonXsltTask>("publishWeblog") {
  dependsOn(copyResources, atomize, publishHtml, sitemap)
  outputs.file(layout.buildDirectory.file("docs/index.html"))
  outputs.file(layout.buildDirectory.file("docs/archive.html"))
  inputs.file(layout.buildDirectory.file("navigation.xml"))

  classpath(configurations["saxonee"])
  input("${layout.buildDirectory.file("navigation.xml").get().asFile}")
  stylesheet("${layout.projectDirectory.file("xslt/indexes.xsl")}")
  if (linkCheck) {
    finalizedBy(linkcheckTask)
  }
}

tasks.register<Exec>("server") {
  dependsOn(publishWeblog)
  commandLine(pythonExecutable,
              "-m", "http.server",
              "--directory", "${layout.buildDirectory.file("docs").get().asFile}",
              serverPort)
  doFirst {
    println("Starting web server; open http://localhost:${serverPort}/ in your browser")
  }
}
