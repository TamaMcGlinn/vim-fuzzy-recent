" Initialize fzf with a list of loaded buffers and recent files from
" the current directory. If <space> is pressed, we load a list of all
" the files in the current directory
function! fuzzy_recent#Find(options = {})
  let extensions = get(a:options, 'extensions', [])
  let sink_function = get(a:options, 'sink_function', '')

  let regex = '^' . fnamemodify(getcwd(), ":p")
  let bufs = getbufinfo({'buflisted':1})
        \ ->reduce({d, b -> extend(d, {b.name:b.lastused})}, {})
  let recent = copy(v:oldfiles)
        \ ->filter({_, f -> f =~# regex && !has_key(bufs, f)})
  let combined = items(bufs)
        \ ->sort({a, b -> b[1] - a[1]})
        \ ->map({_, l -> l[0]})
        \ ->extend(recent)
        \ ->filter({_, f -> filereadable(f)})
        \ ->map({_, f -> fnamemodify(f, ":~:.")})

  let reload_command = "find . -type f"
  if l:extensions != []
    let l:no_ext_match = ""
    if match(l:extensions, "^$") >= 0
      let l:no_ext_match = '^[^\.]*$\|'
    endif
    let l:reload_command = l:reload_command . ' | grep "' . l:no_ext_match . '\.\(' . join(l:extensions, '\|') . '\)$"'
  endif
  let path = getcwd()->fnamemodify(":~:.")->pathshorten() . "/"
  let recent_files_prompt = "(Recent Files) " . path
  let all_files_prompt = "(All Files) " . path
  let reload_handler = 'reload(' .. l:reload_command .. ')+unbind(zero)+unbind(space)+change-prompt(' . all_files_prompt . ')'

  " --hscroll-off=<very large value> ensures that if the file names
  " are long, we see the right end of the name rather than the left
  " --tiebreak=index prevents matches for constantly getting reordered
  " due to matching score and just maintains the list's ordering
  " Keybindings:
  " [+] Pressing <Space> goes from recent files to all files list
  " [+] If no match is found in recent files, all files are loaded
  " [+] Pressing ' toggles between exact and fuzzy matching
  let options = [
        \ '--multi',
        \ '--no-scrollbar',
        \ '--no-separator',
        \ '--info', 'inline',
        \ '--scheme', 'path',
        \ '--tiebreak', 'index',
        \ '--keep-right',
        \ '--hscroll-off', '100000',
        \ '--bind', 'change:top',
        \ '--bind', 'space:' . reload_handler,
        \ '--bind',  'zero:' . reload_handler,
        \ '--bind', "':transform-query(sed s/^\\'\\'// <<< \\'{q})",
        \ '--prompt', recent_files_prompt,
        \ ]

  " filter by extension
  let files = map(combined, {_, f -> fnamemodify(f, ":~:.")})
  if l:extensions != []
    let l:extensions_stringlist = '[' . join(map(l:extensions, '"\"" .. v:val .. "\""'), ',') . ']'
    let l:filter_expression = 'index(' .. l:extensions_stringlist .. ', substitute(v:val, "^[^\\.]*\\.\\?", "", "")) >= 0'
    let l:files = filter(l:files, l:filter_expression)
  endif

  let fzf_params = {
  \ 'source': l:files,
  \ 'options': options,
  \ 'down': '40%',
  \ }
  if l:sink_function != ''
    let fzf_params['sink'] = function(l:sink_function)
  endif
  call fzf#run(fzf#wrap(l:fzf_params))
endfunction

" https://vi.stackexchange.com/a/29063/18875
fu! s:ends_with(longer, shorter) abort
  return a:longer[len(a:longer)-len(a:shorter):] ==# a:shorter
endfunction
