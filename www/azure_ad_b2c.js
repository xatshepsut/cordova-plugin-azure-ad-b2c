var AzureActiveDirectoryB2C = function() {};

AzureActiveDirectoryB2C.prototype.authenticate = function(params, success, fail) {
  if (!params) {
    params = {};
  }
  return cordova.exec(success, fail, "AzureActiveDirectoryB2C", "authenticate", [params]);
};

window.AzureActiveDirectoryB2C = new AzureActiveDirectoryB2C();