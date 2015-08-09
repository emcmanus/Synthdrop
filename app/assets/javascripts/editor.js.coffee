$(document).ready ->
  $("#editor").show()

  ace.config.set('workerPath', '/assets/ace')
  editor = ace.edit("editor")
  editor.setTheme("ace/theme/terminal")
  editor.setKeyboardHandler("ace/keyboard/vim")
  editor.getSession().setMode("ace/mode/coffee")
  editor.getSession().setUseSoftTabs(true)
  editor.getSession().setTabSize(2)
  editor.focus()

  editor.commands.removeCommand("gotoline")

  # Don't interpret Esc to mean blur - annoying in Vim insert mode
  editor.commands.addCommand({
    name: 'Esc'
    bindKey: {win: 'Esc',  mac: 'Esc'}
    exec: (editor) ->
      editor.focus()
  })

  editor.commands.addCommand({
    name: 'Run'
    bindKey: {win: 'Ctrl-Enter',  mac: 'Command-Enter'}
    readOnly: true
    exec: (editor) ->
      f = new Function CoffeeScript.compile(editor.getValue(), bare: true)
      f.call(window)
  })

  updateEditorHeight = ->
    editorElement = $('#editor')
    margin = editorElement.outerHeight(true) - editorElement.height()
    editorElement.height($(window.document).height() - $('nav').outerHeight(true) - margin)
    editor.resize()

  updateEditorHeight()
  $(window).resize updateEditorHeight
