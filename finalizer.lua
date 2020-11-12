local t = ...

-- Copy all additional files.
t:install{
  -- Install the FDL module.
  ['local/lua/fdl.lua']                                    = '${install_lua_path}/',

  -- Install all scripts.
  ['local/decode_fdl.lua']                                 = '${install_base}/',
  ['local/fdl_to_wfp_template.lua']                        = '${install_base}/',

  ['${report_path}']                                       = '${install_base}/.jonchki/'
}

t:createPackageFile()
t:createHashFile()
t:createArchive('${install_base}/../../../${default_archive_name}', 'native')

return true
