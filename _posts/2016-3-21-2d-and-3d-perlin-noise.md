---
layout: post
title: "2 and 3 Dimensional Perlin Noise in JavaScript"
categories: javascript
published: false
---

Welcome back! If you haven't read my previous post on 1D Perlin Noise, I'd recommend looking at that to get an understanding of how it works. It's over [here](/pcg/2016/03/19/1d-perlin-noise.html).

## The code
2D & 3D Perlin Noise is considerably more complicated than 1D, so from here on in, we'll be using the same block of code to do everything, a port of Ken Perlin's original Java program for Improved Noise. Here it is:

```js
function ImprovedNoise(){
	var p = [151,160,137,91,90,15,131,13,201,95,96,53,194,233,7,225,140,36,103,30,69,142,8,99,37,240,21,10,
		 23,190,6,148,247,120,234,75,0,26,197,62,94,252,219,203,117,35,11,32,57,177,33,88,237,149,56,87,
		 174,20,125,136,171,168,68,175,74,165,71,134,139,48,27,166,77,146,158,231,83,111,229,122,60,211,
		 133,230,220,105,92,41,55,46,245,40,244,102,143,54,65,25,63,161,1,216,80,73,209,76,132,187,208,
		 89,18,169,200,196,135,130,116,188,159,86,164,100,109,198,173,186,3,64,52,217,226,250,124,123,5,
		 202,38,147,118,126,255,82,85,212,207,206,59,227,47,16,58,17,182,189,28,42,223,183,170,213,119,
		 248,152,2,44,154,163,70,221,153,101,155,167,43,172,9,129,22,39,253,19,98,108,110,79,113,224,232,
		 178,185,112,104,218,246,97,228,251,34,242,193,238,210,144,12,191,179,162,241,81,51,145,235,249,
		 14,239,107,49,192,214,31,181,199,106,157,184,84,204,176,115,121,50,45,127,4,150,254,138,236,205,
		 93,222,114,67,29,24,72,243,141,128,195,78,66,215,61,156,180];
	for (var i = 0; i < 256 ; i ++){
		p[256 + i] = p[i];
	}
	function fade(t){
		return t * t * t * (t * (t * 6 - 15) + 10);
	}
	function lerp(t, a, b){
		return a + t * (b - a);
	}
	function grad(hash, x, y, z){
		var h = hash & 15;
		var u = h < 8 ? x : y, v = h < 4 ? y : h == 12 || h == 14 ? x : z;
		return ((h&1) == 0 ? u : -u) + ((h&2) == 0 ? v : -v);
	}
	return {
		noise: function (x, y, z){
			var floorX = ~~x, floorY = ~~y, floorZ = ~~z;
			var X = floorX & 255, Y = floorY & 255, Z = floorZ & 255;
			x -= floorX;
			y -= floorY;
			z -= floorZ;
			var xMinus1 = x - 1, yMinus1 = y - 1, zMinus1 = z - 1;
			var u = fade(x), v = fade(y), w = fade(z);
			var A = p[X] + Y, AA = p[A] + Z, AB = p[A + 1] + Z, B = p[X + 1] + Y, BA = p[B] + Z, BB = p[B + 1] + Z;
			return lerp(w, lerp(v, lerp(u, grad(p[AA], x, y, z),
							grad(p[BA], xMinus1, y, z)),
						lerp(u, grad(p[AB], x, yMinus1, z),
							grad(p[BB], xMinus1, yMinus1, z))),
					lerp(v, lerp(u, grad(p[AA + 1], x, y, zMinus1),
							grad(p[BA + 1], xMinus1, y, z - 1)),
						lerp(u, grad(p[AB + 1], x, yMinus1, zMinus1),
							grad(p[BB + 1], xMinus1, yMinus1, zMinus1))));
		}
	}
}
```

Ok.... It's a mouthful, to say the least. The constructor `ImprovedNoise` is used like this:

```js
var noise = new ImprovedNoise();

noise.noise(x, y, z);
```

You can make as many of these generators as you wish, however don't use the same object for multiple things, as you'll end up using the same PRNG, which would just ruin what you're making. The `noise` method takes three parameters: x, y and z. If you want to make 2D noise, just use 1 or some other value for the z to keep it constant.

## Making our first Perlin based texture

{% include codepen-embed.html slug="wGGOqx" %}

Remember that example, from the previous post? Imagine it wasn't animated for a second, as we'll get to animation in time. The texture is just an array of 2D Perlin Noise where the values are turned from floats into an RGB value, like this:

```js
function perlinToRGB(perlinVal){
	//perlinVal is a decimal between 0 and 1
	var rgbVal = perlinVal * 256;
	return `rgb(${rgbVal}, ${rgbVal}, ${rgbVal})`;
}
```

Simply draw the results from the Perlin Noise converted to RGB and boom! Procedurally generated textures! We can easily make our textures colourful by just changing around how the RGB value is calculated. See if you can make something looking like this without peeking at the code (ignoring the animation):

{% include codepen-embed.html slug="bppZrx" %}

## Animation
Now, we'll get into using the Z value. Have a peek at the code in the above example. You'll notice that we put a variable, `time`, in the z position. Every frame we increment `time` by a tiny amount.

That's all there is to it. It's really quite clever, if you think about it. So, let's think about it!

Imagine a cube. It has its interior generated with 3D Perlin Noise. Now, take a slice of it, with the full height and width, at point 0 on the z axis. It looks like 2D Perlin Noise. Well, it *is* 2D Perlin Noise. Now, take a slice of the cube at point 1 on the z axis. Because it's 3D Perlin Noise, the two slices will have a nice transition in colour between them. Now do this again. And again. 60 times a second. And plot the result to a canvas. There you have it. That's how (and why) it works.

So, think about it. Even though we don't know what the 4th dimension would look like (we simply cannot comprehend it), we can still use 4D Perlin Noise to animate 3D stuff.

## 3D Perlin Noise
With the 3D cube example back in the animation section, we now have an idea of what it would look like. Feel free to experiment with using WebGL or THREE.js to render a 3D cube of Perlin Noise. If you could make a threshold of colour intensity where, when reached, the colour is rendered as being transparent, then you could make a 3D colourful cave system!

I'll leave it at that, but for inspiration, I'll leave you with an awesome demo I made.

Controls: WASD or arrow keys to rotate and move, space to jump, and '[' and ']' to change between first and third person views. (Try third person! It looks really cool.) It uses THREE.js to render. The terrain and texture of the terrain are procedurally generated using 2D Perlin Noise, the terrain using a Perlin Noise texture as a heightmap. Have a look! Feel free to fork it and make whatever you want. (If it's laggy, it's the fault of all the other examples in the post combined, not just this one.)

{% include codepen-embed.html slug="jqqgRV" %}

Once again, thanks for reading and see you next time.

*This post was originally posted on my CodePen blog [here.](https://codepen.io/OliverBalfour/post/procedural-generation-part-2-2d-3d-perlin-noise)*
