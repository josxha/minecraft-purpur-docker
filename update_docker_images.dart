import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart';

const PURPUR_API = "https://api.purpurmc.org/v2/purpur";
const DOCKER_TAG_API = "https://registry.hub.docker.com/v2/repositories/josxha/minecraft-purpur/tags?page=";

bool DRY_RUN = false;
bool FORCE_BUILDS = false;

main(List<String> args) async {
  for (var arg in args) {
    switch (arg) {
      case "force":
        FORCE_BUILDS = true;
        break;
      case "dry-run":
        DRY_RUN = true;
        break;
      default:
        throw "Unknown argument: '$arg'";
    }
  }

  var minecraftVersions = await getMinecraftVersions();
  var dockerImageTags = await getDockerImageTags();

  for (var minecraftVersion in minecraftVersions) {
    print("[$minecraftVersion] Checking updates for minecraft version");

    // get purpur build ids for the minecraft version
    var buildNumber = await getLatestBuildForVersion(minecraftVersion);
    print("[$minecraftVersion-$buildNumber] Check if an docker image exists for the purpur build ...");
    if (dockerImageTags.contains("$minecraftVersion-$buildNumber")) {
      // image already exists
      if (FORCE_BUILDS) {
        print("[$minecraftVersion-$buildNumber] Image exists but force update enabled.");
      } else {
        print("[$minecraftVersion-$buildNumber] Image exists, skip build.");
        continue;
      }
    }
    // image doesn't exist yet
    // download build
    print("[$minecraftVersion-$buildNumber] Build and push image");
    if (DRY_RUN) {
      await File("purpur.jar").writeAsString("Dry run by the dev branch. Not the real downloaded jar file.", mode: FileMode.write);
    } else {
      var response = await get(Uri.parse("$PURPUR_API/$minecraftVersion/$buildNumber/download"));
      await File("purpur.jar").writeAsBytes(response.bodyBytes, mode: FileMode.write);
    }
    var tags = ["$minecraftVersion-$buildNumber", "$minecraftVersion"];
    if (minecraftVersion == minecraftVersions.last) {
      tags.add("latest"); // latest minecraft version
    }
    if (versionIsHighestSubversion(minecraftVersion, minecraftVersions))
      tags.add("${getMajorVersion(minecraftVersion)}-latest");

    await dockerBuildPushRemove(tags);
    print("[$minecraftVersion-$buildNumber] Built, pushed and cleaned up successfully!");
  }
}

String getMajorVersion(String version) {
  var list = version.split(RegExp("[\.-]")); // split at . or -
  return list[0] + "." + list[1];
}

bool versionIsHighestSubversion(String version, List<String> allVersions) {
  bool indexOfVersionReached = false;
  var majorVersion = getMajorVersion(version);
  for (var tmpVersion in allVersions) {
    // check if other mayor version
    if (getMajorVersion(tmpVersion) == majorVersion) {
      continue;
    }
    if (indexOfVersionReached)
      return false;
    if (tmpVersion == version) {
      indexOfVersionReached = true;
    }
  }
  return true;
}

Future<void> dockerBuildPushRemove(List<String> tags) async {
  var args = [
    "buildx", "build", ".",
    "--push",
    "--platform", "linux/arm64,linux/amd64",
  ];
  tags.forEach((String tag) {
    args.addAll([
      "--tag",
      "josxha/minecraft-purpur:$tag",
    ]);
  });
  if (DRY_RUN)
    return;
  var taskResult = Process.runSync("docker", args);
  if (taskResult.exitCode != 0) {
    print(taskResult.stdout);
    print(taskResult.stderr);
    throw Exception("Couldn't run docker build for $tags.");
  }
}

Future<int> getLatestBuildForVersion(minecraftVersion) async {
  var response = await get(Uri.parse("$PURPUR_API/$minecraftVersion"));
  return jsonDecode(response.body)["builds"]["latest"] as int;
}

Future<List<String>> getDockerImageTags() async {
  List<String> tags = [];
  int page = 1;
  while (true) {
    var uri = Uri.parse("$DOCKER_TAG_API$page");
    print(uri);
    var response = await get(uri);
    Map<String, dynamic> json = jsonDecode(response.body);
    List jsonList = json["results"];
    tags.addAll(jsonList.map((listElement) => listElement["name"] as String).toList());
    if (json['next'] == null)
      break;
    page++;
  }
  return tags;
}

Future<List<String>> getMinecraftVersions() async {
  var response = await get(Uri.parse(PURPUR_API));
  List versions = jsonDecode(response.body)["versions"];
  return versions.cast<String>();
}
