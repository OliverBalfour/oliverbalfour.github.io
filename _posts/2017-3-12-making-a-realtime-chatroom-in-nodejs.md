---
layout: post
title: "Making a Realtime Chat Room in Node.js"
categories: canvas
tags: nodejs websockets expressjs javascript
---

Obviously, you'll need Node.js for this (https://nodejs.org) which as of writing this post the latest version is v7.4.0 and the latest stable version is v6.9.4.

## Getting started

We'll create a brand new node application in a new folder and initialise it with a pretty much empty `package.json` file:

```json
{
  "name": "realtime-nodejs-chat",
  "version": "1.0.0",
  "description": "A simple realtime nodejs powered chat application."
}
```

Then we install a few dependencies; the ones we need for now are express (simple http server with programmable routing) and socket.io (powerful WebSockets server and client)

`npm install --save express`
`npm install --save socket.io`

## Hello World

Now we are able to start writing our chat app. In a new file, `index.js`, we'll place all of our server side code. Below is a Hello World express application. It does very little for now; simply sending the HTML file `index.html` to any requests to the root of the server (http://localhost:3000/)

```js
const express = require('express')();
const http = require('http').Server(express);
const path = require('path');

express.get('/', (req, res) => {
	res.sendFile(path.join(__dirname, 'index.html'));
});

http.listen(3000, () => {
	console.log('Loaded to http://localhost:3000/');
});
```

Of course, for us to send the file `index.html` it has to exist. Create it and paste in `<h1>Hello, World!</h1>`, just a placeholder for now.

Now you can see it for yourself. Simply run `node index.js` or `node index` in the directory where the files are, and then open http://localhost:3000/ in your browser to see `Hello, World!` emblazoned in huge text across your screen.

Once you're satisfied that it works so far, we'll start building the chat room itself.

## Using usernames

First, we'll initialise socket.io on the server and listen in on the connection event. Socket.io (and by extension WebSockets) are quite simple; the server connects to various sockets (clients) and exchanges data. This realtime communication system is what powers just about every chat application, online game or other I/O heavy server system ever.

The socket.io API revolves primarily around the `io` connection event; for it is there that sockets are received and worked with.

```js
const express = require('express')();
const http = require('http').Server(express);
const path = require('path');
const io = require('socket.io')(http);

io.on('connection', (socket) => {
	console.log('A new user has connected with ID: ' + socket.id);

	//All of our logic will go here
	//...

	socket.on('disconnect', () => {
		console.log('A user disconnected. ID: ' + socket.id);
	});
});

express.get('/', (req, res) => {
	res.sendFile(path.join(__dirname, 'index.html'));
});

http.listen(3000, () => {
	console.log('Loaded to http://localhost:3000/');
});
```

Then we replace the HTML in `index.html` with something useful. Nothing fancy, just a workable form asking for a username for now. I'm not going to include the `head` section or anything like that, just plug everything into a basic HTML template.

For the form to actually work and do something, we need to load in the socket.io client, connect, and use it to alert the server of our username when ready.

```html
<div id='login'>
	<input id='name' placeholder='Username' />
	<button onclick='startChatting()'>Start chatting</button>
</div>
```

Now, that relies upon there being a function, `startChatting`, which we'll now write. `startChatting` will send the client's username via socket.io to the server, and then let the user start chatting. To use socket.io, we need to actually link to it in our HTML. Then, we initialise the client's socket and define our `startChatting` function. (We'll use ES5 for compatibility.)

```html
<script src="/socket.io/socket.io.js"></script>
<script>
	var socket = io();

	function startChatting(){
		socket.emit('login', document.getElementById('name').value, function(nameIsOk){
			if(nameIsOk){
				//Change screens to the chatting screen which we haven't made yet
			}else{
				//Invalid name
				alert('Invalid name!');
			}
		});
	}
</script>
```

Now, when the user wishes to start chatting, they can press the button, which sends the value of the username field via socket.io as a `login` event. Events can be named whatever you want them to be, and you can have as many as you want. To send a message from the client to the server, you use `socket.emit(evt_name, data)` where data can be pretty much anything. (You'll need to refer to the [socket.io docs](http://socket.io/docs/) for that though.)

Then, as well as simply emitting an event, we've given an optional callback function, called an acknowledgement. Put simply, this means that the server will pass some data back to that callback; in this case a boolean indicating whether the client has submitted a valid name or not.

So what we must do next is listen for the `login` event on the server with the following code. We validate the name, send back some data to say the name's ok (or not) and then broadcast to all other clients the new client's name. To broadcast to all other clients from the server, we use `socket.broadcast.emit`, whilst we would normally use `io.emit` to send messages.

As for name validation, anything between 1 and 20 characters, with whitespace trimmed, will do for now.

```
io.on('connection', (socket) => {
	console.log('A new user has connected with ID: ' + socket.id);

	socket.on('login', (name, acknowledge) => {

		//If the name isn't a string, they're a hacker
		if(typeof name !== 'string')
			return;

		//Remove whitespace on left and right; '  a name ' becomes 'a name'
		name = name.trim();

		//If the name is between 1 and 20 chars long (inclusive) it's valid
		if(name.length >= 1 && name.length <= 20){
			console.log(name + ' joined the chat room');

			//Send back data saying the name is valid
			acknowledge(true);

			//Alert all other users of the successful login
			socket.broadcast.emit('loggedin', name);

			//Save their username
			socket.username = name;

		}else{
			//Oops! Invalid name...
			acknowledge(false);
		}

	});

	socket.on('disconnect', () => {
		if(socket.username){
			//Change from logging ID to logging username
			console.log(socket.username + ' left the chat');

			//Emit a loggedout event
			io.emit('loggedout', socket.username);
		}
	});
});
```

So we now have a new event, `loggedin`, being sent to every user other than the logged in user (they are notified by the acknowledgement.) Now that we have that, we can build the chat room itself and listen in on the `loggedin` event on the client. We also have code to emit an event, `loggedout`, when a user disconnects. We'll listen in on that as well soon.

## Building the chat room itself

First we'll build the HTML structure of the chat room. It'll be relatively simple to start off with, and you'll have to write your own CSS. We will need one CSS class though, `.hidden`, which'll do as the name implies.

```css
.hidden{
	display: none;
}
```

```html
<div id='chat' class='hidden'>
	<div id='messages'>
		<!-- This will be where the messages appear -->
	</div>
	<input id='message' placeholder='Message' />
	<button onclick='sendMessage()'>Send message</button>
</div>
```

Now we are nearly ready to set up sending messages. Before we do, though, we need to set up changing from the first screen, the login screen, to the chat screen. Doing that is quite simple; we simply use the `classList` API to swap which screen is `.hidden` and which isn't. We put this code in the `if(nameIsOk){ ... }` part; but don't copy it just yet. Also in that `if` clause, we will utilise a function `addMessage` which we will write shortly to show a server welcome message.

```js
//Change screens to the chatting screen
document.getElementById('login').classList.add('hidden');
document.getElementById('chat').classList.remove('hidden');

//Add a server message saying this client has joined
addMessage(name + ' joined the server. Welcome to the chat room!');
```

Then we can listen in on the `loggedin` and `loggedout` events and show more server messages.

```js
socket.on('loggedin', function(username){
	addMessage(username + ' joined the server. Welcome to the chat room!')
});
socket.on('loggedout', function(username){
	addMessage(username + ' has left. See you next time!');
});
```

And finally, we write the `addMessage` and `sendMessage` functions. We also add a listener for the new `chatmessage` event and the client is done; just a tad of server code left. The addMessage function adds a message to the messages element, showing it on screen; while the sendMessage function emits a `chatmessage` event. The listener for `chatmessage` will simply be `addMessage` itself!

```js
function addMessage(msg){
	document.getElementById('messages').innerHTML += "<div class='msg'>" + msg + "</div>";
}

function sendMessage(){
	socket.emit('chatmessage', document.getElementById('message').value);

	var username = document.getElementById('name').value;
	addMessage(username + ': ' + document.getElementById('message').value);

	document.getElementById('message').value = '';
}

//The chatmessage event listener adds the message straight to the element `div#messages`
socket.on('chatmessage', addMessage);
```

Here is the full client code:

```html
<style>
.hidden{
	display: none;
}
</style>
<div id='login'>
	<input id='name' placeholder='Username' />
	<button onclick='startChatting()'>Start chatting</button>
</div>
<div id='chat' class='hidden'>
	<div id='messages'>
		<!-- This will be where the messages appear -->
	</div>
	<input id='message' placeholder='Message' />
	<button onclick='sendMessage()'>Send message</button>
</div>
<script src="/socket.io/socket.io.js"></script>
<script>
	var socket = io();

	function startChatting(){
		var name = document.getElementById('name').value;

		socket.emit('login', name, function(nameIsOk){
			if(nameIsOk){
				//Change screens to the chatting screen
				document.getElementById('login').classList.add('hidden');
				document.getElementById('chat').classList.remove('hidden');

				//Add a server message saying this client has joined
				addMessage(name + ' joined the server. Welcome to the chat room!');
			}else{
				//Invalid name
				alert('Invalid name!');
			}
		});
	}

	function addMessage(msg){
		document.getElementById('messages').innerHTML += "<div class='msg'>" + msg + "</div>";
	}

	function sendMessage(){
		socket.emit('chatmessage', document.getElementById('message').value);

		var username = document.getElementById('name').value;
		addMessage(username + ': ' + document.getElementById('message').value);

		document.getElementById('message').value = '';
	}

	socket.on('loggedin', function(username){
		addMessage(username + ' joined the server. Welcome to the chat room!')
	});
	socket.on('loggedout', function(username){
		addMessage(username + ' has left. See you next time!');
	});

	//The chatmessage event listener adds the message straight to the element `div#messages`
	socket.on('chatmessage', addMessage);
</script>
```

Now all that's left is finishing off the server. We just need to handle the `chatmessage` event and broadcast the message to all clients other than the sender and the rest will tie in together perfectly. Put the following code right between the `login` event handler and the `disconnect` event handler in `index.js`.

```js
socket.on('chatmessage', function(message){
	if(typeof message !== 'string')
		return;

	message = message.trim();

	//If the client is logged in and the message is valid, send the message!
	if(socket.username && message.length > 0 && message.length <= 2000){
		socket.broadcast.emit('chatmessage', socket.username + ': ' + message);
	}
});
```

The full `index.js` is below:

```js
const express = require('express')();
const http = require('http').Server(express);
const path = require('path');
const io = require('socket.io')(http);

io.on('connection', (socket) => {
	console.log('A new user has connected with ID: ' + socket.id);

	socket.on('login', (name, acknowledge) => {

		//If the name isn't a string, they're a hacker
		if(typeof name !== 'string')
			return;

		//Remove whitespace on left and right; '  a name ' becomes 'a name'
		name = name.trim();

		//If the name is between 1 and 20 chars long (inclusive) it's valid
		if(name.length >= 1 && name.length <= 20){
			console.log(name + ' joined the chat room');

			//Send back data saying the name is valid
			acknowledge(true);

			//Alert all other users of the successful login
			socket.broadcast.emit('loggedin', name);

			//Save their username
			socket.username = name;

		}else{
			//Oops! Invalid name...
			acknowledge(false);
		}

	});

	socket.on('chatmessage', function(message){
		if(typeof message !== 'string')
			return;

		message = message.trim();

		//If the client is logged in and the message is valid, send the message!
		if(socket.username && message.length > 0 && message.length <= 2000){
			socket.broadcast.emit('chatmessage', socket.username + ': ' + message);
		}
	});

	socket.on('disconnect', () => {
		if(socket.username){
			//Change from logging ID to logging username
			console.log(socket.username + ' left the chat');

			//Emit a loggedout event
			io.emit('loggedout', socket.username);
		}
	});
});

express.get('/', (req, res) => {
	res.sendFile(path.join(__dirname, 'index.html'));
});

http.listen(3000, () => {
	console.log('Loaded to http://localhost:3000/');
});
```

## Finishing off

This is an extremely simple chat room, similar to a basic implementation of IRC. There are loads of things you could do to make this better. Here is a list of ideas for expanding the chat room:

 - Checking for duplicate nicknames
 - Logging messages and letting users scroll up to see older messages
 - @mentioning
 - Accounts
 - An online user list
 - 'user123 is typing...'
 - Direct messaging
 - Rate limiting
 - Links and images
 - Moderation
 - File uploads

Any other ideas? Feel free to share them in the comments!
