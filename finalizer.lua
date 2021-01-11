local t = ...
local pl = t.pl

-- Copy all additional files.
t:install{
  -- Install the FDL module.
  ['local/lua/fdl.lua']                                    = '${install_lua_path}/',

  -- Install all scripts.
  ['local/fdl_to_wfp_template.lua']                        = '${install_base}/',

  -- Add the demo files.
  ['local/demo/FDL_NXHX90-JTAG_7833000r3_UseCaseC.fdl']    = '${install_base}/demo/',
  ['local/demo/patch_mac_and_oem.json']                    = '${install_base}/demo/',
  ['local/demo/patch_mac.json']                            = '${install_base}/demo/',
  ['local/demo/patch_oem.json']                            = '${install_base}/demo/',

  ['${report_path}']                                       = '${install_base}/.jonchki/'
}

-- Read the "fdltool.lua" script and replace all "${}" expressions.
-- This is used to insert the version number.
local strSrcFile = pl.path.abspath('local/fdltool.lua', t.strCwd)
local strTemplate, strMessage = pl.utils.readfile(strSrcFile)
if strTemplate==nil then
  error('Failed to read ' .. strSrcFile .. ' : '..tostring(strMessage))
end
local strText = t:replace_template(strTemplate)
local strDstFile = t:replace_template('${install_base}/fdltool.lua')
local fResult
fResult, strMessage = pl.utils.writefile(strDstFile, strText)
if fResult~=true then
  error('Failed to write to ' .. tostring(strDstFile) .. ' : ' .. tostring(strMessage))
end

t:createPackageFile()
t:createHashFile()
t:createArchive('${install_base}/../../../${default_archive_name}', 'native')

return true
