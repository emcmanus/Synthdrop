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

  editor.commands.addCommand({
    name: 'Run'
    bindKey: {win: 'Ctrl-Enter',  mac: 'Command-Enter'}
    readOnly: true
    exec: (editor) ->
      f = new Function CoffeeScript.compile(editor.getValue(), bare: true)
      f.call(window)
  })

  editor.commands.addCommand({
    name: 'Save'
    bindKey: {win: 'Ctrl-s', mac: 'Command-s'}
    exec: (editor) ->
      name = window.prompt "Enter a script name, e.g. com-lib-awesome-synth", ""

      if name?.length > 0
        fb = firebase.child('scripts').push()
        fb.set({
          name: name
          data: editor.getValue()
        }, ->
          loc = fb.ref().toString()
          scriptId = loc.substr(loc.lastIndexOf('/') + 1)
          window.location.hash = scriptId
        )
      else
        alert "Please enter a name"
  })

  updateEditorHeight = ->
    editorElement = $('#editor')
    margin = editorElement.outerHeight(true) - editorElement.height()
    editorElement.height($(window.document).height() - $('nav').outerHeight(true) - margin)
    editor.resize()

  updateEditorHeight()
  $(window).resize updateEditorHeight
