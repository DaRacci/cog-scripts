#!/usr/bin/env nu

use lib.nu

def git_push [dry: bool, ver: string] {
    let maybe_git_res = (do -i {
        lib maybe_dry $dry "git push"
        lib maybe_dry $dry $"git push origin \"v($ver)\""
        lib maybe_dry $dry "git fetch --tags origin"
    })

    if $dry == false {
        let git_res = ($maybe_git_res | complete).stderr
        if $git_res != "" {
            lib error "Git push failed" $git_res $dry
        }
    }
}

def changelog [dry: bool, pre_ver: string, next_ver: string] {
    let changelog = (do -i { cog changelog v($pre_ver)..v($next_ver) } | complete)

    if $dry {
        lib dry $"cog changelog v($pre_ver)..v($next_ver) -> (($changelog).stdout)"
    }

    if ($changelog).stderr != "" {
        lib error "Failed to generate changelog" ($changelog).stderr $dry
    }

    return $changelog
}

def gh_release [dry: bool, name: string, ver: string, changelog: string] {
    lib maybe_dry $dry $"\"(($changelog).stdout)\" |
        gh release create \\
            \"v($ver)\" \\
            -F - -t \\
            \"($name) release ($ver)\" \\
            \"build/libs/($name)-($ver).jar"
}

def gh_workflow [dry: bool] {
    lib maybe_dry $dry "gh workflow run docs.yml"
}

def gradle_publish [dry: bool, sub: string] {
    let target = if $sub == "." { "publish" } else { $":($sub):publish" }
    lib maybe_dry $dry $"./gradlew ($target)"
}

def enter_snapshot [dry: bool, ver: string] {
    lib maybe_dry $dry $"sd \"version=.*\" \"version=($ver)\" gradle.properties"
    lib maybe_dry $dry "cog commit chore \"enter snapshot\" deps --sign"
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
] {
    lib version_check $dry $pre_ver $next_ver

    git_push $dry $next_ver
    let changelog = changelog $dry $pre_ver $next_ver

    if $release {
        gh_release $dry $name $next_ver $changelog
        gh_workflow $dry
        $projects | each {|sub| gradle_publish $dry $sub }

        enter_snapshot $dry $snap_ver

        if $conventions {
            try {
                cd ../Minix-Conventions
            } catch {|err|
                lib error "Failed to cd into Minix-Conventions" $err $dry
                return
            }

            lib maybe_dry $dry "git checkout main"
            lib maybe_dry $dry "git fetch"
            lib maybe_dry $dry "git pull"

            lib maybe_dry $dry $"open gradle/libs.versions.toml | upsert versions {|versions|
                \($versions | select versions\).versions | upsert ($name | str downcase) \"($next_ver)\"
            } | save gradle/libs.versions.toml"

            lib maybe_dry $dry "git add ./gradle/libs.versions.toml"
            lib maybe_dry $dry $"cog commit chore \"Update ($name) version from ($pre_ver) to ($next_ver)\" deps --sign"
            lib maybe_dry $dry "git push"
        }
    }
}

