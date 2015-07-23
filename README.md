# afix

```
$ crystal src/instrument.cr -- sample/sample1.cr
$ crystal src/fix_finder.cr -- ./sample/sample1.afix.cr
```

```
$ crystal src/instrument.cr -- sample/markdown.cr
-- add some some of the only keys to narrow search space
$ crystal src/fix_finder.cr -- ./sample/markdown.afix.cr
```

# only keys

"only":["i2","i3","i5","i6","ia","ib","ii","ij","ik","il","im","i11","i14","i15","i1d","i1e","i1j"] ~ 20min 24057tries

"only":["ib","ii","ij","ik","il","im","i11","i14","i15","i1d","i1e","i1j"] ~ 6seg 99tries
