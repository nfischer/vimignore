Vim-Gitignore
=============

A simple plugin to allow you to efficiently manage your .gitignore files in
your project.

Usage
-----

Simply call `:Gignore` to open up your .gitignore file.

If no file exists, this will open a new .gitignore file in the root of the
git repo.

If you have multiple .gitignore files, this plugin will prefer the one in
the root. If that does not exist, it will then prefer the deepest .gitignore
file along your path.

Configuration
-------------

If you open an empty instance of vim, this will open the .gitignore in the
entire buffer. If you already are editing a file, it will open the
.gitignore file in a split.

The plugin will, by default, open this in a horizontal split. To configure this, set the following variable:

```
let g:gsplit_pref = 1
```

Set this to 0 in order to reconfigure vim to use horizontal splits.
