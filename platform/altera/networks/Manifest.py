def __helper():
  files = [ "altera_networks_pkg.vhd" ]
  if syn_device[:1] == "5":      files.extend(["arria5_networks.qip"])
  if syn_device[:6] == "ep2agx": files.extend(["arria2gx_networks.qip"])
  if syn_device[:4] == "10ax":   files.extend(["arria10gx/dual_region/dual_region.qsys", 
                                               "arria10gx/single_region/single_region.qsys", 
                                               "arria10gx/global_region/global_region.qsys"])
  return files

files = __helper()
