import os
import site

# Add the current folder as a site dir.
site.addsitedir(os.path.dirname(os.path.realpath(__file__)))
