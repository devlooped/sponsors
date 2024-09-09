import os
import sys
from html2image import Html2Image

chrome = sys.argv[1]
input = sys.argv[2]
output = sys.argv[3]

hti = Html2Image(size=(38,38), browser_executable=chrome)
hti.browser.print_command = True
hti.browser.flags = ['--default-background-color=00000000', '--headless', '--disable-remote-debugging', '--no-sandbox'];

hti.screenshot(other_file=input, save_as=output)