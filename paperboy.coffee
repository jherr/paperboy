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
						@running[key]
							status: 'complete'
							result: data
						delete @running[key]
				else
					@running[key] data
		window.setTimeout(
			( ) => @update()
		, 200 )

	process: ( text, callback, customer = 1 ) ->
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
jserv.process 'My job rocks!', ( data ) ->
	console.log data.result
