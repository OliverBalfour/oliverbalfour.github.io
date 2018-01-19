---
layout: post
title: "Building a Simple Chat Room with PHP"
tags: php
categories: archive
---

[PHP is awful.](https://eev.ee/blog/2012/04/09/php-a-fractal-of-bad-design/) If you're learning it by choice, don't. Use something else, like node.js, Ruby on Rails, Python Django, or anything really. However, there are environments where you can't use anything but PHP and I respect that. For a beginning programmer, free PHP hosts are often the easiest way to get things online. This tutorial shows how to make a very simple chat room in which you need to refresh the page to update the chat.

First of all you'll need your basic HTML skeleton.

Save this file as index.php; there's nothing here to explain.

```php
<!DOCTYPE html>
<html>
<head>
<title>Chat Room</title>
<meta charset='UTF-8' />
</head>
<body>
<style>
/* Add CSS here */
</style>
<!-- Add HTML here -->
</body>
</html>
```

The way it will work is like this: The user goes onto the chat room. If they haven't already chosen a username, they will do so by entering it into a basic GET form. The page will refresh with the chosen username in the query string (/index.php?username=blah). Now, when they are logged in, they will see a log of all previous chat messages, and at the bottom, a form that allows them to send a message. The page will refresh upon sending their message and the user will see their message (and any other messages posted since they last refreshed the page) logged to the chat log, as well as all previous messages.

The login form is simple; if the GET parameter 'username' isn't set it asks for one, otherwise it shows the chat.

```php
<?php
//if they haven't already logged in, display login form
if(!isset($_GET['username'])){
?>
<form method='GET' id='login-form'>
	<h1>Log in</h1>
	<input name='username' placeholder='Username' /><br>
	<button type='submit'>Start Chatting</button>
</form>
<?php
//otherwise, display chat room
}else{
	//don't forget to protect the username from XSS!
	$username = htmlspecialchars($_GET['username']);
?>
<!-- Rest of chat room -->

<?php
}
?>
```

Now, with that set up we can code the chat page. In the last snippet, before the 'Rest of chat room' comment, we defined a variable called $username, which will be used throughout the rest of the chat room. We need to remember to put a hidden input tag containing the username so that on page refresh you won't need to log in again.

```php
<?php

?>
<div id='chat-log'><?php

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

Now, in there you have probably noticed the two empty PHP tags. Those two places are where the rest of our logic will go.

In the first one will be the code to check if the user has just sent a message, and if so, to add it to the chat log.

Hang on, what chat log? There's no chat log ... yet. Open and save a new blank file called log.txt and change the file permissions so that only the server can read the file.

So, now that we have a chat log, we'll be able to log to it. This code, if a message has been POSTed, will append the message to the end of the log.txt file. The code is surprisingly simple, isn't it? (Put this in the first empty PHP tag.)

```php
if(isset($_POST['message'])){
	//prevent XSS with the htmlspecialchars function
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

And the final bit of PHP that makes all the difference: (Put this in the second empty PHP tag.)

```php
//display the chat log
echo file_get_contents('log.txt');
```

Here's the code so far:

```php
<!DOCTYPE html>
<html>
<head>
<title>Chat Room</title>
<meta charset='UTF-8' />
</head>
<body>
<style>
/* CSS */

</style>
<?php
//if they haven't already logged in, display  login form
if(!isset($_GET['username'])){
?>
<form method='GET' id='login-form'>
	<h1>Log in</h1>
	<input name='username' placeholder='Username' /><br>
	<button type='submit'>Start Chatting</button>
</form>
<?php
//otherwise, display chat room
}else{
	//don't forget to protect the username from XSS!
	$username = htmlspecialchars($_GET['username']);
?>
<?php
if(isset($_POST['message'])){
	//prevent XSS with the htmlspecialchars function
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
//display the chat log
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

Now, we're done with the core functionality of the chat room, but it looks astoundingly dreadful. We'll add some CSS to the final product.

This is, of course, a very very simple example and not by any means a good way to make a chat room. For a good chat room nodejs would be the best way to go.

Here's some CSS, feel free to use this however you wish.

```css
*{
	box-sizing: border-box;
}

h1{
	font-weight: 300;
	font-family: sans-serif;
}

#login-form{
	position: absolute;
	top: calc(50% - 120px);
	left: calc(50% - 180px);
	height: 240px;
	width: 360px;
	background: antiquewhite;
	padding: 30px;
}
#login-form input{
	width: 100%;
	padding: 5px;
	margin-bottom: 10px;
}
#login-form input:focus{
	outline: none;
}
#login-form button{
	padding: 15px;
	width: 100%;
	background: lightblue;
	border: 0;
	display: block;
	margin: auto;
	border-radius: 7px;
	cursor: pointer;
}
#login-form button:hover{
	background: skyblue;
}

#chat-log{
	position: absolute;
	top: 0;
	left: 0;
	position: absolute;
	height: calc(100% - 60px);
	width: 100%;
	padding: 10px;
	overflow: auto;
}
.message{
	background: antiquewhite;
	margin: 20px;
	padding: 10px;
	border-radius: 5px;
}
.message strong{
	font-family: sans-serif;
}

#message-bar{
	position: absolute;
	bottom: 0;
	left: 0;
	height: 60px;
	width: 100%;
	overflow: hidden;
}
#message-bar textarea{
	height: 60px;
	width: calc(100% - 80px);
	resize: none;
	border: 0;
	border-top: 1px solid lightblue;
	padding: 5px;
}
#message-bar textarea:focus{
	outline: none;
	border-top: 1px solid skyblue;
}
#message-bar button{
	position: absolute;
	top: 0;
	right: 0;
	height: 60px;
	width: 80px;
	background: lightblue;
	border: 0;
	cursor: pointer;
}
#message-bar button:hover{
	background: skyblue;
}
```

Thanks for reading. Feel free to mess around.
