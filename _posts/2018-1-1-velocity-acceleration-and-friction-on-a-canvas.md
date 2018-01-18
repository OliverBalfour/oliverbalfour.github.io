---
layout: post
title: "Implementing Velocity, Acceleration and Friction on a Canvas"
categories: canvas
tags: canvas javascript physics
---

## Definition
First of all we have to understand what velocity, acceleration and friction are, and how they can be conveyed with code.

### Velocity
Velocity is a vector (meaning it has magnitude and direction) that conveys the amount at which an object will travel in a given amount of time. In physics, this amount of time is typically 1 second. In all examples in this post, however, the unit of time will be the time passing between each frame, so 1 sixtieth of a second (on average). If accuracy is a big deal for you, or you would prefer to have your velocity measured in metres/second, then what you can do is calculate the time in seconds between the current and last frame and multiply the m/s variant of the velocity by that fraction of a second.

Velocity is typically represented in x, y, and z components (z only if you are working in 3D). To keep things short, variables are typically named vx, vy and vz, with the 'v' standing for 'velocity.' Every frame, we will add the vx, vy and vz components of each object to the x, y and z positions of the object.

### Acceleration
Acceleration is another vector, represented the same way as velocity. It is also typically represented in x, y and z components, often named ax, ay and az. Every frame we will add the acceleration values to their velocity counterparts, resulting in, well, acceleration. One thing to note is that unless you want an object visibly accelerating, the magnitude of the acceleration should be 0.

### Friction
Friction is the force that slows things down. It is caused by objects rubbing against each other, or by things hitting something travelling at speed and, hence, slowing down. Friction is subtractive of velocity, meaning that you subtract the value you have in place for friction from the magnitude of the velocity vector (not the individual x, y components).

## Implementation
Now that we (hopefully) have an understanding of what velocity, acceleration and friction are, we can attempt to write up a simulation of the three forces with JavaScript. A simple implementation of all three looks somewhat like this:

```js
function updatePosition(obj){
	//update velocity
	obj.vx += obj.ax;
	obj.vy += obj.ay;

	//cheat's friction (friction = 0.97)
	obj.vx *= friction;
	obj.vy *= friction;

	//update position
	obj.x += obj.vx;
	obj.y += obj.vy;
}
```

This can be used in our animations to produce realistic motion. What we're going to do with that code is simulate a spaceship, however, at first without the friction.

```css
canvas{
	background: black;
}
```

```js
//canvas setup up here

var spaceship = {
	x: canvas.width / 2, y: canvas.height / 2,
	vx: 0, vy: 0,
	ax: 0, ay: 0,
	r: 0,
	draw: function(){
		ctx.save();
		ctx.translate(this.x, this.y);
		ctx.rotate(this.r);
		ctx.fillStyle = 'white';
		ctx.fillRect(-10, -5, 20, 10);
		ctx.restore();
	}
};

function updatePosition(obj){
    //update velocity
    obj.vx += obj.ax;
    obj.vy += obj.ay;

    //update position
    obj.x += obj.vx;
    obj.y += obj.vy;
}

//user interactivity

var keys = [];
document.addEventListener('keydown', function(e){
	keys[e.which] = true;
});
document.addEventListener('keyup', function(e){
	keys[e.which] = false;
});

(function animloop(){
	requestAnimationFrame(animloop, canvas);
	ctx.clearRect(0, 0, canvas.width, canvas.height);

	//rotation
	if(keys[37]) spaceship.r -= 0.05;
	if(keys[39]) spaceship.r += 0.05;

	//thrust
	if(keys[38]){
		spaceship.ax = Math.cos(spaceship.r) * 0.05;
		spaceship.ay = Math.sin(spaceship.r) * 0.05;
	}else{
		spaceship.ax = spaceship.ay = 0;
	}

	updatePosition(spaceship);
	spaceship.draw();
})();
```

There we have it. A basic spaceship simulation controlled by arrow keys. The only problem with it, though, is that there is no friction, so the spaceship will just drift endlessly when left untouched.

[[[pen ONWmRd]]]

There we have it. It works, but we need to have friction or else it's nearly unusable.

### Friction
There are two ways to implement friction. One is the correct way, which is slightly more CPU intensive, but more accurate. You should always do it the proper way in simulations, but there is also a cheat's way, which we'll use most of the time because it's easier to type.

#### The correct way
As I said in the definition, friction is *subtractive* of velocity. This essentially means that you subtract the friction value from the magnitude of the velocity, until it reaches 0 (it can't go beyond 0). So, first we'll need to learn how to split cartesian x, y values into magnitude and direction.

To convert cartesian coordinates into polar coordinates (which are composed of magnitude and direction instead of x and y), we have to use a bit of trigonometry. The magnitude can be achieved using the Pythagorean theorem, and the direction with JavaScript's amazing `Math.atan2` function. Look it up if you aren't familiar with it, as it's amazing.

```js
var magnitude = Math.sqrt(x * x + y * y), //or Math.hypot(x, y)
	direction = Math.atan2(y, x);
```

To convert polar coordinates back to their cartesian counterparts, simply use the sine and cosine functions to find the 'missing sides'. As per usual, cosine is used for the x value, sine for the y.

```js
var x = Math.cos(direction) * magnitude,
	y = Math.sin(direction) * magnitude;
```

Now that we can easily convert to and from polar coordinates, we can use our knowledge to make our friction. The code, in essence, looks like this:

```js
var speed = Math.sqrt(vx * vx + vy * vy),
	angle = Math.atan2(vy, vx);
if(speed > friction){
	speed -= friction;
}else{
	speed = 0;
}
vx = Math.cos(angle) * speed;
vy = Math.sin(angle) * speed;
```

A good value for friction would be 0.01, the number I use in the simulation below. If you're going to use the proper method for friction, I'd suggest wrapping it in a function for ease of access. It is rather lengthy, especially compared to the cheat version of friction, which is mathematically incorrect but looks ok. The updated spaceship simulation looks like this:

{% include codepen-embed.html slug="qZRmpx" %}

See how much better and realistic it is?

#### The cheat's way
The cheat's way of achieving friction is to simply multiply the velocity x and y components by a constant, a decimal close to (but less than) 1. The only problem (other than it being mathematically incorrect and a dangerous shortcut) is that you can end up with squarish (rather than roundish) results if you're not careful, because the friction can reduce one part of the velocity (x) to 0 while the other isn't yet nullified, which makes things look wacky.

```js
var friction = 0.95;

(function animloop(){
	...
	vx *= friction;
	vy *= friction;
	...
})();
```

Yes, it's that simple. And it's very hard to tell the difference between that and the proper implementation. Only it can't be used in high precision and accuracy requiring projects, just crappy games.

{% include codepen-embed.html slug="jqympW" %}

The difference isn't exactly noticeable, excluding the fact that the strength of the friction differs slightly due to the value chosen.

## Wrapping up
There you are. You now have three new tools under your belt. Hopefully you'll actually remember all of that. Anyway, thanks for reading, and if you liked that, there's plenty more where it came from. See you next time!
