# Script to generate the HDL sourceid information for a given project
# Local parameter: project

# Note: this script differs from the (similar) gen_buildinfo.py in that it produces std_logic
# vectors with versioning info to be embedded in the metadata, while buildinfo produces a string
# that focuses more on when/how/who built the bitstream.

import argparse
import sys

parser = argparse.ArgumentParser(
  description='Generate source ID for given project')
parser.add_argument('-p', '--project',
                    help = "Project name to use. If not provided, will look for a 'project' local variable.")
parser.add_argument('-l', '--language', choices = ['VHDL','Verilog'], default = 'VHDL',
                    help = "HDL language for output file. If not provided, defaults to VHDL.")
args = parser.parse_args()

if(args.project):
  project = args.project

try:
  project
except NameError:
  print("""No project defined, make sure you either define your variable
(e.g. like HdlMake does when you source this script),
or that you provide the '-p' argument at run-time.""")
  sys.exit(1)

if (args.language) == 'VHDL':
  outfile = "sourceid_{}_pkg.vhd".format(project)
  comment = "--"
else:
  outfile = "sourceid_{}.vh".format(project)
  comment = "//"

with open(outfile, "w") as f:
  import subprocess
  import time
  import re

  # Extract current commit id.
  try:
    sourceid = subprocess.check_output(
      ["git", "log", "-1", "--format=%H"]).decode().strip()
    sourceid = sourceid[0:32]
  except:
    sourceid = 16 * "00"

  # Extract current tag + dirty indicator.
  # It is not sure if the definition of dirty is stable across all git versions.
  try:
    tag = subprocess.check_output(
      ["git", "describe", "--dirty", "--always"]).decode().strip()
    dirty = tag.endswith('-dirty')
  except:
    dirty = True

  try:
    version = re.search("\d+\.\d+\.\d+", tag)
    major,minor,patch = [int(x) for x in version.group().split('.')]
  except:
    major = minor = patch = 0

  if dirty:
      #  There is no room for a dirty flag, just erase half of the bytes, so
      #  that's obvious it's not a real sha1, and still leaves enough to
      #  find the sha1 in the project.
      sourceid = sourceid[:16] + (16 * '0')

  f.write(f"{comment} Sourceid for project {project}\n")
  f.write(f"{comment}\n")
  f.write(f"{comment} This file was automatically generated; do not edit\n")
  f.write("\n")

  if args.language == 'VHDL':
    f.write("library ieee;\n")
    f.write("use ieee.std_logic_1164.all;\n")
    f.write("\n")
    f.write("package sourceid_{}_pkg is\n".format(project))
    f.write("  constant sourceid : std_logic_vector(127 downto 0) :=\n")
    f.write('       x"{}";\n'.format(sourceid))
    f.write("  constant version : std_logic_vector(31 downto 0) := ")
    f.write('x"{:02x}{:02x}{:04x}";\n'.format(major & 0xff, minor & 0xff, patch & 0xffff))
    f.write('end sourceid_{}_pkg;\n'.format(project))
  else:
    f.write(f"`ifndef SOURCEID_{project.upper()}_H\n")
    f.write(f"`define SOURCEID_{project.upper()}_H\n")
    f.write("\n")
    f.write(f"`define SOURCEID_{project.upper()}_SOURCEID 128'h{sourceid}\n")
    f.write(f"`define SOURCEID_{project.upper()}_VERSION 32'h{major:02x}{minor:02x}{patch:04x}\n")
    f.write("\n")
    f.write(f"`endif // ifndef SOURCEID_{project.upper()}_H\n")
