# frozen_string_literal: true

module Jekyll
  PICTURE_VERSIONS = {
    #"xs" => "256",
    "s" => "400",
    "m" => "700",
  }

  class StaticFile
    attr_reader :site, :dest, :dir, :name
  end

  class OutImageFile < StaticFile
    def initialize(site, orig_static_file, version, pictype)
      super(site, site.source, orig_static_file.dir, orig_static_file.name)
      @version = version
      @picture_dim = PICTURE_VERSIONS.merge(site.config['picture_versions'] || {})[@version]
      @pictype = pictype
      @collection = nil
    end

    def picture?
      extname =~ /(\.jpg|\.jpeg|\.webp)$/i
    end

    def destination(dest)
      output_dir = File.join("img",@version,@dir)
      output_basename = @site.in_dest_dir(@site.dest,File.join(output_dir, "#{basename}.#{@pictype}"))
      FileUtils.mkdir_p(File.dirname(output_dir))
      @destination ||= {}
      @destination[dest] ||= output_basename
    end

    def write(*args)
      puts "write : #{args} Modified : #{modified?}"
      super(*args)
    end

    def copy_file(dest_path)
      puts "copy_file : #{path} -> #{dest_path}"
      if @pictype == "jpg"
        p=IO.popen(["convert", @path, "-resize", @picture_dim+"x"+">", "-background", "#"+@site.config["background_color"], "-flatten", "-alpha", "off", dest_path])
        p.close
      else
        p=IO.popen(["convert", @path, "-resize", @picture_dim+"x"+">", dest_path])
        p.close
      end

      unless File.symlink?(dest_path)
        File.utime(self.class.mtimes[path], self.class.mtimes[path], dest_path)
      end
    end
  end

  class PicsGenerator < Generator
    safe true
    priority :lowest

    def generate(site)
      @picture_versions = PICTURE_VERSIONS.merge(site.config['picture_versions'] || {})
      new_statics = []
      site.static_files.filter{|f| f.extname =~ /(\.jpg|\.jpeg|\.webp)$/i}.each do |f|
        @picture_versions.each do |v, s|
          img_f = OutImageFile.new(site, f, v, "jpg")
          new_statics << img_f
          img_f = OutImageFile.new(site, f, v, "webp")
          new_statics << img_f
        end
      end

      new_statics.each{|f| site.static_files << f}
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
                x.gsub(" ", "%20")
              end.join("/"),
              File.basename(el.attr['src'],File.extname(el.attr['src'])).gsub(" ", "%20")
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
