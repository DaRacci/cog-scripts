#!/usr/bin/env nu

use lib.nu

def gradle_check [] {
    try {
        ./gradlew clean check -q
    } catch {|err|
        lib error "Gradle check failed" $err
    }
}

def update_ver [ver: string] {
    lib maybe_dry $"sd \"version=.*\" \"version=($ver)\" gradle.properties"
    lib maybe_dry "git add gradle.properties"
}

def main [
    pre_ver: string                 # The current version.
    next_ver: string                # The version being bumped to.
    --dry (-d)                      # If present, dry runs and prints the commands that would run.
    --debug (-D)                    # If present, prints debug information.
] {
    with-env [DRY $dry DEBUG $debug] {
        lib version_check $pre_ver $next_ver
        gradle_check
        update_ver $next_ver
        lib maybe_dry $"./gradlew build -q -Pversion=\"($next_ver)\""
    }
}

