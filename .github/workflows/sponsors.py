import os
import sys
from html2image import Html2Image

chrome = sys.argv[1]
# read entire contents of file in args[2] as input
with open(sys.argv[2], 'r') as file:
    input = file.read()
    
output = sys.argv[3]

hti = Html2Image(size=(38,38), browser_executable=chrome)
hti.browser.print_command = True
hti.browser.flags = ['--hide-scrollbars', '--default-background-color=00000000', '--disable-remote-debugging', '--no-sandbox'];

# specify css with zero margin and padding and transparent html background
css = '''
html, body {
    margin: 0;
    padding: 0;
    background-color: transparent;
}
'''

print(f'{sys.argv[2]} -> {output}')
hti.screenshot(html_str=input, css_str=css, save_as=output)