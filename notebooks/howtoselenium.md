# Automate web scraping with selenium

\toc

## Install selenium

```shell
conda install -c conda-forge selenium
```

## Download driver
### Chrome
1. Visit https://sites.google.com/chromium.org/driver/
2. Download https://chromedriver.storage.googleapis.com/index.html?path=96.0.4664.45/

### Firefox
1. Go to https://github.com/mozilla/geckodriver/releases/tag/v0.30.0
2. Download https://github.com/mozilla/geckodriver/releases/download/v0.30.0/geckodriver-v0.30.0-macos-aarch64.tar.gz

### Check if the driver works
```python
driver = webdriver.Chrome('/Users/siida/Documents/chromedriver')
```

Then, if you are a mac user, you may encounter the following message: 

> **“chromedriver” cannot be opened because it is from an unidentified developer.**


Note: Chrome and the driver's version must be compatible. Otherwise, you will get an error related to the imcompatibility 

## To get started
### Search on google
```python
driver = webdriver.Chrome('/Users/siida/Documents/chromedriver')
driver.get('https://www.google.co.jp') #Open chrome
search_bar = driver.find_element_by_name("q") # Search for name q from the HTML
search_bar.send_keys("python")                # Fill out the search bar
search_bar.submit()                           # Submit the search
```

### Upload a file 
```python
import os
driver = webdriver.Chrome('/Users/siida/Documents/chromedriver')
driver.get('https://www.google.co.jp') #Open chrome
search_bar = driver.find_element_by_name("q") # Search for name q from the HTML
search_bar.send_keys(os.pwd() + "filename")
search_bar.submit()                           # Submit the search
```

### Main methods
```python
find_element_by_id(id)	         # id属性で要素を検索する
find_element_by_name(name)	     # name属性で要素を検索する
find_element_by_class_name(name) # class属性で要素を検索する
find_element_by_tag_name(name)   #タグ名で要素を検索する
find_element_by_xpath(xpath)     # XPathで要素を検索する
find_element_by_css_selector(css_selector)   # CSSセレクタで要素を検索する
find_element_by_link_text(link_text)         # リンクテキストで要素を検索する
find_element_by_partial_link_text(link_text) # リンクテキストの部分一致で要素を検索する
```

### Headless mode
```python
from selenium import webdriver
from time import sleep
from selenium.webdriver.chrome.options import Options
 
options = Options()
options.add_argument('--headless')
driver = webdriver.Chrome('/Users/siida/Documents/chromedriver',options=options)
driver.get('https://www.google.co.jp')
 
search_bar = driver.find_element_by_name("q")
search_bar.send_keys("python")
search_bar.submit()
```

### Automate Swissparam: Generate a ligand parameter
```python
#For Firefox
from selenium import webdriver
from selenium.webdriver.common.keys import Keys
import selenium
import os
import time
import sys

mol2file = sys.argv[1]

#driver = webdriver.Chrome('/Users/siida/Documents/chromedriver')
driver = webdriver.Firefox(executable_path='/Users/siida/Documents/geckodriver')

driver.get('https://www.swissparam.ch/')
search_bar = driver.find_element_by_name("mol2Files")
search_bar.send_keys(os.getcwd()+f"/{mol2file}")

search_bar = driver.find_element_by_id("sib_action")
search_bar.submit()

time.sleep(5)

search_bar = driver.find_element_by_partial_link_text("results")
search_bar.click()
```

### Automate CHARMM-GUI: Generate a ligand PDB with hydrogens
```python
from selenium import webdriver
from selenium.webdriver.common.keys import Keys
import selenium
import os
import time
import sys

PDBID = sys.argv[1]

#driver = webdriver.Chrome('/Users/siida/Documents/chromedriver')
driver = webdriver.Firefox(executable_path='/Users/siida/Documents/geckodriver')

driver.get('https://www.charmm-gui.org/?doc=input/ligandrm')

search_bar = driver.find_element_by_id("email")
search_bar.send_keys("EMAILADRESS") #<- replace

search_bar = driver.find_element_by_id("password")
search_bar.send_keys("PASSWORD") #<- replace

search_bar.submit()

time.sleep(3)

driver.find_element_by_id("pdb_id").send_keys(PDBID)
time.sleep(2)
driver.find_element_by_xpath("/html/body/div[4]/div[2]/div[3]/form/span[2]/span[3]/table/tbody/tr[3]/td/table[1]/tbody/tr[1]/td[1]/input").click()
```

### How to get XPath from Firefox
```
Follow Bellow Steps:
Step 1 : Right click on page -> Select (Inspect Element)
Step 2 : Pick an element from the page
Step 3 : Right Click on highlighted html -> Copy -> Xpath
```

