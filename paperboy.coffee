HOST = 'jack-herrington.vm.lithium.com:8080'

class @NLPService
	constructor: ->
		@running = {}
		@queue = []
		@in_process = false
		window.setTimeout(
			( ) => @update()
		, 200 )

	update_job: ( key ) ->
		@status key, ( data ) =>
			if data.status is 'complete'
				@get key, ( data ) =>
					if @running[key]?
						@running[key] data
						delete @running[key]
						@in_process = false
						@process_queue()

	update: ->
		for key of @running
			@update_job( key )
		window.setTimeout(
			( ) => @update()
		, 200 )

	process: ( text, callback, customer = 1 ) ->
		@queue.push
			text: text
			callback: callback
			customer: customer
		@process_queue()

	process_queue: ( ) ->
		return if @in_process or @queue.length is 0
		job = @queue.shift()
		@start_job job.text, job.callback, job.customer

	start_job: ( text, callback, customer ) ->
		@in_process = true
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
