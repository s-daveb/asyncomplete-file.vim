let s:forbidden_patterns = [
\ '/*', '*/',
\ '</',
\ 'http:', 'https', 'ftp://', 'sftp://', 'scp://',
\ '/net',
\]

let s:async_file_debug = 1

function! s:debug_print(function, string)
	if s:async_file_debug != 0
		call asyncomplete#log("file-debug", a:function, a:string)
	endif
endfunction


function! s:check_forbidden_patterns(string)
  for l:pattern in s:forbidden_patterns
    if matchstr(a:string, l:pattern) == l:pattern
      return 1
    endif
  endfor
  return 0
endfunction

" Maps available filenames to type (file vs dir)
function! s:filename_map(prefix, file) abort
  let l:abbr = fnamemodify(a:file, ':t')
  let l:word = a:prefix . l:abbr

  if isdirectory(a:file)
    let l:menu = '[dir]'
    let l:abbr = '/' . l:abbr
  else
    let l:menu = '[file]'
    let l:abbr = l:abbr
  endif

  return {
        \ 'menu': l:menu,
        \ 'word': l:word,
        \ 'abbr': l:abbr,
        \ 'icase': 1,
        \ 'dup': 0
        \ }
endfunction

function! s:extract_final_word(typed)
	" Get the current line and strip leading whitespace
	let l:currentLine = substitute(a:typed, '^\s*', '', 'g')

	call s:debug_print("extract_final_word", "l:currentLine: " . l:currentLine)

	" Use an optimized regex to directly capture the final word, excluding preceding characters
	" This regex looks for the last segment of alphanumerics, hyphens, or underscores that follow
	" any non-word character or start of line, without including the delimiter in the match.
	"let l:pattern = '\v(\s|''|"|[|{|(|<|]^)\zs(\w|[-_])+$'
	let l:pattern = '\v^([^(\[{<]*)(\(|\[|\{|<|<\/)?([^\]\)}>]*)'
	let l:finalWord = matchstr(l:currentLine, l:pattern)

	call s:debug_print("extract_final_word", "l:finalWord: " . l:finalWord)
	" Return the final word
	return l:finalWord
endfunction

" Asymcomplete calls this for reach completion
function! asyncomplete#sources#file#completor(opt, ctx)
  let l:bufnr = a:ctx['bufnr']
  let l:typed = a:ctx['typed']
  let l:col   = a:ctx['col']

  let l:keyword =  s:extract_final_word(l:typed)
  let l:keyword_len = len(l:keyword)

	call s:debug_print( "asycomplete#sources#file#completor", "l:typed=" . l:typed .  "  l:keyword="  . l:keyword)

  let l:sep = '/'
  if has('win32')
    let l:sep = '\\'
  endif

  if l:keyword_len < 1
    return
  endif

  " Check for potentially deliterious patterns
  if s:check_forbidden_patterns(l:keyword)
    return
  endif

  " if the path is not absolute (/) or $HOME paths (~), convert it to absolute
  if l:keyword !~ '^\(/\|\~\)'
    let l:absolute_filepath = expand('#' . l:bufnr . ':p:h') . l:sep . l:keyword
  else
    let l:absolute_filepath = l:keyword
  endif

  if has('win32')
    let l:glob = fnamemodify(l:absolute_filepath, ':t') . '*'
  else
    let l:glob = fnamemodify(l:absolute_filepath, ':t') . '.\=[^.]*'
  endif
  let l:search_root  = fnamemodify(l:absolute_filepath, ':p:h')

  let l:search_prefix  = fnamemodify(l:keyword, ':h')
  let l:result_prefix = l:search_prefix

  " If the file search did not start with ., then leave it out in the
  " completion.  Set result_prefix to blank
  if l:result_prefix == '.' && l:keyword !~ '^\.'
    let l:result_prefix = ''
  endif

  " Append a / to the result prefix if it's not blank
  if !empty(l:result_prefix)
    let l:result_prefix = l:result_prefix . l:sep
  endif

  " Get the list of file
  "  map each file name to its filetype info
  "  and sort
  let l:files    = split(globpath(l:search_root, l:glob), '\n')
  let l:unsorted_matches  = map(l:files, {key, val -> s:filename_map(l:result_prefix, val)})
  let l:matches  = sort(l:unsorted_matches, function('s:sort'))

  " use the completion engine to display the found files at the correct
  " location
  call asyncomplete#complete(a:opt['name'], a:ctx, l:col - l:keyword_len, l:matches)
endfunction

function! asyncomplete#sources#file#get_source_options(opts)
  return extend(extend({}, a:opts), {
        \ 'name': 'file',
        \ 'triggers': {'*': ['\.','\.\','/']}
        \ })
endfunction

function! s:sort(item1, item2) abort
  if a:item1.menu ==# '[dir]' && a:item2.menu !=# '[dir]'
    return -1
  endif
  if a:item1.menu !=# '[dir]' && a:item2.menu ==# '[dir]'
    return 1
  endif
  return 0
endfunction

" vim: set ts=2 sts=2 noet sw=2 :
