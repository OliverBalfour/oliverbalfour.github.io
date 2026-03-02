---
layout: post
title: "1 Dimensional Perlin Noise in JavaScript"
categories: javascript
---

## Procedural generation
Procedural generation is a class of techniques that allow you to generate data, typically game content such as random maps or game textures.

Procedural generation is used widely for all sorts of things, from creating simple linear graphs of curves to making heatmaps and randomized textured terrain. In this guide I will explain how to use Perlin Noise, a very popular Procedural Generation technique that generates smooth curves that can be used in all manner of ways, from random texture generation to terrain generation.

## Perlin Noise
Perlin Noise originated in the 80's when a guy named Ken Perlin who was working on graphics for the movie Tron decided he was sick of the computery look graphics had. He created a basic program that allowed him to generate nice looking (pseudo) random textures, like the one below:

{% include codepen-embed.html slug="PNNgZV" %}

There are a few differences, though, as that that version uses a later version of his noise ported to JS and it is also animated. However, that's not the point; the point is that Perlin Noise is absolutely amazing, as you will see later.

In this post we will look at 1D Perlin Noise.

## 1D Perlin Noise
To begin with, I'll explain what Perlin Noise consists of. There are two parts for a basic 1D implementation: a psuedo-random number generator (PRNG), and an interpolation function. Put together with some canvas magic, it looks like this:

{% include codepen-embed.html slug="QNyKEE" %}

At the moment it doesn't look very impressive, but towards the end of this post we'll implement 'octaves', which layer progressively smaller instances of noise on top of each other.

### Pseudo-Random Number Generators (PRNGs)

For those of you who don't know, a PRNG generates numbers that may seem random but actually strictly speaking aren't. If you give the same starting value (seed) to a PRNG it will return the same result. So, if you want to generate random numbers using a PRNG, use a random number, either `Math.random()` or the current `Date.now()` (number of milliseconds since Unix Epoch, 1st Jan 1970), as a seed for it.

You're probably asking why we're using a PRNG and not good old `Math.random()`. It's simply because you can save a seed and get the same result. Plenty of games depend on this. Take, for example, Minecraft. When you generate a world, you can choose to input a seed for the world to be based off. The same seed always produces the same map. And when it comes to the generation of that world, can you guess how the terrain is generated? Multidimensional Perlin Noise. You get the idea.

Now, we will actually make a PRNG. We'll make a Linear Congruential Generator, or LCG for short. It is an especially simple PRNG, and only requires a few lines of code to see the magic in action.

```js
var M = 4294967296, // a - 1 should be divisible by m's prime factors
    A = 1664525, // c and m should be co-prime
    C = 1,
    seed = Math.floor(Math.random() * M);

function rand(){
	seed = (A * seed + C) % M;
	return seed / M;
}
```

Don't worry about the huge numbers there, they are the parameters for our LCG. I chose large numbers because the length of the sequence of numbers you get is equal to `M`. So the bigger `M` is, the more possible values you can have before everything repeats. [Here](https://en.wikipedia.org/wiki/Linear_congruential_generator#Parameters_in_common_use) is a list of parameter combinations.

Now, this generator returns decimals between 0 and 1, just like `Math.random()`. It can be seeded, although in that example we've seeded it with a random number, `seed`. Now we're ready to move onto interpolation.

### Interpolation
Interpolation is the act of creating new data points between two given ones in a way that makes the data look smooth. I suppose that's not a particularly precise definition, but it'll do for what we're doing. We are going to interpolate between two points (generated with our PRNG) using cosine interpolation. It looks like this:

```js
function interpolate(a, b, x){
	var ft = x * Math.PI,
		f = (1 - Math.cos(ft)) * 0.5;
	return a * (1 - f) + b * f;
}
```

I won't go into the maths, but that function, when graphed with `x` from 0 to 1, will generate a smooth curve from `a` to `b`. This function takes three parameters, `a`, `b` and `x`. `a` is the first point, `b` the second, and `x`, a decimal between 0 and 1 specifying where along the curve you want to solve the value for. Now, that's a rather complicated example, though the results make the line look smooth, as in the last example. Below is a linear interpolation function (LERP), which generates a straight line from `a` to `b` when graphed:

```js
function interpolate(pa, pb, px){
	return  pa * (1 - px) + pb * px;
}
```

That interpolation function is linear, so your lines will look jagged. Unless you're using Perlin Noise every frame in a CPU intensive game, you shouldn't use a linear function. Even then, try not to if possible. The example is only there so that you can see how it works without the trigenometry bulking it up.

## Putting it all together
We'll define a few variables first, which will be the starting point for our noise. Feel free to change them around.

```js
var x = 0,
	y = h / 2,
	amp = 100, // amplitude
	wl = 100, // wavelength
	a = rand(),
	b = rand();
```

The amplitude is the distance from the top (or highest possible value) to the bottom (or lowest possible value) of the wave. The wavelength is the distance from the peak of one wave to the peak of the next (that is, along the x axis, or horizontally, if the wave is oriented the same way as in the previous example.)

Now that we've got that set up, let's go crazy! We generate two pseudo-random numbers for `a` and `b`, draw an interpolated line between them, and then draw another from the original `b` to a new `b`, until we reach the end of the canvas.

```js
// w = canvas.width, h = canvas.height
while (x < w) {
	if(x % wl === 0){
		a = b;
		b = rand();
		y = h / 2 + a * amp;
	}else{
		y = h / 2 + interpolate(a, b, (x % wl) / wl) * amp;
	}
	ctx.fillRect(x, y, 1, 1);
	x += 1;
}
```

That plots the line along the x axis on a canvas, using the variable `ctx` as its context. Now, we put that all together with some canvas setup and we have the example I showed you earlier! Now that we have basic 1D Perlin Noise plotted, we can move onto having multiple octaves, creating the effect below:

### Octaves

{% include codepen-embed.html slug="JXbGxy" %}

As you can see in that example, you can make lines that are very bumpy. The way we do this is by adding new octaves. Essentially what this means is that you get some Perlin Noise. Then, you divide the amplitude and wavelength by a divisor of your choice (2 is probably the best option), and then we make *another* lot of Perlin Noise. That second line is another octave, with waves half the size in height and in width. You should probably make enough octaves in your lines as can be seen on your canvas (so until your Perlin Noise values are less than one). With an amplitude and wavelength of 128 we can have about 8 octaves before the values become indistinguishable/unnoticeable.

So, once we have our 8 octaves, each a progressively finer curve, we add the values of each together. Don't average them, as that means each additional octave we add brings the resultant curve closer to 0. So, we add them together and use the resultant values for our curve. Here's my implementation of this code, a refactored version of the example above: (the `Perlin` function is a 1D Perlin Noise making function, using all the stuff we've been working on. It returns an object, where the `pos` property is an array containing all the values.)

```js
//octave generator
function GenerateNoise(amp, wl, octaves, divisor, width){
	var result = [];
	for(var i = 0; i < octaves; i++){
		result.push(new Perlin(amp, wl, width));
		amp /= divisor;
		wl /= divisor;
	}
	return result;
}

//combines octaves together
function CombineNoise(pl){
	var result = {pos: []};
	for(var i = 0, total = 0, j = 0; i < pl[0].pos.length; i++){
		total = 0;
		for(j = 0; j < pl.length; j++){
			total += pl[j].pos[i];
		}
		result.pos.push(total);
	}
	return result;
}
```

Add a line drawing function and you're ready to go! The final code would look like this, assuming that we've written a `DrawLine` function:

```js
DrawLine(CombineNoise(GenerateNoise(128, 128, 8, 2, window.innerWidth)));
```

## Finishing up
With 1D Perlin Noise alone, you can make procedurally generated landscapes similar to those in Terraria (But much simpler). With 2 & 3D Perlin noise, however, the sky is the limit. That, however, is left as an exercise to the reader. (There are other tutorials online, don't worry.)

*This post was originally posted on my CodePen blog [here.](https://codepen.io/OliverBalfour/post/procedural-generation-part-1-1d-perlin-noise)*
