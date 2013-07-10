HOST = 'jack-herrington.vm.lithium.com:8080'

class @NLPService
	constructor: ->
		@running = {}
		window.setTimeout(
			( ) => @update()
		, 200 )

	update: ->
		for key of @running
			@status key, ( data ) =>
				if data.status is 'complete'
					@get key, ( data ) =>
						@running[key] data
						delete @running[key]
		window.setTimeout(
			( ) => @update()
		, 200 )

	process: ( text, callback, customer = 1 ) ->
		cb = callback
		$.ajax
			url: "http://#{HOST}/api/v1/jobs/start"
			type: 'POST'
			data:
				customer: customer
				type: 'SINGLE'
				text: text
				extra: null
			success: ( data ) =>
				@running[ data.jobid ] = callback

	status: ( job_id, callback ) ->
		$.ajax
			url: "http://#{HOST}/api/v1/jobs/status/#{job_id}"
			type: 'GET'
			success: ( data ) => callback( data )

	get: ( job_id, callback ) ->
		$.ajax
			url: "http://#{HOST}/api/v1/jobs/get/#{job_id}"
			type: 'GET'
			success: ( data ) => callback( data )

jserv = new @NLPService()
jserv.process 'I\'ve been trying to figure out what kind of lip makeup should I wear (i.e. lip stain, stick, gloss). Also, I want to find a suitable color for my very fair skin.  Most of the time when I wear lip stick it fades rather quickly, especially in the middle and then I\'m left with the color only around my outer lips. I also tend to like a little shine.  What should I use??', ( data ) ->
	console.log data
