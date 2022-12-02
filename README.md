### Requirements
* [NuShell](https://github.com/nushell/nushell) 0.72 or later
* [SD](https://github.com/chmln/sd)

### How to set up.
In the root of your git repo run:
```shell
git submodule add https://github.com/DaRacci/cog-scripts.git
```
This will add the cog-scripts repo as a submodule to your repo, Which will make keeping them up-to-date easier.

Inside cog.toml, add the following:
```toml
pre_bump_hooks = [
    "nu -c \"cog-scripts/src/pre-bump.nu {{latest}} {{version}}\"",
]
post_bump_hooks = [
    "nu -c \"cog-scripts/src/post-bump.nu {{name}} {{latest}} {{version}} {{version+patch-SNAPSHOT}}\"",
]

```
Replacing {{name}} with your projects name.

If you want to auto-publish to Maven and make a GitHub Release append post-bump with `-r`.

To Define what projects or subprojects to publish append post-bump with `-p [gradle paths]` (separated by ',' and no spaces), use '.' to represent the root project, All supplied subprojects must have a publish task defined.
