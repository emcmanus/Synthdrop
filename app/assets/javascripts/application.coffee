#= require jquery
#= require jquery.turbolinks
#= require jquery_ujs
#= require turbolinks
#= require cyborg/loader
#= require cyborg/bootswatch
#= require ace-rails-ap
#= require ace/theme-terminal
#= require ace/mode-coffee
#= require ace/mode-javascript
#= require ace/keybinding-vim
#= require ace/keybinding-emacs
#= require_tree

Turbolinks.enableProgressBar()

$(document).ready ->
  $('[data-toggle="tooltip"]').tooltip()
