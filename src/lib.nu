export def error [
    msg: string,
    err?: string,
] {
    if $err != null {
        $err
        | lines
        | str replace 'error: ' ''
        | each {|err| print $"(ansi red_bold)($msg); Error: (ansi reset)($err)" }
    } else {
        print $"(ansi red_bold)($msg); Error: (ansi reset)unknown error"
    }

    if not (is_dry) {
        exit 1
    }
}

export def log [cmd: string] {
    if (is_debug) {
        print $"(ansi yellow_bold)DEBUG: (ansi green)($cmd)"
    }

    return (do -i { nu -c $cmd } | complete)
}


export def dry [
    cmd: string,
] {
    print $"(ansi yellow_bold)DRY RUN: (ansi green)($cmd)"
}

export def maybe_dry [cmd: string] {
    if (is_dry) {
        dry $cmd
    } else {
        nu -c $cmd
        if (is_debug) {
            print $"(ansi yellow_bold)DEBUG: (ansi green)($cmd)"
        }

    }
}

export def version_check [pre_ver: string, next_ver: string] {
    if $pre_ver == $next_ver {
        error "Version is the same" $"($pre_ver) == ($next_ver)"
    }
}

export def env_def [env_str: string, default: any] {
    if not ($env_str in (env).name) {
        return $default
    } else {
        return ($env | get $env_str)
    }
}

export def is_dry [] {
    return (env_def "DRY" false)
}

export def is_debug [] {
    return (env_def "DEBUG" false)
}
