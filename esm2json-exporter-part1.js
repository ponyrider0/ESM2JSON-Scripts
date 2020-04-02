

var filename = "Morrowind_ob.esm";
var file_handle = xelib.FileByName(filename);
if (file_handle == 0) return;

var recordHandles = xelib.GetRecords(file_handle, "");
//var recordHandles = zedit.GetSelectedRecords();

zedit.info("# Records: " + recordHandles.length);

for (let i=0; i < recordHandles.length; i++) {
  record = recordHandles[i];
//  sig_string = xelib.Signature(record);
//  base_filename = xelib.LongName(record);
//  zedit.info("base_filename: " + base_filename);

  var path_string = xelib.LongPath(record);
//  zedit.info("path_string: " + path_string)

  if (path_string.search("CELL") != -1) continue;
  if (path_string.search("WRLD") != -1) continue;

//  if (path_string.search("ACTI") == -1) continue;

  var full_path = "esm2json-export/" + path_string + ".json";
  //zedit.info("full_path: " + full_path);

  // save JSONFile to string
  var jsonEntry = xelib.ElementToJSON(record);
  fh.saveJsonFile(full_path, jsonEntry, false);

};
