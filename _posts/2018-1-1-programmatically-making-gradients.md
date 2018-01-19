---
layout: post
title: "Programmatically Making Gradients"
categories: canvas
tags: canvas javascript
---

In this post we will make gradients without using any of the functions built into the canvas's context for making them. In other words, we'll learn how to make a gradient without using `createLinearGradient` or `createRadialGradient`. Why? Simple. You can do much more with these gradients, as you can interpolate between colours in any way you like, like using cosine interpolation rather than linear for a linear gradient. Also, if you understand how it works, you will better understand how to make metaballs. (I'll probably write a post on them soon, they're really cool.)

## Making a linear gradient
To make our gradient, we need to have two colours: the start and end colours. We'll have them in an object format, with r, g and b properties.

```js
var startColour = {r: 0, g: 255, b: 50},
	endColour = {r: 255, g: 0, b: 100};
```

Then, we simply need to go across the screen, drawing values from an interpolation function. Here is that function, a simple linear interpolation (lerp) function:

```js
function interpolate(a, b, x){
	return a * (1 - x) + b * x;
}
```

It's that easy. Then, we just pass each element of the colour into that function. We do this for every pixel along the length of the gradient. All in all, it's very simple.

```js
var currentColour = {r: startColour.r, g: startColour.g, b: startColour.b},
	x = 0,
	percent = 0;
while(x < w){
	percent = x / w;

	currentColour.r = Math.floor(startColour.r * (1 - percent) + endColour.r * percent);
	currentColour.g = Math.floor(startColour.g * (1 - percent) + endColour.g * percent);
	currentColour.b = Math.floor(startColour.b * (1 - percent) + endColour.b * percent);

	ctx.fillStyle = 'rgb('+currentColour.r+', '+currentColour.g+', '+currentColour.b+')';
	ctx.fillRect(x, 0, 1, h);
	x++;
}
```

Remember when setting the fill style to make sure the r, g and b values are all whole numbers!

{% include codepen-embed.html slug="oxYzde"%}

You can easily make our linear gradient work like a normal one. However, that's for you to do, and only if you want to. But before you go and make something like a traditional `createLinearGradient`, we'll be making that gradient with cosine interpolation you were promised!

### Cosine interpolation
The code for cosine interpolation looks like this:

```js
function interpolate(a, b, px){
	var ft = px * Math.PI,
		f = (1 - Math.cos(ft)) * 0.5;
	return  a * (1 - f) + b * f;
}
```

If you use it as a replacement for the linear interpolation function, you get this result:

{% include codepen-embed.html slug="zqoNrm"%}

There isn't much difference, but if you compare it closely with the last one, you'll find it eases in and out, whereas linear interpolation is, well, linear and ugly. But, truth be told, it's still ugly. There is a reason behind this, based on the way computers render colors. To get rid of the weird brown line in the middle of the gradient, you need to square the rgb values of the start and end colors, and get the square root of the colour values after operating on them. To see why, take a look at this video: https://youtu.be/LKnqECcg6Gw

That makes these changes to the code we already have for a plain linear gradient:

```js
startColour = {
	r: 0,
	g: 255 * 255,
	b: 50 * 50
};

endColour = {
	r: 255 * 255,
	g: 0,
	b: 100 * 100
};
```

And inside the loop, we do this to calculate the color at each step along the way:

```js
currentColour.r = Math.floor(Math.sqrt(startColour.r * (1 - percent) + endColour.r * percent));
currentColour.g = Math.floor(Math.sqrt(startColour.g * (1 - percent) + endColour.g * percent));
currentColour.b = Math.floor(Math.sqrt(startColour.b * (1 - percent) + endColour.b * percent));
```

{% include codepen-embed.html slug="WwpoBv"%}

## Making a radial gradient
This is much more complicated in terms of maths, but is still relatively easy to implement. We can also (sort of) cheat. By simply reversing the while loop so it runs backwards, we can effectively use the `arc` function to draw each layer. If you feel that this is too cheaty, by all means use trigonometry to do it instead. The advantage of that is that you can make oval shaped gradients as well, and it looks sharper. (Though, once again, you could cheat using the `scale` function.) Anyway, cheating or not, here is our code for it:

```js
var radius = 100,
	x = radius,
	percent = 0;
while(x > 0){
	percent = x / radius;

	currentColour.r = Math.floor(startColour.r * (1 - percent) + endColour.r * percent);
	currentColour.g = Math.floor(startColour.g * (1 - percent) + endColour.g * percent);
	currentColour.b = Math.floor(startColour.b * (1 - percent) + endColour.b * percent);

	ctx.fillStyle = 'rgb('+currentColour.r+', '+currentColour.g+', '+currentColour.b+')';
	ctx.beginPath();
	ctx.arc(w / 2, h / 2, x, 0, Math.PI * 2);
	ctx.fill();
	x--;
}
```

Combine that with the beginning of the linear gradient's code (the start and end colour variables, the canvas setup etc.) you have a fully functioning radial gradient maker!

{% include codepen-embed.html slug="aNBBKG"%}

But, that's no fun. Cheating is so boring. Let's make a radial gradient using trig, just because it was pi day on the 14th. The way we do it is, instead of drawing a circle with the `arc` function, we loop an amount of iterations equal to the circumference of the circle at the current radius. (Equal to `radius * Math.PI * 2`.) Then, we calculate the angle that we're up to, which is a fraction of `Math.PI * 2`. Lastly we draw a small dot at the position we're up to. Seeing as we only have the angle and radius, we need trig. So, `x = Math.cos(angle) * radius` and `y = Math.sin(angle) * radius`.

{% include codepen-embed.html slug="pyNNZe"%}

Looks all right, huh? Similar to the previous example, just without the cheating! Not that it really is cheating, though. The previous example is certainly faster. Not as fast as a generic radial gradient made with CSS or the canvas's context, but good all the same. Anyway, that brings us to the end of making radial gradients programmatically.

Thanks for reading. See you next time!

*This post was originally posted on my CodePen blog [here.](https://codepen.io/Tobsta/post/programmatically-making-gradients)*
