""
" @private
" Returns the full path to the git base directory
" @throws vimignore if this is not a git repository
function! s:FindGitDir()
  if exists('b:git_dir')
    return b:git_dir
  else
    let l:git_dir = system('git rev-parse --git-dir 2>/dev/null')
    if empty(l:git_dir)
      throw 'vimignore'
    endif
    " Strip trailing newline
    let l:git_dir = l:git_dir[:-2]
    return fnamemodify(l:git_dir, ':p:h')
  endif
endfunction

""
" @private
" Figure out the gitignore file and set the global variable
" @throws vimignore if this is not a git repository
function! s:SetGitIgnore()
  " First, figure out if this is a git repo

  " Set current dir (call function to silence output
  let l:cur_dir = system('pwd')
  let l:old_autochdir = &l:autochdir

  " Change into the directory of the current file
  setlocal autochdir

  " Check for Git
  try
    let l:git_dir = s:FindGitDir()
  catch /vimignore/
    exe 'cd ' . l:cur_dir
    echohl ErrorMsg
    echo 'This is not a Git repository'
    echohl NONE
    throw 'vimignore'
  endtry

  let l:root_dir = fnamemodify(l:git_dir, ':h')
  let l:root_ignore = l:root_dir . '/.gitignore'

  if filereadable(l:root_ignore)
    let b:gitignore = l:root_ignore
  else
    " Begin looking for .gitignore
    while !isdirectory('.git')
      if filereadable('.gitignore')
        " If we found a gitignore file here, let's choose it
        let b:gitignore = fnamemodify('.gitignore', ':p')
        exe 'cd ' . l:cur_dir
        break
      else
        " Try one directory up
        cd ..
      endif
    endwhile
  endif

  if !exists('b:gitignore')
    let b:gitignore = l:root_ignore
  endif

  let &l:autochdir = l:old_autochdir
  exe 'cd ' . l:cur_dir
  return 0
endfunction

""
" @private
" Reloads current buffer if this is a git index
function! s:RefreshGitFiles()
  if &filetype == 'gitcommit'
    silent! edit
  endif
endfunction

""
" Reloads all git-status buffers to reflect new changes to the git index
function! vimignore#ReloadGitIndex()
  let l:orig_buf = bufnr('%')
  silent bufdo call s:RefreshGitFiles()
  exe 'buffer ' . l:orig_buf
  " Restore syntax hilighting
  if !empty(&syntax)
    syntax on
  endif
endfunction

""
" @private
" This opens a file based on my preference:
"   * If I don't have a file open currently, open this with |:edit|
"   * If I'm already editing something useful, open this in a split
function! s:OpenIgnoreFile(fname)
  if empty(expand('%'))
    exe 'edit ' . a:fname
  else
    if exists('g:gsplit_pref') && g:gsplit_pref == 1
      let l:make_split = 'vsp'
    else
      let l:make_split = 'split'
    endif
    exe l:make_split . ' ' . a:fname
  endif
endfunction

""
" Open the gitignore file for edit
" Returns 0 on success, nonzero on failure
function! vimignore#EditGitIgnore(bang)
  " If we've already found the gitignore file, use it!
  if !exists('b:gitignore') || !filereadable(b:gitignore)
    try
      let l:ret = s:SetGitIgnore()
    catch /vimignore/
      return 1
    endtry
  endif

  if bufloaded(b:gitignore)
    call s:OpenIgnoreFile(b:gitignore)
  else
    call s:OpenIgnoreFile(b:gitignore)
    if (exists('a:bang') && empty(a:bang))
      set bufhidden=delete
    endif
  endif
  return 0
endfunction

""
" Add several files to the ignore list. If the <bang> is supplied, allow
" duplicates to be added, otherwise don't permit duplicates. If a:silent is
" nonempty, then don't provide any warning output.
function! vimignore#IgnoreFiles(bang, silent, ...)
  let l:win_pos = winsaveview()
  let l:orig_winnr = winnr()
  let l:orig_bufname = expand('%')

  silent call vimignore#EditGitIgnore('')
  let l:old_cursor = getpos('.')
  normal! G
  let l:num_duplicates = 0
  if empty(a:bang)
    for l:fname in a:000
      if empty(system('git check-ignore ' . l:fname))
        put=l:fname
      else
        let l:num_duplicates += 1
      endif
    endfor
  else
    " Don't check for duplicates
    for l:fname in a:000
      put=l:fname
    endfor
  endif

  call setpos('.', l:old_cursor)
  silent write

  " Jump back to original buffer
  if empty(l:orig_bufname)
    enew
  else
    hide
    exe l:orig_winnr . 'wincmd w'
    call winrestview(l:win_pos)
  endif

  call vimignore#ReloadGitIndex()

  " If we detected any duplicates, let's provide a warning
  if l:num_duplicates > 0 && empty(a:silent)
    echohl WarningMsg
    echon 'Warning: '
    if l:num_duplicates == a:0 && l:num_duplicates == 1
      echon 'Your file was'
    elseif l:num_duplicates == a:0
      echon 'Your files were'
    else
      echon l:num_duplicates . '/' . a:0 . ' files were'
    endif
    echon ' already being ignored'
    echohl NONE
  endif
endfunction
