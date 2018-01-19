---
layout: post
title: "Procedural Content Generation (PCG) Part 1 - 1 Dimensional Perlin Noise"
categories: pcg
tags: canvas javascript pcg
---

## Procedural generation
Procedural generation is a technique used by programmers, typically used in games. It essentially refers to creating assets like textures and terrain algorithimically instead of manually.

It is used widely for all sorts of things, from creating simple linear graphs of curves to making heatmaps and randomized textured terrain. In this guide I will explain how to use Perlin Noise, a technique that generates smooth curves that can be used in all manner of ways.

## Perlin Noise
Perlin Noise originated in the 80's when a guy named Ken Perlin decided he was sick of the computery look graphics had. He created a basic program that allowed him to generate nice looking (pseudo) random textures, like the one below:

{% include codepen-embed.html slug="PNNgZV"%}

There are a few differences, though, as that that version uses a later version of his noise ported to JS and it is also animated. However, that's not the point; the point is that Perlin Noise is absolutely amazing, as you will see later.

In this post we will look at 1D Perlin Noise.

## 1D Perlin Noise
To begin with, I'll explain what Perlin Noise consists of. There are two parts for a basic 1D implementation. A psuedo-random number generator (PRNG), and an interpolation function. Put together with some canvas magic, it looks like this:

{% include codepen-embed.html slug="QNyKEE"%}

Cool, huh? Don't fret if this seems to complicated; you don't have to fully understand every tenet of this. As long as you're able to plug Perlin Noise into a program by the end of the next post, you're good.

### Pseudo-Random Number Generators (PRNGs)
Essentially a PRNG generates numbers that may seem random but actually strictly speaking aren't. If you give the same starting value to a PRNG it will return the same result. So, if you want to generate random numbers using a PRNG, use a random number as a seed for it.

You're probably asking why we're using a PRNG and not good old `Math.random()`. It's simply because you can save a seed and get the same result. Plenty of games depend on this. Take, for example, Minecraft. When you generate a world, you can choose to input a seed for the world to be based off. And when it comes to the generation of that world, can you guess how the world is made so smooth? *\*Cough\** Perlin Noise *\*Cough\**. You get the idea.

Now, we will actually make a PRNG. We'll make a Linear Congruential Generator, or LCG for short. It is an especially simple PRNG, and only requires a few lines of code to see the magic in action.

```js
var M = 4294967296,
    // a - 1 should be divisible by m's prime factors
    A = 1664525,
    // c and m should be co-prime
    C = 1;
var Z = Math.floor(Math.random() * M);
function rand(){
	Z = (A * Z + C) % M;
	return Z / M;
}
```

Don't worry about the huge numbers there, they are the parameters for our LCG. I chose large numbers because the length of the sequence of numbers you get is equal to M. So the bigger M is, the more possible values you can have before everything repeats.

Now, this generator returns decimals between 0 and 1, just like `Math.random()`. It can be seeded, although in that example we've seeded it with a random number, `Z`. Now we're ready to move onto interpolation.

### Interpolation
Interpolation is the act of creating new data points between two given ones in a way that makes the data look smooth. I suppose that's not a particularly precise definition, but it'll do for what we're doing. We are going to interpolate between two points (generated with our PRNG) using cosine interpolation. It looks like this:

```js
function interpolate(pa, pb, px){
	var ft = px * Math.PI,
		f = (1 - Math.cos(ft)) * 0.5;
	return pa * (1 - f) + pb * f;
}
```

You can try and work out how that works if you want, but there really isn't much point. In essence, this function takes three parameters, a, b and x. A is the first point, b the second, and x, a decimal between 0 and 1 specifying where along the space between the points the point who's value you want. Now, that's a rather complicated example, though the results make the line look smooth, as in the last example.

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
	amp = 100, //amplitude
	wl = 100, //wavelength
	fq = 1 / wl, //frequency
	a = rand(),
	b = rand();
```

The amplitude, in case you don't know, is the distance from the top (or highest possible value) to the bottom (or lowest possible value) of the wave. The wavelength is the distance from the peak of one wave to the peak of the next (that is, along the x axis, or horizontally, if the wave is oriented the same way as in the previous example.) The frequency, although we don't use it in the end, is the amount of waves in one second (or other unit of time).

Now that we've got the setup, let's go crazy!

```js
while(x < w){
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

That plots the line along the x axis on a canvas, using the variable `ctx` as it's context. Now, we put that all together with some canvas setup and we have the example I showed you earlier! Now that we have basic 1D Perlin Noise plotted, we should move onto having multiple octaves, creating the effect below:

### Octaves

{% include codepen-embed.html slug="JXbGxy"%}

As you can see in that example, you can make lines that are very bumpy. The way we do this is by adding new octaves. Essentially what this means is that you get some Perlin Noise. Then, you divide the amplitude and wavelength by a divisor of your choice (2 is probably the best option), and then we make *another* lot of Perlin Noise. That second line is another octave. You should probably make enough octaves in your lines as can be seen on your canvas (so until your Perlin Noise values are less than one). With an amplitude and wavelength of 128 we can have about 8 octaves before the values become indistinguishable/unnoticeable.

So, once we have our 8 octaves, each a progressively smaller curve, we add the values of each together. Don't average them, as that means each additional octave we add brings the resultant curve closer to 0. So, we add them together and get the values for our awesome bumpy curve. Here's my implementation of this code, coming straight out of the example above: (the `Perlin` function is a 1D Perlin Noise making function, using all the stuff we've been working on. It returns an object, where the `pos` property is an array containing all the values.)

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

## You're ready to go!
With that simple trick under your toolbelt you can make procedurally generated landscapes similar to those in Terraria (But much simpler). You can make plenty of stuff with 1D noise alone. With that, thanks for reading and stay tuned for the next post, about 2D Perlin Noise. We will get into using it to make procedurally generated textures and basic terrain.

*This post was originally posted on my CodePen blog [here.](https://codepen.io/Tobsta/post/procedural-generation-part-1-1d-perlin-noise)*
