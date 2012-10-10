var sys = require('sys')
var exec = require('child_process').exec;
var execFile = require('child_process').execFile;
var _ = require('underscore');
var fs = require('fs');
var nano = require('nano')("http://localhost:5984");
var Q = require('q');
var mime = require('mime');
var path = require('path');
var url = require('url');

function get_host_name(){
  var deferred = Q.defer();
  exec('hostname',function(error,hostname){
    if (error) {
      deferred.reject(new Error(error));
    } else {
      deferred.resolve(hostname);
    }
  })
  return deferred.promise;
}

get_host_name()
  .then(function(){
    console.log(arguments);
  });

var qexec = Q.nbind(exec);

qexec('hostname')
  .then(console.log);

qexec('ls')
  .then(function(){
    return qexec('cat node.couchapp.js')
  })
  .then(function(){
    return qexec('find .')
  })
  .then(console.log)
