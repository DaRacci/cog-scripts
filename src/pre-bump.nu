#!/usr/bin/env nu

use lib.nu

def gradle_check [dry: bool] {
    try {
        ./gradlew clean check -q
    } catch {|err|
        lib error "Gradle check failed" $err $dry
    }
}

def update_ver [dry: bool, ver: string] {
    lib maybe_dry $dry $"sd \"version=.*\" \"version=($ver)\" gradle.properties"
    lib maybe_dry $dry "git add gradle.properties"
}

def main [
    pre_ver: string                 # The current version.
    next_ver: string                # The version being bumped to.
    --dry (-d)                      # If present, dry runs and prints the commands that would run.
] {
    lib version_check $dry $pre_ver $next_ver
    gradle_check $dry
    update_ver $dry $next_ver
    lib maybe_dry $dry $"./gradlew build -q -Pversion=\"v($next_ver)\""
}

