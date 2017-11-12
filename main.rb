require 'mini_magick'
require 'matrix'
require 'parallel'

class Main
  def initialize(front, back)
    @front = front
    @back = back
    @front_image = MiniMagick::Image.open(front)
    @back_image = MiniMagick::Image.open(back)
  end

  def generate_frame(i, yaw, pitch, roll)
    front_matrix = generate_rotation_matrix yaw, pitch, roll
    front_corners = [Vector[0, 0], Vector[@front_image.width.to_i, 0], Vector[@front_image.width.to_i, @front_image.height.to_i], Vector[0, @front_image.height.to_i]]
    front_projected_corners = front_corners.map do |corner|
      c2 = Vector[corner[0], corner[1], 0]
      rotated = front_matrix * c2
      project_2d rotated, @front_image.width / 2, @front_image.height / 2, 3000
    end
    front_perspective = front_corners.zip(front_projected_corners).map { |pair| "#{pair[0].to_a.map(&:round).join ','},#{pair[1].to_a.map(&:round).join ','}" }.join(' ')

    # x = Math::PI / 4
    back_matrix = generate_rotation_matrix yaw, pitch, roll - Math::PI
    back_corners = [Vector[0, 0], Vector[@back_image.width.to_i, 0], Vector[@back_image.width.to_i, @back_image.height.to_i], Vector[0, @back_image.height.to_i]]
    back_projected_corners = back_corners.map do |corner|
      c2 = Vector[corner[0], corner[1], 0]
      rotated = back_matrix * c2
      project_2d rotated, @back_image.width / 2, @back_image.height / 2, 3000
    end
    back_perspective = back_corners.zip(back_projected_corners).map { |pair| "#{pair[0].to_a.map(&:round).join ','},#{pair[1].to_a.map(&:round).join ','}" }.join(' ')

    convert @front, @back, "out_#{i.to_s.rjust(3, '0')}.png", front_perspective, back_perspective
  end

  def generate_rotation_matrix(yaw, pitch, roll)
    Matrix[
        [cos(yaw) * cos(pitch), cos(yaw) * sin(pitch) * sin(roll) - sin(yaw) * cos(roll), cos(yaw) * sin(pitch) * cos(roll) + sin(yaw) * sin(roll)],
        [sin(yaw) * cos(pitch), sin(yaw) * sin(pitch) * sin(roll) + cos(yaw) * cos(roll), sin(yaw) * sin(pitch) * cos(roll) - cos(yaw) * sin(roll)],
        [-sin(pitch), cos(pitch) * sin(roll), cos(pitch) * cos(roll)]
    ]
  end

  def project_2d(point, ex, ey, ez)
    px = point[0]
    py = point[1]
    pz = point[2]
    sx = (ez * (px - ex)) / (ez + pz) + ex
    sy = (ez * (py - ey)) / (ez + pz) + ey
    Vector[sx, sy]
  end

  def convert(front, back, output, front_perspective, back_perspective)
    MiniMagick::Tool::Convert.new do |convert|
      # convert << input
      convert.extent '1920x1080'
      convert.background 'white'
      # convert.stack do |stack|
      #   stack << front
      #   stack.background 'white'
      #   stack.virtual_pixel 'white'
      #   stack.distort 'Perspective', front_perspective
      # end
      convert << front
      convert.background 'white'
      convert.virtual_pixel 'white'
      convert.distort 'SRT', '0,0 1,1 0 772,300'
      convert.distort 'Perspective', front_perspective
      # convert.stack do |stack|
      #   stack << back
      #   stack.alpha 'set'
      #   stack.virtual_pixel 'transparent'
      #   stack.distort 'Perspective', back_perspective
      # end
      # convert.compose 'plus'
      # convert.layers 'merge'
      # convert.repage.+
      # convert.compose 'over'
      convert << output
    end
  end

  private

  def cos(x)
    Math.cos(x)
  end

  def sin(x)
    Math.sin(x)
  end
end

m = Main.new ARGV[0], ARGV[1]


a = 30
Parallel.each(a.times, progress: 'Generating frames A', in_threads: 8) do |i|
  p = (Math::PI/2 - i * Math::PI / 50).abs
  m.generate_frame i, 0, p, 0
end

b = 30
Parallel.each(b.times, progress: 'Generating frames B', in_threads: 8) do |i|
  p = (Math::PI/2 - i * Math::PI / 30).abs
  m.generate_frame i + 13 + a, p, 0, 0
end

c = 30
Parallel.each(c.times, progress: 'Generating frames C', in_threads: 8) do |i|
  p = (Math::PI/2 - i * Math::PI / 30).abs
  m.generate_frame i + 13 + a + b, 0, (Math::PI/2 - i * Math::PI / 40).abs, p
end

# 40.times do |i|
# end
# m.generate_frame 0, 0, 0, 3 * Math::PI / 4
