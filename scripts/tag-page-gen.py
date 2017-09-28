
import os, glob

tags_dir = 'tags/'
tags = []

for name in glob.glob('_posts/*.md'):
    buffer = open(name, 'r')
    search = False

    for line in buffer:
        # check if current line declares tags
        if search:
            current_tags = line.strip().split(' ')
            if current_tags[0] == 'tags:':
                # found tags
                tags += current_tags[1:]
                search = False
                break
        # YAML Front Matter fence detection
        if line.strip() == '---':
            if not search:
                # start of YAML Front Matter
                search = True
            else:
                # end of YAML Front Matter without tags, skip to next post
                search = False
                break

    buffer.close()

old = glob.glob(tags_dir + '*.md')
for fname in old:
    os.remove(fname)

for tag in tags:
    tag_fname = tags_dir + tag + '.md' # this is why tags must be lowercase and use dashes instead of spaces (ie `cool-tag`)
    buffer = open(tag_fname, 'a')
    buffer.write('---'
                 'layout: tag'
                 'title: Posts tagged ' + tag
                 '---')
    buffer.close()

print("Finished generating " + str(len(tags)) + " tag pages")
