highlight = (snippet, priority, noun, result, index) ->
	return '' if snippet.length is 0

	color = 'white'
	switch priority
		when 1 then color = 'goldenrod'
		when 2 then color = 'lawnGreen'
		when -1 then color = 'orangeRed'

	patts = []
	if result?
		for p in result['PATTERNS MATCHED']
			p = p.replace /^\s+/, ''
			p = p.replace /\s+$/, ''
			patts.push p

	patterns = patts.join ', '

	fw = if noun then "font-weight:bold;text-decoration:underline;" else ""
	"<span data-index='#{index}' class='fragment' style='background-color:#{color};#{fw}' title='#{patterns}'>#{snippet}</span>"

nlpIndex = 1
nlpData = {}

processText = ( el ) =>
	text = $(el).text()
	text = text.replace( /^\s+/, '' )
	text = text.replace( /\s+$/, '' )
	text = text.replace( /\s+/g, ' ' )

	return unless text.length > 0

	$(el).css 'background-color', 'beige'

	chrome.extension.sendRequest
		type: 'nlp'
		text: text
	, ( data ) ->
		$(el).css 'background-color', 'white'

		if data[0].result.length > 0
			states = []

			for loc in [ 0 .. text.length ]
				states.push
					priority: 0
					result: null
					noun: false
					index: 0

			for result in data[0].result
				priority = 1
				switch result.FOUND
					when "advocateObject" then priority = 2
					when "detractObject" then priority = -1

				start = text.indexOf result.SNIPPET
				if start isnt -1
					nlpIndex += 1
					nlpData[ nlpIndex ] = result
					chrome.extension.sendRequest
						type: 'found'
						index: nlpIndex
						data: result

					if result.NOUNPHRASES?
						substr = text.slice start, start + result.SNIPPET.length
						for np in result.NOUNPHRASES
							npl = substr.indexOf np
							if npl isnt -1
								for loc in [ start + npl .. start + npl + np.length - 1 ]
									states[loc].noun = true

					for loc in [ start .. start + result.SNIPPET.length - 1 ]
						if states[ loc ].priority is 0 or states[ loc ].priority is 1
							states[ loc ].priority = priority
							states[ loc ].result = result
							states[ loc ].index = nlpIndex
				else
					console.log "Couldn't find: #{result.SNIPPET}"

			current =
				priority: 0
				noun: false
				text: ''
				result: null
				index: -1

			out = ''

			for loc in [0..text.length-1]
				priority = states[loc].priority
				noun = states[loc].noun
				result = states[loc].result
				index = states[loc].index

				if current.priority isnt priority or current.noun isnt noun or current.result isnt result or current.index isnt index
					out += highlight current.text, current.priority, current.noun, current.result, current.index

					current.text = text[loc]
					current.noun = noun
					current.result = result
					current.priority = priority
					current.index = index
				else
					current.text += text[loc]

			out += highlight current.text, current.priority, current.noun, current.result, current.index

			$(el).html( out )

			$('.fragment',el).click ( event ) ->
				index = $(event.target).data('index')
				chrome.extension.sendRequest
					type: 'selected'
					text: $(event.target).text()
					result: if index is -1 then null else nlpData[ index ]

scanForTags = () ->
	found = false
	for el in $('.lia-message-body-content p')
		processText( el )
		found = true
	unless found
		window.setTimeout scanForTags, 100

window.setTimeout scanForTags, 100
