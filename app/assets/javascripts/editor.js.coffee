# -
class ScriptRunner
  constructor: ->

  run: (content) ->
    @killWorker()

    script = CoffeeScript.compile(content, bare: true)
    blob = new Blob([script])
    current_worker = new Worker(URL.createObjectURL(blob))
    current_worker.onerror = @_workerError

  _workerError: (error) ->
    console.log "#{error.message}. Line #{error.lineno}"
    console.log error
    error.preventDefault()

  killWorker: ->
    if @current_worker
      @current_worker.terminate()


# -
class EditorBuilder
  constructor: (@editorElement) ->
    ace.config.set('workerPath', '/assets/ace')

    @editor = editor = ace.edit("editor")
    editor.setTheme("ace/theme/terminal")
    editor.setKeyboardHandler("ace/keyboard/vim")
    editor.getSession().setMode("ace/mode/coffee")
    editor.getSession().setUseSoftTabs(true)
    editor.getSession().setTabSize(2)
    editor.$blockScrolling = Infinity # Disable deprecation warning

    @editorElement.show()
    @_addListeners()
    @_configureCommands()

  updateContent: (data) ->
    @editor.setValue data, -1
    @editor.focus()

  resize: ->
    @editor.resize()

  _addListeners: ->
    @editor.on "blur", =>
      @editorElement.addClass('blur')

    @editor.on "focus", =>
      @editorElement.removeClass('blur')

  _configureCommands: ->
    @editor.commands.removeCommand("gotoline")

    # Don't interpret Esc to mean blur - annoying in Vim insert mode
    @editor.commands.addCommand({
      name: 'Esc'
      bindKey: {win: 'Esc',  mac: 'Esc'}
      exec: (editor) ->
        editor.focus()
    })

    @editor.commands.addCommand({
      name: 'Run'
      bindKey: {win: 'Ctrl-Enter',  mac: 'Command-Enter'}
      readOnly: true
      exec: (editor) ->
        scriptRunner.run(editor.getValue())
    })

    @editor.commands.addCommand({
      name: 'Save'
      bindKey: {win: 'Ctrl-s',  mac: 'Command-s'}
      readOnly: true
      exec: (editor) =>
        url = @editorElement.data('update-url')
        $.ajax( url, method: "PUT", data: {
          'authenticity_token': @editorElement.data('authenticity_token')
          'script[content]': editor.getValue()
        }).fail((request, status, error) ->
          console.log "Failed with #{status}: #{error}"
        ).done( ->
          console.log "Done"
        )
    })


#
# Start of execution
#

scriptRunner = new ScriptRunner()

$(document).ready ->
  if editorElement = $('#editor')
    editorBuilder = new EditorBuilder($('#editor'))
    editorBuilder.resize()
    
    updateEditorHeight = ->
      margin = editorElement.outerHeight(true) - editorElement.height()
      editorElement.height($(window.document).height() - $('nav').outerHeight(true) - margin)
      editorBuilder.resize()

    updateEditorHeight()
    $(window).resize updateEditorHeight

    # Load and edit remote script
    resource_url = editorElement.data('content-url')
    if resource_url
      $.ajax url: resource_url, success: (data) ->
        editorBuilder.updateContent(data)
