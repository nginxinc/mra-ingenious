# Testing the Ingenious Application

We use selenium-webdriver to run a full suite of tests against the Ingenious Application.

Node is required to run the tests and you can find instructions to install Node [here](https://docs.npmjs.com/getting-started/installing-node).

Once node is installed, additional dependencies must be downloaded before running the tests. Node will use the [package.json](package.json) file to download [selenium-webdriver](https://www.npmjs.com/package/selenium-webdriver) and [geckodriver](https://www.npmjs.com/package/geckodriver) to a directory called _node_modules_. Run the `npm install` command to get the dependencies.

With the dependencies in place, the tests can be run using the command:


```
 node ingenious-tests.js -i <path-to-repo>/mra-ingenious/tests/nginx.jpg
```

_<path-to-repo>_ is the absolute path to the directory where the repository has been cloned. Selenium Webdriver requires an absolute path; a relative path will not work.

There following usage for the ingenious-tests.js script can be output with the command `node ingenious-tests.js -h`

```
--- You must set the image path with the -i parameter ---
----- Help For Ingenious Test Script -----

Example:

-- using default parameters:
    node ingenious-tests.js

-- using custom host and image:
    node ingenious-tests.js -u http(s)://<some-host> -i <absolute-path-to-image>

Options:

  -h  display this help
  -u  URL of the host to test against, you must specify the scheme: ex. https://k8s.mra.nginxps.com, defaults to http://localhost
  -i Absolute path to the image file on your system: ex. /Users/username/repos/mra-ingenious/tests/nginx.jpg
``` 

The _-u_ switch allows the option to specify an URL against which to run the tests. The default value is _https://localhost_

Upon executing the tests, a Firefox browser window will open and the tests will begin to traverse the site and act on the elements of the pages. If there are any errors, they will appear in the console. 