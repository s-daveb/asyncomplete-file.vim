# asyncomplete-file.vim

Filename completion source for [asyncomplete.vim](https://github.com/prabirshrestha/asyncomplete.vim)

## Installing

```vim
Plug 'prabirshrestha/asyncomplete.vim'
Plug 's-daveb/asyncomplete-file.vim'
```

## Register asyncomplete-file.vim

```vim
au User asyncomplete_setup call asyncomplete#register_source(asyncomplete#sources#file#get_source_options({
    \ 'allowlist': ['*'],
    \ 'priority': 10,
    \ 'completor': function('asyncomplete#sources#file#completor')
    \ }))
```
