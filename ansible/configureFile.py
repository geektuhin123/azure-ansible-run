import sys
import os
import errno
import json
print "This is the name of the script: ", sys.argv[0]
print "Creating file .. : " , str(sys.argv[1])
data = sys.argv[2]
filePath = sys.argv[1]
def main():
  if not os.path.exists(os.path.dirname(filePath)):
      try:
          os.makedirs(os.path.dirname(filePath))
      except OSError as exc: # Guard against race condition
          if exc.errno != errno.EEXIST:
              raise

  with open(sys.argv[1], "w+") as f:
      a = data.split("|")
      print "Writing data into a file:"
      print a
      for i in a:
        f.write(i+"\n")
if __name__== "__main__":
  main()
