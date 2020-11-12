local t = ...

-- Copy all additional files.
t:install{
  -- Install the FDL module.
  ['local/lua/fdl.lua']                                    = '${install_lua_path}/',

  -- Install all scripts.
  ['local/fdltool.lua']                                    = '${install_base}/',
  ['local/fdl_to_wfp_template.lua']                        = '${install_base}/',

  -- Add the demo files.
  ['local/demo/FDL_NXHX90-JTAG_7833000r3_UseCaseC.fdl']    = '${install_base}/demo/',
  ['local/demo/patch_mac_and_oem.json']                    = '${install_base}/demo/',
  ['local/demo/patch_mac.json']                            = '${install_base}/demo/',
  ['local/demo/patch_oem.json']                            = '${install_base}/demo/',

  ['${report_path}']                                       = '${install_base}/.jonchki/'
}

t:createPackageFile()
t:createHashFile()
t:createArchive('${install_base}/../../../${default_archive_name}', 'native')

return true
