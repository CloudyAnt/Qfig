# Qfig

Useful tools, configurations, commands for developers who use Mac (especially for java developer)

run the script `active.sh`, you'll have full access to these commands in the command folder

## Configurations

### `iRecipe.json`, an iTerm profile 

Includes some iTerm basic settings, include shortcuts, windows size, etc.

Shortcut ****Command + ←**** will jump to begin of line, other shortcuts perform is also the same as in the Chrome

## Commands

all commmands are in `commands` folder

To use these commands, you should add `source $yourProjectLocation/config.sh` to the end of `.zshrc` or `.bash_profile`. Actually, the `active.sh` will help you do this.

Here are some example commands:

### `gadd`, `gct`

`gadd` will execute command `git add -A`

`gct` allows your commit process and commit message more standardized:

```txt
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
...

There are more commands in the **command** folder.

## Tools

`Chrome`, best for developer

`Homebrew`, great package manager, it's similiar with `yum` & `apt-get`

*if connection refuesed, set your DNS Server to 8.8.8.8*

`iTerm`, better than terminal, by the way, `oh-my-zsh` is a good friend

`Postman`, useful for testing you apis

`tablePlus`, convenient DB GUI tool

`VSCode`, slight, quick coding experience

`Scroll Reverser`, just reverse mouse scroll, all in humanized way

`JetBrains IDEs`, pick as you needed

`Yuyue`, perfect note taking software

`Sougou Input Method`, perferred software for chinese inputting

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

## Chrome extensions

`AdBlock`

`Block Site`

`Google Translate`

`沙拉查词`

`Medium Unlimited`

## WebSites

Animated Algorithms: [USFCA](https://www.cs.usfca.edu/~galles/visualization/Algorithms.html)

Git Learning: [learngitbranching](https://learngitbranching.js.org/)

Fronted Learning: [StackBlitz](https://stackblitz.com/)

## Scripts

### Configure Vim

```
" 打开行号
set nu
" 设置配色
colorscheme desert
" 打开代码高亮
syntax on
" use plugin to enable indent setting
filetype plugin indent on
" show existing tab with 4 spaces width
set tabstop=4
" when indenting with '>', use 4 spaces width
set shiftwidth=4
" On pressing tab, insert 4 spaces
set expandtab
```
