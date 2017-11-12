require 'mini_magick'
require 'matrix'

class Main
  def initialize
    image = MiniMagick::Image.open('x.png')
    matrix = generate_rotation_matrix 0, 0, Math::PI / 4
    corners = [Vector[0, 0, 0], Vector[image.width.to_i, 0, 0], Vector[image.width.to_i, image.height.to_i, 0], Vector[0, image.height.to_i, 0]]
    projected_corners = corners.map do |corner|
      rotated = matrix * corner
      project_2d rotated, 1920/2, 1080/2, 3000
    end

    perspective = corners.zip(projected_corners).map { |pair| "#{pair[0].to_a.join ','},#{pair[1].to_a.join ','}" }.join(' ')
    convert 'x.png', 'out.png', perspective
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

  def convert(input, output, perspective)
    MiniMagick::Tool::Convert.new do |convert|
      convert << input
      convert.extent '4096x4096'
      convert.distort 'Perspective', perspective
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

Main.new
