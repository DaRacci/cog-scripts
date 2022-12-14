#!/usr/bin/env nu

use lib.nu

    let maybe_git_res = (do -i {
        lib maybe_dry "git push"
        lib maybe_dry $"git push origin \"v($ver)\""
        lib maybe_dry "git fetch --tags origin"
    })

        let git_res = ($maybe_git_res | complete).stderr
        if $git_res != "" {
    if not (lib is_dry) {
            lib error "Git push failed"
        }
    }
}

    let changelog = (do -i { cog changelog v($pre_ver)..v($next_ver) } | complete)
def changelog [pre_ver: string, next_ver: string] {

    if (lib is_dry) {
        lib dry $"cog changelog v($pre_ver)..v($next_ver) -> (($changelog).stdout)"
    }

    if ($changelog).stderr != "" {
        lib error "Failed to generate changelog" ($changelog).stderr
    }

    return $changelog
}

    lib maybe_dry $dry $"\"(($changelog).stdout)\" |
        gh release create \\
            \"v($ver)\" \\
            -F - -t \\
            \"($name) release ($ver)\" \\
            \"build/libs/($name)-($ver).jar"
def gh_release [name: string, ver: string, changelog: string] {
}

def gh_workflow [workflow: string] {
    lib maybe_dry $"gh workflow run ($workflow).yml"
}

def gradle_publish [sub: string] {
    let target = if $sub == "." { "publish" } else { $":($sub):publish" }
    lib maybe_dry $"./gradlew ($target)"
}

def enter_snapshot [ver: string] {
    lib maybe_dry $"sd \"version=.*\" \"version=($ver)\" gradle.properties"
    lib maybe_dry "cog commit chore \"enter snapshot\" deps --sign"
}

def main [
    name: string                    # The project name.
    pre_ver: string                 # The current version.
    next_ver: string                # The version being bumped to.
    snap_ver: string                # The version after this bump.

    --release (-r)                  # If present, publishes to GH and maven repo.
    --projects (-p): list           # Defines the projects, ("." to represent root).
    --conventions (-c)              # If present updates the version in Minix-Conventions
    --dry (-d)                      # If present, dry runs and prints the commands that would run.
    --debug (-D)                    # If present, prints the commands are being ran.
] {
    with-env [DEBUG $debug DRY $dry] {
        lib version_check $pre_ver $next_ver
        let changelog = changelog $pre_ver $next_ver
        if $release {
            $projects | each {|sub| gradle_publish $sub }

    git_push $dry $next_ver
            enter_snapshot $snap_ver

        gh_release $dry $name $next_ver $changelog
        gh_workflow $dry
            if $conventions {
                try {
                    cd ../Minix-Conventions
                } catch {|err|
                    lib error "Failed to cd into Minix-Conventions" $err
                    return
                }

                lib maybe_dry "git checkout main"
                lib maybe_dry "git fetch"
                lib maybe_dry "git pull"

                lib maybe_dry $"open gradle/libs.versions.toml | upsert versions {|versions|
                    \($versions | select versions\).versions | upsert ($name | str downcase) \"($next_ver)\"
                } | save gradle/libs.versions.toml"

                lib maybe_dry "git add ./gradle/libs.versions.toml"
                lib maybe_dry $"cog commit chore \"Update ($name) version from ($pre_ver) to ($next_ver)\" deps --sign"
                lib maybe_dry "git push"
            }
        }
    }
}

