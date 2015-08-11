# FIXME - The listeners probably cause this to leak when used over multiple
# documents.


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

#
# -
class ScriptSaver
  constructor: ->
    @dirty = false
    @dirty_since = undefined
    @working = false

  setBuilder: (@editorBuilder) ->
    @_reset()

    @editor = @editorBuilder.getEditor()
    @editorElement = @editorBuilder.getEditorElement()

    @editor.on "change", =>
      @_markDirty()

  _reset: ->
    if @current_timer
      window.clearInterval @current_timer
    @current_timer = window.setInterval @_checkDirty, 500

  _markDirty: =>
    @dirty = true
    @dirty_since = new Date

  _markClean: =>
    @dirty = false
    @dirty_since = undefined

  _dirtyElapsed: =>
    if @dirty_since
      new Date - @dirty_since
    else
      0

  _checkDirty: =>
    if @_dirtyElapsed() >= 2000
      $('#slow-load-notice').fadeIn()
    else
      $('#slow-load-notice').fadeOut()

    if @dirty && !@working
      @working = true
      @_startSave().always =>
        @working = false

  _startSave: =>
    requestData ={ 'authenticity_token': @editorElement.data('authenticity_token'), 'script[content]': @editor.getValue() }
    $.ajax( @editorElement.data('update-url'), method: "PUT", data: requestData ).done =>
      @_markClean()

# -
class EditorBuilder
  constructor: (@editorElement) ->
    @language = @editorElement.data('language')
    @keyboard = @editorElement.data('keyboard')

    ace.config.set('workerPath', '/assets/ace')

    @editor = editor = ace.edit("editor")
    editor.setTheme("ace/theme/terminal")

    switch @keyboard
      when 'vim'
        editor.setKeyboardHandler("ace/keyboard/vim")
      when 'emacs'
        editor.setKeyboardHandler("ace/keyboard/emacs")

    switch @language
      when 'coffeescript'
        editor.getSession().setMode("ace/mode/coffee")
      when 'javascript'
        editor.getSession().setMode("ace/mode/javascript")

    editor.getSession().setUseSoftTabs(true)
    editor.getSession().setTabSize(2)
    editor.$blockScrolling = Infinity # Disable deprecation warning

    @_addListeners()
    @_configureCommands()

    if window.yieldEditor
      window.yieldEditor(editor)

  updateContent: (data) ->
    @editorElement.removeClass('unloaded')
    @editor.setValue data, -1
    @editor.focus()

  resize: ->
    @editor.resize()

  getEditor: ->
    @editor

  getEditorElement: ->
    @editorElement

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
      exec: (editor) ->
        alert "Saves are automatic."
    })


#
# Start of execution
#

scriptRunner = new ScriptRunner()
scriptSaver = new ScriptSaver()

$(document).ready ->
  if (editorElement = $('#editor')).length > 0
    editorBuilder = new EditorBuilder(editorElement)
    editorBuilder.resize()

    unless editorElement.hasClass("demo")
      updateEditorHeight = ->
        margin = editorElement.outerHeight(true) - editorElement.height()
        editorElement.height($(window.document).height() - $('nav').outerHeight(true) - margin)
        editorBuilder.resize()

      updateEditorHeight()
      $(window).resize updateEditorHeight

    # Wait until we've updated the editor contents before attaching the
    # scriptSaver. The script saver will otherwise act on the change event and
    # issue a PUT to the server when it's not necessary. That's not normally
    # a huge problem, but if you hit back in the browser it's possible to
    # restore the text field to an earlier state, and then save THAT as the
    # latest version of the document, losing lots of work!
    resource_url = editorElement.data('content-url')
    if resource_url
      $.ajax url: resource_url, success: (data) ->
        editorBuilder.updateContent(data)
        scriptSaver.setBuilder(editorBuilder)

    else
      editorBuilder.updateContent("")
      scriptSaver.setBuilder(editorBuilder)

