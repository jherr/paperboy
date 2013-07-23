HOST = 'jack-herrington.vm.lithium.com:8080'
# HOST = 'localhost:3000'
CUSTOMER = 1

class NLPService
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

	process: ( text, additional_rules, callback, customer = CUSTOMER ) ->
		@queue.push
			text: text
			additional_rules: additional_rules
			callback: callback
			customer: customer
		@process_queue()

	process_queue: ( ) ->
		return if @in_process or @queue.length is 0
		job = @queue.shift()
		@start_job job.text, job.additional_rules, job.callback, job.customer

	start_job: ( text, additional_rules, callback, customer ) ->
		console.log text
		@in_process = true
		cb = callback
		$.ajax
			url: "http://#{HOST}/api/v1/jobs/start"
			type: 'POST'
			data:
				customer: customer
				type: 'SINGLE'
				text: text
				additional_rules: JSON.stringify additional_rules
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
			success: ( data ) =>
				console.log data
				callback( data )

window.nlp =
	result: null
	text: ''
	service: new NLPService()
	rules: []
	categories: []

window.nlp.rules = []

@update_rules = ( rules ) ->
	console.log rules
	window.nlp.rules = rules

$.ajax
	type: 'GET'
	url: "http://#{HOST}/api/v1/categories"
	success: ( data ) =>
		window.nlp.categories = data

@add_rule = ( type, text, callback = null ) ->
	$.ajax
		type: 'POST'
		url: "http://#{HOST}/api/v1/customers/#{CUSTOMER}/terms"
		data:
			terms:
				customer_id: CUSTOMER
				category_id: type
				term: text
		success: ( data ) =>
			callback() if callback?

@submit_bug = ( title, description, callback ) =>
	cb = callback
	$.ajax
		type: 'POST'
		url: "http://#{HOST}/api/v1/jira"
		data:
			title: title
			description: description
		success: ( data ) =>
			cb( data )

chrome.extension.onRequest.addListener ( data, sender, response ) =>
	if data.type is 'selected'
		chrome.pageAction.show sender.tab.id if sender.tab?
		window.nlp.result = data.result
		window.nlp.text = if data.result?.SNIPPET then data.result.SNIPPET else data.text

	if data.type is 'nlp'
		window.nlp.service.process data.text, [], ( data ) =>
			try
				response( data ) if response?
			catch error
				console.log error

