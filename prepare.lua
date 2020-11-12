local t = ...

-- Filter the testcase XML with the VCS ID.
t:filterVcsId('../..', '../../fdltool.xml', 'fdltool.xml')

return true
