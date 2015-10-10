""
" @section Introduction, intro
" @stylized Vimignore
" @order Introduction fugitive-integration commands
"
" I came up with the idea for this plugin when I was working on various projects
" with partners and would need to reconfigure the gitignore file for the
" project. I had to do this often enough that I felt that it should flow more
" natively in vim.
"
" I decided to make this plugin to facilitate the process. @plugin(stylized)
" offers a few different commands for making sure the appropriate files are
" ignored.

""
" @section Fugitive Integration
"
" The best way to use this plugin is in conjunction with Tim Pope's fugitive
" plugin (www.github.com/tpope/vim-fugitive). In particular, when using the
" |:Gstatus| command, @plugin(stylized) adds a mapping on I.
"
" Press 'I' when viewing the git index (|:Gstatus| window) to add the file on
" the current line to the gitignore list and update the git index accordingly.

""
" @private
" This is my function. There are many like it, but this one is mine
function! s:GIgnoreFileOnLine()
  let l:line_text = getline('.')
  let l:fname = matchstr(l:line_text, '\S\+$')
  call vimignore#IgnoreFile(l:fname)
endfunction

""
" Find and open the appropriate .gitignore file for editing.
"
" Note: unless this file is already open, this will set 'bufhidden' to delete.
command! -nargs=0 GEditIgnore call vimignore#EditGitIgnore()

""
" Append the current file to the .gitignore list. This internally uses the
" |:GEditIgnore| command, so be aware of side effects due to compatibility
" issues with the 'hidden' option.
command! -nargs=0 GIgnoreCurrentFile call vimignore#IgnoreFile(expand('%'))

""
" @usage {filename}
" Add {filename} to the .gitignore list.
command! -nargs=1 -complete=file GAddToIgnore call vimignore#IgnoreFile(<f-args>)

""
" @private
" Set mappings for when we're in a gitcommit file
" This is for fugitive integration with :Gstatus
function! s:SetCommitMappings()
  nnoremap <buffer> <silent> I :call <SID>GIgnoreFileOnLine()<CR>
endfunction

""
" Set filetype mappings
augroup vimignore
  autocmd!
  autocmd FileType gitcommit call s:SetCommitMappings()
augroup END
