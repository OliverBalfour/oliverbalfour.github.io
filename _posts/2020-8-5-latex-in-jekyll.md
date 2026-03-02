---
layout: post
title: "Adding LaTeX Equations to a Jekyll Blog"
categories: jekyll
---

This is a quick tutorial on how to set up LaTeX equations in Jekyll, agnostic to the Jekyll version and without needing extra packages. This is an updated version of [this guide](https://varunagrawal.github.io/2018/03/27/latex-jekyll/), with no dependence on jQuery, error handling, and the latest version of KaTeX. All you need is to copy/paste predefined snippets into two files, and it should work like a charm!

First, we configure the markdown rendering as follows in our `_config.yml` file:

```yml
markdown: kramdown
kramdown:
  math_engine: mathjax
```

This will emit any equations delimited by `$$these$$` as `<script type='math/tex' />` HTML tags. However, we will not use MathJax as it is a little tricky to set up. Instead, we will use [KaTeX](https://katex.org/), a similar library maintained by Khan Academy. Then, we need to include the following HTML in the our default page layout (just before the `</body>` line in your `_layouts/default.html`).

```html
<!-- KaTeX libraries -->
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/katex@0.12.0/dist/katex.min.css" crossorigin="anonymous">
<script defer src="https://cdn.jsdelivr.net/npm/katex@0.12.0/dist/katex.min.js" crossorigin="anonymous"></script>
<!-- Convert Kramdown output into KaTeX rendered HTML -->
<script type="text/javascript">
  // Kramdown dumps our math expressions in plaintext, so we replace the elements
  // containing them with KaTeX rendered HTML
  window.onload = function () {
    document.querySelectorAll("script[type='math/tex; mode=display']")
      .forEach(function (elem) {
        try {
          var tex = elem.innerText.replace(/%.*/g, '');
          elem.outerHTML = katex.renderToString(tex, {displayMode: true});
        } catch (e) { console.log("Invalid LaTeX. Skipping."); console.error(e) }
      });
    document.querySelectorAll("script[type='math/tex']")
      .forEach(function (elem) {
        try {
          var tex = elem.innerText.replace(/%.*/g, '');
          elem.outerHTML = katex.renderToString(tex, {displayMode: false});
        } catch (e) { console.log("Invalid LaTeX. Skipping."); console.error(e) }
      });
  }
</script>
```

Once these two edits have been made, try testing it out! If you enter `$$\int_0^\pi \sin (x) dx = 2$$` it should display the following:

$$\int_0^\pi \sin (x) dx = 2$$

Just make sure your math displays locally *and* on GitHub Pages if relevant, as there is occasionally some discrepancy.

If for some reason this does not work correctly, you can easily change to MathJax by simply replacing the above HTML code with the following. There will be a slight performance regression, but it will almost certainly do the job. (Note that the `_config.yml` file stays the same.)

```html
<script type="text/javascript" async src="https://cdnjs.cloudflare.com/ajax/libs/mathjax/2.7.1/MathJax.js?config=TeX-MML-AM_CHTML"></script>
```

And that's all there is to it!
