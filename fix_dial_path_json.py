
import json
from collections import OrderedDict
import glob
import os
import sys
import shutil


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
        # if subdir is 'Child Group' then add to job pool
        if "child group" in subdir.lower():
            # if subdir not in job_pool, then add it
            if subdir not in job_pool:
                job_pool.append(subdir[0:-1])
        else:
            for filename in os.listdir(subdir):
                if os.path.isdir(subdir + filename):
                    # recurse down and do check below
                    recurse_subdirs(subdir + filename + "/")
    else:
        print "ERROR: subdir not found: " + subdir

    return job_pool


def MoveFilesToParent(subdir):
    parent_dir = os.path.dirname(subdir)
    #debug
    print "DEBUG: subdir=[" + subdir + "], parent_dir=[" + parent_dir + "]"
    for filename in os.listdir(subdir + "/"):
        shutil.move(subdir + "/" + filename, parent_dir)
    os.rmdir(subdir)
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
    for subdir in job_pool:
#        print(filename)
        MoveFilesToParent(subdir)
        count += 1
        if (count % 1000) == 0:
            print "processed " + str(count) + " subfolders..."

    print "Script complete, processed " + str(count) + " subfolders."
   


#arg = 'd:/dev/Morroblivion ESM2JSON/'
#arg = "./"
if len(sys.argv) == 1:
    print "no command line argument"
else:
    arg = sys.argv[1]
    arg = os.path.normpath(arg).replace("\\", "/")
    main(arg)
raw_input("Press ENTER to exit.")
