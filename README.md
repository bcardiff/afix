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
## change markdown.afix.json for trace optimizations
$ crystal src/fix_finder.cr -- ./sample/markdown.afix.cr
$ patch -p1 < sample/markdown.cr.patch
$ crystal sample/markdown.cr
```

The instrumentation is greedy. It covers the whole file making the search space pretty huge. To mimic an instrumentation only on the expressions stressed on the failing test case and the following key/value to `.afix.json` file.


| strategy | time | tries |
| --- | --- | --- |
| naïve changes | 7yrs | NaN |
| naïve with trace hint | 20min | 24057 |
| near without trace hint | **40seg** | 333 |
| near with trace hint | **8seg** | 129 |

```
# markdown.afix.json with trace hint
{"i2":0,"i3":0,"i5":0,"i6":0,"ia":0,"ib":0,"ii":0,"ij":0,"ik":0,"il":0,"im":0,"i11":0,"i14":0,"i15":0,"i1d":0,"i1e":0,"i1j":0}
```

# Trace approximation

Make the `.afix.cr` file start with

```
require "../src/monitor"
require "../src/trace"
AfixMonitor.load(ARGV[0])
```

Run the failing test only, extract the monitors keys, etc.

```
crystal spec sample/markdown.afix.cr:773 sample/markdown.afix.json | uniq | sort
```

# Outputs

```
diff --git a/sample/sample1.cr b/sample/sample1.cr
index 2031d4b..d5c1e66 100644
--- a/sample/sample1.cr
+++ b/sample/sample1.cr
@@ -1,7 +1,7 @@
 require "spec"

 def succ(a)
-  res = a + 2
+  res = a + 2 - 1
   res
 end

@@ -10,3 +10,4 @@ describe "self" do
     succ(1).should eq(2)
   end
 end
```

```
diff --git a/sample/markdown.cr b/sample/markdown.cr
index 87fc0a4..dbac2de 100644
--- a/sample/markdown.cr
+++ b/sample/markdown.cr
@@ -472,8 +472,8 @@ class Markdown::Parser
           @renderer.end_link

           paren_idx = (str + pos + 1).to_slice(bytesize - pos - 1).index(')'.ord).not_nil!
-          pos += paren_idx + 2
-          cursor = pos
+          pos += paren_idx + 2 - 1
+          cursor = pos + 1
           in_link = false
         end
       end
```

compare to [bugfix](https://github.com/manastech/crystal/commit/ed6d3d1be8ff71fd428b65d040475a1d1b7f1d0e) .
