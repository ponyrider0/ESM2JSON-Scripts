
import json
from collections import OrderedDict
import glob
import os
import sys


def recurse_subdirs(subdir=""):
    global job_pool
    if (subdir[-1] != "/"):
        subdir += "/"
    if (subdir == ""):
        return
    if os.path.exists(subdir):
        #debug_print("DEBUG: searching subdir: " + subdir + "...")
        if os.path.isdir(subdir) == False:
            print "ERROR: not a directory: " + subdir
            return
        for filename in os.listdir(subdir):
            if os.path.isdir(subdir + filename):
                # recurse down and do check below
                recurse_subdirs(subdir + filename + "/")
                continue
            # if filename is supported, add fullpath to job pool
            if (".json" in filename.lower()):
                job_pool.append(subdir + filename)
    else:
        print "ERROR: subdir not found: " + subdir

    return job_pool


def ReformatFile(filename):
    with open(filename, 'r') as in_file:
        json_data = json.load(in_file, object_pairs_hook=OrderedDict)

# DEBUGGING
#    print(json.dumps(json_data, indent=4, sort_keys=False))
#    filename = filename.replace(".json", "2.json")

    with open(filename, 'w') as out_file:
        json.dump(json_data, out_file, indent=4,)

    return

def main(arg):
    # glob all files recursively into list
    global job_pool
    job_pool = list()
    job_pool = recurse_subdirs(arg)

    if job_pool is None:
        print "job_pool is None"
        return
    
    # process list
    count = 0
    for filename in job_pool:
#        print(filename)
        ReformatFile(filename)
        count += 1
        if (count % 1000) == 0:
            print "processed " + str(count) + " files..."

    print "Script complete, processed " + str(count) + " files."
   


#arg = 'd:/dev/Morroblivion ESM2JSON/'
#arg = "./"
if len(sys.argv) == 1:
    print "no command line argument"
else:
    arg = sys.argv[1]
    arg = os.path.normpath(arg).replace("\\", "/")
    main(arg)
raw_input("Press ENTER to exit.")
