# unite-git-repo

This Vim plugin adds the `file_rec/git_repo` source to use with
[Unite.vim](https://github.com/Shougo/unite.vim). It requires
[vimproc.vim](https://github.com/Shougo/vimproc.vim) and `git`.

The difference between the standard `file_rec/git` and the `file_rec/git_repo` added by this plugin
is that `file_rec/git_repo` always works from the repository root instead of the current working
directory. This makes it incredibly useful to switch files inside a project.

Example mapping:

    nmap <silent> <leader>g :Unite -start-insert file_rec/git_repo:--cached:--others:--exclude-standard<CR>
