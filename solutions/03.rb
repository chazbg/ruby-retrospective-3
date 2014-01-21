module Graphics
  module Renderers
    class Html
      HTML_HEADER = "<!DOCTYPE html>
                      <html>
                      <head>
                        <title>Rendered Canvas</title>
                        <style type=\"text/css\">
                          .canvas {
                            font-size: 1px;
                            line-height: 1px;
                          }
                          .canvas * {
                            display: inline-block;
                            width: 10px;
                            height: 10px;
                            border-radius: 5px;
                          }
                          .canvas i {
                            background-color: #eee;
                          }
                          .canvas b {
                            background-color: #333;
                          }
                        </style>
                      </head>
                      <body>
                      <div class=\"canvas\">\n"
      HTML_FOOTER = " </div>
                  </body>
                  </html>\n"

      def render(canvas)
        HTML_HEADER + (0...canvas.height).to_a.map do |y|
          (0...canvas.width).to_a.map do |x|
            pixel_to_html canvas, x, y
          end.join
        end.join("<br>\n") + HTML_FOOTER
      end

      private

      def pixel_to_html(canvas, x, y)
        canvas.pixel_at?(x, y) ? "<b></b>" : "<i></i>"
      end
    end

    class Ascii
      def render(canvas)
        (0...canvas.height).to_a.map do |y|
          (0...canvas.width).to_a.map do |x|
            pixel_to_ascii canvas, x, y
          end.join
        end.join "\n"
      end

      private

      def pixel_to_ascii(canvas, x, y)
        canvas.pixel_at?(x, y) ? "@" : "-"
      end
    end
  end
  class Point
    attr_reader :x, :y, :plot

    def initialize(x, y)
      @x = x
      @y = y
      @plot = [self]
    end

    def ==(point)
      @x == point.x and @y == point.y
    end

    alias_method :eql?, :==

    def hash
      [@x, @y].hash
    end
  end

  class Line
    attr_reader :from, :to, :plot

    def initialize(point_a, point_b)
      initialize_line_ends(point_a, point_b)
      @plot = []
      point_a.x != point_b.x ? plot_standard : plot_vertical
    end

    def ==(line)
      @from == line.from and @to == line.to
    end

    alias_method :eql?, :==

    def hash
      [@from, @to].hash
    end

    private

    def initialize_line_ends(point_a, point_b)
      if point_a.x != point_b.x
        @from = point_a.x <= point_b.x ? point_a : point_b
        @to = point_a.x > point_b.x ? point_a : point_b
      else
        @from = point_a.y <= point_b.y ? point_a : point_b
        @to = point_a.y > point_b.y ? point_a : point_b
      end
    end

    def plot_standard
      error_delta = ((@to.y - @from.y).to_f / (@to.x - @from.x).to_f).abs
      error, y = 0, @from.y

      (@from.x..@to.x).each do |x|
        @plot << Point.new(x, y)
        error, y = new_error_and_ordinate error, error_delta, y
      end

      @plot += Line.new(Point.new(@to.x, y), @to).plot
    end

    def new_error_and_ordinate(error, error_delta, y)
      error += error_delta
      if error >= 0.5
        @from.y < @to.y ? y += 1 : y -= 1
        error -= 1.0
      end
      return error, y
    end

    def plot_vertical
      (@from.y..@to.y).each { |y| @plot << Point.new(@from.x, y) }
    end
  end

  class Rectangle
    attr_reader :left, :right, :plot
    attr_reader :top_left, :top_right, :bottom_left, :bottom_right

    def initialize(point_a, point_b)
      @plot = []
      initialize_ends point_a, point_b
      create_ends
      plot_pixels
    end

    def ==(rectangle)
      @left == rectangle.left and @right == rectangle.right
    end

    alias_method :eql?, :==

    def hash
      [@top_left, @top_right, @bottom_left, @bottom_right].hash
    end

    private

    def initialize_ends(point_a, point_b)
      if point_a.x != point_b.x
        @left = point_a.x <= point_b.x ? point_a : point_b
        @right = point_a.x > point_b.x ? point_a : point_b
      else
        @left = point_a.y <= point_b.y ? point_a : point_b
        @right = point_a.y > point_b.y ? point_a : point_b
      end
    end

    def create_ends
      left_x = Point.new(@left.x, @right.y)
      right_x = Point.new(@right.x, @left.y)

      @top_left = @left.y <= left_x.y ? @left : left_x
      @bottom_left = @left.y > left_x.y ? @left : left_x

      @top_right = @right.y <= right_x.y ? @right : right_x
      @bottom_right = @right.y > right_x.y ? @right : right_x
    end

    def plot_pixels
      @plot = [
                @top_left,     @top_right,
                @top_right,    @bottom_right,
                @bottom_right, @bottom_left,
                @bottom_left,  @top_left,
              ].each_slice(2).map { |a, b| Line.new(a, b).plot }.flatten
    end
  end

  class Canvas
    attr_reader :width, :height

    def initialize(width, height)
      @width = width
      @height = height
      @pixel_matrix = Hash.new
    end

    def set_pixel(x, y)
      @pixel_matrix[Point.new(x, y)] = true
    end

    def pixel_at?(x, y)
      @pixel_matrix[Point.new(x, y)]
    end

    def draw(object)
      object.plot.each { |pixel| set_pixel(pixel.x, pixel.y) }
    end

    def render_as(renderer_type)
      renderer = renderer_type.new
      renderer.render self
    end
  end
end

d = Graphics::Canvas.new(10,10)
#d.set_pixel(1,0)
#p d.pixel_at?(1,1), d.pixel_at?(1,0)
#d.draw Graphics::Point.new(3,2)
#d.render_as(Graphics::Renderers::Html)
#p Graphics::Point.new(3,2).eql? Graphics::Point.new(3,2)
rectangle = Graphics::Rectangle.new(Graphics::Point.new(3,2), Graphics::Point.new(4,5))
#p line.from.x, line.from.y, line.to.x, line.to.y
#p rectangle.hash
#d.draw rectangle
#d.render_as(Graphics::Renderers::Ascii)

module Graphics
  canvas = Canvas.new 30, 30

  # Door frame and window
  canvas.draw Rectangle.new(Point.new(3, 3), Point.new(18, 12))
  canvas.draw Rectangle.new(Point.new(1, 1), Point.new(20, 28))

  # Door knob
  canvas.draw Line.new(Point.new(4, 15), Point.new(7, 15))
  canvas.draw Point.new(4, 16)

  # Big "R"
  canvas.draw Line.new(Point.new(8, 5), Point.new(8, 10))
  canvas.draw Line.new(Point.new(9, 5), Point.new(12, 5))
  canvas.draw Line.new(Point.new(9, 7), Point.new(12, 7))
  canvas.draw Point.new(13, 6)
  canvas.draw Line.new(Point.new(12, 8), Point.new(13, 10))

  puts canvas.render_as(Renderers::Ascii)
end