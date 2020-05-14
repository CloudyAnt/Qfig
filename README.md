# Qfig

Useful tools, configurations, commands for developers who use Mac (especially for java developer)

## Configurations

### `iRecipe.json`, an iTerm profile 

Includes some iTerm basic settings, include shortcuts, windows size, etc.

Shortcut ****Command + ←**** will jump to begin of line


## Commands

all commmands are in `commands` folder

To use these commands, you should add `source $yourProjectLocation/config.sh` to the end of `.zshrc` or `.bash_profile`

### `gadd`, `gct`

`gadd` will execute command `git add -A`

`gct` allows your commit process and commit message more standardized:

```
name [story] message
```

### `defaultV`

```sh
$ defaultV var 1
$ echo $var
1
$ defaultV var 2
$ echo $var
1
```

## Tools

`Chrome`, best for developer

`iTerm`, better than terminal

`Postman`, useful for testing you apis

`VSCode`, slight, quick coding experience

`Scroll Reverser`, just reverse mouse scroll, all in humanized way

IDEs, pick as you needed

## IDEA plugins

### Visual improvement

`Rainbow Brackets`

`Material theme`

### Productivity improvement

`Lombok`

### Problems invesigatation

`SonarLint`

`FindBugs`

`CheckStyle`