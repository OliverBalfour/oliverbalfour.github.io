---
layout: post
title: "Programmatically Making Gradients"
categories: canvas
tags: canvas javascript
---

In this post we will make gradients without using any of the helper functions built into the canvas context for making them. In other words, we'll make a gradient without using `createLinearGradient` or `createRadialGradient`. Whilst those two functions are satisfactory for most applications, you can do much more with these gradients, as you can interpolate between colours in any way you like. For example, uou can use cosine interpolation rather than linear for a smoother, eased gradient. Also, if you understand how to perform colour interpolation, you will better understand how to make metaballs and similar graphical effects. (I'll probably write a post on them soon, they're really cool.)

## Making a linear gradient
To make our gradient, we need to have two colours: the start and end colours. We'll have them in an object format, with `r`, `g` and `b` properties.

```js
var startColour = {r: 0, g: 255, b: 50}, // green
	endColour = {r: 255, g: 0, b: 100}; // pink
```

Then, we simply need to go across the screen, drawing values from an interpolation function. For now, we will use a simple linear interpolation (LERP) function. All it does is, given the decimal `p`, get the number between `a` and `b` that falls along a straight line between `a` and `b` on a graph. So, if you were to plot the values of the function from `p = 0.0` to `p = 1.0` on a graph, you would get a straight line going from `a` to `b`. Instead, though, we will use the value for each of the three colour values (or four, if you wanted a fading gradient) from the start and end colours (as `a` and `b`,) and plot the interpolated values as the red, green and blue components of the gradient. We will do this for every column of pixels along the gradient.

```js
function interpolate (a, b, p) {
	// The higher p is, the less a is weighted and the more b is weighted in the result
	// The inverse is also true
	return a * (1 - p) + b * p;
}
```

It's that easy. Then, we just pass each element of the colour into that function. We do this for every pixel along the length of the gradient. All in all, it's very simple.

```js
var currentColour = {r: startColour.r, g: startColour.g, b: startColour.b},
	x = 0, // x position along the canvas
	percent = 0; // p

while (x < w) { // w is the width of the canvas in pixels
	percent = x / w;

	// Notice we aren't actually calling the function here, although we are still using the same algorithm
	currentColour.r = Math.round(startColour.r * (1 - percent) + endColour.r * percent);
	currentColour.g = Math.round(startColour.g * (1 - percent) + endColour.g * percent);
	currentColour.b = Math.round(startColour.b * (1 - percent) + endColour.b * percent);

	ctx.fillStyle = 'rgb('+currentColour.r+', '+currentColour.g+', '+currentColour.b+')';
	ctx.fillRect(x, 0, 1, h);
	x++;
}
```

Remember when setting the fill style to make sure the `r`, `g` and `b` values are all whole numbers using `Math.round`!

{% include codepen-embed.html slug="oxYzde"%}

You can easily make a function that interfaces like `createLinearGradient` using the above code as a starting point. However, that's out of the scope of this tutorial. But first, we will adapt our above code to use cosine interpolation instead of linear interpolation.

### Cosine interpolation
The code for cosine interpolation looks like this:

```js
function interpolate(a, b, px){
	var ft = px * Math.PI,
		f = (1 - Math.cos(ft)) * 0.5;
	return  a * (1 - f) + b * f;
}
```

I won't go into the math, but If you use it as a replacement for the linear interpolation function, you get this result:

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
