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
    @language = @editorElement.data('language')
    @keyboard = @editorElement.data('keyboard')

    ace.config.set('workerPath', '/assets/ace')

    @editor = editor = ace.edit("editor")
    editor.setTheme("ace/theme/terminal")

    if @keyboard == 'vim'
      editor.setKeyboardHandler("ace/keyboard/vim")

    if @language == 'coffeescript'
      editor.getSession().setMode("ace/mode/coffee")
    else
      editor.getSession().setMode("ace/mode/javascript")

    editor.getSession().setUseSoftTabs(true)
    editor.getSession().setTabSize(2)
    editor.$blockScrolling = Infinity # Disable deprecation warning

    @_addListeners()
    @_configureCommands()

  updateContent: (data) ->
    @editorElement.removeClass('unloaded')
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
  if (editorElement = $('#editor')).length > 0
    editorBuilder = new EditorBuilder($('#editor'))
    editorBuilder.resize()

    unless editorElement.hasClass("demo")
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
    else
      editorBuilder.updateContent("")
