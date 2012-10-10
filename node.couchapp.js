var args = require('optimist')
  .default('dir', __dirname)
  .default('ouput','dump')
  .argv;

var async = require('async');
var sys = require('sys')
var exec = require('child_process').exec;
var execFile = require('child_process').execFile;
var _ = require('underscore');
require('underscore_extended');
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
/*
get_host_name()
  .then(function(){
    console.log(arguments);
  });
*/
var qexec = Q.nbind(exec);
//var qcd = Q.nbind(process.chdir);

/*
qexec('hostname')
  .then(console.log);

qexec('find', '.' ,'-type f')
  .then(function(file_paths)
        {
          console.log("files");
          console.log(arguments);
          _.each(file_paths,function(){
            console.log(arguments);
          })
            })
  .fail(function(){
    console.log('failed')
  })
*/


execFile('./list_files',args.dir, function(err,file_paths){
  var files = file_paths.split('/n');
  console.log(file_paths)
  console.log('error',err);
  async.map(files,
            function(path,done){
              var nice_path = path.replace(/^\.\//,"");
              done(null,nice_path);
            },
            function(err,nice_paths){
              console.log(_.size(nice_paths));
            })
})


