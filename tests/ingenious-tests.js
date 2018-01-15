const {Builder, By, Key, logging, until, Assertion} = require('selenium-webdriver');
require('geckodriver')
const assert = require('assert');
const test = require('selenium-webdriver/testing');
const startTime = new Date();
const username = 'test_' + startTime.getTime() + '@nginx.com';
const password = 'testing123';
const userFirstLast = 'Test User';
var imageFilePath;
var host = 'https://localhost';

// TODO: parse arguments and use named parameters to set imageFilePath and host

process.argv.forEach(function(arg, index) {
  switch (arg) {
    case '-h':
      logHelp();
      process.exit(1);
    case '-u':
      host = trimTrailingSlash(process.argv[index + 1]);
      break;
    case '-i':
      imageFilePath = process.argv[index + 1];
      break;
  }
});

if (!imageFilePath) {
  console.log('\x1b[31m--- You must set the image path with the -i parameter ---\x1b[0m');
  logHelp();
  process.exit(1);
}

console.log('\x1b[32mStarting Ingenious tests with parameters:');
console.log('\t- host: ' + host);
console.log('\t- image ' + imageFilePath + '\x1b[0m');

var baseElement;

let driver = new Builder()
	.withCapabilities(
    {
      'acceptInsecureCerts':true,
      'pageLoadStrategy' : 'eager',
      'moz:firefoxOptions' : {
        'log': {
          'level' : 'trace'
        }
    }})
	.forBrowser('firefox')
	.build();

driver.manage().timeouts().implicitlyWait(5000);

// HOME PAGE
driver.get(host).then(() => {
  console.log('- Getting the home page\n');
  driver.wait(until.titleIs('Ingenious Photos'));
  driver.wait(until.elementLocated(By.id('top')));
  driver.wait(until.elementLocated(By.className('hero-banner-title')));
}).then(() => {
  console.log('- Checking the page title\n');
  baseElement = driver.findElement(By.id('top'));

  baseElement.getText().then(function(text) {
  	console.log('--' + text);
  });

  baseElement.findElement(By.className('hero-banner-title')).getText().then(function(text) {
  	console.log('--' + text + '\n');
  	assert.equal(text, 'Ingenious');
  });
}).then(() => {
  console.log('- Verifying the existence of the articles on the home page');

   driver.findElement(By.id('articles')).findElements(By.css('.single-post')).then(function(result) {
  	console.log('-- There are ' + result.length + ' articles\n');
  	// assert.ok(result.length > 0, 'There are not enough articles');
  });
}).then(() => {
  console.log('- Checking the about page');

  driver.get(host + '/about');

  baseElement = driver.findElement(By.css('#about .page-header .page-title'));

  baseElement.getText().then(function(text) {
  	console.log('-- ' + text + '\n');
  	assert.equal(text, 'About Microservices', 'The values are not equal');
  });
}).then(() => {
  console.log('- Checking the account page as an unauthenticated user');

  driver.get(host + '/account');

  driver.findElement(By.id('user-login')).then(function(result) {
  	console.log('-- Loaded account page and found the login form\n');
  });
}).then(() => {
  console.log('- Checking the myphotos page as an unauthenticated user');

  driver.get(host + '/myphotos');

  driver.findElement(By.id('user-login')).then(function(result) {
  	console.log('-- Loaded photos page and found the login form\n');
  });

}).then(() => {
  console.log('- Creating a new user for authenticated test');
  driver.get(host + '/login');

  baseElement = verifyLoginFormExists();
  populateLoginFormFields(baseElement);
  driver.findElement(By.id('login-form-button')).click();

  console.log('- Updating the user account with ' + userFirstLast + '\n');
  getAccountForm().findElement(By.id('name')).sendKeys(userFirstLast);
  driver.findElement(By.id('update-account-button')).click();
}).then(() => {
  console.log('- Checking account update');
  driver.findElement(By.id('name')).getAttribute('value').then(function(accountName) {
  	console.log('-- Comparing ' + accountName + ' with ' + userFirstLast + '\n');
  	assert.ok(userFirstLast == accountName, "The account update operation failed");
  });

}).then(() => {
  console.log('- Starting photo upload tests');
  driver.get(host + '/myphotos');
  driver.wait(until.elementLocated(By.css('#albums')));
  baseElement = driver.findElement(By.id('albums'));
  baseElement.findElement(By.css('.page-title')).getText().then(function(albumPage) {
  	console.log('- Validating album page');
  	assert.ok(albumPage.toUpperCase() == 'MY ALBUMS', 'The album page titie is incorrect. Expected "My Albums" got "' + albumPage + '"');
  	driver.findElement(By.css('.right-nav .right-nav-items')).isDisplayed().then(function(isDisplayed) {
  		console.log('Is the right nav visible? ' + isDisplayed + '\n');
  		assert.ok(!isDisplayed, 'The right nav is visible');
  	})
  }).then(() => {
    console.log('- Starting Album Management');
    driver.findElement(By.css('.right-nav-btn a')).click().then(() => {
    	driver.findElement(By.css('.right-nav.nav-close.nav-open')).then(rightNav => {
        	driver.wait(until.elementIsEnabled(driver.findElement(By.css('.add-album-btn')))).then(albumButton => {
            driver.wait(until.elementIsVisible(albumButton));
          }).then(() => {
            console.log('-- Adding a new album')
            driver.findElement(By.css('.add-album-btn')).click().then(() => {
              console.log('--- Add album button clicked');
              var newAlbumForm = driver.findElement(By.id('album-upload'));
              driver.wait(newAlbumForm);
              populateNewAlbumFormFields(newAlbumForm);
              driver.findElement(By.css('button[type="submit"]')).click();
            }).then(() => {
              console.log('-- Verify that the album was created and the image was loaded');
                var albumLoadingElement = driver.findElement(By.id('album-loading'));
                driver.wait(until.elementLocated(By.id('upload-thumb-2')));
                albumLoadingElement.getAttribute('innerHTML').then(innerHTML => {
                  driver.findElements(By.css('#album-upload-thumbs .upload-thumb')).then(uploadedThumbs => {
                    assert.ok(uploadedThumbs.length > 0, 'No thumbnails are displayed');
                  });
                  driver.findElement(By.css('.add-album .cancel-upload')).click();
                });
            }).then(() => {
              driver.findElement(By.css('.right-nav-items .nav-item .add-photo-btn')).click().then(() => {
                console.log('-- Adding photo');
                driver.findElement(By.id('photo-upload')).then(photoUploadForm => {
                  driver.wait(until.elementIsEnabled(
                    photoUploadForm.findElement(By.xpath('//option[text()="album_' + startTime.getTime() + '"]'))
                  )).then(optionElement => {
                    driver.wait(until.elementIsVisible(optionElement));
                    return optionElement;
                  }).then(optionElement => {
                    optionElement.click();
                  });
                });
              });
            }).then(() => {
              console.log('-- Add image ' + imageFilePath)
              driver.findElement(By.css('#photo-upload #add-photo-input')).sendKeys(imageFilePath);
            }).then(() => {
              console.log('-- Submit photo update');
              driver.findElement(By.css('#photo-upload #add-photo-button')).click();
            }).then(() => {
              console.log('-- Wait for upload');
              driver.findElement(By.id('photos-loading')).then(element => {
                driver.wait(until.elementTextMatches(element, new RegExp('.*1 of 1.*', 'i')));
              });
            }).then(() => {
              console.log('-- Close Add Photo Form')
              driver.findElement(By.css('.add-photo .cancel-upload')).click();
            }).then(() => {
              console.log('-- Start Delete Album: album_' + startTime.getTime());
              rightNav.findElement(By.css('.delete-album-btn')).click();
            }).then(() => {
              console.log('-- Select the dropdown option: album_' + startTime.getTime());
              driver.findElement(By.xpath('//select[@id="delete-album-id"]/option[text()="album_' + startTime.getTime() + '"]')).click();
            }).then(t => {
              console.log('-- Selected album');
              driver.findElement(By.xpath('//form[@id="album-delete"]//button[text()="Delete Album"]')).click();
            }).then(() => {
              console.log('-- Deleted album');
              driver.findElement(By.css('.delete-album .cancel-upload')).click();
            }).then(() => {
              console.log('-- Create post');
              rightNav.findElement(By.css('.create-post-btn')).click().then(() => {
                driver.findElement(By.id('post-title')).sendKeys('Test Post ' + startTime.getTime());
                driver.findElement(By.id('post-body')).sendKeys('This is the body for a test post. It can be much longer, but for now it is short');
                driver.findElement(By.id('post-author')).sendKeys('author field is required by the form. we should change that');
                driver.findElement(By.id('post-photo')).sendKeys('Photo field is required by the form we should change that');
                driver.findElement(By.id('post-location')).sendKeys('San Francisco');
                driver.findElement(By.id('post-extract')).sendKeys('This is a short description of the post');
                driver.findElement(By.id('add-post-button')).click();
              });
            }).then(() => {
              console.log('-- Confirm that the post was uploaded');
              driver.findElement(By.id('post-loading')).getText().then(uploadMessage => {
                console.log('--- uploaded response message is: ' + uploadMessage);
                assert.ok(uploadMessage, 'There is no upload message');
                assert.equal(uploadMessage.toLowerCase(), 'post upload done', 'The upload message does not indicate success');
              });
            }).then(() => {
              console.log('-- Close Create Post Form');
              driver.findElement(By.css('.create-post .cancel-upload')).click();
              driver.get(host + '');
            }).then(() => {
              driver.findElement(By.xpath('//div[contains(@class, "article-container")]//h2[contains(@class, "entry-title")]/a[text()="Test Post ' + startTime.getTime() + '"]'))
              .getText().then(title => {
                console.log('-- Confirm post exists');
                console.log('--- Found post title: "' + title + '"');
                assert.equal(title.toLowerCase(), 'test post ' + startTime.getTime(), "The title doesn't match the post");
              });
            });
        	});
      });
    });
  });
}).then(() => {
  console.log('\n Tests Complete! \n');
});


driver.quit();

function getUserLoginForm() {
	return driver.findElement(By.id('user-login'));
}

function getAccountForm() {
	return driver.findElement(By.id('account-manager'));
}

function verifyLoginFormExists() {
	var loginForm = getUserLoginForm();
	loginForm.then(function(result){
		assert.ok(result, 'there is no user-login form');
	});

	return loginForm;
}

function populateNewAlbumFormFields(newAlbumForm) {
	console.log('--- creating a new album: album_' + startTime.getTime() + '\n');
	newAlbumForm.findElement(By.id('album-name')).sendKeys('album_'+startTime.getTime());
	newAlbumForm.findElement(By.id('album-photo-input')).sendKeys(imageFilePath);
}

function populateLoginFormFields(loginForm) {
	console.log('-- creating user for email: ' + username + '\n');
	loginForm.findElement(By.id('email')).sendKeys(username);
	loginForm.findElement(By.id('password')).sendKeys(password);
}

function trimTrailingSlash(stringToTrim) {
  return (stringToTrim.charAt(stringToTrim.length) == '/') ?
    stringToTrim.substring(0, stringToTrim.length - 1) : stringToTrim;
}

function logHelp() {
  console.log('----- Help For Ingenious Test Script -----');
  console.log();
  console.log('Example:\n');
  console.log('-- using default parameters:')
  console.log('    node ingenious-tests.js\n');
  console.log('-- using custom host and image:');
  console.log('    node ingenious-tests.js -u http(s)://<some-host> -i <absolute-path-to-image>\n');
  console.log('Options:\n');
  console.log('  -h  display this help');
  console.log('  -u  URL of the host to test against, you must specify the scheme: ex. https://k8s.mra.nginxps.com, defaults to http://localhost');
  console.log('  -i Absolute path to the image file on your system: ex. /Users/username/repos/mra-ingenious/tests/nginx.jpg\n\n');
}
