# afix

Automatic software repair excercise in [Crystal](http://crystal-lang.org) for [eci2015](www.dc.uba.ar/events/eci/2015/cursos/monperrus).

It searches for fixes adding +1/-1 to integers assignments.

They were indeed [bugs](https://github.com/manastech/crystal/commit/ed6d3d1be8ff71fd428b65d040475a1d1b7f1d0e) that could have been solved by this technique in Crystal. This bug is ported in `sample/markdown.cr`

## Sample1

```
$ crystal sample/sample1.cr
$ crystal src/instrument.cr -- sample/sample1.cr
$ crystal src/fix_finder.cr -- ./sample/sample1.afix.cr
$ patch -p1 < sample/sample1.cr.patch
$ crystal sample/sample1.cr
```

## Markdown sample

```
$ crystal sample/markdown.cr
$ crystal src/instrument.cr -- sample/markdown.cr
```

The instrumentation is greedy. It covers the whole file making the search space pretty huge. To mimic an instrumentation only on the expressions stressed on the failing test case:

```
"only":["i2","i3","i5","i6","ia","ib","ii","ij","ik","il","im","i11","i14","i15","i1d","i1e","i1j"] ~ 20min 24057tries
```

narrowing 5 more expressions for demo

```
"only":["ib","ii","ij","ik","il","im","i11","i14","i15","i1d","i1e","i1j"] ~ 6seg 99tries
```

(this can be added to `.afix.json` file)

```
$ crystal src/fix_finder.cr -- ./sample/markdown.afix.cr
$ patch -p1 < sample/markdown.cr.patch
$ crystal sample/markdown.cr
```

