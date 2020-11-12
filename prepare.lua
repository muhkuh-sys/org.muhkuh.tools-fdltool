local t = ...

-- Filter the testcase XML with the VCS ID.
t:filterVcsId('../..', '../../fdl.xml', 'fdl.xml')

return true
