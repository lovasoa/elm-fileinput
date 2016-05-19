//import Native.Scheduler //
var _lovasoa$elm_fileinput$Native_ReadFile = function() {

function findFile(file) {
  var inputs = document.querySelectorAll("input[type=file]");
  for(var i=0; i<inputs.length; i++) {
    var input = inputs[i];
    if (!input.files || !input.files.length) continue;
    for(var j=0; j<input.files.length; j++) {
      var f = input.files[j];
      if(f.name === file.name && f.size === file.size) {
        return f;
      }
    }
  }
  return null;
}

function readFile(fileInfo, success, error) {
  var file = findFile(fileInfo);
  if (file === null) error("File not found in the page");
  var r = new FileReader();
  r.onerror = function(e){error(e.target.error.name);};
  r.onload  = function(e){success(e.target.result);};
  r.readAsText(file);
}

function readFileWrap(file) {
  return _elm_lang$core$Native_Scheduler.nativeBinding(function(callback) {
    return readFile(file, function(contents){
      callback(_elm_lang$core$Native_Scheduler.succeed(contents));
    }, function(errmsg){
      callback(_elm_lang$core$Native_Scheduler.fail(errmsg));
    });
  });
}

return {
  readFile : readFileWrap
};

}();
