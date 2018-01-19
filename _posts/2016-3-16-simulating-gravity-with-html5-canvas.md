---
layout: post
title: "Implementation of Gravity of a Canvas"
categories: canvas
tags: canvas javascript physics
---

Before we dive into how to properly implement gravity, we need to have a good understanding of what it is. Even if you're simply trying to add gravity to a basic platformer, it's good to know how gravity works on an interstellar level.

## What is gravity?
I'm no expert, but I'll tell you what I know. In terms of the our everyday lives, we can satisfy our need for a definition with the simple statement: 'Gravity pulls things down.' But is that really correct? No! Even if we're talking about the effect it has on a really small scale, that isn't even close to correct. It *appears* that gravity moves things down, but it doesn't just do that. It moves *heavier* things down, and *lighter* things up. Even that is a massive oversimplification; that's simply what happens in our day to day lives. In a platformer, you probably won't need to program in the physics to allow for hot air balloons etc. but it's still good to understand that difference.

Now, we'll move onto defining gravity at large. It's a force that moves things together. The less mass something has relative to another thing, the faster it moves toward it. So, when you throw a ball and it falls back down, the ball isn't actually falling *down*, it's moving toward the earth, and the earth is moving towards it, though only very slightly, so slightly that the earth isn't moving a feasibly measurable amount (It'd be less than you could imagine. Probably an undecillionth of a millimeter or some other ridiculously small amount.) So, yes, we can think of gravity as a force that pulls things together, or we can think of it as the effect of objects moving at speeds being affected by relativistic forces. It's all very fascinating and rather complicated, hence its being my cup of tea, but I feel I am not qualified to explain all of this. You can get a grasp on the advanced theoretical stuff [here,](https://www.youtube.com/watch?v=aSz5BjExs9o) thought up by Einstein.

## Implementing it
Now that we have a good understanding of what gravity is, we can attempt to implement it. Firstly we'll implement gravity as you'd experience it on earth. This means that we'll have a constant, called `gravity`, that is additive to the acceleration on the y axis of all moveable objects. Our simulation will run at 60 fps, so we'll make it quite small. Our gravity constant will have a value of 0.05 px/s^2 (pixels a second squared).

We'll have a particle simulation, so we'll be able to see the effect of gravity on each particle.

{% include codepen-embed.html slug="XdNOgg"%}

However, you'll notice that balls of different mass don't react differently. This is a problem that can't be fixed without really hacky code. Because of strange physics trickery, objects of different masses and shapes fall at exactly the same speed without air resistance (thanks Einstein) and so even if we weren't doing gravity the hacky way it'd still have to use either spot on physics which would be even more fruitless than it already was (if that's even possible...) and it'd be slow as hell, and in the end if you're making a platformer (just an example) then people would prefer it to run at more than 10 FPS over having spot on pixel perfect physics simulations eating up their system resources.

The way I hack in realistic gravity is giving each object a mass and multiplying the gravity constant by the mass to get acceleration. You may have to change your gravity constant to a lower value as masses get higher, and none of the measurements are done in actual units really, it's just whatever looks good, but it works. And the users of whatever you're making will be happy. Unless it's a professional grade space simulator that expects calculations to be accurate to the millionth decimal point. Then you're stuffed.

The original particle simulator with more realistic gravity. Feel free to play around with it.
{% include codepen-embed.html slug="pyREMz"%}

If you want another post about the 'proper' way to do gravity let me know below. Until then, I hope you've enjoyed this.

*This post was originally posted on my CodePen blog [here.](https://codepen.io/Tobsta/post/implementation-of-gravity-on-a-canvas)*
