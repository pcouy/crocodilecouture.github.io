# frozen_string_literal: true


module Jekyll
  PICTURE_VERSIONS = {
    "xs" => "128",
    "s" => "256",
    "m" => "512",
    "l" => "1024",
    "xl" => "2048"
  }

  class StaticFile
    def picture_versions
      @site.config['picture_versions']
    end

    alias_method :old_copy_file, :copy_file
    def copy_file(dest_path)
      if picture?
        convert_picure(dest_path)
      end
      old_copy_file(dest_path)
    end

    def picture?
      extname =~ /(\.jpg|\.jpeg|\.webp)$/i
    end

    def convert_picure(dest_path)
      puts dest_path
      Jekyll::PICTURE_VERSIONS.each do |version, geometry|
        output_dir = @site.in_dest_dir(File.join("img",version,@dir))
        FileUtils.mkdir_p(output_dir)
        output_basename = File.join(output_dir, basename)
        p=IO.popen(["convert", path, "-resize", geometry+"x"+geometry+">", "-background", "#"+@site.config["background_color"], "-flatten", "-alpha", "off", output_basename+".jpg"])
        p.close

        p=IO.popen(["convert", path, "-resize", geometry+"x"+geometry+">", output_basename+".webp"])
        p.close
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
        res = "<picture>"
        if File.extname(el.attr['src']) =~ /(\.jpg|\.jpeg|\.webp)$/i
          Jekyll::PICTURE_VERSIONS.each do |version, geometry|
            src_base = File.join("img",version,File.dirname(el.attr['src']),File.basename(el.attr['src'],File.extname(el.attr['src'])))
            res+= "<source media=\"(max-width: #{geometry}px)\" srcset=\"#{src_base}.webp, #{src_base}.jpg\">"
          end
        end
        res += "<img#{html_attributes(el.attr)}>" 
        res += "</picture>"
      end
    end
  end
end
