let s:save_cpo = &cpo
set cpo&vim

" Inherit from file_rec/git.
let s:git_root = deepcopy(unite#sources#rec#define()[4])
let s:git_root['name'] = 'file_rec/git_root'
let s:git_root['description'] = 'candidates from git repository recursive'

function! unite#sources#git_root#define()
    return s:git_root
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo
