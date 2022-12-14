export def error [
    msg: string,
    dry: bool
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

    if $dry == false {
        exit 1
    }
}

export def dry [
    cmd: string,
] {
    print $"(ansi yellow_bold)DRY RUN: (ansi green)($cmd)"
}

export def maybe_dry [dry: bool, cmd: string] {
    if $dry == true {
        dry $cmd
    } else {
        nu -c $cmd
    }
}

export def version_check [$dry: bool, pre_ver: string, next_ver: string] {
    if $pre_ver == $next_ver {
        error "Version is the same" $"($pre_ver) == ($next_ver)" $dry
    }
}

