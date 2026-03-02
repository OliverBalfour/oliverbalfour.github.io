
import os, glob

categories_dir = 'categories/'
categories = []

# generate list of categories
for name in glob.glob('_posts/*.md'):
    buffer = open(name, 'r')
    search = False

    for line in buffer:
        # check if current line declares categories
        if search:
            parts = line.strip().split(' ')
            if parts[0] == 'categories:' and parts[1] and parts[1] != '""':
                # found categories
                categories += parts[1:]
                search = False
                break
        # YAML Front Matter fence detection
        if line.strip() == '---':
            if not search:
                # start of YAML Front Matter
                search = True
            else:
                # end of YAML Front Matter without categories, skip to next post
                search = False
                break

    buffer.close()

# remove dupes
categories = list(set(categories))

# clear out /categories directory for fresh rebuild
old = glob.glob(categories_dir + '*.md')
for fname in old:
    os.remove(fname)

# repopulate /categories
for tag in categories:
    tag_fname = categories_dir + tag + '.md' # this is why categories must be lowercase and use dashes instead of spaces (ie `cool-tag`)
    buffer = open(tag_fname, 'w')
    buffer.write(
        '---\n' +
        'layout: tag\n' +
        'title: Posts tagged ' + tag + '\n' +
        'permalink: /categories/' + tag + '/\n' +
        'tag: ' + tag + '\n' +
        'sitemap: false\n' +
        '---\n'
    )
    buffer.close()

print("Finished generating " + str(len(categories)) + " tag pages")
