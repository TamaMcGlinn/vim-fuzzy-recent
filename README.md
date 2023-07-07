# fuzzy-recent

Fuzzy-recent is a small vim plugin built on [fzf.vim](https://github.com/junegunn/fzf.vim)
to fuzzy find and operate on files, which shows open buffers and recently viewed files first,
and expands that list to all git tracked files when you press space.

## Prerequisites

Vim 8/9 and NeoVim are supported.
You need fzf.vim installed.

## Installation

If you use [Plug](https://github.com/junegunn/vim-plug), add the following to your `.vimrc`:

```vim
Plug 'TamaMcGlinn/vim-fuzzy-recent'
```

## Using fuzzy-recent

The default operation is to open the file(s) selected,
so you can just use a binding such as the following to quickly switch files.

```
nnoremap <silent> <leader>fj :call fuzzy_recent#Find()<CR>
```

Type any characters to narrow down the search with fuzzy search, control-N / control-P to move up and down the list,
and press enter to select the file. You can use tab to select multiple files. Pressing space expands the list
to all git tracked files (output of `git ls-files`).

You can pass a dictionary to Find with two additional options:

```
{'extensions': ["h", "c", "cpp", "c++"],   " this is a case-insensitive list of file extensions to include
 'sink_function': 'SomeFunction'}          " instead of opening file, pass filename to this vimscript function
```

For example, you could define this binding to find shell scripts:

```
nnoremap <silent> <leader>fb :call fuzzy_recent#Find({'extensions': ["", "bash", "zsh", "tsh", "bat", "cmd"]})<CR>
```

Or define a custom function to add a reference to some file relative to the git root or the current file:

```
function! LinkGitSink(filename) abort
  let l:git_root = systemlist('git rev-parse --show-toplevel')[0]
  let l:relative_path = systemlist('realpath --relative-base="' .. l:git_root .. '" ' .. a:filename)[0]
  call setline('.', getline('.') .. l:relative_path)
endfunction

function! LinkFileSink(filename) abort
  let l:current_file_dir = expand('%:p:h')
  let l:relative_path = systemlist('realpath --relative-base="' .. l:current_file_dir .. '" ' .. a:filename)[0]
  call setline('.', getline('.') .. l:relative_path)
endfunction

nnoremap <silent> <leader>fl :call fuzzy_recent#Find({'sink_function': 'LinkGitSink'})<CR>
nnoremap <silent> <leader>fL :call fuzzy_recent#Find({'sink_function': 'LinkFileSink'})<CR>
```

## Getting Help

See [the issue tracker](https://github.com/TamaMcGlinn/fuzzy-recent/issues) and `:help fuzzy-recent`.
