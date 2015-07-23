require "spec"

class Markdown
  def self.parse(text, renderer)
    parser = Parser.new(text, renderer)
    parser.parse
  end

  def self.to_html(text)
    String.build do |io|
      parse text, Markdown::HTMLRenderer.new(io)
    end
  end
end

class Markdown::HTMLRenderer
  def initialize(@io)
  end

  def begin_paragraph
    @io << "<p>"
  end

  def end_paragraph
    @io << "</p>"
  end

  def begin_italic
    @io << "<em>"
  end

  def end_italic
    @io << "</em>"
  end

  def begin_bold
    @io << "<strong>"
  end

  def end_bold
    @io << "</strong>"
  end

  def begin_header(level)
    @io << "<h"
    @io << level
    @io << '>'
  end

  def end_header(level)
    @io << "</h"
    @io << level
    @io << '>'
  end

  def begin_inline_code
    @io << "<code>"
  end

  def end_inline_code
    @io << "</code>"
  end

  def begin_code(language = nil)
    @io << "<pre><code>"
  end

  def end_code
    @io << "</code></pre>"
  end

  def begin_unordered_list
    @io << "<ul>"
  end

  def end_unordered_list
    @io << "</ul>"
  end

  def begin_ordered_list
    @io << "<ol>"
  end

  def end_ordered_list
    @io << "</ol>"
  end

  def begin_list_item
    @io << "<li>"
  end

  def end_list_item
    @io << "</li>"
  end

  def begin_link(url)
    @io << %(<a href=")
    @io << url
    @io << %(">)
  end

  def end_link
    @io << "</a>"
  end

  def image(url, alt)
    @io << %(<img src=")
    @io << url
    @io << %(" alt=")
    @io << alt
    @io << %("/>)
  end

  def text(text)
    @io << text.gsub('<', "&lt;")
  end

  def horizontal_rule
    @io << "<hr/>"
  end
end

class Markdown::Parser
  def initialize(text, @renderer)
    @lines = text.lines.map &.chomp
    @line = 0
  end

  def parse
    while @line < @lines.length
      process_paragraph
    end
  end

  def process_paragraph
    line = @lines[@line]

    if empty? line
      @line += 1
      return
    end

    if next_line_is_all?('=')
      return render_header 1, line, 2
    end

    if next_line_is_all?('-')
      return render_header 2, line, 2
    end

    pounds = count_pounds line
    if pounds
      return render_prefix_header pounds, line
    end

    if line.starts_with? "    "
      return render_code
    end

    if is_horizontal_rule? line
      return render_horizontal_rule
    end

    if starts_with_star? line
      return render_unordered_list
    end

    if starts_with_backticks? line
      return render_fenced_code
    end

    if starts_with_digits_dot? line
      return render_ordered_list
    end

    render_paragraph
  end

  def render_prefix_header(level, line)
    bytesize = line.bytesize
    str = line.to_unsafe
    pos = level
    while pos < bytesize && str[pos].chr.whitespace?
      pos += 1
    end

    render_header level, line.byte_slice(pos), 1
  end

  def render_header(level, line, increment)
    @renderer.begin_header level
    process_line line
    @renderer.end_header level
    @line += increment

    append_double_newline_if_has_more
  end

  def render_paragraph
    @renderer.begin_paragraph

    while true
      process_line @lines[@line]
      @line += 1

      if @line == @lines.length
        break
      end

      line = @lines[@line]

      if empty? line
        @line += 1
        break
      end

      if starts_with_star?(line) || starts_with_backticks?(line) || starts_with_digits_dot?(line)
        break
      end

      newline
    end

    @renderer.end_paragraph

    append_double_newline_if_has_more
  end

  def render_code
    @renderer.begin_code

    while true
      line = @lines[@line]

      break unless has_code_spaces? line

      @renderer.text line.byte_slice(Math.min(line.bytesize, 4))
      @line += 1

      if @line == @lines.length
        break
      end

      if next_lines_empty_of_code?
        break
      end

      newline
    end

    @renderer.end_code

    append_double_newline_if_has_more
  end

  def render_fenced_code
    line = @lines[@line]
    language = line[3 .. -1].strip

    if language.empty?
      @renderer.begin_code
    else
      @renderer.begin_code language
    end

    @line += 1

    if @line < @lines.length
      while true
        line = @lines[@line]

        @renderer.text line
        @line += 1

        if (@line == @lines.length)
          break
        end

        if starts_with_backticks? @lines[@line]
          @line += 1
          break
        end

        newline
      end
    end

    @renderer.end_code

    append_double_newline_if_has_more
  end

  def render_unordered_list
    @renderer.begin_unordered_list

    while true
      line = @lines[@line]

      if empty? line
        @line += 1

        if @line == @lines.length
          break
        end

        next
      end

      break unless starts_with_star? line

      @renderer.begin_list_item
      process_line line.byte_slice(line.index('*').not_nil! + 1)
      @renderer.end_list_item
      @line += 1

      if @line == @lines.length
        break
      end
    end

    @renderer.end_unordered_list

    append_double_newline_if_has_more
  end

  def render_ordered_list
    @renderer.begin_ordered_list

    while true
      line = @lines[@line]

      if empty? line
        @line += 1

        if @line == @lines.length
          break
        end

        next
      end

      break unless starts_with_digits_dot? line

      @renderer.begin_list_item
      process_line line.byte_slice(line.index('.').not_nil! + 1)
      @renderer.end_list_item
      @line += 1

      if @line == @lines.length
        break
      end
    end

    @renderer.end_ordered_list

    append_double_newline_if_has_more
  end

  def append_double_newline_if_has_more
    if @line < @lines.length
      newline
      newline
    end
  end

  def process_line(line)
    bytesize = line.bytesize
    str = line.to_unsafe
    pos = 0

    while pos < bytesize && str[pos].chr.whitespace?
      pos += 1
    end

    cursor = pos
    one_star = false
    two_stars = false
    one_underscore = false
    two_underscores = false
    one_backtick = false
    in_link = false
    last_is_space = true

    while pos < bytesize
      case str[pos].chr
      when '*'
        if pos + 1 < bytesize && str[pos + 1].chr == '*'
          if two_stars || has_closing?('*', 2, str, (pos + 2), bytesize)
            @renderer.text line.byte_slice(cursor, pos - cursor)
            pos += 1
            cursor = pos + 1
            if two_stars
              @renderer.end_bold
            else
              @renderer.begin_bold
            end
            two_stars = !two_stars
          end
        elsif one_star || has_closing?('*', 1, str, (pos + 1), bytesize)
          @renderer.text line.byte_slice(cursor, pos - cursor)
          cursor = pos + 1
          if one_star
            @renderer.end_italic
          else
            @renderer.begin_italic
          end
          one_star = !one_star
        end
      when '_'
        if pos + 1 < bytesize && str[pos + 1].chr == '_'
          if two_underscores || (last_is_space && has_closing?('_', 2, str, (pos + 2), bytesize))
            @renderer.text line.byte_slice(cursor, pos - cursor)
            pos += 1
            cursor = pos + 1
            if two_underscores
              @renderer.end_bold
            else
              @renderer.begin_bold
            end
            two_underscores = !two_underscores
          end
        elsif one_underscore || (last_is_space && has_closing?('_', 1, str, (pos + 1), bytesize))
          @renderer.text line.byte_slice(cursor, pos - cursor)
          cursor = pos + 1
          if one_underscore
            @renderer.end_italic
          else
            @renderer.begin_italic
          end
          one_underscore = !one_underscore
        end
      when '`'
        if one_backtick || has_closing?('`', 1, str, (pos + 1), bytesize)
          @renderer.text line.byte_slice(cursor, pos - cursor)
          cursor = pos + 1
          if one_backtick
            @renderer.end_inline_code
          else
            @renderer.begin_inline_code
          end
          one_backtick = !one_backtick
        end
      when '!'
        if pos + 1 < bytesize && str[pos + 1] == '['.ord
          link = check_link str, (pos + 2), bytesize
          if link
            @renderer.text line.byte_slice(cursor, pos - cursor)

            bracket_idx = (str + pos + 2).to_slice(bytesize - pos - 2).index(']'.ord).not_nil!
            alt = line.byte_slice(pos + 2, bracket_idx)

            @renderer.image link, alt

            paren_idx = (str + pos + 2 + bracket_idx + 1).to_slice(bytesize - pos - 2 - bracket_idx - 1).index(')'.ord).not_nil!
            pos += 2 + bracket_idx + 1 + paren_idx
            cursor = pos + 1
          end
        end
      when '['
        unless in_link
          link = check_link str, (pos + 1), bytesize
          if link
            @renderer.text line.byte_slice(cursor, pos - cursor)
            cursor = pos + 1
            @renderer.begin_link link
            in_link = true
          end
        end
      when ']'
        if in_link
          @renderer.text line.byte_slice(cursor, pos - cursor)
          @renderer.end_link

          paren_idx = (str + pos + 1).to_slice(bytesize - pos - 1).index(')'.ord).not_nil!
          pos += paren_idx + 2
          cursor = pos
          in_link = false
        end
      end
      last_is_space = pos < bytesize && str[pos].chr.whitespace?
      pos += 1
    end

    @renderer.text line.byte_slice(cursor, pos - cursor)
  end

  def empty?(line)
    line_is_all? line, ' '
  end

  def has_closing?(char, count, str, pos, bytesize)
    str += pos
    bytesize -= pos
    idx = str.to_slice(bytesize).index char.ord
    return false unless idx

    if count == 2
      return false unless idx + 1 < bytesize && str[idx + 1].chr == char
    end

    !str[idx - 1].chr.whitespace?
  end

  def check_link(str, pos, bytesize)
    # We need to count nested brackets to do it right
    bracket_count = 1
    while pos < bytesize
      case str[pos].chr
      when '['
        bracket_count += 1
      when ']'
        bracket_count -= 1
        if bracket_count == 0
          break
        end
      end
      pos += 1
    end

    return nil unless bracket_count == 0
    bracket_idx = pos

    return nil unless str[bracket_idx + 1] == '('.ord

    paren_idx = (str + bracket_idx + 1).to_slice(bytesize - bracket_idx - 1).index ')'.ord
    return nil unless paren_idx

    String.new(Slice.new(str + bracket_idx + 2, paren_idx - 1))
  end

  def next_line_is_all?(char)
    return false unless @line + 1 < @lines.length

    line = @lines[@line + 1]
    return false if line.empty?

    line_is_all? line, char
  end

  def line_is_all?(line, char)
    line.each_byte do |byte|
      return false if byte != char.ord
    end
    true
  end

  def next_line_starts_with_backticks?
    return false unless @line + 1 < @lines.length
    starts_with_backticks? @lines[@line + 1]
  end

  def count_pounds(line)
    bytesize = line.bytesize
    str = line.to_unsafe
    pos = 0
    while pos < bytesize && pos < 6 && str[pos].chr == '#'
      pos += 1
    end
    pos == 0 ? nil : pos
  end

  def has_code_spaces?(line)
    bytesize = line.bytesize
    str = line.to_unsafe
    pos = 0
    while pos < bytesize && pos < 4 && str[pos].chr.whitespace?
      pos += 1
    end

    if pos < 4
      pos == bytesize
    else
      true
    end
  end

  def starts_with_star?(line)
    bytesize = line.bytesize
    str = line.to_unsafe
    pos = 0
    while pos < bytesize && str[pos].chr.whitespace?
      pos += 1
    end

    return false unless pos < bytesize
    return false unless str[pos].chr == '*'

    pos += 1

    return false unless pos < bytesize
    str[pos].chr.whitespace?
  end

  def starts_with_backticks?(line)
    line.starts_with? "```"
  end

  def starts_with_digits_dot?(line)
    bytesize = line.bytesize
    str = line.to_unsafe
    pos = 0
    while pos < bytesize && str[pos].chr.whitespace?
      pos += 1
    end

    return false unless pos < bytesize
    return false unless str[pos].chr.digit?

    while pos < bytesize && str[pos].chr.digit?
      pos += 1
    end

    return false unless pos < bytesize
    str[pos].chr == '.'
  end

  def next_lines_empty_of_code?
    line_number = @line

    while line_number < @lines.length
      line = @lines[line_number]

      if empty? line
        # Nothing
      elsif has_code_spaces? line
        return false
      else
        return true
      end

      line_number += 1
    end

    return true
  end

  def is_horizontal_rule?(line)
    non_space_char = nil
    count = 1

    line.each_char do |char|
      next if char.whitespace?

      if non_space_char
        if char == non_space_char
          count += 1
        else
          return false
        end
      else
        case char
        when '*', '-', '_'
          non_space_char = char
        else
          return false
        end
      end
    end

    count >= 3
  end

  def render_horizontal_rule
    @renderer.horizontal_rule
    @line += 1
  end

  def newline
    @renderer.text "\n"
  end
end

# specs

private def assert_render(input, output, file = __FILE__, line = __LINE__)
  it "renders #{input.inspect}", file, line do
    Markdown.to_html(input).should eq(output)
  end
end

describe Markdown do
  assert_render "", ""
  assert_render "Hello", "<p>Hello</p>"
  assert_render "Hello\nWorld", "<p>Hello\nWorld</p>"
  assert_render "Hello\n\nWorld", "<p>Hello</p>\n\n<p>World</p>"
  assert_render "Hello\n\n\n\n\nWorld", "<p>Hello</p>\n\n<p>World</p>"
  assert_render "Hello\n  \nWorld", "<p>Hello</p>\n\n<p>World</p>"
  assert_render "Hello\nWorld\n\nGood\nBye", "<p>Hello\nWorld</p>\n\n<p>Good\nBye</p>"

  assert_render "*Hello*", "<p><em>Hello</em></p>"
  assert_render "*Hello", "<p>*Hello</p>"
  assert_render "*Hello *", "<p>*Hello *</p>"
  assert_render "*Hello World*", "<p><em>Hello World</em></p>"
  assert_render "これは　*みず* です", "<p>これは　<em>みず</em> です</p>"

  assert_render "**Hello**", "<p><strong>Hello</strong></p>"
  assert_render "**Hello **", "<p>**Hello **</p>"

  assert_render "_Hello_", "<p><em>Hello</em></p>"
  assert_render "_Hello", "<p>_Hello</p>"
  assert_render "_Hello _", "<p>_Hello _</p>"
  assert_render "_Hello World_", "<p><em>Hello World</em></p>"

  assert_render "__Hello__", "<p><strong>Hello</strong></p>"
  assert_render "__Hello __", "<p>__Hello __</p>"

  assert_render "this_is_not_italic", "<p>this_is_not_italic</p>"
  assert_render "this__is__not__bold", "<p>this__is__not__bold</p>"

  assert_render "`Hello`", "<p><code>Hello</code></p>"

  assert_render "Hello\n=", "<h1>Hello</h1>"
  assert_render "Hello\n===", "<h1>Hello</h1>"
  assert_render "Hello\n===\nWorld", "<h1>Hello</h1>\n\n<p>World</p>"
  assert_render "Hello\n===World", "<p>Hello\n===World</p>"

  assert_render "Hello\n-", "<h2>Hello</h2>"
  assert_render "Hello\n-", "<h2>Hello</h2>"
  assert_render "Hello\n-World", "<p>Hello\n-World</p>"

  assert_render "#Hello", "<h1>Hello</h1>"
  assert_render "# Hello", "<h1>Hello</h1>"
  assert_render "#    Hello", "<h1>Hello</h1>"
  assert_render "## Hello", "<h2>Hello</h2>"
  assert_render "### Hello", "<h3>Hello</h3>"
  assert_render "#### Hello", "<h4>Hello</h4>"
  assert_render "##### Hello", "<h5>Hello</h5>"
  assert_render "###### Hello", "<h6>Hello</h6>"
  assert_render "####### Hello", "<h6># Hello</h6>"

  assert_render "# Hello\nWorld", "<h1>Hello</h1>\n\n<p>World</p>"

  assert_render "    Hello", "<pre><code>Hello</code></pre>"
  assert_render "    Hello\n    World", "<pre><code>Hello\nWorld</code></pre>"
  assert_render "    Hello\n\n    World", "<pre><code>Hello\n\nWorld</code></pre>"
  assert_render "    Hello\n\n   \n    World", "<pre><code>Hello\n\n\nWorld</code></pre>"
  assert_render "    Hello\n   World", "<pre><code>Hello</code></pre>\n\n<p>World</p>"
  assert_render "    Hello\n\n\nWorld", "<pre><code>Hello</code></pre>\n\n<p>World</p>"

  assert_render "```crystal\nHello\nWorld\n```", "<pre><code>Hello\nWorld</code></pre>"
  assert_render "Hello\n```\nWorld\n```", "<p>Hello</p>\n\n<pre><code>World</code></pre>"

  assert_render "* Hello", "<ul><li>Hello</li></ul>"
  assert_render "* Hello\n* World", "<ul><li>Hello</li><li>World</li></ul>"
  assert_render "* Hello\nWorld", "<ul><li>Hello</li></ul>\n\n<p>World</p>"
  assert_render "Params:\n  * Foo\n  * Bar", "<p>Params:</p>\n\n<ul><li>Foo</li><li>Bar</li></ul>"

  assert_render "1. Hello", "<ol><li>Hello</li></ol>"
  assert_render "2. Hello", "<ol><li>Hello</li></ol>"
  assert_render "01. Hello\n02. World", "<ol><li>Hello</li><li>World</li></ol>"
  assert_render "Params:\n  1. Foo\n  2. Bar", "<p>Params:</p>\n\n<ol><li>Foo</li><li>Bar</li></ol>"

  assert_render "Hello [world](http://foo.com)", %(<p>Hello <a href="http://foo.com">world</a></p>)
  assert_render "Hello [world](http://foo.com)!", %(<p>Hello <a href="http://foo.com">world</a>!</p>)
  assert_render "Hello [world **2**](http://foo.com)!", %(<p>Hello <a href="http://foo.com">world <strong>2</strong></a>!</p>)

  assert_render "Hello ![world](http://foo.com)", %(<p>Hello <img src="http://foo.com" alt="world"/></p>)
  assert_render "Hello ![world](http://foo.com)!", %(<p>Hello <img src="http://foo.com" alt="world"/>!</p>)

  assert_render "[![foo](bar)](baz)", %(<p><a href="baz"><img src="bar" alt="foo"/></a></p>)

  assert_render "***", "<hr/>"
  assert_render "---", "<hr/>"
  assert_render "___", "<hr/>"
  assert_render "  *  *  *  ", "<hr/>"

  assert_render "hello < world", "<p>hello &lt; world</p>"

  assert_render "Hello __[World](http://foo.com)__!", %(<p>Hello <strong><a href="http://foo.com">World</a></strong>!</p>)
end
