module.exports = class Interpreter
  commandRegExes   : {}
  directionRegExes : {}
  texts = []

  directions:
    left:
      text: ['left']
    right:
      text: ['right']
    front:
      text: ['forward','forwards']
    back:
      text: ['back','backwards']
    up:
      text: ['up']
    down:
      text: ['down']

  commands:
    fly:
      params: ['direction', 'duration']
      text: ['fly']
    takeoff:
      text: ['takeoff', 'take\\ off', 'start']
    land:
      text: ['land']
    reset:
      text: ['reset']
    rotate:
      params: ['direction', 'duration']
      text: ['rotate', 'turn']
    flip:
      params: ['direction']
      text: ['flip', 'loop']
  
  constructor: (@drone) ->
    throw new Error("I need a drone!") unless @drone

    for command, obj of @commands
      reg = "(#{obj.text.join('|')})"
      reg += '\\s([\\w]+)'                    if obj.params and 'direction' in obj.params
      reg += '\\sfor\\s([\\w]+)\\ssecond(s?)' if obj.params and 'duration' in obj.params

      @commandRegExes[command] = RegExp reg

    for direction, obj of @directions
      @directionRegExes[direction] = "(#{obj.text.join('|')})"


  interpret: (text) ->    
    @texts = text.split('then')
    @_popFirstCommand()    
    return texts.length > 0;

  fly: (direction, duration=1, callback) ->
    console.log("flying #{direction} for #{duration}")
    @drone.after(0, ->
      @[direction](0.4)
      @animateLeds('redSnake', 5, 2)
    ).after(duration * 1000, ->
      @stop()
      callback?()
    )
    return true

  rotate: (direction, duration, callback) ->
    @drone.after(0, ->
      switch direction
        when 'left'
          @counterClockwise(0.7)
        when 'right'
          @clockwise(0.7)
    ).after(duration * 1000, ->
      @stop()
      callback?()
    )  
    
    
  flip: (direction, callback) ->
    switch direction
      when 'left'
        @drone.animate('flipLeft', 1500)        
      when 'right'
        @drone.animate('flipRight', 1500)
      when 'front'
        @drone.animate('flipAhead', 1500)
      when 'back'
        @drone.animate('flipBehind', 1500)
      else
        return false
    callback?()
    return true        
    
  stop: (callback) ->
    console.log('Stop')
    @drone.stop(callback)    
   
  takeoff: (callback) ->
    console.log('Taking off')
    @drone.takeoff(callback)
    @drone.animateLeds('redSnake', 5, 2)
    true
    
  land: ->
    console.log('Land')
    @drone.land()
    @drone.animateLeds('redSnake', 5, 2)
    true
    
  
  _popFirstCommand: =>    
    text = @texts[0]
    @texts.shift()
    for command, expression of @commandRegExes
      if matches = expression.exec text
        if params = @_matchParams(command, matches)
          return @[command](params..., @_popFirstCommand)
        else
          console.log "invalid statement"
          return false

  _matchParams: (command, matches) ->
    return [] if typeof @commands[command].params is 'undefined'
    params = []
    for paramName, index in @commands[command].params
      switch paramName
        when 'direction'
          if direction = @_matchDirection(matches[index+2])
            params.push direction
          else
            return false
        when 'duration'
          if duration = @_matchDuration(matches[index+2])
            params.push duration
          else
            return false
    return params
    
  _matchDirection: (text) ->
    for direction, expression of @directionRegExes
      return direction if expression.match text
    return false

  _matchDuration: (text) ->
    strings = ['one','two','three','four','five','six','seven','eight','nine','ten']
    if (int = parseInt(text, 10)) and not isNaN(int)
      return int
    else if text in strings
      return strings.indexOf(text) + 1
    else
      return false
  
