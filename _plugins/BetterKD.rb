# frozen_string_literal: true


module Jekyll
  PICTURE_VERSIONS = {
    #"xs" => "256",
    "s" => "400",
    "m" => "700",
  }

  class StaticFile
    def picture_versions
      @site.config['picture_versions']
    end

    alias_method :old_copy_file, :copy_file
    def copy_file(dest_path)
      res=old_copy_file(dest_path)
      if picture?
        convert_picture(dest_path)
      end
      res
    end

    def picture?
      extname =~ /(\.jpg|\.jpeg|\.webp)$/i
    end

    def convert_picture(dest_path)
      puts dest_path
      threads = []
      Jekyll::PICTURE_VERSIONS.each_with_index do |(version, geometry), index|
        output_dir = @site.in_dest_dir(File.join("img",version,@dir))
        FileUtils.mkdir_p(output_dir)
        output_basename = File.join(output_dir, basename)
        threads.push Thread.new {
          p=IO.popen(["convert", path, "-resize", geometry+"x"+">", "-background", "#"+@site.config["background_color"], "-flatten", "-alpha", "off", output_basename+".jpg"])
          p.close
        }

        threads.push Thread.new {
          p=IO.popen(["convert", path, "-resize", geometry+"x"+geometry+">", output_basename+".webp"])
          p.close
        }
      end
      threads.each do |thread|
        thread.join
      end
    end
  end
end

module Kramdown
  module Parser
    class Kramdown
      def add_link(el, href, title, alt_text = nil, ial = nil)
        el.options[:ial] = ial
        update_attr_with_ial(el.attr, ial) if ial
        if el.type == :a
          el.attr['href'] = href
        else
          el.attr['src'] = href
          el.attr['alt'] = alt_text
          el.attr['loading'] = el.attr['loading']||"lazy"
          el.children.clear
          #puts href
        end
        el.attr['title'] = title if title
        @tree.children << el
      end

      require 'kramdown/parser/kramdown'
    end
  end

  module Converter
    class Html
      def convert_img(el, _indent)
        require 'cgi'
        res = "<picture>"
        new_src = el.attr['src']
        if File.extname(el.attr['src']) =~ /(\.jpg|\.jpeg|\.webp)$/i
          Jekyll::PICTURE_VERSIONS.each_with_index do |(version, geometry), index|
            src_base = File.join(
              "/img",
              version,
              File.dirname(el.attr['src']).split("/").map do |x|
                CGI.escapeURIComponent(x)
              end.join("/"),
              CGI.escapeURIComponent(File.basename(el.attr['src'],File.extname(el.attr['src'])))
            )
            if index == Jekyll::PICTURE_VERSIONS.size - 1
              media = ""
              new_src = "#{src_base}.jpg"
            else
              media = "media=\"(max-width: #{geometry}px)\""
            end
            res+= "<source #{media} srcset=\"#{src_base}.webp\" type=\"image/webp\">"
            res+= "<source #{media} srcset=\"#{src_base}.jpg\" type=\"image/jpeg\">"
          end
        end
        el.attr['src'] = new_src
        res += "<img#{html_attributes(el.attr)}>" 
        res += "</picture>"
      end
    end
  end
end
