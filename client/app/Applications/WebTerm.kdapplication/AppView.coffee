class WebTermView extends KDView
  viewAppended: ->
    @container = new KDView
      cssClass : "console"
    @addSubView @container
    
    @terminal = new WebTerm.Terminal @container.$(), (sessions) =>
      keys = Object.keys sessions
      keys.sort (a, b) ->
        if sessions[a] < sessions[b]
          -1
        else if sessions[a] > sessions[b]
          1
        else
          0
      @sessionList.empty()
      for key in keys
        @sessionList.addItem
          id: parseInt(key)
          name: sessions[key]
          mainView: this
      @sessionBox.show()
    
    @sessionBox = new KDView
      cssClass: "kddialogview"
      position:
        top: 10
        left: 10
    @sessionBox.hide()
    @addSubView @sessionBox
    
    label = new KDLabelView
      title: "Select session:"
    @sessionBox.addSubView label

    @sessionList = new KDListView
      subItemClass: WebTermSessionItem
    @sessionBox.addSubView @sessionList
    
    label = new KDLabelView
      title: "Create session with name:"
    @sessionBox.addSubView label
    
    sessionNameInput = new KDInputView
      label: label
      defaultValue: (new Date).format "yyyy-mm-dd HH:MM:ss"
    @sessionBox.addSubView sessionNameInput
    
    createSessionButton = new KDButtonView
      title: "Create"
      callback: =>
        @sessionBox.hide()
        @terminal.createSession sessionNameInput.getValue()
        @setKeyView()
    @sessionBox.addSubView createSessionButton
    
    @listenWindowResize()
  
  click: ->
    @setKeyView()
    
  keyDown: (event) ->
    @terminal.keyDown event
  
  keyPress: (event) ->
    @terminal.keyPress event
  
  keyUp: (event) ->
    @terminal.keyUp event
  
  _windowDidResize: (event) ->
    @terminal.updateSize()

class WebTermSessionItem extends KDListItemView
  constructor: (options = {},data) ->
    super options, data
  
  partial: (data) ->
    link = $(document.createElement("a"))
    link.text data.name
    link.attr "href", "#"
    link.bind "click", (event) =>
      data.mainView.sessionBox.hide()
      data.mainView.terminal.joinSession data.id
      event.preventDefault()
    link