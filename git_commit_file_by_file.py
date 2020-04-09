import sys
import os
import subprocess

git_exe = "git"

if len(sys.argv) != 2:
    print "Please specify commit message to continue."
    exit()
commit_title = sys.argv[1]
#print "DEBUG: commit message is: \"" + commit_title + "\""

#print "DEBUG: Running 'git status --porcelain=1' ..."
result_array = subprocess.check_output(["git", "status", "--porcelain=1", "--untracked-files=all"])
result_lines = result_array.splitlines()
#print "DEBUG: Number of files to commit: " + str(len(result_lines))
i=0
for line in result_lines:
    if line == "":
        continue
#    print "DEBUG: line[" + str(i) + "]=" + line
    if len(line) > 4:
        operator=line[0:2]
        files=line[3:].split("\0")
#        print "DEBUG: operator=\"" + operator + "\""
#        print "DEBUG: file=\"" + files[0] + "\""
#        if len(files) > 1:
#            print "DEBUG: orig_file=" +files[1]
        if operator[0] != ' ' and operator[0] != '?':
            print "ERROR: existing staging detected, please commit or revert staging before running script."
            exit()
        if operator[1] == 'D':
#            print "DEBUG: file marked for deletion"
#            print "DEBUG: git rm " + files[0]
            subprocess.call([git_exe, "rm", files[0].strip('\"')])
            commit_message = "Removed " + files[0]
        elif operator[1] == 'M':
#            print "DEBUG: file marked as modified"
#            print "DEBUG: git add " + files[0]
            subprocess.call([git_exe, "add", files[0].strip('\"')])
            commit_message = "Modified " + files[0]
        elif operator[1] == '?':
#            print "DEBUG: file marked as untracked"
#            print "DEBUG: git add " + files[0]
            subprocess.call([git_exe, "add", files[0].strip('\"')])
            commit_message = "Added " + files[0]
        else:
            print "ERROR: unhandled file status: " + operator[1]
            exit()
        commit_message = commit_title + ": " + commit_message
#        print "DEBUG: git commit -m \"" + commit_message + "\""
        subprocess.call([git_exe, "commit", "-m", commit_message])
#        raw_input("Press ENTER to continue.")
    else:
        print "ERROR: parsing output on line[" + str(i) + "]: " + line
    i += 1
