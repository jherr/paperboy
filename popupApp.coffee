HOST = 'jack-herrington.vm.lithium.com:8080'

app = angular.module("popupApp", [])

@popupController = ( $scope, $timeout, $http ) ->
	$scope.result = chrome.extension.getBackgroundPage().nlp.result

	$scope.results = []

	$scope.rules = chrome.extension.getBackgroundPage().nlp.rules
	$scope.categories = chrome.extension.getBackgroundPage().nlp.categories

	$scope.rules_add = () =>
		$scope.rules.push { type: 1, text: "" }

	$scope.rules_delete = ( index ) =>
		$scope.rules.splice( index, 1 )

	$scope.rules_save = () =>
		if $scope.rules.length > 0
			rule = $scope.rules.shift()
			chrome.extension.getBackgroundPage().add_rule rule.type, rule.text, () =>
				window.setTimeout $scope.rules_save(), 0 if $scope.rules.length > 0

	$scope.bug =
		title: ''
		description: ''
		url: ''
		key: ''
		disabled: false

	$scope.copy_to_bug = () =>
		$scope.bug.title = "NLP issue with: #{$scope.text}"
		desc = "Expected Result:\n\nReceived Result:\n\n"
		for res in $scope.results
			for k,v of res
				desc += "#{k}: #{v}\n" unless k is '$$hashKey'
			desc += "\n\n"
		desc += "Configuration:\n\n#{$scope.text}"
		$scope.bug.description = desc

	$scope.submit_test = () =>
		chrome.extension.getBackgroundPage().nlp.service.process $scope.text, $scope.rules, ( data ) =>
			$scope.results = data[0].result
			$scope.$digest()

	$scope.$watch 'bug.title+bug.description', () =>
		$scope.bug.disabled = if $scope.bug.title.length > 0 and $scope.bug.description.length > 0 then false else true

	$scope.submit_bug = () =>
		chrome.extension.getBackgroundPage().submit_bug $scope.bug.title, $scope.bug.description, ( data ) =>
			$scope.bug.url = data.url
			$scope.bug.key = data.key
			$scope.$digest()

	$scope.selection = $scope.result

	$scope.text = chrome.extension.getBackgroundPage().nlp.text

