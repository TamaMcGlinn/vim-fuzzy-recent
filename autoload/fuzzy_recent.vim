" Initialize fzf with a list of loaded buffers and recent files from
" the current directory. If <space> is pressed, we load a list of all
" the files in the current directory
function! fuzzy_recent#Find(options = {})
  let extensions = get(a:options, 'extensions', [])
  let sink_function = get(a:options, 'sink_function', '')

  let regex = '^' . fnamemodify(getcwd(), ":p")
  let buffers = filter(map(
        \ getbufinfo({'buflisted':1}), {_, b -> fnamemodify(b.name, ":p")}),
        \ {_, f -> filereadable(f)}
        \ )
  let recent = filter(
        \ map(copy(v:oldfiles), {_, f -> fnamemodify(f, ":p")}),
        \ {_, f -> filereadable(f) && f =~# regex})
  let combined = <SID>add_unique(buffers, recent)

  " Allow pressing space to return all git tracked files instead
  let reload_command = "git ls-files"
  if l:extensions != []
    let l:no_ext_match = ""
    if match(l:extensions, "^$") >= 0
      let l:no_ext_match = '^[^\.]*$\|'
    endif
    let l:reload_command = l:reload_command . ' | grep "' . l:no_ext_match . '\.\(' . join(l:extensions, '\|') . '\)$"'
  endif
  let options = [
        \ '--bind', 'space:reload:' . l:reload_command, '--multi'
        \ ]

  let files = map(combined, {_, f -> fnamemodify(f, ":~:.")})
  if l:extensions != []
    let l:extensions_stringlist = '[' . join(map(l:extensions, '"\"" .. v:val .. "\""'), ',') . ']'
    let l:filter_expression = 'index(' .. l:extensions_stringlist .. ', substitute(v:val, "^[^\\.]*\\.\\?", "", "")) >= 0'
    let l:files = filter(l:files, l:filter_expression)
  endif
  let fzf_params = {
  \ 'source': l:files,
  \ 'options': options
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

" deduped is a list of items without duplicates, this
" function inserts elements from items into deduped
function! s:add_unique(deduped, items)
  let dict = {}
  for item in a:deduped
    let dict[item] = ''
  endfor

  for f in a:items
    if has_key(dict, f) | continue | endif
    let dict[f] = ''
    call add(a:deduped, f)
  endfor
  return a:deduped
endfunction
