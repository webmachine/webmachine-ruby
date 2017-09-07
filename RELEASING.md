1. Open `CHANGELOG.md` and summarize the changes made since the last release (hopefully better than the individual commit messages). The history can be grabbed with a simple git command (assuming the last version was 1.3.0:

        $ git log --pretty=format:'  * %s' v1.3.0..HEAD

2. Edit the version in `lib/webmachine/version.rb` according to semantic versioning rules.
3. Commit both files.

        $ git add CHANGELOG.md lib/webmachine/version.rb
        $ git commit -m "chore(release): version 1.3.1"

4. Release the gem.

        $ bundle exec rake release

5. If this is a new major or minor release, push a new stable branch, otherwise merge the commit into the stable branch (or master, depending on where you made the commit).

        $ git push origin HEAD:1.3-stable
        # or
        $ git checkout 1.3-stable; git merge master; git push origin; git checkout master

6. YOU'RE DONE!
