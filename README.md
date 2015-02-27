# dust

*Magic fairy dust for [Pixie](https://github.com/pixie-lang/pixie)*.

Provides tooling around pixie, e.g. a nicer repl, running tests and fetching
dependencies.

## Usage

* `dust` or `dust repl` to start a REPL
* `dust test` to run the tests
* `dust run` to run code in a file
* all commands:

    ```
    $ dust help
    Usage: dust <cmd> <options>

    Available commands:
    deps      List the dependencies and their versions of the current project.
    repl      Start a REPL in the current project.
    run       Run the code in the given file.
    load-path Print the load path of the current project.
    test      Run the tests of the current project.
    help      Display the help
    describe  Describe the current project.
    ```

## Project definition

`dust` reads its settings from a per-project `project.pxi` file. In that file
one configures the name, version, dependencies and other metadata about the
project:

```clojure
(defproject dust "0.1.0-alpha"
  :description "Magic fairy dust for Pixie"
  :dependencies [[heyLu/hiccup.pxi "0.1.0-alpha"]])
```

With such a project definition, dust will set up the `load-paths` var in
Pixie so that the namespaces of all your dependencies are availlable in the repl or when running
programs:

```
$ dust repl
Downloading heyLu/hiccup.pxi
Pixie 0.1 - Interactive REPL
(linux, gcc)
:exit-repl or Ctrl-D to quit
----------------------------
user => (use 'hiccup.core)
nil
user => (html [:span#foo.bar.baz "HOORAY!"])
"<span class="bar baz" id="foo">HOORAY!</span>"
user => @load-paths
["/home/lu/t/pixie/pixie" "." "deps/heyLu/hiccup.pxi/src"]
```

## Installation

* install [Pixie](https://github.com/pixie-lang/pixie)
* `ln -s <path-to-pixie>/pixie-vm /usr/bin/pixie-vm` (or really anywhere else in `$PATH`)
* `git clone git://github.com/pixie-lang/dust`
* `ln -s <path-to-dust>/dust /usr/bin/dust` (or really anywhere else in `$PATH`)

For an improved REPL with history and line-editing you'll need to install
`rlwrap`.

## Contributions welcome!

Some ideas:

* `dust doc`, probably using something like [this](https://github.com/pixie-lang/pixie/blob/master/examples/gen-docs.pxi)
* dependency improvements:
    - recursive dependencies (e.g. fetch dependencies of dependencies)
    - fetch dependencies from paths inside repositories, maybe via a `:path "sub/dir"` option
