"""
Simulation helper tools: Vunit post_run jobs, dealing with ISE/Vivado.

Precompile Xilinx standard libraries (unisim etc.) feature is strongly based on
VUnit Vivado example from github.
"""

# Created by Adrian Byszuk <adrian.byszuk@cern.ch> (2020)

import subprocess
import shutil
import os
import uuid
from pathlib import Path
from itertools import product
from vunit.sim_if.factory import SIMULATOR_FACTORY
from vunit.vivado import (
    run_vivado,
    add_from_compile_order_file,
    create_compile_order_file,
)


def vunit_postrun(script, src=""):
    """
    Create a post_run job passed to Vunit.main() method.

    For now, this function takes care of postprocessing code coverage results.
    :param script: Absolute path to a script file calling this function
    :param src: Path to sources that should be taken into account when
        generating HTML report. Either an absolute path, or relative to script
        path. Applies to GHDL-gcc simulator only.
    :returns: post_run function
    """
    def post_run(results):
        """Pass/fail indicator, log file and coverage data."""
        print("Generating code coverage report")
        if results._simulator_if.name == "ghdl":
            src_path = '../../../modules/common/'
#            if Path(src).is_absolute():
#                src_path = src
#            else:
#                src_path = (Path(script).parent / src).resolve()
            # In case of multiple run.py running, collect and merge results for all
            # these runs, so first must store the results separately
            uid = str(uuid.uuid4()).partition('-')[0]
            cov_output = "coverage_data"
            results.merge_coverage(cov_output)
            # gcovr run should collect  data from all these directories
            cmd = ["gcovr", "-r", str(Path(src_path).resolve()),
                   "--html-details", "cover_report.html",
                   "--xml-pretty", "--exclude-unreachable-branches",
                   "-o", "cover_report.xml", "."]
            print(' '.join(cmd))
            subprocess.run(cmd)
        if results._simulator_if.name == "modelsim":
            results.merge_coverage(file_name="coverage.ucdb")
            cmd = ["vcover", "report", "-html", "-details", "-source",
                   "coverage.ucdb"]
            print(' '.join(cmd))
            subprocess.run(cmd)
        if results._simulator_if.name == "rivierapro":
            results.merge_coverage(file_name="coverage.acdb")
            cmd = ["vsim", "-c", "-do", "acdb report -html -i coverage.acdb; exit"]
            print(' '.join(cmd))
            subprocess.run(cmd)
            cmd = ["acdb2xml", "-i", "coverage.acdb", "-o", "ucdb.xml"]

    return post_run


def vunit_enable_coverage(uut):
    """
    Enable code coverage in simulation for all supported simulators.

    Currently supported simulators: ghdl (GCC backend), Modelsim, Riviera-PRO
    :param uut: Library UUT object as returned by `VUnit.add_library()` method
    """
    uut.set_compile_option("enable_coverage", True)
    uut.add_compile_option("modelsim.vcom_flags", ["+cover=bs"])
    uut.add_compile_option("modelsim.vlog_flags", ["+cover=bs"])
    uut.add_compile_option("rivierapro.vcom_flags", ["-coverage", "bs"])
    uut.add_compile_option("rivierapro.vlog_flags", ["-coverage", "bs"])
    uut.set_sim_option("enable_coverage", True)

def vunit_generate_tests(obj, **kwargs):
    """
    Generate tests (using cartesian products) on an arbitrary amount of
    named arguments, independent of the target design.

    This function eliminates the need to rewrite the "generate_tests"
    function for each new VUnit testbench.
    For example,
        vunit_generate_tests(tb,data_width=[1,2,3],threshold=[2,3,4],delay=[10,20])
    This provides variations to the VHDL generics data_width,threshold and delay.

    :param obj: VUnit testbench object
    """

    for gen_vals in product(*kwargs.values()):
        gen = dict(zip(kwargs.keys(),gen_vals))

        config_name = ','.join([f'{k}={v}' for k,v in gen.items()])

        obj.add_config(
            name=config_name,
            generics=gen
        )

def compile_ise_libraries(vunit_obj, output_path):
    """
    Compile Xilinx standard libraries for simulator used for this VUnit run.

    If [SIMULATOR]_ISE_LIBS (e.g. GDHL_ISE_LIBS) environment variable exists
    and if precompiled Vivado libraries for given simulator are already
    available as pointed out by [SIMULATOR]_ISE_LIBS they will be used instead.

    :param vunit_obj: Main Vunit class:`vunit.ui.VUnit` class
    :param output_path: Path to the folder where compiled library should be
        stored
    :return: Final output path where libs for selected simulator are stored
    """
    return _compile_xilinx_libraries(vunit_obj, output_path, 'ise')


def compile_vivado_libraries(vunit_obj, output_path):
    """
    Compile Xilinx standard libraries for simulator used for this VUnit run.

    If [SIMULATOR]_VIVADO_LIBS (e.g. GDHL_VIVADO_LIBS) environment variable
    exists and if precompiled Vivado libraries for given simulator are already
    available as pointed out by [SIMULATOR]_VIVADO_LIBS they will be used
    instead.

    :param vunit_obj: Main Vunit class:`vunit.ui.VUnit` class
    :param output_path: Path to the folder where compiled library should be
        stored
    :return: Final output Path() where libs for selected simulator are stored
    """
    return _compile_xilinx_libraries(vunit_obj, output_path, 'vivado')


def add_vivado_ip(vunit_obj, project_file, output_path, vivado_path=None,
                  clean=False):
    """
    Add all IP files from Vivado project to the vunit project.

    Caching is used to save time where Vivado is not called again if the
    compile order already exists.
    If Clean is True the compile order is always re-generated

    :return: The list of SourceFile objects added
    """
    compile_order_file = str(Path(output_path) / "compile_order.txt")

    if clean or not Path(compile_order_file).exists():
        create_compile_order_file(
            project_file, compile_order_file, vivado_path=vivado_path
        )
    else:
        print(
            "Vivado project Compile order already exists, re-using: %s"
            % str(Path(compile_order_file).resolve())
        )

    return add_from_compile_order_file(vunit_obj, compile_order_file)


def run_compxlib(cfg_file, out_path, sim_name, sim_path, ise_path=None):
    """
    Run ISE compxlib app to compile vendor libraries.

    :param cfg_file: Path to compxlib CFG file
    :param out_path: Path to compile output directory
    :param sim_name: Simulator name
    :param sim_path: Path to the simulator binary
    :param ise_path: Path to ise/compxlib binary
    """
    binary = (
        "compxlib"
        if ise_path is None
        else str(Path(ise_path).resolve() / "bin" / "lin64" / "compxlib")
    )
    out_path_abs = str(Path(out_path).resolve())
    cmd = f"{binary}  "
    cmd += " ".join(["-w",
                     f"-cfg {str(Path(cfg_file).resolve())}",
                     "-64bit",
                     "-l all",
                     f"-s {sim_name}",
                     "-verbose",
                     "-lib unisim",
                     "-lib simprim",
                     "-lib xilinxcorelib",
                     "-arch all",
                     f"-p {str(Path(sim_path).resolve())}",
                     f"-dir {out_path_abs}"]
                    )

    if not os.path.exists(out_path_abs):
        os.makedirs(out_path_abs)
    print(f"Changing CWD to {out_path_abs}")
    print(cmd)
    # Note: the shell=True is important in windows where ISE is just a bat file.
    subprocess.run(cmd, cwd=out_path_abs, shell=True, check=True)


# In case Modelsim is the main simulator
def vsim_create_startup_do(filename):
    with open(filename, 'w') as f:
        f.write("global StdArithNoWarnings\n")
        f.write("set StdArithNoWarnings 1\n")
        f.write("global NumericStdNoWarnings\n")
        f.write("set NumericStdNoWarnings 1\n")


def get_sim_class(name):
    """
    Retrieve VUnit simulator class based on the simulator name.

    :param name: Simulator name
    :return: VUnit class`vunit.sim_if.Simulator` matching simulator name
    """
    for sim_class in SIMULATOR_FACTORY.supported_simulators():
        if sim_class.name == name:
            return sim_class


def _compile_xilinx_libraries(vunit_obj, output_path, tool):
    """
    Compile Xilinx standard libraries for either ISE or Vivado project.

    Skip compilation if precompiled libraries already exist in given location
    or location specified by [SIMULATOR]_[TOOL]_LIBS environment variable.
    """
    assert tool in ('ise', 'vivado')

    simname = vunit_obj.get_simulator_name()

    # First let's check if precompiled libraries already exist globally
    opath = os.environ.get(f"{simname}_{tool}_LIBS".upper())
    print(opath)
    if not opath:
        # User may want to use different simulators, so let's create/reuse
        # subdirectories for every simulator that was used
        opath = str(Path(output_path).resolve() / simname)
    done_token = Path(opath) / "all_done.txt"
    if not os.path.lexists(done_token):
        print(f"Compiling standard libraries into {opath}")

        simulator = get_sim_class(simname)
        try:
            sim_prefix = simulator.find_prefix().replace("\\", "/")
        except AttributeError:
            raise Exception(f"Couldn't find simulator {simname}, check your PATH!\n")

        # Xilinx calls rivierapro for riviera
        if simname == "rivierapro":
            simname = "riviera"

        if simname != 'ghdl' and tool == 'vivado':
            run_vivado(
                str(Path(__file__).parent.parent / "tcl" / "compile_vivado_libraries.tcl"),
                tcl_args=[
                    simname,
                    sim_prefix,
                    opath,
                ],
            )
        elif simname != 'ghdl' and tool == 'ise':
            # ISE distinguishes between modelsim versions by name
            # The one used at CERN is AFAIK SE
            if simname == "modelsim":
                simname = "mti_se"

            run_compxlib(
                str(Path(__file__).parent.parent / "tcl" / "compxlib.cfg"),
                opath,
                simname,
                sim_prefix
            )
        elif simname == 'ghdl':
            # GHDL uses their own shell script for compilation
            bin_path = sim_prefix
            try:
                if tool == 'ise':
                    tool_path = Path(shutil.which(tool)).parents[2]
                    src_path = tool_path / 'vhdl/src'
                elif tool == 'vivado':
                    tool_path = Path(shutil.which(tool)).parents[1]
                    src_path = tool_path / 'data/vhdl/src'

                script_path = Path(bin_path).parent / 'lib' / 'ghdl' / \
                    'vendors' / f'compile-xilinx-{tool}.sh'
            except:
                raise Exception("Couldn't find Xilinx toolchain. Is your PATH set?")

            print("WARNING: GDHL doesn't support linkink libraries of different standard")
            print("Xilinx libraries will be compiled with 2008 standard, which may cause problems!")
            run = subprocess.run([str(script_path) + ' --all --vhdl2008' +
                                  ' --ghdl ' + bin_path + '/ghdl' +
                                  ' --out ' + opath +
                                  ' --src ' + str(src_path)],
                                 shell=True
                                 )
            run.check_returncode()

        with open(done_token, "w") as fptr:
            fptr.write("done")
    else:
        print(f"Standard libraries already exists in {opath}, skipping")

    return Path(opath)

