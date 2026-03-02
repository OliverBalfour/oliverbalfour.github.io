# Oliver's Blog

Uses jekyll + GH pages

[OliverBalfour/oliverbalfour.github.io: Personal website source code](https://github.com/OliverBalfour/oliverbalfour.github.io)
[Oliver’s Blog | Yet another programming blog](https://blog.oliverbalfour.com/)

## Setup

Follow these instructions to install Ruby [Linux](https://jekyllrb.com/docs/installation/other-linux/) / [Mac](https://jekyllrb.com/docs/installation/macos/), then run:

`gem install bundler jekyll`

`bundle install`

If you need to add extra packages try `bundle add XXX`

Add pre-commit hook to generate tag pages: `.git/hooks/pre-commit`
```sh
#!/bin/bash
python scripts/tag-page-gen.py
git add categories/*.md
```
And `chmod +x .git/hooks/pre-commit`

## Usage

`bundle exec jekyll serve --livereload --future --unpublished --open-url` to build, watch and run in realtime.

```sh
cd ~/Vault/blog && bundle exec jekyll serve --livereload --future --unpublished --open-url
```
This will build, watch and run in realtime.

Pushing to GitHub will **automatically update the site.**

## Troubleshooting

Installation problems:
- If `bundle` is not found, make sure Ruby is in your path (eg `PATH=$PATH:/root/.gem/ruby/2.7.0/bin` in `.bashrc`), and try using `sudo gem install ...`.

GitHub Pages build errors:
- Make sure all `post_url`s are correct and for posts which have been published.
- Make sure to run `bundle exec jekyll serve` once before trying the livereload option.

Homepage not updating:
- Disable `incremental: true` in `_config.yml` temporarily or edit `_layouts/home.html` while watch is enabled.
