/*global cordova, module*/

module.exports = {
    compress: function (stream, data, successCallback, errorCallback) {
        cordova.exec(successCallback, errorCallback, "Zlib", "deflate", [stream, data]);
    },
    uncompress: function (stream, data, successCallback, errorCallback) {
        cordova.exec(successCallback, errorCallback, "Zlib", "inflate", [stream, data]);
    },
    reset: function (stream, successCallback, errorCallback) {
        cordova.exec(successCallback, errorCallback, "Zlib", "reset", [stream]);
    }
};
