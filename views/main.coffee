main = ()->
  source = original.value
  try
    result = JSON.stringify(parse(source), null, 2)
  catch result
    result = """<div class="error">#{result}</div>"""

  OUTPUT.innerHTML = result

window.onload = ()->
  PARSE.onclick = main

Object.constructor::error = (message, t) ->
  t = t or this
  t.name = "SyntaxError"
  t.message = message
  throw treturn

RegExp::bexec = (str) ->
  i = @lastIndex
  m = @exec(str)
  return m if m and m.index is i
  null

String::tokens = ->
  from = undefined # The index of the start of the token.
  i = 0 # The index of the current character.
  n = undefined # The number value.
  m = undefined # Matching
  result = [] # An array to hold the results.
  tokens =
    WHITES: /\s+/g
    ID: /[a-zA-Z_]\w*/g
    NUM: /\b\d+(\.\d*)?([eE][+-]?\d+)?\b/g
    STRING: /('(\\.|[^'])*'|"(\\.|[^"])*")/g
    ONELINECOMMENT: /\/\/.*/g
    MULTIPLELINECOMMENT: /\/[*](.|\n)*?[*]\//g
    COMPARISONOPERATOR: /[<>=!]=|[<>]/g
    ONECHAROPERATORS: /([-+*\/=()&|;:,{}[\]])/g
    ADDOP: /([+-])/g
    MULTOP: /[*\/]/g

  RESERVED_WORD =
    p: "P"
    "if": "IF"
    then: "THEN"
    "while": "WHILE"
    "do": "DO"
    call: "CALL"
    begin: "BEGIN"
    end: "END"
    "const": "CONST"
    "var": "VAR"
    procedure: "PROCEDURE"

  
  # Make a token object.
  make = (type, value) ->
    type: type
    value: value
    from: from
    to: i

  getTok = ->
    str = m[0]
    i += str.length # Warning! side effect on i
    str

  
  # Begin tokenization. If the source string is empty, return nothing.
  return unless this
  
  # Loop through this text
  while i < @length
    for key, value of tokens
      value.lastIndex = i

    from = i
    
    # Ignore whitespace and comments
    if m = tokens.WHITES.bexec(this) or
           (m = tokens.ONELINECOMMENT.bexec(this)) or
           (m = tokens.MULTIPLELINECOMMENT.bexec(this))
      getTok()
    
    # name.
    else if m = tokens.ID.bexec(this)
      rw = RESERVED_WORD[m[0]]
      if rw
        result.push make(rw, getTok())
      else
        result.push make("ID", getTok())
    
    # number.
    else if m = tokens.NUM.bexec(this)
      n = +getTok()
      if isFinite(n)
        result.push make("NUM", n)
      else
        make("NUM", m[0]).error "Bad number"
    
    # string
    else if m = tokens.STRING.bexec(this)
      result.push make("STRING", getTok().replace(/^["']|["']$/g, ""))
    
    # comparison operator
    else if m = tokens.COMPARISONOPERATOR.bexec(this)
      result.push make("COMPARISON", getTok())
      
    # ADDOP operator
    else if m = tokens.ADDOP.bexec(this)
      result.push make("ADDOP", getTok())

    # MULTOP operator
    else if m = tokens.MULTOP.bexec(this)
      result.push make("MULTOP", getTok())
      
    # single-character operator
    else if m = tokens.ONECHAROPERATORS.bexec(this)
      result.push make(m[0], getTok())
    else
      throw "Syntax error near '#{@substr(i)}'"
  result


parse = (input) ->
  tokens = input.tokens()
  lookahead = tokens.shift()
  match = (t) ->
    if lookahead.type is t
      lookahead = tokens.shift()
      lookahead = null if typeof lookahead is "undefined"
    else # Error. Throw exception
      throw "Syntax Error. Expected #{t} found '" +
            lookahead.value + "' near '" +
            input.substr(lookahead.from) + "'"
    return

  #STATEMENTS-------------------------------------------------------------
  statements = ->
    result = [program()]
    while lookahead and lookahead.type is ";"
      match ";"
      result.push program()
    (if result.length is 1 then result[0] else result)

  #PROGRAM
  program = ->   
    if lookahead and lookahead.type is "." 
      match "."
    else
      result = block()  
    result    

  #BLOCK------------------------------------------------------------------
  block = ->
    result = null
    if lookahead 
      switch lookahead.type

        when "CONST"    
          while lookahead and (lookahead.type is "CONST" or lookahead.type is ",")
            if lookahead.type is "CONST"
              match "CONST"
            else if lookahead.type is ","
              match ","
            left =
              type: "ID"
              value: lookahead.value
            match "ID"
            match "="
            right =
              type: "NUM"
              value: lookahead.value
            match "NUM"
            result =
              type: "CONST"
              left: left
              right: right   
            result

        when "VAR" 
          while lookahead and (lookahead.type is "VAR" or lookahead.type is ",")
            if lookahead.type is "VAR"
              match "VAR"
            else if lookahead.type is ","
              match ","
            result =
              type: "VAR"
              value: lookahead.value
            match "ID"
            result

        when "PROCEDURE"    
          match "PROCEDURE"
          left = lookahead.value
          match "ID"
          match ";"
          right = block()
          match ";"
          result1 =
            left: left
            right: right
          result =
            left: result1
            right: statements()
          result

        else      
          result = [statement()]

  #STATEMENT-------------------------------------------------------------
  statement = ->
    result = null
    if lookahead 
      switch lookahead.type

        when "ID"
          left =
            type: "ID"
            value: lookahead.value
          match "ID"
          match "="
          right = expression()
          result =
            type: "="
            left: left
            right: right

        when "P"
          match "P"
          right = expression()
          result =
            type: "P"
            value: right

        when "CALL"
          match "CALL"
          result =
            type: "CALL"
            value: lookahead.value
          match "ID"

        when "BEGIN"
          match "BEGIN"
          left = statements() #Funciona sin el último statements pillado no tiene ';''
          match "END"
          result =
            type: "BEGIN"
            left: left
            right: right

        when "IF"
          match "IF"
          left = condition()
          match "THEN"
          right = statement()
          result =
            type: "IF"
            left: left
            right: right

        when "WHILE"
          match "WHILE"
          left = condition()
          match "DO"
          right = statement()
          result =
            type: "WHILE"
            left: left
            right: right

        else # Error!
          throw "Syntax Error. Expected identifier but found " +
            (if lookahead then lookahead.value else "end of input") +
            " near '#{input.substr(lookahead.from)}'"
    result

  #CONDITION--------------------------------------------------------------
  condition = ->
    left = expression()
    type = lookahead.value
    match "COMPARISON"
    right = expression()
    result =
      type: type
      left: left
      right: right
    result

  #EXPRESSION-------------------------------------------------------------
  expression = ->
    result = term()
    while lookahead and lookahead.type is "ADDOP"
      type = lookahead.value
      match "ADDOP"
      right = term()
      result =
        type: type
        left: result
        right: right
    result

  #TERM-----------------------------------------------------------------
  term = ->
    result = factor()
    while lookahead and lookahead.type is "MULTOP"
      type = lookahead.value
      match "MULTOP"
      right = factor()
      result =
        type: type
        left: result
        right: right
    result

  #FACTOR---------------------------------------------------------------
  factor = ->
    result = null
    switch lookahead.type
     
      when "NUM"
        result =
          type: "NUM"
          value: lookahead.value
        match "NUM"

      when "ID"
        result =
          type: "ID"
          value: lookahead.value
        match "ID"

      when "(" #NO FUNCIONA (3*5) pero si a = (3*5)
        match "("
        result = expression()
        match ")"

      else # Throw exception
        throw "Syntax Error. Expected number or identifier or '(' but found " +
          (if lookahead then lookahead.value else "end of input") +
          " near '" + input.substr(lookahead.from) + "'"
    result

  #END------------------------------------------------------------------
  tree = statements(input)
  if lookahead?
    throw "Syntax Error parsing statements. " +
      "Expected 'end of input' and found '" +
      input.substr(lookahead.from) + "'"
  tree