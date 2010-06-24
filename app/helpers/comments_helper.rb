module CommentsHelper
  # formats an comment's body for display on updates/index
  def abbreviated_body(comment)
    text = simple_link_format(comment.body)
    if comment.body.length <= 256
      text
    else 
      paragraphs = text.split(/<p>|<\p>/).collect {|p| p.strip}.select {|p| p.length > 0}
      len = 0
      to_display = paragraphs.select do |p|
        len += p.length if len < 256
        len < 256 || len - p.length < 256
      end
      
      if len > 256 # truncate
        to_display[-1] = truncate_at(to_display[-1], 256 - (len - to_display[-1].length))
      end
      
      joined = to_display.join("</p>\n<p>")
      "<p>#{joined}</p>"
    end
  end

  # trims text down to about 256 characters for display
  def truncate_at(str,len)
    truncated = str[0..len+1]
    if truncated[-1] =~ /\s/
      truncated.strip!
    else
      words = truncated.split(' ')
      words.delete_at(-1)
      truncated = words.join(' ')
    end
    truncated
  end
end
