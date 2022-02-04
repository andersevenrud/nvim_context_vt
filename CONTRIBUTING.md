# Contribution Guide

Pull requests are very welcome and this guide will walk through some of the basics
on how to contribute.

## Code style

This project uses [stylua](https://github.com/JohnnyMorganz/StyLua) and [luacheck](https://github.com/mpeterv/luacheck)
to check the code for potential errors and styling issues.

It is adviced to install these utilities and check your code before submission. Most modern IDEs and editors have some
way of alerting you with diagnostics using the provided configurations.

## Commit messages

This project uses the [conventional commits](https://conventionalcommits.org/) specification for git commit messages.

## Modifying context virtual text

The file `lua/nvim_context_vt/config.lua` contains the tables required for resolving virtual text.

Use the command `:NvimContextVtDebug` to show the context for the current line to inspect the tree of nodes.

* `targets`: valid node targets
* `ignore_root_targets`: invalid root node targets
* `line_targets`: valid node targets used for line targets and not inline
* `line_ft`: filetypes that should use `line_targets`

Commit the changes with the message `feat: support X` or `feat: improve Y`, etc. into your fork and open a pull-request.
