# FIXME - The listeners probably cause this to leak when used over multiple
# documents.

# TODO - Migrate to event system for much of this


SAVE_WARNING_THRESHOLD = 3000

AUDIO_BUFFER_SIZE = 2048
SAMPLE_RATE = 44100

# -
class ScriptRunner
  constructor: ->
    @_nextAudioBuffer = []
    @_samplesGenerated = 0
    @_audioStarted = false

  play: (compiledSource) ->
    @_killWorker()
    setEditorControlPlayState(true)

    blob = new Blob([compiledSource])

    @current_worker = new Worker(URL.createObjectURL(blob))
    @current_worker.onerror = @_workerError
    @current_worker.onmessage = @_workerMessage

    if window.yieldWorker
      window.yieldWorker(@current_worker)

    @_buildNextFrame()

  stop: ->
    @_killWorker()
    @_stopAudio()
    setEditorControlPlayState(false)

  _workerMessage: (message) =>
    switch message.data[0]
      when "buffer"
        @_nextAudioBuffer = message.data[1]
        @_startAudio() unless @_audioStarted
      when "log"
        console.log message.data[1]
      else
        console.log "Worker message received. Arguments:"
        console.log message.data

  _workerError: (error) =>
    console.log "Worker Error: #{error.message}. Line #{error.lineno}"
    console.log error
    error.preventDefault()

  _killWorker: ->
    if @current_worker
      @current_worker.terminate()

  _startAudio: ->
    @_audioStarted = true
    context = new (window.AudioContext || window.webkitAudioContext)()
    @_source = context.createScriptProcessor(AUDIO_BUFFER_SIZE, 0, 1)
    @_source.onaudioprocess = (event) =>
      buffer = event.outputBuffer
      outData = buffer.getChannelData(0)
      if @_nextAudioBuffer.length > 0
        for i in [0...buffer.length]
          outData[i] = @_nextAudioBuffer[i]
      else
        console.log "MISSED A BUFFER. This may mean your script is not fast enough to process audio in realtime, or could be the result of some other bug."
      @_nextAudioBuffer = []
      @_buildNextFrame()
    @_source.connect(context.destination)

  _stopAudio: ->
    try
      @_source.disconnect()
    @_audioStarted = false

  _buildNextFrame: ->
    @current_worker.postMessage(["generate", @_samplesGenerated, AUDIO_BUFFER_SIZE, SAMPLE_RATE])
    @_samplesGenerated += AUDIO_BUFFER_SIZE



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

  compiledSource: (suppressWarning) ->
    content = @editor.getValue()
    switch @editorElement.data('language')
      when 'coffeescript'
        try
          CoffeeScript.compile(content, bare: true)
        catch error
          alert "Unable to compile track. Open your browser's Javascript console for more details.\n\n#{error.toString()}" unless suppressWarning
          console.log "Error compiling track"
          console.log error.toString()
          console.log error
          undefined
      else
        content

  _reset: ->
    if @current_timer
      window.clearInterval @current_timer
    @current_timer = window.setInterval @_checkDirty, 250

  _markDirty: =>
    @dirty = true
    @dirty_since = new Date
    $('#saving-notice').show()

  _markClean: =>
    @dirty = false
    @dirty_since = undefined
    $('#saving-notice').hide()

  _dirtyElapsed: =>
    if @dirty_since
      new Date - @dirty_since
    else
      0

  _checkDirty: =>
    if @_dirtyElapsed() >= SAVE_WARNING_THRESHOLD
      $('#slow-load-notice').fadeIn()
    else
      $('#slow-load-notice').fadeOut()

    if @dirty && !@working
      @working = true
      @_startSave().always =>
        @working = false

  _startSave: =>
    requestData ={
      'authenticity_token': @editorElement.data('authenticity_token')
      'script[content]': @editor.getValue()
    }
    requestData['script[compiled_content]'] = compiled if compiled = @compiledSource(true)
    $.ajax( @editorElement.data('update-url'), method: "PUT", data: requestData ).done =>
      @_markClean()


scriptRunner = new ScriptRunner()
scriptSaver = new ScriptSaver()

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

  isDemo: ->
    @editorElement.hasClass('demo')

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
        scriptRunner.play(scriptSaver.compiledSource())
    })

    @editor.commands.addCommand({
      name: 'Stop'
      bindKey: {win: 'Ctrl-.',  mac: 'Command-.'}
      readOnly: true
      exec: (editor) ->
        scriptRunner.stop()
    })

    @editor.commands.addCommand({
      name: 'Save'
      bindKey: {win: 'Ctrl-s',  mac: 'Command-s'}
      readOnly: true
      exec: (editor) =>
        unless @isDemo()
          scriptSaver._markDirty()
    })

# TODO - move to event system
showEditorControls = ->
  $('#play-btn, #save-btn').show()

hideEditorControls = ->
  $('#play-btn, #stop-btn, #save-btn').hide()

setEditorControlPlayState = (playing) ->
  if playing
    $('#play-btn').hide()
    $('#stop-btn').show()
  else
    $('#play-btn').show()
    $('#stop-btn').hide()

#
# Start of execution
#

$(document).ready ->
  if (editorElement = $('#editor')).length > 0
    editorBuilder = new EditorBuilder(editorElement)
    editorBuilder.resize()

    unless editorBuilder.isDemo()
      updateEditorHeight = ->
        margin = editorElement.outerHeight(true) - editorElement.height()
        editorElement.height($(window.document).height() - $('nav').outerHeight(true) - margin)
        editorBuilder.resize()

      updateEditorHeight()
      $(window).resize updateEditorHeight

    hideEditorControls()
    $('#play-btn').click ->
      editorBuilder.getEditor().execCommand('Run')
    $('#stop-btn').click ->
      editorBuilder.getEditor().execCommand('Stop')
    $('#save-btn').click ->
      editorBuilder.getEditor().execCommand('Save')

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
        showEditorControls()
    else
      editorBuilder.updateContent("")
      scriptSaver.setBuilder(editorBuilder)
      showEditorControls()

