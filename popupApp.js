// Generated by CoffeeScript 1.4.0
(function() {
  var HOST, app;

  HOST = 'jack-herrington.vm.lithium.com:8080';

  app = angular.module("popupApp", []);

  this.popupController = function($scope, $timeout, $http) {
    var _this = this;
    $scope.result = chrome.extension.getBackgroundPage().nlp.result;
    $scope.results = [];
    $scope.rules = chrome.extension.getBackgroundPage().nlp.rules;
    $scope.categories = chrome.extension.getBackgroundPage().nlp.categories;
    $scope.rules_add = function() {
      return $scope.rules.push({
        type: 1,
        text: ""
      });
    };
    $scope.rules_delete = function(index) {
      return $scope.rules.splice(index, 1);
    };
    $scope.rules_save = function() {
      var rule;
      if ($scope.rules.length > 0) {
        rule = $scope.rules.shift();
        return chrome.extension.getBackgroundPage().add_rule(rule.type, rule.text, function() {
          if ($scope.rules.length > 0) {
            return window.setTimeout($scope.rules_save(), 0);
          }
        });
      }
    };
    $scope.bug = {
      title: '',
      description: '',
      url: '',
      key: '',
      disabled: false
    };
    $scope.copy_to_bug = function() {
      var desc, k, res, v, _i, _len, _ref;
      $scope.bug.title = "NLP issue with: " + $scope.text;
      desc = "Expected Result:\n\nReceived Result:\n\n";
      _ref = $scope.results;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        res = _ref[_i];
        for (k in res) {
          v = res[k];
          if (k !== '$$hashKey') {
            desc += "" + k + ": " + v + "\n";
          }
        }
        desc += "\n\n";
      }
      desc += "Configuration:\n\n" + $scope.text;
      return $scope.bug.description = desc;
    };
    $scope.submit_test = function() {
      return chrome.extension.getBackgroundPage().nlp.service.process($scope.text, $scope.rules, function(data) {
        $scope.results = data[0].result;
        return $scope.$digest();
      });
    };
    $scope.$watch('bug.title+bug.description', function() {
      return $scope.bug.disabled = $scope.bug.title.length > 0 && $scope.bug.description.length > 0 ? false : true;
    });
    $scope.submit_bug = function() {
      return chrome.extension.getBackgroundPage().submit_bug($scope.bug.title, $scope.bug.description, function(data) {
        $scope.bug.url = data.url;
        $scope.bug.key = data.key;
        return $scope.$digest();
      });
    };
    $scope.selection = $scope.result;
    return $scope.text = chrome.extension.getBackgroundPage().nlp.text;
  };

}).call(this);
