---
layout: post
title: "Building a Simple Chat Room with PHP"
tags: php
categories: archive
edited: 2018-1-19
---

[PHP is awful.](https://eev.ee/blog/2012/04/09/php-a-fractal-of-bad-design/) If you're learning it by choice, don't. Use something else, like node.js, Ruby on Rails, Python Django, or anything really. However, there are environments where PHP is the only option and I respect that. For a beginning programmer, free PHP hosts are often the easiest way to get things online. This tutorial shows how to make a very simple chat room in which you need to refresh the page to update the chat. Whilst I may cover automatic updating using server pinging in a future tutorial, that requires JavaScript which is out of the scope of this tutorial.

First of all you'll need your basic HTML skeleton. Save the following file as `chat.php`; there's nothing here to explain.

```php
<!DOCTYPE html>
<html>
	<head>
		<title>Chat Room</title>
		<meta charset='UTF-8' />
		<style>
		/* Add CSS here */
		</style>
	</head>
	<body>
		<!-- Add HTML here -->
	</body>
</html>
```

The way this chat room will work is as follows:

1. The user goes onto the chat room (`chat.php`)
2. If they haven't already chosen a username, they will do so by entering it into a basic GET form. The page will refresh with the chosen username in the query string (/index.php?username=blah).
3. When they have a username, they will see a log of all previous chat messages, and at the bottom, a form that allows them to send a message.
4. The page will refresh upon sending their message and the user will see their message (along with any other messages posted since they last refreshed the page), as well as all previous messages.

## Username selection

The 'login' form is simple; if the GET parameter `username` isn't set it asks for one, otherwise it shows the chat. Of course, it's not an account based login system, however feel free to implement one when you are done.

```php
<?php
// If they haven't already logged in, display login form
// Simple GET form that GETs the active page, so pressing 'Start Chatting' navigates them to /chat.php?username=Hello
if (!isset($_GET['username'])) {
?>
<form method='GET' id='login-form'>
	<h1>Log in</h1>
	<input name='username' placeholder='Username' /><br>
	<button type='submit'>Start Chatting</button>
</form>
<?php
// Otherwise, display chat room
} else {
	// Don't forget to protect the username from XSS!
	$username = htmlspecialchars($_GET['username']);
?>
<!-- Rest of chat room -->
<?php
}
?>
```

In the above code we called `htmlspecialchars` on the username string. This is because of XSS (cross-site scripting), a security vulnerability that occurs in webpages. If we set our username to `<script>alert("I'm a 1337 HAX0R")</script>` without escaping the HTML characters (`<`, `>`), then that malicious code would execute every time that user sent a message and had their username added to the page. A general rule is to never trust user data; always sanitise it first.

## Writing the chat page

Now, with that set up we can program the chat page. In the last snippet, before the 'Rest of chat room' comment, we defined a variable called `$username`, which will be used throughout the rest of the chat room. In our message sending form, we will need to add a hidden input field that contains the username to avoid having to log in again every time you send a message and trigger a page refresh.

```php
<?php
// 1: Add sent message, if any, to the chat log
?>
<div id='chat-log'><?php
// 2: Insert messages here
?>
</div>
<div id='message-bar'>
	<form method='POST'>
		<input name='username' type='hidden' value='<?php echo $_GET['username'] ?>' />
		<textarea name='message' placeholder='Message' maxlength='2500'></textarea><br>
		<button type='submit'>Send</button>
	</form>
</div>
```

Above we have implemented the message sending form, with a hidden `username` value. Now, in there you have probably noticed the two empty PHP tags. Those two places are where the rest of our logic will go. In the first one will be the code to check if the user has just sent a message, and if so, to add it to the chat log. For now, we'll just use a plain text file as a chat log, but you may want to use a database for a more complex chat application. Open and save a new blank file called log.txt and change the file permissions so that only the server can read the file.

So, now that we have a chat log, we'll be able to log to it. This code, if a message has been POSTed, will append the message as HTML to the end of the log.txt file. Note that this is a very naive approach &mdash; if we wanted to change message markup we'd have to manually go through the file and change it or scrap the older logs. Dumping messages in plaintext or JSON and then formatting them later is a better approach, but more verbose. The following code goes into the first empty PHP tag from above. (The dot `.` operator in PHP concatenates strings, so `$current . $new` adds them together.)

```php
if(isset($_POST['message'])){
	// Prevent XSS with the htmlspecialchars function
	$message = htmlspecialchars($_POST['message']);
	$current = file_get_contents('log.txt');
	$new = '
	<div class=\'message\'>
		<strong>$username</strong><br>
		$message
	</div>';
	file_put_contents('log.txt', $current . $new);
}
```

Because we cut corners in the code above, to display the chat log all we need to do is print the contents of the log file into the second empty PHP tag.

```php
// Display the chat log
echo file_get_contents('log.txt');
```

Here's the code so far:

```php
<!DOCTYPE html>
<html>
	<head>
		<title>Chat Room</title>
		<meta charset='UTF-8' />
		<style>
		/* CSS */
		</style>
	</head>
	<body>
	<?php
	// If they haven't already logged in, display  login form
	if (!isset($_GET['username'])) {
	?>
	<form method='GET' id='login-form'>
		<h1>Log in</h1>
		<input name='username' placeholder='Username' /><br>
		<button type='submit'>Start Chatting</button>
	</form>
	<?php
	// Otherwise, display chat room
	} else {
		// Don't forget to protect the username from XSS!
		$username = htmlspecialchars($_GET['username']);
	?>
	<?php
	if (isset($_POST['message'])) {
		// Prevent XSS with the htmlspecialchars function
		$message = htmlspecialchars($_POST['message']);
		$current = file_get_contents('log.txt');
		$new = '
		<div class=\'message\'>
			<strong>$username</strong><br>
			$message
		</div>';
		file_put_contents('log.txt', $current . $new);
	}
	?>
	<div id='chat-log'><?php
	// Display the chat log
	echo file_get_contents('log.txt');
	?>
	</div>
	<div id='message-bar'>
		<form method='POST'>
			<input name='username' type='hidden' value='<?php echo $_GET['username'] ?>' />
			<textarea name='message' placeholder='Message' maxlength='2500'></textarea><br>
			<button type='submit'>Send</button>
		</form>
	</div>
	<?php
	}
	?>
	</body>
</html>
```

## Improving the chat room

Now we're done with the core functionality of the chat room. You should be able to test it out with multiple people over a network, however the experience isn't great. Here are some ideas for improvement:

 - Automatically load messages from the server as they are posted. There are two ways of doing this: server pinging and WebSockets. WebSockets are, to my knowledge, not easy to work with in PHP, but server pinging is as easy as using a JavaScript `setInterval` timer to periodically request a page, `ping.php`, which returns any newly posted messages.
 - Change the message sending form to ping the server using an `XMLHttpRequest` instead of reloading the page.
 - Add better CSS. I've written some below, but it's still very basic.
 - Add a login system, or at least prevent duplicate or null/empty usernames.
 - Character limits and rate limiting to avoid spamming. Rate limiting can be achieved by comparing the timestamps of a pending message and the last message and discarding the message if the difference in time is too close. To do this, you'll need to associate timestamp data with messages. (This would also make server pinging easier as the server script would be able to accept the timestamp of the last seen message to continue from.)

Now, we're done with the core functionality of the chat room, but it looks awful. We'll add some CSS to the final product. Here's some CSS, feel free to use this as a starting point. I'm not a designer though, so don't expect anything amazing.

```css
* { box-sizing: border-box; }
h1 {
	font-weight: 300;
	font-family: sans-serif;
}
#login-form {
	position: absolute;
	top: calc(50% - 120px);
	left: calc(50% - 180px);
	height: 240px;
	width: 360px;
	background: antiquewhite;
	padding: 30px;
}
#login-form input {
	width: 100%;
	padding: 5px;
	margin-bottom: 10px;
}
#login-form input:focus {
	outline: none;
}
#login-form button {
	padding: 15px;
	width: 100%;
	background: lightblue;
	border: 0;
	display: block;
	margin: auto;
	border-radius: 7px;
	cursor: pointer;
}
#login-form button:hover {
	background: skyblue;
}
#chat-log {
	position: absolute;
	top: 0;
	left: 0;
	position: absolute;
	height: calc(100% - 60px);
	width: 100%;
	padding: 10px;
	overflow: auto;
}
.message {
	background: antiquewhite;
	margin: 20px;
	padding: 10px;
	border-radius: 5px;
}
.message strong {
	font-family: sans-serif;
}
#message-bar {
	position: absolute;
	bottom: 0;
	left: 0;
	height: 60px;
	width: 100%;
	overflow: hidden;
}
#message-bar textarea {
	height: 60px;
	width: calc(100% - 80px);
	resize: none;
	border: 0;
	border-top: 1px solid lightblue;
	padding: 5px;
}
#message-bar textarea:focus {
	outline: none;
	border-top: 1px solid skyblue;
}
#message-bar button {
	position: absolute;
	top: 0;
	right: 0;
	height: 60px;
	width: 80px;
	background: lightblue;
	border: 0;
	cursor: pointer;
}
#message-bar button:hover {
	background: skyblue;
}
```

Thanks for reading.
