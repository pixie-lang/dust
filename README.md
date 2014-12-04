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

    Availlable commands:
    get-deps  Download the dependencies of the current project.
    deps      List the dependencies and their versions of the current project.
    repl      Start a REPL in the current project.
    run       Run the code in the given file.
    load-path Print the load path of the current project.
    test      Run the tests of the current project.
    help      Display the help
    describe  Describe the current project.
    ```

## Project definition

`dust` reads it's settings from a per-project `project.pxi` file. In that file
one configures the name, version, dependencies and other metadata about the
project.

```clojure
(defproject dust "0.1.0-alpha"
  :description "Magic fairy dust for Pixie"
  :dependencies [[heyLu/hiccup.pxi "0.1.0-alpha"]])
```

With such a project definition you can run `dust get-deps` to fetch the
dependencies of the project and dust will set up the `load-paths` var in
Pixie so that the namespaces are availlable in the repl or when running
programs:

```
$ dust get-deps
Downloading heyLu/hiccup.pxi
$ dust repl
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
* `git clone git://github.com/pixie-lang/dust`
* `ln -s <path-to-dust> /usr/bin/dust` (or really anywhere else in `$PATH`
