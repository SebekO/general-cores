def __helper():
  files = [
    "pcie_32to64.vhd",
    "pcie_64to32.vhd",
    "pcie_altera.vhd",
    "pcie_tlp.vhd",
    "pcie_wb.vhd",
    "pcie_wb_pkg.vhd"]
  if syn_device[:1] == "5":         files.extend(["arria5_pcie.qip"])
  if syn_device[:9] == "10ax027e3": files.extend(["arria10gx_scu4_pcie_hip/arria10gx_scu4_pcie_hip.qsys"])
  if syn_device[:9] == "10ax027h2": files.extend(["arria10gx_pex10_pcie_hip/arria10gx_pex10_pcie_hip.qsys"])
  if syn_device[:7] == "10ax066":   files.extend(["arria10gx_pcie_hip/arria10gx_pcie_hip.qsys"])
  if syn_device[:4] == "10as":      files.extend(["arria10_pcie_hip/arria10_pcie_hip.qsys"])
  if syn_device[:4] == "ep2a":      files.extend(["arria2_pcie.qip"])
  return files

files = __helper()
