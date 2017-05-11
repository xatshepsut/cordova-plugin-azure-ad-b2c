
var AzureActiveDirectoryB2C = function() {};
var PLUGIN_NAME = 'AzureActiveDirectoryB2C';

AzureActiveDirectoryB2C.prototype.authenticate = function(params, success, fail) {
  if (!params) {
    params = {};
  }

  params.email = params.email || '';
  params.showLoadingIndicator = params.showLoadingIndicator || 'true';

  return cordova.exec(success, fail, PLUGIN_NAME, 'authenticate', [params]);
};

AzureActiveDirectoryB2C.prototype.reauthenticate = function(success, fail) {
  return cordova.exec(success, fail, PLUGIN_NAME, 'reauthenticate', [{}]);
};

window.AzureActiveDirectoryB2C = new AzureActiveDirectoryB2C();
