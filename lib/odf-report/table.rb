module ODFReport

  class Table
    include Images, Nested

    def initialize(opts)
      @name             = opts[:name]
      @collection_field = opts[:collection_field]
      @collection       = opts[:collection]

      @fields = []
      @texts = []
      @tables = []

      @images = []
      @image_name_additions = {}

      @template_rows = []
      @header           = opts[:header] || false
      @skip_if_empty    = opts[:skip_if_empty] || false
    end

    def replace!(doc, file, row = nil)

      return {} unless table = find_table_node(doc)

      @template_rows = table.xpath("table:table-row")

      @header = table.xpath("table:table-header-rows").empty? ? @header : false


      @collection = get_collection_from_item(row, @collection_field) if row

      if @skip_if_empty && @collection.empty?
        table.remove
        return
      end

      @collection.each do |data_item|

        new_node = get_next_row

        @tables.each { |t| @image_name_additions.merge! t.replace!(new_node, file, data_item) }

        @texts.each  { |t| t.replace!(new_node, data_item) }

        @fields.each { |f| f.replace!(new_node, data_item) }

        @images.each { |i| x = i.replace!(new_node, data_item); x.nil? ? nil : (@image_name_additions.merge! x) }

        table.add_child(new_node)

      end

      @template_rows.each_with_index do |r, i|
        r.remove if (get_start_node..template_length) === i
      end

      update_images(file)

      @image_name_additions

    end # replace

    private

    def get_next_row
      @row_cursor = get_start_node unless defined?(@row_cursor)

      ret = @template_rows[@row_cursor]
      if @template_rows.size == @row_cursor + 1
        @row_cursor = get_start_node
      else
        @row_cursor += 1
      end
      return ret.dup
    end

    def get_start_node
      @header ? 1 : 0
    end

    def template_length
      @tl ||= @template_rows.size
    end

    def find_table_node(doc)
      tables = doc.xpath(".//table:table[@table:name='#{@name}']")
      return tables.first if tables.first

      bookmark = doc.xpath(".//text:bookmark[@text:name='#{@name}']")
      return nil unless bookmark.first
      bookmark.first.ancestors('.//table:table').first
    end

  end

end
