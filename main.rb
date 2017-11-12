require 'mini_magick'
require 'matrix'

class Main
  def initialize(input)
    image = MiniMagick::Image.open(input)
    matrix = generate_rotation_matrix Math::PI / 4, Math::PI / 4, Math::PI / 4
    corners = [Vector[0, 0], Vector[image.width.to_i, 0], Vector[image.width.to_i, image.height.to_i], Vector[0, image.height.to_i]]
    projected_corners = corners.map do |corner|
      c2 = Vector[corner[0], corner[1], 0]
      rotated = matrix * c2
      project_2d rotated, image.width / 2, image.height / 2, 3000
    end

    perspective = corners.zip(projected_corners).map { |pair| "#{pair[0].to_a.map(&:round).join ','},#{pair[1].to_a.map(&:round).join ','}" }.join(' ')
    convert input, 'out.png', perspective
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
      convert.extent '1920x1080'
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

Main.new ARGV[0]
