
import os, glob

tags_dir = 'tags/'
tags = []

# generate list of tags
for name in glob.glob('_posts/*.md'):
    buffer = open(name, 'r')
    search = False

    for line in buffer:
        # check if current line declares tags
        if search:
            parts = line.strip().split(' ')
            if parts[0] == 'tags:' and parts[1] and parts[1] != '""':
                # found tags
                tags += parts[1:]
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

# clear out /tags directory for fresh rebuild
old = glob.glob(tags_dir + '*.md')
for fname in old:
    os.remove(fname)

# repopulate /tags
# note: tags may contain dupes, doesn't matter except for speed though
for tag in tags:
    tag_fname = tags_dir + tag + '.md' # this is why tags must be lowercase and use dashes instead of spaces (ie `cool-tag`)
    buffer = open(tag_fname, 'w')
    buffer.write(
        '---\n' +
        'layout: tag\n' +
        'title: Posts tagged ' + tag + '\n' +
        'permalink: /tags/' + tag + '/\n' +
        'tag: ' + tag + '\n' +
        '---\n'
    )
    buffer.close()

print("Finished generating " + str(len(tags)) + " tag pages")
