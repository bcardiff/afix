echo 'Jarvis> running buggy code ...'
crystal sample/$1.cr || echo ''
echo 'Jarvis> instrumenting ...'
crystal src/instrument.cr -- sample/$1.cr
echo 'Jarvis> searching for a fix ...'
crystal src/fix_finder.cr -- ./sample/$1.afix.cr
echo 'Jarvis> patching ...'
patch -p1 < sample/$1.cr.patch
echo 'Jarvis> I am done'
crystal sample/$1.cr
./clean.sh
git diff
